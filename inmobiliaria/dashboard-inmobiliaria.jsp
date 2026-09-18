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
    <% String hgTitulo = "Panel de la inmobiliaria"; %>
    <%@ include file="/jspf/head-comun.jspf" %>
</head>
<body>
<%@ include file="/jspf/panel-header.jspf" %>

<div class="hg-panel-body">
    <div class="hg-panel-hero">
        <span class="hg-eyebrow">Panel de inmobiliaria</span>
        <h1>Hola, <%= session.getAttribute("nombreUsuario") %></h1>
        <p><% if (nombreInmobiliaria != null) { %>Agente de <strong><%= nombreInmobiliaria %></strong>.<% } else { %>Tu cuenta aun no esta asociada a ninguna inmobiliaria; contacta al administrador.<% } %></p>
    </div>

    <div class="hg-panel-grid">
        <a class="hg-panel-stat" href="<%= request.getContextPath() %>/inmobiliaria/mis-propiedades.jsp">
            <div class="hg-panel-stat__icon"><i class="bi bi-houses-fill"></i></div>
            <div><strong><%= totalPropiedades %></strong><span>Propiedades activas</span></div>
        </a>
        <a class="hg-panel-stat" href="<%= request.getContextPath() %>/inmobiliaria/citas-recibidas.jsp">
            <div class="hg-panel-stat__icon"><i class="bi bi-calendar-check-fill"></i></div>
            <div><strong><%= citasPendientes %></strong><span>Citas pendientes por atender</span></div>
        </a>
        <a class="hg-panel-stat" href="<%= request.getContextPath() %>/inmobiliaria/solicitudes-recibidas.jsp">
            <div class="hg-panel-stat__icon"><i class="bi bi-clipboard-check-fill"></i></div>
            <div><strong><%= solicitudesPendientes %></strong><span>Solicitudes por revisar</span></div>
        </a>
    </div>

    <div class="hg-panel-card">
        <h3 class="hg-panel-card__titulo"><i class="bi bi-lightning-charge-fill"></i> Acciones rapidas</h3>
        <div class="hg-quick-actions">
            <a class="hg-quick-action" href="<%= request.getContextPath() %>/inmobiliaria/propiedad-form.jsp">
                <i class="bi bi-plus-circle"></i>
                <span>Publicar propiedad</span>
            </a>
            <a class="hg-quick-action" href="<%= request.getContextPath() %>/inmobiliaria/mis-propiedades.jsp">
                <i class="bi bi-houses"></i>
                <span>Mis propiedades</span>
            </a>
            <a class="hg-quick-action" href="<%= request.getContextPath() %>/inmobiliaria/reportes.jsp">
                <i class="bi bi-graph-up-arrow"></i>
                <span>Reportes de ventas</span>
            </a>
            <a class="hg-quick-action" href="<%= request.getContextPath() %>/catalogo.jsp" target="_blank">
                <i class="bi bi-eye"></i>
                <span>Ver catalogo publico</span>
            </a>
        </div>
    </div>
</div>
</body>
</html>
