<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ page import="java.sql.PreparedStatement, java.sql.ResultSet" %>
<%@ page import="java.time.format.DateTimeFormatter" %>
<%@ page import="java.util.ArrayList, java.util.List, java.util.Map, java.util.LinkedHashMap" %>
<%
    String[] rolesPermitidos = { "Administrador" };
%>
<%@ include file="/jspf/seguridad.jspf" %>
<%@ include file="/jspf/conexion.jspf" %>
<%
    List<Map<String, Object>> eventos = new ArrayList<>();
    if (conexion != null) {
        try (PreparedStatement ps = conexion.prepareStatement(
                "SELECT a.fecha_hora, a.accion, a.tabla_afectada, a.descripcion, a.ip_origen, u.correo " +
                "FROM auditoria a LEFT JOIN usuario u ON u.id_usuario = a.id_usuario " +
                "ORDER BY a.fecha_hora DESC LIMIT 200");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String, Object> f = new LinkedHashMap<>();
                f.put("fecha", rs.getTimestamp("fecha_hora"));
                f.put("accion", rs.getString("accion"));
                f.put("tabla", rs.getString("tabla_afectada"));
                f.put("descripcion", rs.getString("descripcion"));
                f.put("ip", rs.getString("ip_origen"));
                f.put("correo", rs.getString("correo"));
                eventos.add(f);
            }
        } catch (Exception ignored) { }
        try { conexion.close(); } catch (Exception ignored) { }
    }
    DateTimeFormatter formatoFecha = DateTimeFormatter.ofPattern("dd/MM/yyyy hh:mm a");
%><!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Auditoria | Hogaria</title>
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Fraunces:opsz,wght@9..144,500;9..144,600;9..144,700&family=Work+Sans:wght@400;500;600;700&display=swap">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css">
    <link rel="stylesheet" href="<%= request.getContextPath() %>/assets/css/estilos.css">
</head>
<body>
<%@ include file="/jspf/panel-header.jspf" %>

<div class="hg-panel-body">
    <div class="hg-panel-hero">
        <span class="hg-eyebrow">Panel de administracion</span>
        <h1>Auditoria del sistema</h1>
        <p><a href="<%= request.getContextPath() %>/administrador/dashboard-administrador.jsp">&larr; Volver a mi panel</a></p>
    </div>

    <% if (eventos.isEmpty()) { %>
    <div class="hg-panel-card">
        <div class="hg-panel-empty">
            <div class="hg-panel-empty__icon">🗒️</div>
            <p>Aun no hay eventos de auditoria registrados.</p>
        </div>
    </div>
    <% } else { %>
    <div class="hg-panel-card" style="padding:0; overflow-x:auto;">
        <table class="hg-tabla">
            <thead><tr><th>Fecha</th><th>Usuario</th><th>Accion</th><th>Tabla</th><th>Descripcion</th><th>IP</th></tr></thead>
            <tbody>
                <% for (Map<String, Object> e : eventos) { %>
                <tr>
                    <td style="font-variant-numeric:tabular-nums; white-space:nowrap;"><%= ((java.sql.Timestamp) e.get("fecha")).toLocalDateTime().format(formatoFecha) %></td>
                    <td><%= e.get("correo") != null ? e.get("correo") : "(usuario eliminado)" %></td>
                    <td><%= e.get("accion") %></td>
                    <td style="color:var(--hg-ink-muted);"><%= e.get("tabla") != null ? e.get("tabla") : "-" %></td>
                    <td style="color:var(--hg-ink-muted); font-size:.88rem;"><%= e.get("descripcion") != null ? e.get("descripcion") : "-" %></td>
                    <td style="color:var(--hg-ink-muted); font-size:.82rem;"><%= e.get("ip") != null ? e.get("ip") : "-" %></td>
                </tr>
                <% } %>
            </tbody>
        </table>
    </div>
    <% } %>
</div>
</body>
</html>
