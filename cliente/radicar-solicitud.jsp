<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ page import="java.sql.PreparedStatement, java.sql.ResultSet" %>
<%@ page import="java.util.ArrayList, java.util.List" %>
<%
    String[] rolesPermitidos = { "Cliente" };
%>
<%@ include file="/jspf/seguridad.jspf" %>
<%@ include file="/jspf/conexion.jspf" %>
<%
    Integer idPropiedad = null;
    try { idPropiedad = Integer.valueOf(request.getParameter("propiedad")); } catch (Exception ignored) { }
    if (idPropiedad == null) {
        response.sendRedirect(request.getContextPath() + "/catalogo.jsp");
        return;
    }

    String tituloPropiedad = null, operacionPropiedad = null, ciudadPropiedad = null;
    if (conexion != null) {
        try (PreparedStatement ps = conexion.prepareStatement(
                "SELECT p.titulo, p.operacion, c.nombre_ciudad FROM propiedad p " +
                "INNER JOIN ciudad c ON c.id_ciudad = p.id_ciudad " +
                "WHERE p.id_propiedad = ? AND p.activo = 1")) {
            ps.setInt(1, idPropiedad);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    tituloPropiedad = rs.getString(1);
                    operacionPropiedad = rs.getString(2);
                    ciudadPropiedad = rs.getString(3);
                }
            }
        } catch (Exception ignored) { }
    }

    if (tituloPropiedad == null) {
        try { if (conexion != null) conexion.close(); } catch (Exception ignored) { }
        response.sendRedirect(request.getContextPath() + "/catalogo.jsp");
        return;
    }

    List<String> errores = new ArrayList<>();
    boolean radicadaExitosa = false;
    String tipoSolicitud = operacionPropiedad, observaciones = "";
    int idUsuarioSesion = (Integer) session.getAttribute("idUsuario");

    if ("POST".equalsIgnoreCase(request.getMethod())) {
        tipoSolicitud = request.getParameter("tipoSolicitud") != null ? request.getParameter("tipoSolicitud").trim() : "";
        observaciones = request.getParameter("observaciones") != null ? request.getParameter("observaciones").trim() : "";

        if (!"compra".equals(tipoSolicitud) && !"arriendo".equals(tipoSolicitud)) {
            errores.add("Selecciona un tipo de solicitud valido.");
        }
        if (observaciones.length() > 255) {
            errores.add("Las observaciones no pueden superar 255 caracteres.");
        }

        if (errores.isEmpty() && conexion != null) {
            try (PreparedStatement ps = conexion.prepareStatement(
                    "INSERT INTO solicitud (id_propiedad, id_cliente, tipo_solicitud, estado, observaciones) " +
                    "VALUES (?, ?, ?, 'pendiente', ?)")) {
                ps.setInt(1, idPropiedad);
                ps.setInt(2, idUsuarioSesion);
                ps.setString(3, tipoSolicitud);
                if (observaciones.isEmpty()) ps.setNull(4, java.sql.Types.VARCHAR); else ps.setString(4, observaciones);
                ps.executeUpdate();
                radicadaExitosa = true;
            } catch (Exception e) {
                errores.add("No fue posible radicar la solicitud. Intenta nuevamente.");
            }
        }
    }

    try { if (conexion != null) conexion.close(); } catch (Exception ignored) { }
%><!DOCTYPE html>
<html lang="es">
<head>
    <% String hgTitulo = "Radicar solicitud"; %>
    <%@ include file="/jspf/head-comun.jspf" %>
</head>
<body>
<%@ include file="/jspf/panel-header.jspf" %>

<div class="hg-panel-body" style="max-width:560px;">
    <div class="hg-panel-hero">
        <span class="hg-eyebrow">Radicar solicitud</span>
        <h1><%= tituloPropiedad %></h1>
        <p>📍 <%= ciudadPropiedad %> &middot; <a href="<%= request.getContextPath() %>/detalle.jsp?id=<%= idPropiedad %>">Ver ficha completa</a></p>
    </div>

    <% if (radicadaExitosa) { %>
    <div class="hg-panel-card">
        <div class="hg-panel-empty">
            <div class="hg-panel-empty__icon"><i class="bi bi-clipboard"></i></div>
            <p>Tu solicitud quedo <strong>pendiente</strong> de revision. Ahora puedes radicar los documentos requeridos.</p>
            <a class="hg-btn hg-btn--primary" href="<%= request.getContextPath() %>/cliente/mis-solicitudes.jsp">Ir a mis solicitudes</a>
        </div>
    </div>
    <% } else { %>

        <% if (!errores.isEmpty()) { %>
        <div class="hg-alert hg-alert--error" style="margin-bottom:20px;">
            <ul><% for (String err : errores) { %><li><%= err %></li><% } %></ul>
        </div>
        <% } %>

        <div class="hg-panel-card">
            <form method="post" action="<%= request.getContextPath() %>/cliente/radicar-solicitud.jsp?propiedad=<%= idPropiedad %>" style="display:flex; flex-direction:column; gap:16px;" class="js-form-cargando">
                <div class="hg-field">
                    <label for="tipoSolicitud">Tipo de solicitud</label>
                    <select class="form-select" id="tipoSolicitud" name="tipoSolicitud">
                        <option value="compra" <%= "compra".equals(tipoSolicitud) ? "selected" : "" %>>Compra</option>
                        <option value="arriendo" <%= "arriendo".equals(tipoSolicitud) ? "selected" : "" %>>Arriendo</option>
                    </select>
                </div>
                <div class="hg-field">
                    <label for="observaciones">Observaciones (opcional)</label>
                    <textarea class="form-control" id="observaciones" name="observaciones" rows="3" maxlength="255"><%= observaciones %></textarea>
                </div>
                <button class="hg-btn hg-btn--primary" type="submit">Radicar solicitud</button>
            </form>
        </div>
    <% } %>
</div>
<%@ include file="/jspf/scripts-panel.jspf" %>
</body>
</html>
