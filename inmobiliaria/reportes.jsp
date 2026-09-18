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
    // Reportes de ventas y arriendos de la inmobiliaria del agente en
    // sesion (nunca de otra inmobiliaria).
    // =========================================================================
    int idUsuarioSesion = (Integer) session.getAttribute("idUsuario");
    Integer idInmobiliaria = null;
    String nombreInmobiliaria = null;

    if (conexion != null) {
        try (PreparedStatement ps = conexion.prepareStatement(
                "SELECT u.id_inmobiliaria, i.nombre_comercial FROM usuario u " +
                "LEFT JOIN inmobiliaria i ON i.id_inmobiliaria = u.id_inmobiliaria WHERE u.id_usuario = ?")) {
            ps.setInt(1, idUsuarioSesion);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    int idIn = rs.getInt(1);
                    if (!rs.wasNull()) idInmobiliaria = idIn;
                    nombreInmobiliaria = rs.getString(2);
                }
            }
        } catch (Exception ignored) { }
    }

    int totalVendidas = 0, totalArrendadas = 0;
    java.math.BigDecimal valorVendidas = java.math.BigDecimal.ZERO, canonArrendadas = java.math.BigDecimal.ZERO;
    List<Map<String, Object>> porEstado = new ArrayList<>();
    List<Map<String, Object>> solicitudesPorTipo = new ArrayList<>();
    List<Map<String, Object>> cerradas = new ArrayList<>();
    List<Map<String, Object>> sinCitas = new ArrayList<>();

    if (conexion != null && idInmobiliaria != null) {
        try (PreparedStatement ps = conexion.prepareStatement(
                "SELECT " +
                "  SUM(CASE WHEN estado = 'vendido' THEN 1 ELSE 0 END) AS total_vendidas, " +
                "  SUM(CASE WHEN estado = 'arrendado' THEN 1 ELSE 0 END) AS total_arrendadas, " +
                "  SUM(CASE WHEN estado = 'vendido' THEN precio ELSE 0 END) AS valor_vendidas, " +
                "  SUM(CASE WHEN estado = 'arrendado' THEN precio ELSE 0 END) AS canon_arrendadas " +
                "FROM propiedad WHERE id_inmobiliaria = ?")) {
            ps.setInt(1, idInmobiliaria);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    totalVendidas = rs.getInt("total_vendidas");
                    totalArrendadas = rs.getInt("total_arrendadas");
                    valorVendidas = rs.getBigDecimal("valor_vendidas");
                    canonArrendadas = rs.getBigDecimal("canon_arrendadas");
                    if (valorVendidas == null) valorVendidas = java.math.BigDecimal.ZERO;
                    if (canonArrendadas == null) canonArrendadas = java.math.BigDecimal.ZERO;
                }
            }
        } catch (Exception ignored) { }

        try (PreparedStatement ps = conexion.prepareStatement(
                "SELECT estado, COUNT(*) AS total FROM propiedad WHERE id_inmobiliaria = ? GROUP BY estado ORDER BY total DESC")) {
            ps.setInt(1, idInmobiliaria);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> f = new LinkedHashMap<>();
                    f.put("etiqueta", rs.getString("estado"));
                    f.put("total", rs.getInt("total"));
                    porEstado.add(f);
                }
            }
        } catch (Exception ignored) { }

        try (PreparedStatement ps = conexion.prepareStatement(
                "SELECT s.tipo_solicitud, COUNT(*) AS total FROM solicitud s " +
                "INNER JOIN propiedad p ON p.id_propiedad = s.id_propiedad " +
                "WHERE p.id_inmobiliaria = ? AND s.estado = 'aprobada' " +
                "GROUP BY s.tipo_solicitud")) {
            ps.setInt(1, idInmobiliaria);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> f = new LinkedHashMap<>();
                    f.put("etiqueta", "compra".equals(rs.getString(1)) ? "Compra" : "Arriendo");
                    f.put("total", rs.getInt("total"));
                    solicitudesPorTipo.add(f);
                }
            }
        } catch (Exception ignored) { }

        try (PreparedStatement ps = conexion.prepareStatement(
                "SELECT p.titulo, p.operacion, p.estado, p.precio, c.nombre_ciudad, t.nombre_tipo " +
                "FROM propiedad p " +
                "INNER JOIN ciudad c ON c.id_ciudad = p.id_ciudad " +
                "INNER JOIN tipo_propiedad t ON t.id_tipo = p.id_tipo " +
                "WHERE p.id_inmobiliaria = ? AND p.estado IN ('vendido','arrendado') " +
                "ORDER BY p.fecha_publicacion DESC")) {
            ps.setInt(1, idInmobiliaria);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> f = new LinkedHashMap<>();
                    f.put("titulo", rs.getString("titulo"));
                    f.put("operacion", rs.getString("operacion"));
                    f.put("estado", rs.getString("estado"));
                    f.put("precio", rs.getBigDecimal("precio"));
                    f.put("ciudad", rs.getString("nombre_ciudad"));
                    f.put("tipo", rs.getString("nombre_tipo"));
                    cerradas.add(f);
                }
            }
        } catch (Exception ignored) { }

        try (PreparedStatement ps = conexion.prepareStatement(
                "SELECT p.titulo, c.nombre_ciudad, t.nombre_tipo " +
                "FROM propiedad p " +
                "LEFT JOIN cita ci ON ci.id_propiedad = p.id_propiedad " +
                "INNER JOIN ciudad c ON c.id_ciudad = p.id_ciudad " +
                "INNER JOIN tipo_propiedad t ON t.id_tipo = p.id_tipo " +
                "WHERE p.id_inmobiliaria = ? AND ci.id_cita IS NULL " +
                "ORDER BY p.titulo")) {
            ps.setInt(1, idInmobiliaria);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> f = new LinkedHashMap<>();
                    f.put("titulo", rs.getString("titulo"));
                    f.put("ciudad", rs.getString("nombre_ciudad"));
                    f.put("tipo", rs.getString("nombre_tipo"));
                    sinCitas.add(f);
                }
            }
        } catch (Exception ignored) { }

        try { conexion.close(); } catch (Exception ignored) { }
    }

    NumberFormat formatoCOP = NumberFormat.getInstance(new Locale("es", "CO"));
%><!DOCTYPE html>
<html lang="es">
<head>
    <% String hgTitulo = "Reportes"; %>
    <%@ include file="/jspf/head-comun.jspf" %>
</head>
<body>
<%@ include file="/jspf/panel-header.jspf" %>

<div class="hg-panel-body">
    <div class="hg-panel-hero">
        <span class="hg-eyebrow">Panel de inmobiliaria</span>
        <h1>Reportes de ventas y arriendos</h1>
        <p><% if (nombreInmobiliaria != null) { %><%= nombreInmobiliaria %> &middot; <% } %><a href="<%= request.getContextPath() %>/inmobiliaria/dashboard-inmobiliaria.jsp">&larr; Volver a mi panel</a></p>
    </div>

    <% if (idInmobiliaria == null) { %>
    <div class="hg-alert hg-alert--error">Tu cuenta aún no está asociada a ninguna inmobiliaria.</div>
    <% } else { %>

    <div class="hg-panel-grid">
        <div class="hg-panel-stat"><div class="hg-panel-stat__texto"><span>Propiedades vendidas</span><strong><%= totalVendidas %></strong></div></div>
        <div class="hg-panel-stat"><div class="hg-panel-stat__texto"><span>Propiedades arrendadas</span><strong><%= totalArrendadas %></strong></div></div>
        <div class="hg-panel-stat"><div class="hg-panel-stat__texto"><span>Valor total en ventas</span><strong>$ <%= formatoCOP.format(valorVendidas) %></strong></div></div>
        <div class="hg-panel-stat"><div class="hg-panel-stat__texto"><span>Canon mensual en arriendos activos</span><strong>$ <%= formatoCOP.format(canonArrendadas) %></strong></div></div>
    </div>

    <div class="hg-reporte-grid">
        <div class="hg-panel-card">
            <h3>Propiedades por estado</h3>
            <p class="hg-reporte-nota">GROUP BY sobre propiedad, filtrado por tu inmobiliaria</p>
            <% if (porEstado.isEmpty()) { %>
            <p class="hg-panel-empty" style="padding:20px 0;">Sin datos para mostrar.</p>
            <% } else {
                int maxEstado = 1;
                for (Map<String, Object> f : porEstado) maxEstado = Math.max(maxEstado, (Integer) f.get("total"));
                for (Map<String, Object> f : porEstado) {
                    int total = (Integer) f.get("total");
                    int pct = (int) Math.round(total * 100.0 / maxEstado);
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
            <h3>Solicitudes aprobadas por tipo</h3>
            <p class="hg-reporte-nota">INNER JOIN solicitud &middot; propiedad, filtrado por tu inmobiliaria</p>
            <% if (solicitudesPorTipo.isEmpty()) { %>
            <p class="hg-panel-empty" style="padding:20px 0;">Sin datos para mostrar.</p>
            <% } else {
                int maxTipo = 1;
                for (Map<String, Object> f : solicitudesPorTipo) maxTipo = Math.max(maxTipo, (Integer) f.get("total"));
                for (Map<String, Object> f : solicitudesPorTipo) {
                    int total = (Integer) f.get("total");
                    int pct = (int) Math.round(total * 100.0 / maxTipo);
            %>
            <div class="hg-barra">
                <div class="hg-barra__etiqueta"><%= f.get("etiqueta") %></div>
                <div class="hg-barra__pista"><div class="hg-barra__relleno" style="width:<%= pct %>%;"></div></div>
                <div class="hg-barra__valor"><%= total %></div>
            </div>
            <% } } %>
        </div>

        <div class="hg-panel-card">
            <h3>Propiedades sin citas agendadas</h3>
            <p class="hg-reporte-nota">LEFT JOIN sobre propiedad &middot; cita</p>
            <% if (sinCitas.isEmpty()) { %>
            <p class="hg-panel-empty" style="padding:20px 0;">Todas tus propiedades tienen al menos una cita agendada.</p>
            <% } else { %>
            <div style="max-height:220px; overflow-y:auto;">
                <% for (Map<String, Object> f : sinCitas) { %>
                <div style="display:flex; justify-content:space-between; align-items:center; gap:10px; padding:8px 0; border-bottom:1px dashed var(--hg-border); font-size:.86rem;">
                    <span><%= f.get("titulo") %></span>
                    <span style="color:var(--hg-ink-muted); font-size:.8rem; white-space:nowrap;"><%= f.get("ciudad") %> &middot; <%= f.get("tipo") %></span>
                </div>
                <% } %>
            </div>
            <% } %>
        </div>
    </div>

    <div class="hg-panel-card" style="margin-top:20px; padding:0; overflow-x:auto;">
        <table class="hg-tabla">
            <thead><tr><th>Propiedad</th><th>Ciudad / Tipo</th><th>Operación</th><th>Estado</th><th>Precio</th></tr></thead>
            <tbody>
                <% if (cerradas.isEmpty()) { %>
                <tr><td colspan="5" style="text-align:center; color:var(--hg-ink-muted); padding:24px;">Aún no tienes ventas ni arriendos concretados.</td></tr>
                <% } %>
                <% for (Map<String, Object> f : cerradas) {
                    String estadoF = (String) f.get("estado");
                    String operacionF = (String) f.get("operacion");
                    String precioTxt = "$ " + formatoCOP.format(f.get("precio")) + ("arriendo".equals(operacionF) ? " / mes" : "");
                %>
                <tr>
                    <td><%= f.get("titulo") %></td>
                    <td><%= f.get("ciudad") %><br><span style="color:var(--hg-ink-muted); font-size:.85rem;"><%= f.get("tipo") %></span></td>
                    <td><%= "venta".equals(operacionF) ? "Venta" : "Arriendo" %></td>
                    <td><span class="hg-badge--estado hg-badge--<%= estadoF %>" style="position:static; display:inline-block;"><%= estadoF.substring(0,1).toUpperCase() + estadoF.substring(1) %></span></td>
                    <td style="font-variant-numeric:tabular-nums;"><%= precioTxt %></td>
                </tr>
                <% } %>
            </tbody>
        </table>
    </div>
    <% } %>
</div>
<%@ include file="/jspf/scripts-panel.jspf" %>
</body>
</html>
