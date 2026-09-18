<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ page import="java.sql.PreparedStatement, java.sql.ResultSet" %>
<%@ page import="java.time.format.DateTimeFormatter" %>
<%@ page import="java.util.ArrayList, java.util.List, java.util.Map, java.util.LinkedHashMap" %>
<%
    String[] rolesPermitidos = { "Cliente" };
%>
<%@ include file="/jspf/seguridad.jspf" %>
<%@ include file="/jspf/conexion.jspf" %>
<%
    int idUsuarioSesion = (Integer) session.getAttribute("idUsuario");

    if ("POST".equalsIgnoreCase(request.getMethod()) && "cancelar".equals(request.getParameter("accion")) && conexion != null) {
        try {
            int idCita = Integer.parseInt(request.getParameter("idCita"));
            try (PreparedStatement ps = conexion.prepareStatement(
                    "UPDATE cita SET estado = 'cancelada' WHERE id_cita = ? AND id_cliente = ? AND estado IN ('pendiente','confirmada')")) {
                ps.setInt(1, idCita);
                ps.setInt(2, idUsuarioSesion);
                ps.executeUpdate();
            }
        } catch (Exception ignored) { }
        try { conexion.close(); } catch (Exception ignored) { }
        response.sendRedirect(request.getContextPath() + "/cliente/mis-citas.jsp");
        return;
    }

    List<Map<String, Object>> citas = new ArrayList<>();
    if (conexion != null) {
        try (PreparedStatement ps = conexion.prepareStatement(
                "SELECT c.id_cita, c.fecha_hora, c.estado, c.observaciones, p.id_propiedad, p.titulo, ciu.nombre_ciudad " +
                "FROM cita c " +
                "INNER JOIN propiedad p ON p.id_propiedad = c.id_propiedad " +
                "INNER JOIN ciudad ciu ON ciu.id_ciudad = p.id_ciudad " +
                "WHERE c.id_cliente = ? " +
                "ORDER BY c.fecha_hora DESC")) {
            ps.setInt(1, idUsuarioSesion);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> f = new LinkedHashMap<>();
                    f.put("id", rs.getInt("id_cita"));
                    f.put("fechaHora", rs.getTimestamp("fecha_hora"));
                    f.put("estado", rs.getString("estado"));
                    f.put("observaciones", rs.getString("observaciones"));
                    f.put("idPropiedad", rs.getInt("id_propiedad"));
                    f.put("titulo", rs.getString("titulo"));
                    f.put("ciudad", rs.getString("nombre_ciudad"));
                    citas.add(f);
                }
            }
        } catch (Exception ignored) { }
        try { conexion.close(); } catch (Exception ignored) { }
    }

    DateTimeFormatter formatoFecha = DateTimeFormatter.ofPattern("dd/MM/yyyy hh:mm a");
%><!DOCTYPE html>
<html lang="es">
<head>
    <% String hgTitulo = "Mis citas"; %>
    <%@ include file="/jspf/head-comun.jspf" %>
</head>
<body>
<%@ include file="/jspf/panel-header.jspf" %>

<div class="hg-panel-body">
    <div class="hg-panel-hero">
        <span class="hg-eyebrow">Panel de cliente</span>
        <h1>Mis citas</h1>
        <p><a href="<%= request.getContextPath() %>/cliente/dashboard-cliente.jsp">&larr; Volver a mi panel</a></p>
    </div>

    <% if (citas.isEmpty()) { %>
    <div class="hg-panel-card">
        <div class="hg-panel-empty">
            <div class="hg-panel-empty__icon">📅</div>
            <p>Aun no has agendado ninguna visita.</p>
            <a class="hg-btn hg-btn--primary" href="<%= request.getContextPath() %>/catalogo.jsp">Explorar propiedades</a>
        </div>
    </div>
    <% } else { %>
    <div class="hg-panel-card" style="padding:0; overflow-x:auto;">
        <table class="hg-tabla">
            <thead>
                <tr><th>Propiedad</th><th>Fecha y hora</th><th>Estado</th><th>Observaciones</th><th>Accion</th></tr>
            </thead>
            <tbody>
                <% for (Map<String, Object> c : citas) {
                    String estadoC = (String) c.get("estado");
                    boolean sePuedeCancelar = "pendiente".equals(estadoC) || "confirmada".equals(estadoC);
                    java.sql.Timestamp fh = (java.sql.Timestamp) c.get("fechaHora");
                %>
                <tr>
                    <td><a href="<%= request.getContextPath() %>/detalle.jsp?id=<%= c.get("idPropiedad") %>"><%= c.get("titulo") %></a><br><span style="color:var(--hg-ink-muted); font-size:.82rem;"><%= c.get("ciudad") %></span></td>
                    <td style="font-variant-numeric:tabular-nums;"><%= fh.toLocalDateTime().format(formatoFecha) %></td>
                    <td><span class="hg-badge--estado hg-badge--<%= estadoC %>" style="position:static; display:inline-block;"><%= estadoC.substring(0,1).toUpperCase() + estadoC.substring(1) %></span></td>
                    <td style="color:var(--hg-ink-muted); font-size:.88rem;"><%= c.get("observaciones") != null ? c.get("observaciones") : "-" %></td>
                    <td>
                        <% if (sePuedeCancelar) { %>
                        <form method="post" action="<%= request.getContextPath() %>/cliente/mis-citas.jsp">
                            <input type="hidden" name="accion" value="cancelar">
                            <input type="hidden" name="idCita" value="<%= c.get("id") %>">
                            <button class="hg-btn hg-btn--ghost hg-btn--sm" type="submit">Cancelar</button>
                        </form>
                        <% } else { %>&mdash;<% } %>
                    </td>
                </tr>
                <% } %>
            </tbody>
        </table>
    </div>
    <% } %>
</div>
</body>
</html>
