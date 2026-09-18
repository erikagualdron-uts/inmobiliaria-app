<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ page import="java.sql.PreparedStatement, java.sql.ResultSet" %>
<%@ page import="java.util.ArrayList, java.util.List, java.util.Map, java.util.LinkedHashMap" %>
<%
    String[] rolesPermitidos = { "Cliente" };
%>
<%@ include file="/jspf/seguridad.jspf" %>
<%@ include file="/jspf/conexion.jspf" %>
<%
    int idUsuarioSesion = (Integer) session.getAttribute("idUsuario");
    List<Map<String, Object>> favoritos = new ArrayList<>();

    if (conexion != null) {
        try (PreparedStatement ps = conexion.prepareStatement(
                "SELECT p.id_propiedad, p.titulo, p.precio, p.operacion, p.estado, " +
                "       p.num_habitaciones, p.num_banos, p.area_m2, " +
                "       c.nombre_ciudad, t.nombre_tipo, img.url_imagen " +
                "FROM favorito f " +
                "INNER JOIN propiedad p ON p.id_propiedad = f.id_propiedad " +
                "INNER JOIN ciudad c ON c.id_ciudad = p.id_ciudad " +
                "INNER JOIN tipo_propiedad t ON t.id_tipo = p.id_tipo " +
                "LEFT JOIN imagen_propiedad img ON img.id_propiedad = p.id_propiedad AND img.es_principal = 1 " +
                "WHERE f.id_usuario = ? AND p.activo = 1 " +
                "ORDER BY f.fecha_agregado DESC")) {
            ps.setInt(1, idUsuarioSesion);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> fila = new LinkedHashMap<>();
                    fila.put("id", rs.getInt("id_propiedad"));
                    fila.put("titulo", rs.getString("titulo"));
                    fila.put("precio", rs.getBigDecimal("precio"));
                    fila.put("operacion", rs.getString("operacion"));
                    fila.put("estado", rs.getString("estado"));
                    fila.put("habitaciones", rs.getObject("num_habitaciones"));
                    fila.put("banos", rs.getObject("num_banos"));
                    fila.put("area", rs.getBigDecimal("area_m2"));
                    fila.put("ciudad", rs.getString("nombre_ciudad"));
                    fila.put("tipo", rs.getString("nombre_tipo"));
                    fila.put("imagen", rs.getString("url_imagen"));
                    favoritos.add(fila);
                }
            }
        } catch (Exception ignored) { }
        try { conexion.close(); } catch (Exception ignored) { }
    }
%><!DOCTYPE html>
<html lang="es">
<head>
    <% String hgTitulo = "Mis favoritos"; %>
    <%@ include file="/jspf/head-comun.jspf" %>
</head>
<body>
<%@ include file="/jspf/panel-header.jspf" %>

<div class="hg-panel-body">
    <div class="hg-panel-hero">
        <span class="hg-eyebrow">Panel de cliente</span>
        <h1>Mis favoritos</h1>
        <p><a href="<%= request.getContextPath() %>/cliente/dashboard-cliente.jsp">&larr; Volver a mi panel</a></p>
    </div>

    <% if (favoritos.isEmpty()) { %>
    <div class="hg-panel-card">
        <div class="hg-panel-empty">
            <div class="hg-panel-empty__icon"><i class="bi bi-heart"></i></div>
            <p>Aun no has guardado ninguna propiedad como favorita.</p>
            <a class="hg-btn hg-btn--primary" href="<%= request.getContextPath() %>/catalogo.jsp">Explorar propiedades</a>
        </div>
    </div>
    <% } else { %>
    <div class="row g-4">
        <% for (Map<String, Object> prop : favoritos) { %>
        <%@ include file="/jspf/tarjeta-propiedad.jspf" %>
        <% } %>
    </div>
    <% } %>
</div>
</body>
</html>
