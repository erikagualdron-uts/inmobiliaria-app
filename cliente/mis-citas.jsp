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
            <div class="hg-panel-empty__icon"><i class="bi bi-calendar3"></i></div>
            <p>Aún no has agendado ninguna visita.</p>
            <a class="hg-btn hg-btn--primary" href="<%= request.getContextPath() %>/catalogo.jsp">Explorar propiedades</a>
        </div>
    </div>
    <% } else { %>
    <div class="hg-mgmt-grid">
        <% String[] hgMeses = {"ENE","FEB","MAR","ABR","MAY","JUN","JUL","AGO","SEP","OCT","NOV","DIC"};
           for (Map<String, Object> c : citas) {
            String estadoC = (String) c.get("estado");
            boolean sePuedeCancelar = "pendiente".equals(estadoC) || "confirmada".equals(estadoC);
            java.sql.Timestamp fh = (java.sql.Timestamp) c.get("fechaHora");
            java.time.LocalDateTime ldt = fh.toLocalDateTime();
        %>
        <div class="hg-mgmt-card">
            <div class="hg-cita-fecha">
                <span class="hg-cita-fecha__dia"><%= ldt.getDayOfMonth() %></span>
                <span class="hg-cita-fecha__mes"><%= hgMeses[ldt.getMonthValue() - 1] %></span>
            </div>
            <div class="hg-mgmt-card__body">
                <div class="hg-mgmt-card__top">
                    <div>
                        <h4><a href="<%= request.getContextPath() %>/detalle.jsp?id=<%= c.get("idPropiedad") %>"><%= c.get("titulo") %></a></h4>
                        <p><i class="bi bi-geo-alt"></i> <%= c.get("ciudad") %> &middot; <i class="bi bi-clock"></i> <%= ldt.format(formatoFecha) %></p>
                    </div>
                    <span class="hg-badge--estado hg-badge--<%= estadoC %>" style="position:static; display:inline-block; height:fit-content;"><%= estadoC.substring(0,1).toUpperCase() + estadoC.substring(1) %></span>
                </div>
                <% if (c.get("observaciones") != null) { %>
                <p class="hg-mgmt-card__obs">"<%= c.get("observaciones") %>"</p>
                <% } %>
                <% if (sePuedeCancelar) { %>
                <div class="hg-mgmt-card__bottom">
                    <span></span>
                    <div class="hg-mgmt-card__acciones">
                        <form method="post" action="<%= request.getContextPath() %>/cliente/mis-citas.jsp">
                            <input type="hidden" name="accion" value="cancelar">
                            <input type="hidden" name="idCita" value="<%= c.get("id") %>">
                            <button class="hg-btn hg-btn--ghost hg-btn--sm" type="submit"><i class="bi bi-x-circle"></i> Cancelar</button>
                        </form>
                    </div>
                </div>
                <% } %>
            </div>
        </div>
        <% } %>
    </div>
    <% } %>
</div>
<%@ include file="/jspf/scripts-panel.jspf" %>
</body>
</html>
