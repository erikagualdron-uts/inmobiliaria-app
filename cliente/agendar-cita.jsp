<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ page import="java.sql.PreparedStatement, java.sql.ResultSet, java.sql.SQLException, java.sql.Timestamp" %>
<%@ page import="java.time.LocalDateTime, java.time.format.DateTimeFormatter, java.time.format.DateTimeParseException" %>
<%@ page import="java.util.ArrayList, java.util.List" %>
<%
    String[] rolesPermitidos = { "Cliente" };
%>
<%@ include file="/jspf/seguridad.jspf" %>
<%@ include file="/jspf/conexion.jspf" %>
<%
    // =========================================================================
    // Agendamiento de cita para una propiedad. La restriccion UNIQUE
    // cita(id_propiedad, fecha_hora) impide agendar dos visitas al mismo
    // inmueble en el mismo horario; el error se captura y se muestra un
    // mensaje claro.
    // =========================================================================
    Integer idPropiedad = null;
    try { idPropiedad = Integer.valueOf(request.getParameter("propiedad")); } catch (Exception ignored) { }
    if (idPropiedad == null) {
        response.sendRedirect(request.getContextPath() + "/catalogo.jsp");
        return;
    }

    String tituloPropiedad = null, ciudadPropiedad = null;
    if (conexion != null) {
        try (PreparedStatement ps = conexion.prepareStatement(
                "SELECT p.titulo, c.nombre_ciudad FROM propiedad p " +
                "INNER JOIN ciudad c ON c.id_ciudad = p.id_ciudad " +
                "WHERE p.id_propiedad = ? AND p.activo = 1")) {
            ps.setInt(1, idPropiedad);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    tituloPropiedad = rs.getString(1);
                    ciudadPropiedad = rs.getString(2);
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
    boolean agendadaExitosa = false;
    String fecha = "", hora = "", observaciones = "";
    int idUsuarioSesion = (Integer) session.getAttribute("idUsuario");

    if ("POST".equalsIgnoreCase(request.getMethod())) {
        fecha = request.getParameter("fecha") != null ? request.getParameter("fecha").trim() : "";
        hora = request.getParameter("hora") != null ? request.getParameter("hora").trim() : "";
        observaciones = request.getParameter("observaciones") != null ? request.getParameter("observaciones").trim() : "";

        LocalDateTime fechaHora = null;
        try {
            fechaHora = LocalDateTime.parse(fecha + "T" + hora + ":00");
            if (fechaHora.isBefore(LocalDateTime.now().plusHours(1))) {
                errores.add("Elige una fecha y hora con al menos una hora de anticipación.");
            }
        } catch (DateTimeParseException e) {
            errores.add("Ingresa una fecha y hora válidas.");
        }
        if (observaciones.length() > 255) {
            errores.add("Las observaciones no pueden superar 255 caracteres.");
        }

        if (errores.isEmpty() && conexion != null) {
            try (PreparedStatement ps = conexion.prepareStatement(
                    "INSERT INTO cita (id_propiedad, id_cliente, fecha_hora, estado, observaciones) " +
                    "VALUES (?, ?, ?, 'pendiente', ?)")) {
                ps.setInt(1, idPropiedad);
                ps.setInt(2, idUsuarioSesion);
                ps.setTimestamp(3, Timestamp.valueOf(fechaHora));
                if (observaciones.isEmpty()) ps.setNull(4, java.sql.Types.VARCHAR); else ps.setString(4, observaciones);
                ps.executeUpdate();
                agendadaExitosa = true;
            } catch (SQLException sqlEx) {
                if ("23000".equals(sqlEx.getSQLState())) {
                    errores.add("Ya existe una cita agendada en ese horario para esta propiedad. Elige otro horario.");
                } else {
                    errores.add("No fue posible agendar la cita. Intenta nuevamente.");
                }
            }
        }
    }

    try { if (conexion != null) conexion.close(); } catch (Exception ignored) { }
%><!DOCTYPE html>
<html lang="es">
<head>
    <% String hgTitulo = "Agendar visita"; %>
    <%@ include file="/jspf/head-comun.jspf" %>
</head>
<body>
<%@ include file="/jspf/panel-header.jspf" %>

<div class="hg-panel-body" style="max-width:560px;">
    <div class="hg-panel-hero">
        <span class="hg-eyebrow">Agendar visita</span>
        <h1><%= tituloPropiedad %></h1>
        <p>📍 <%= ciudadPropiedad %> &middot; <a href="<%= request.getContextPath() %>/detalle.jsp?id=<%= idPropiedad %>">Ver ficha completa</a></p>
    </div>

    <% if (agendadaExitosa) { %>
    <div class="hg-panel-card">
        <div class="hg-panel-empty">
            <div class="hg-panel-empty__icon"><i class="bi bi-check-circle-fill"></i></div>
            <p>Tu cita quedó registrada como <strong>pendiente</strong>. La inmobiliaria la confirmará pronto.</p>
            <a class="hg-btn hg-btn--primary" href="<%= request.getContextPath() %>/cliente/mis-citas.jsp">Ver mis citas</a>
        </div>
    </div>
    <% } else { %>

        <% if (!errores.isEmpty()) { %>
        <div class="hg-alert hg-alert--error" style="margin-bottom:20px;">
            <ul><% for (String err : errores) { %><li><%= err %></li><% } %></ul>
        </div>
        <% } %>

        <div class="hg-panel-card">
            <form method="post" action="<%= request.getContextPath() %>/cliente/agendar-cita.jsp?propiedad=<%= idPropiedad %>" style="display:flex; flex-direction:column; gap:16px;" class="js-form-cargando">
                <div class="hg-field">
                    <label for="fecha">Fecha</label>
                    <input class="form-control" type="date" id="fecha" name="fecha" value="<%= fecha %>" required>
                </div>
                <div class="hg-field">
                    <label for="hora">Hora</label>
                    <input class="form-control" type="time" id="hora" name="hora" value="<%= hora %>" required>
                </div>
                <div class="hg-field">
                    <label for="observaciones">Observaciones (opcional)</label>
                    <textarea class="form-control" id="observaciones" name="observaciones" rows="3" maxlength="255"><%= observaciones %></textarea>
                </div>
                <button class="hg-btn hg-btn--primary" type="submit">Confirmar cita</button>
            </form>
        </div>
    <% } %>
</div>
<%@ include file="/jspf/scripts-panel.jspf" %>
</body>
</html>
