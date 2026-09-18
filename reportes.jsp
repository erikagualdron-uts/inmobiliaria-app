<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ page import="java.sql.PreparedStatement, java.sql.ResultSet" %>
<%@ page import="java.util.ArrayList, java.util.List, java.util.Map, java.util.LinkedHashMap" %>
<%
    String[] rolesPermitidos = { "Administrador" };
%>
<%@ include file="/jspf/seguridad.jspf" %>
<%@ include file="/jspf/conexion.jspf" %>
<%
    // =========================================================================
    // Reportes con SQL multi-tabla:
    //  1) Propiedades disponibles por ciudad (GROUP BY + HAVING)
    //  2) Citas por estado (GROUP BY)
    //  3) Solicitudes por inmobiliaria (INNER JOIN de 3 tablas + GROUP BY)
    // =========================================================================
    List<Map<String, Object>> porCiudad = new ArrayList<>();
    List<Map<String, Object>> porEstadoCita = new ArrayList<>();
    List<Map<String, Object>> porInmobiliaria = new ArrayList<>();

    if (conexion != null) {
        try (PreparedStatement ps = conexion.prepareStatement(
                "SELECT c.nombre_ciudad, COUNT(*) AS total " +
                "FROM propiedad p INNER JOIN ciudad c ON c.id_ciudad = p.id_ciudad " +
                "WHERE p.estado = 'disponible' AND p.activo = 1 " +
                "GROUP BY c.nombre_ciudad " +
                "HAVING COUNT(*) >= 1 " +
                "ORDER BY total DESC");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String, Object> f = new LinkedHashMap<>();
                f.put("etiqueta", rs.getString("nombre_ciudad"));
                f.put("total", rs.getInt("total"));
                porCiudad.add(f);
            }
        } catch (Exception ignored) { }

        try (PreparedStatement ps = conexion.prepareStatement(
                "SELECT estado, COUNT(*) AS total FROM cita GROUP BY estado ORDER BY total DESC");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String, Object> f = new LinkedHashMap<>();
                f.put("etiqueta", rs.getString("estado"));
                f.put("total", rs.getInt("total"));
                porEstadoCita.add(f);
            }
        } catch (Exception ignored) { }

        try (PreparedStatement ps = conexion.prepareStatement(
                "SELECT i.nombre_comercial, COUNT(*) AS total " +
                "FROM solicitud s " +
                "INNER JOIN propiedad p ON p.id_propiedad = s.id_propiedad " +
                "INNER JOIN inmobiliaria i ON i.id_inmobiliaria = p.id_inmobiliaria " +
                "GROUP BY i.nombre_comercial " +
                "ORDER BY total DESC");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String, Object> f = new LinkedHashMap<>();
                f.put("etiqueta", rs.getString("nombre_comercial"));
                f.put("total", rs.getInt("total"));
                porInmobiliaria.add(f);
            }
        } catch (Exception ignored) { }

        try { conexion.close(); } catch (Exception ignored) { }
    }
%><!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Reportes | Hogaria</title>
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Fraunces:opsz,wght@9..144,500;9..144,600;9..144,700&family=Work+Sans:wght@400;500;600;700&display=swap">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css">
    <link rel="stylesheet" href="<%= request.getContextPath() %>/assets/css/estilos.css">
</head>
<body>
<%@ include file="/jspf/panel-header.jspf" %>

<div class="hg-panel-body">
    <div class="hg-panel-hero">
        <span class="hg-eyebrow">Panel de administracion</span>
        <h1>Reportes</h1>
        <p><a href="<%= request.getContextPath() %>/dashboard-administrador.jsp">&larr; Volver a mi panel</a></p>
    </div>

    <div class="hg-reporte-grid">
        <div class="hg-panel-card">
            <h3>Propiedades disponibles por ciudad</h3>
            <p class="hg-reporte-nota">GROUP BY + HAVING sobre propiedad &middot; ciudad</p>
            <% if (porCiudad.isEmpty()) { %>
            <p class="hg-panel-empty" style="padding:20px 0;">Sin datos para mostrar.</p>
            <% } else {
                int maxCiudad = 1;
                for (Map<String, Object> f : porCiudad) maxCiudad = Math.max(maxCiudad, (Integer) f.get("total"));
                for (Map<String, Object> f : porCiudad) {
                    int total = (Integer) f.get("total");
                    int pct = (int) Math.round(total * 100.0 / maxCiudad);
            %>
            <div class="hg-barra">
                <div class="hg-barra__etiqueta"><%= f.get("etiqueta") %></div>
                <div class="hg-barra__pista"><div class="hg-barra__relleno" style="width:<%= pct %>%;"></div></div>
                <div class="hg-barra__valor"><%= total %></div>
            </div>
            <% } } %>
        </div>

        <div class="hg-panel-card">
            <h3>Citas por estado</h3>
            <p class="hg-reporte-nota">GROUP BY sobre cita</p>
            <% if (porEstadoCita.isEmpty()) { %>
            <p class="hg-panel-empty" style="padding:20px 0;">Sin datos para mostrar.</p>
            <% } else {
                int maxCita = 1;
                for (Map<String, Object> f : porEstadoCita) maxCita = Math.max(maxCita, (Integer) f.get("total"));
                for (Map<String, Object> f : porEstadoCita) {
                    int total = (Integer) f.get("total");
                    int pct = (int) Math.round(total * 100.0 / maxCita);
                    String etiqueta = (String) f.get("etiqueta");
            %>
            <div class="hg-barra">
                <div class="hg-barra__etiqueta"><span class="hg-badge--estado hg-badge--<%= etiqueta %>" style="position:static; display:inline-block;"><%= etiqueta.substring(0,1).toUpperCase() + etiqueta.substring(1) %></span></div>
                <div class="hg-barra__pista"><div class="hg-barra__relleno" style="width:<%= pct %>%;"></div></div>
                <div class="hg-barra__valor"><%= total %></div>
            </div>
            <% } } %>
        </div>

        <div class="hg-panel-card">
            <h3>Solicitudes por inmobiliaria</h3>
            <p class="hg-reporte-nota">INNER JOIN de 3 tablas: solicitud &middot; propiedad &middot; inmobiliaria</p>
            <% if (porInmobiliaria.isEmpty()) { %>
            <p class="hg-panel-empty" style="padding:20px 0;">Sin datos para mostrar.</p>
            <% } else {
                int maxInmo = 1;
                for (Map<String, Object> f : porInmobiliaria) maxInmo = Math.max(maxInmo, (Integer) f.get("total"));
                for (Map<String, Object> f : porInmobiliaria) {
                    int total = (Integer) f.get("total");
                    int pct = (int) Math.round(total * 100.0 / maxInmo);
            %>
            <div class="hg-barra">
                <div class="hg-barra__etiqueta"><%= f.get("etiqueta") %></div>
                <div class="hg-barra__pista"><div class="hg-barra__relleno" style="width:<%= pct %>%;"></div></div>
                <div class="hg-barra__valor"><%= total %></div>
            </div>
            <% } } %>
        </div>
    </div>
</div>
</body>
</html>
