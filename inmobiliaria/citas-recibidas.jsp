<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ page import="java.sql.PreparedStatement, java.sql.ResultSet" %>
<%@ page import="java.time.format.DateTimeFormatter" %>
<%@ page import="java.util.ArrayList, java.util.List, java.util.Map, java.util.LinkedHashMap" %>
<%
    String[] rolesPermitidos = { "Inmobiliaria" };
%>
<%@ include file="/jspf/seguridad.jspf" %>
<%@ include file="/jspf/conexion.jspf" %>
<%
    int idUsuarioSesion = (Integer) session.getAttribute("idUsuario");
    Integer idInmobiliaria = null;

    if (conexion != null) {
        try (PreparedStatement ps = conexion.prepareStatement("SELECT id_inmobiliaria FROM usuario WHERE id_usuario = ?")) {
            ps.setInt(1, idUsuarioSesion);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) { int idIn = rs.getInt(1); if (!rs.wasNull()) idInmobiliaria = idIn; }
            }
        } catch (Exception ignored) { }
    }

    // Cambiar estado de una cita (patron Post/Redirect/Get), verificando que
    // la propiedad de la cita pertenezca a esta inmobiliaria.
    if ("POST".equalsIgnoreCase(request.getMethod()) && conexion != null && idInmobiliaria != null) {
        String accion = request.getParameter("accion");
        String nuevoEstado = "confirmar".equals(accion) ? "confirmada"
                : "rechazar".equals(accion) ? "rechazada"
                : "marcarRealizada".equals(accion) ? "realizada" : null;
        if (nuevoEstado != null) {
            try {
                int idCita = Integer.parseInt(request.getParameter("idCita"));
                try (PreparedStatement ps = conexion.prepareStatement(
                        "UPDATE cita c INNER JOIN propiedad p ON p.id_propiedad = c.id_propiedad " +
                        "SET c.estado = ? WHERE c.id_cita = ? AND p.id_inmobiliaria = ?")) {
                    ps.setString(1, nuevoEstado);
                    ps.setInt(2, idCita);
                    ps.setInt(3, idInmobiliaria);
                    ps.executeUpdate();
                }
            } catch (Exception ignored) { }
            try { conexion.close(); } catch (Exception ignored) { }
            response.sendRedirect(request.getContextPath() + "/inmobiliaria/citas-recibidas.jsp");
            return;
        }
    }

    List<Map<String, Object>> citas = new ArrayList<>();
    if (conexion != null && idInmobiliaria != null) {
        try (PreparedStatement ps = conexion.prepareStatement(
                "SELECT c.id_cita, c.fecha_hora, c.estado, c.observaciones, " +
                "       p.id_propiedad, p.titulo, per.nombres, per.apellidos, per.telefono " +
                "FROM cita c " +
                "INNER JOIN propiedad p ON p.id_propiedad = c.id_propiedad " +
                "INNER JOIN perfil per ON per.id_usuario = c.id_cliente " +
                "WHERE p.id_inmobiliaria = ? " +
                "ORDER BY (c.estado = 'pendiente') DESC, c.fecha_hora ASC")) {
            ps.setInt(1, idInmobiliaria);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> f = new LinkedHashMap<>();
                    f.put("id", rs.getInt("id_cita"));
                    f.put("fechaHora", rs.getTimestamp("fecha_hora"));
                    f.put("estado", rs.getString("estado"));
                    f.put("observaciones", rs.getString("observaciones"));
                    f.put("idPropiedad", rs.getInt("id_propiedad"));
                    f.put("titulo", rs.getString("titulo"));
                    f.put("cliente", rs.getString("nombres") + " " + rs.getString("apellidos"));
                    f.put("telefono", rs.getString("telefono"));
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
    <% String hgTitulo = "Citas recibidas"; %>
    <%@ include file="/jspf/head-comun.jspf" %>
</head>
<body>
<%@ include file="/jspf/panel-header.jspf" %>

<div class="hg-panel-body">
    <div class="hg-panel-hero">
        <span class="hg-eyebrow">Panel de inmobiliaria</span>
        <h1>Citas recibidas</h1>
        <p><a href="<%= request.getContextPath() %>/inmobiliaria/dashboard-inmobiliaria.jsp">&larr; Volver a mi panel</a></p>
    </div>

    <% if (idInmobiliaria == null) { %>
    <div class="hg-alert hg-alert--error">Tu cuenta aun no esta asociada a ninguna inmobiliaria.</div>
    <% } else if (citas.isEmpty()) { %>
    <div class="hg-panel-card">
        <div class="hg-panel-empty">
            <div class="hg-panel-empty__icon"><i class="bi bi-calendar3"></i></div>
            <p>Todavia no tienes citas agendadas.</p>
        </div>
    </div>
    <% } else { %>
    <div class="hg-mgmt-grid">
        <% String[] hgMeses = {"ENE","FEB","MAR","ABR","MAY","JUN","JUL","AGO","SEP","OCT","NOV","DIC"};
           for (Map<String, Object> c : citas) {
            String estadoC = (String) c.get("estado");
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
                        <p><i class="bi bi-person"></i> <%= c.get("cliente") %><% if (c.get("telefono") != null) { %> &middot; <i class="bi bi-telephone"></i> <%= c.get("telefono") %><% } %> &middot; <i class="bi bi-clock"></i> <%= ldt.format(formatoFecha) %></p>
                    </div>
                    <span class="hg-badge--estado hg-badge--<%= estadoC %>" style="position:static; display:inline-block; height:fit-content;"><%= estadoC.substring(0,1).toUpperCase() + estadoC.substring(1) %></span>
                </div>
                <% if ("pendiente".equals(estadoC) || "confirmada".equals(estadoC)) { %>
                <div class="hg-mgmt-card__bottom">
                    <span></span>
                    <div class="hg-mgmt-card__acciones">
                        <% if ("pendiente".equals(estadoC)) { %>
                        <form method="post" action="<%= request.getContextPath() %>/inmobiliaria/citas-recibidas.jsp">
                            <input type="hidden" name="accion" value="confirmar"><input type="hidden" name="idCita" value="<%= c.get("id") %>">
                            <button class="hg-btn hg-btn--primary hg-btn--sm" type="submit"><i class="bi bi-check-lg"></i> Confirmar</button>
                        </form>
                        <form method="post" action="<%= request.getContextPath() %>/inmobiliaria/citas-recibidas.jsp">
                            <input type="hidden" name="accion" value="rechazar"><input type="hidden" name="idCita" value="<%= c.get("id") %>">
                            <button class="hg-btn hg-btn--ghost hg-btn--sm" type="submit"><i class="bi bi-x-lg"></i> Rechazar</button>
                        </form>
                        <% } else { %>
                        <form method="post" action="<%= request.getContextPath() %>/inmobiliaria/citas-recibidas.jsp">
                            <input type="hidden" name="accion" value="marcarRealizada"><input type="hidden" name="idCita" value="<%= c.get("id") %>">
                            <button class="hg-btn hg-btn--primary hg-btn--sm" type="submit"><i class="bi bi-check-circle"></i> Marcar realizada</button>
                        </form>
                        <% } %>
                    </div>
                </div>
                <% } %>
            </div>
        </div>
        <% } %>
    </div>
    <% } %>
</div>
</body>
</html>
