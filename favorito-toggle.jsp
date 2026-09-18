<%@ page contentType="application/json;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ page import="java.sql.PreparedStatement, java.sql.ResultSet" %>
<%@ page import="java.util.List" %>
<%@ page import="javax.servlet.http.HttpServletResponse" %>
<%@ include file="/jspf/conexion.jspf" %>
<%
    // =========================================================================
    // Endpoint AJAX para alternar un favorito desde el boton de la ficha de
    // detalle sin recargar la pagina (fetch). JSP puro, sin Servlet ni DAO:
    // hace exactamente el mismo INSERT/DELETE en "favorito" que ya existia
    // en detalle.jsp (patron POST/Redirect/GET); ese formulario sigue
    // funcionando igual como respaldo si el cliente no tiene JavaScript.
    // Responde JSON (a mano, sin libreria) en vez de redirigir, porque quien
    // llama es fetch() y no un navegador completo.
    // =========================================================================
    response.setHeader("Cache-Control", "no-store");

    Integer idUsuarioSesion = (Integer) session.getAttribute("idUsuario");
    @SuppressWarnings("unchecked")
    List<String> rolesSesion = (List<String>) session.getAttribute("roles");
    boolean autorizado = idUsuarioSesion != null && rolesSesion != null && rolesSesion.contains("Cliente");

    if (!autorizado) {
        response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
        out.print("{\"error\":\"No autorizado\"}");
        return;
    }

    Integer idPropiedad = null;
    try { idPropiedad = Integer.valueOf(request.getParameter("idPropiedad")); } catch (Exception ignored) { }

    if (idPropiedad == null || conexion == null) {
        response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
        out.print("{\"error\":\"Solicitud invalida\"}");
        return;
    }

    try {
        boolean yaEsFavorito;
        try (PreparedStatement psCheck = conexion.prepareStatement(
                "SELECT 1 FROM favorito WHERE id_usuario = ? AND id_propiedad = ?")) {
            psCheck.setInt(1, idUsuarioSesion);
            psCheck.setInt(2, idPropiedad);
            try (ResultSet rs = psCheck.executeQuery()) { yaEsFavorito = rs.next(); }
        }

        boolean favoritoFinal;
        if (yaEsFavorito) {
            try (PreparedStatement psDel = conexion.prepareStatement(
                    "DELETE FROM favorito WHERE id_usuario = ? AND id_propiedad = ?")) {
                psDel.setInt(1, idUsuarioSesion);
                psDel.setInt(2, idPropiedad);
                psDel.executeUpdate();
            }
            favoritoFinal = false;
        } else {
            try (PreparedStatement psIns = conexion.prepareStatement(
                    "INSERT INTO favorito (id_usuario, id_propiedad) VALUES (?, ?)")) {
                psIns.setInt(1, idUsuarioSesion);
                psIns.setInt(2, idPropiedad);
                psIns.executeUpdate();
            }
            favoritoFinal = true;
        }
        out.print("{\"favorito\":" + favoritoFinal + "}");
    } catch (Exception e) {
        response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
        out.print("{\"error\":\"No fue posible actualizar el favorito\"}");
    } finally {
        try { if (conexion != null) conexion.close(); } catch (Exception ignored) { }
    }
%>
