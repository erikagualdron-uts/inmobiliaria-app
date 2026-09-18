<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ page import="java.sql.PreparedStatement, java.sql.ResultSet" %>
<%
    String[] rolesPermitidos = { "Inmobiliaria" };
%>
<%@ include file="/jspf/seguridad.jspf" %>
<%@ include file="/jspf/conexion.jspf" %>
<%
    int idUsuario = (Integer) session.getAttribute("idUsuario");
    Integer idInmobiliaria = null;
    String nombreInmobiliaria = null;
    int totalPropiedades = 0, citasPendientes = 0, solicitudesPendientes = 0;

    if (conexion != null) {
        try (PreparedStatement ps = conexion.prepareStatement(
                "SELECT u.id_inmobiliaria, i.nombre_comercial FROM usuario u " +
                "LEFT JOIN inmobiliaria i ON i.id_inmobiliaria = u.id_inmobiliaria WHERE u.id_usuario = ?")) {
            ps.setInt(1, idUsuario);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    int idIn = rs.getInt("id_inmobiliaria");
                    if (!rs.wasNull()) idInmobiliaria = idIn;
                    nombreInmobiliaria = rs.getString("nombre_comercial");
                }
            }
        } catch (Exception ignored) { }

        if (idInmobiliaria != null) {
            try (PreparedStatement ps = conexion.prepareStatement(
                    "SELECT COUNT(*) FROM propiedad WHERE id_inmobiliaria = ? AND activo = 1")) {
                ps.setInt(1, idInmobiliaria);
                try (ResultSet rs = ps.executeQuery()) { if (rs.next()) totalPropiedades = rs.getInt(1); }
            } catch (Exception ignored) { }

            try (PreparedStatement ps = conexion.prepareStatement(
                    "SELECT COUNT(*) FROM cita c INNER JOIN propiedad p ON p.id_propiedad = c.id_propiedad " +
                    "WHERE p.id_inmobiliaria = ? AND c.estado = 'pendiente'")) {
                ps.setInt(1, idInmobiliaria);
                try (ResultSet rs = ps.executeQuery()) { if (rs.next()) citasPendientes = rs.getInt(1); }
            } catch (Exception ignored) { }

            try (PreparedStatement ps = conexion.prepareStatement(
                    "SELECT COUNT(*) FROM solicitud s INNER JOIN propiedad p ON p.id_propiedad = s.id_propiedad " +
                    "WHERE p.id_inmobiliaria = ? AND s.estado IN ('pendiente','en_revision')")) {
                ps.setInt(1, idInmobiliaria);
                try (ResultSet rs = ps.executeQuery()) { if (rs.next()) solicitudesPendientes = rs.getInt(1); }
            } catch (Exception ignored) { }
        }

        try { conexion.close(); } catch (Exception ignored) { }
    }
%><!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Panel de la inmobiliaria | Hogaria</title>
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Fraunces:opsz,wght@9..144,500;9..144,600;9..144,700&family=Work+Sans:wght@400;500;600;700&display=swap">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css">
    <link rel="stylesheet" href="<%= request.getContextPath() %>/assets/css/estilos.css">
</head>
<body>
<%@ include file="/jspf/panel-header.jspf" %>

<div class="hg-panel-body">
    <div class="hg-panel-hero" style="display:flex; justify-content:space-between; align-items:flex-end; flex-wrap:wrap; gap:16px;">
        <div>
            <span class="hg-eyebrow">Panel de inmobiliaria</span>
            <h1>Hola, <%= session.getAttribute("nombreUsuario") %></h1>
            <p><% if (nombreInmobiliaria != null) { %>Agente de <strong><%= nombreInmobiliaria %></strong>.<% } else { %>Tu cuenta aun no esta asociada a ninguna inmobiliaria; contacta al administrador.<% } %></p>
        </div>
        <% if (nombreInmobiliaria != null) { %>
        <a class="hg-btn hg-btn--primary" href="<%= request.getContextPath() %>/mis-propiedades.jsp">Gestionar mis propiedades</a>
        <% } %>
    </div>

    <div class="hg-panel-grid">
        <a class="hg-panel-stat" href="<%= request.getContextPath() %>/mis-propiedades.jsp" style="display:block; text-decoration:none;"><strong><%= totalPropiedades %></strong><span>Propiedades activas</span></a>
        <a class="hg-panel-stat" href="<%= request.getContextPath() %>/citas-recibidas.jsp" style="display:block; text-decoration:none;"><strong><%= citasPendientes %></strong><span>Citas pendientes por atender</span></a>
        <a class="hg-panel-stat" href="<%= request.getContextPath() %>/solicitudes-recibidas.jsp" style="display:block; text-decoration:none;"><strong><%= solicitudesPendientes %></strong><span>Solicitudes por revisar</span></a>
    </div>
</div>
</body>
</html>
