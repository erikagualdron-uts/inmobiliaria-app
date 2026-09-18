<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ page import="java.sql.PreparedStatement, java.sql.ResultSet" %>
<%@ page import="java.text.NumberFormat, java.util.Locale" %>
<%@ page import="java.util.ArrayList, java.util.List, java.util.Map, java.util.LinkedHashMap" %>
<%
    String[] rolesPermitidos = { "Inmobiliaria" };
%>
<%@ include file="/jspf/seguridad.jspf" %>
<%@ include file="/jspf/conexion.jspf" %>
<%
    // =========================================================================
    // Listado de propiedades de LA inmobiliaria del agente en sesion. Toda
    // operacion valida que la propiedad pertenezca a esa inmobiliaria antes
    // de tocarla (no basta con el rol: tambien se verifica la propiedad).
    // =========================================================================
    int idUsuarioSesion = (Integer) session.getAttribute("idUsuario");
    Integer idInmobiliaria = null;
    String mensaje = null, mensajeTipo = "success";

    if (conexion != null) {
        try (PreparedStatement ps = conexion.prepareStatement("SELECT id_inmobiliaria FROM usuario WHERE id_usuario = ?")) {
            ps.setInt(1, idUsuarioSesion);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    int idIn = rs.getInt(1);
                    if (!rs.wasNull()) idInmobiliaria = idIn;
                }
            }
        } catch (Exception ignored) { }

        // Alternar baja logica (activo <-> inactivo), patron Post/Redirect/Get
        if ("POST".equalsIgnoreCase(request.getMethod()) && "toggleActivo".equals(request.getParameter("accion")) && idInmobiliaria != null) {
            try {
                Integer idPropiedadAccion = Integer.valueOf(request.getParameter("idPropiedad"));
                try (PreparedStatement ps = conexion.prepareStatement(
                        "UPDATE propiedad SET activo = 1 - activo WHERE id_propiedad = ? AND id_inmobiliaria = ?")) {
                    ps.setInt(1, idPropiedadAccion);
                    ps.setInt(2, idInmobiliaria);
                    ps.executeUpdate();
                }
            } catch (Exception ignored) { }
            try { conexion.close(); } catch (Exception ignored) { }
            response.sendRedirect(request.getContextPath() + "/inmobiliaria/mis-propiedades.jsp?actualizado=1");
            return;
        }
    }

    if ("1".equals(request.getParameter("creado"))) { mensaje = "Propiedad publicada con exito."; }
    if ("1".equals(request.getParameter("actualizado"))) { mensaje = "Los cambios se guardaron correctamente."; }

    List<Map<String, Object>> propiedades = new ArrayList<>();
    if (conexion != null && idInmobiliaria != null) {
        try (PreparedStatement ps = conexion.prepareStatement(
                "SELECT p.id_propiedad, p.titulo, p.matricula_inmobiliaria, p.precio, p.operacion, p.estado, p.activo, " +
                "       c.nombre_ciudad, t.nombre_tipo, img.url_imagen " +
                "FROM propiedad p " +
                "INNER JOIN ciudad c ON c.id_ciudad = p.id_ciudad " +
                "INNER JOIN tipo_propiedad t ON t.id_tipo = p.id_tipo " +
                "LEFT JOIN imagen_propiedad img ON img.id_propiedad = p.id_propiedad AND img.es_principal = 1 " +
                "WHERE p.id_inmobiliaria = ? " +
                "ORDER BY p.fecha_publicacion DESC")) {
            ps.setInt(1, idInmobiliaria);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> fila = new LinkedHashMap<>();
                    fila.put("id", rs.getInt("id_propiedad"));
                    fila.put("titulo", rs.getString("titulo"));
                    fila.put("matricula", rs.getString("matricula_inmobiliaria"));
                    fila.put("precio", rs.getBigDecimal("precio"));
                    fila.put("operacion", rs.getString("operacion"));
                    fila.put("estado", rs.getString("estado"));
                    fila.put("activo", rs.getInt("activo") == 1);
                    fila.put("ciudad", rs.getString("nombre_ciudad"));
                    fila.put("tipo", rs.getString("nombre_tipo"));
                    fila.put("imagen", rs.getString("url_imagen"));
                    propiedades.add(fila);
                }
            }
        } catch (Exception ignored) { }
    }

    if (conexion != null) { try { conexion.close(); } catch (Exception ignored) { } }

    NumberFormat formatoCOP = NumberFormat.getInstance(new Locale("es", "CO"));
%><!DOCTYPE html>
<html lang="es">
<head>
    <% String hgTitulo = "Mis propiedades"; %>
    <%@ include file="/jspf/head-comun.jspf" %>
</head>
<body>
<%@ include file="/jspf/panel-header.jspf" %>

<div class="hg-panel-body">
    <div class="hg-panel-hero" style="display:flex; justify-content:space-between; align-items:flex-end; flex-wrap:wrap; gap:16px;">
        <div>
            <span class="hg-eyebrow">Panel de inmobiliaria</span>
            <h1>Mis propiedades</h1>
            <p>Publica, edita o da de baja los inmuebles de tu inmobiliaria.</p>
        </div>
        <a class="hg-btn hg-btn--primary" href="<%= request.getContextPath() %>/inmobiliaria/propiedad-form.jsp"><i class="bi bi-plus-lg"></i> Publicar propiedad</a>
    </div>

    <% if (idInmobiliaria == null) { %>
    <div class="hg-alert hg-alert--error">Tu cuenta aun no esta asociada a ninguna inmobiliaria. Contacta al administrador para poder publicar propiedades.</div>
    <% } else { %>

        <% if (mensaje != null) { %>
        <div class="hg-alert hg-alert--success" style="margin-bottom:20px;"><%= mensaje %></div>
        <% } %>

        <% if (propiedades.isEmpty()) { %>
        <div class="hg-panel-card">
            <div class="hg-panel-empty">
                <div class="hg-panel-empty__icon"><i class="bi bi-house"></i></div>
                <p>Aun no has publicado ninguna propiedad.</p>
                <a class="hg-btn hg-btn--primary" href="<%= request.getContextPath() %>/inmobiliaria/propiedad-form.jsp">Publicar la primera</a>
            </div>
        </div>
        <% } else { %>
        <div class="hg-mgmt-grid">
            <% for (Map<String, Object> p : propiedades) {
                boolean activo = (Boolean) p.get("activo");
                String estadoP = (String) p.get("estado");
                String operacionP = (String) p.get("operacion");
                String precioTxt = "$ " + formatoCOP.format(p.get("precio")) + ("arriendo".equals(operacionP) ? " / mes" : "");
                Object imgP = p.get("imagen");
            %>
            <div class="hg-mgmt-card">
                <div class="hg-mgmt-card__media">
                    <% if (imgP != null) { %>
                    <img src="<%= imgP %>" alt="<%= p.get("titulo") %>">
                    <% } else { %><i class="bi bi-image"></i><% } %>
                </div>
                <div class="hg-mgmt-card__body">
                    <div class="hg-mgmt-card__top">
                        <div>
                            <h4><%= p.get("titulo") %></h4>
                            <p><i class="bi bi-upc-scan"></i> <%= p.get("matricula") %> &middot; <i class="bi bi-geo-alt"></i> <%= p.get("ciudad") %> &middot; <%= p.get("tipo") %></p>
                        </div>
                        <div class="hg-mgmt-card__badges">
                            <span class="hg-badge--estado hg-badge--<%= estadoP %>" style="position:static; display:inline-block;"><%= estadoP.substring(0,1).toUpperCase() + estadoP.substring(1) %></span>
                            <span class="hg-badge--estado <%= activo ? "hg-badge--disponible" : "hg-badge--vendido" %>" style="position:static; display:inline-block;"><%= activo ? "Activa" : "Dada de baja" %></span>
                        </div>
                    </div>
                    <div class="hg-mgmt-card__bottom">
                        <span class="hg-mgmt-card__precio"><%= precioTxt %> &middot; <%= "venta".equals(operacionP) ? "Venta" : "Arriendo" %></span>
                        <div class="hg-mgmt-card__acciones">
                            <a class="hg-btn hg-btn--ghost hg-btn--sm" href="<%= request.getContextPath() %>/detalle.jsp?id=<%= p.get("id") %>" target="_blank"><i class="bi bi-eye"></i> Ver ficha</a>
                            <a class="hg-btn hg-btn--ghost hg-btn--sm" href="<%= request.getContextPath() %>/inmobiliaria/propiedad-form.jsp?id=<%= p.get("id") %>"><i class="bi bi-pencil"></i> Editar</a>
                            <a class="hg-btn hg-btn--ghost hg-btn--sm" href="<%= request.getContextPath() %>/inmobiliaria/propiedad-galeria.jsp?id=<%= p.get("id") %>"><i class="bi bi-images"></i> Galeria</a>
                            <form method="post" action="<%= request.getContextPath() %>/inmobiliaria/mis-propiedades.jsp">
                                <input type="hidden" name="accion" value="toggleActivo">
                                <input type="hidden" name="idPropiedad" value="<%= p.get("id") %>">
                                <button class="hg-btn hg-btn--sm <%= activo ? "hg-btn--ghost" : "hg-btn--primary" %>" type="submit">
                                    <i class="bi <%= activo ? "bi-slash-circle" : "bi-arrow-counterclockwise" %>"></i> <%= activo ? "Dar de baja" : "Reactivar" %>
                                </button>
                            </form>
                        </div>
                    </div>
                </div>
            </div>
            <% } %>
        </div>
        <% } %>
    <% } %>
</div>
<%@ include file="/jspf/scripts-panel.jspf" %>
</body>
</html>
