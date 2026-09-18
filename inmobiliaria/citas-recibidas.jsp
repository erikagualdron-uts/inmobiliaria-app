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
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Citas recibidas | Hogaria</title>
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Fraunces:opsz,wght@9..144,500;9..144,600;9..144,700&family=Work+Sans:wght@400;500;600;700&display=swap">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css">
    <link rel="stylesheet" href="<%= request.getContextPath() %>/assets/css/estilos.css">
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
            <div class="hg-panel-empty__icon">📅</div>
            <p>Todavia no tienes citas agendadas.</p>
        </div>
    </div>
    <% } else { %>
    <div class="hg-panel-card" style="padding:0; overflow-x:auto;">
        <table class="hg-tabla">
            <thead>
                <tr><th>Propiedad</th><th>Cliente</th><th>Fecha y hora</th><th>Estado</th><th>Acciones</th></tr>
            </thead>
            <tbody>
                <% for (Map<String, Object> c : citas) {
                    String estadoC = (String) c.get("estado");
                    java.sql.Timestamp fh = (java.sql.Timestamp) c.get("fechaHora");
                %>
                <tr>
                    <td><a href="<%= request.getContextPath() %>/detalle.jsp?id=<%= c.get("idPropiedad") %>"><%= c.get("titulo") %></a></td>
                    <td><%= c.get("cliente") %><br><span style="color:var(--hg-ink-muted); font-size:.82rem;"><%= c.get("telefono") != null ? c.get("telefono") : "" %></span></td>
                    <td style="font-variant-numeric:tabular-nums;"><%= fh.toLocalDateTime().format(formatoFecha) %></td>
                    <td><span class="hg-badge--estado hg-badge--<%= estadoC %>" style="position:static; display:inline-block;"><%= estadoC.substring(0,1).toUpperCase() + estadoC.substring(1) %></span></td>
                    <td class="hg-tabla__acciones">
                        <% if ("pendiente".equals(estadoC)) { %>
                        <form method="post" action="<%= request.getContextPath() %>/inmobiliaria/citas-recibidas.jsp">
                            <input type="hidden" name="accion" value="confirmar"><input type="hidden" name="idCita" value="<%= c.get("id") %>">
                            <button class="hg-btn hg-btn--primary hg-btn--sm" type="submit">Confirmar</button>
                        </form>
                        <form method="post" action="<%= request.getContextPath() %>/inmobiliaria/citas-recibidas.jsp">
                            <input type="hidden" name="accion" value="rechazar"><input type="hidden" name="idCita" value="<%= c.get("id") %>">
                            <button class="hg-btn hg-btn--ghost hg-btn--sm" type="submit">Rechazar</button>
                        </form>
                        <% } else if ("confirmada".equals(estadoC)) { %>
                        <form method="post" action="<%= request.getContextPath() %>/inmobiliaria/citas-recibidas.jsp">
                            <input type="hidden" name="accion" value="marcarRealizada"><input type="hidden" name="idCita" value="<%= c.get("id") %>">
                            <button class="hg-btn hg-btn--primary hg-btn--sm" type="submit">Marcar realizada</button>
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
