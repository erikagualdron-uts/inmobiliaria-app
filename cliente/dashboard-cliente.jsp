<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ page import="java.sql.PreparedStatement, java.sql.ResultSet" %>
<%
    String[] rolesPermitidos = { "Cliente" };
%>
<%@ include file="/jspf/seguridad.jspf" %>
<%@ include file="/jspf/conexion.jspf" %>
<%
    int idUsuario = (Integer) session.getAttribute("idUsuario");
    int totalCitas = 0, totalSolicitudes = 0, totalFavoritos = 0;

    if (conexion != null) {
        try (PreparedStatement ps = conexion.prepareStatement("SELECT COUNT(*) FROM cita WHERE id_cliente = ?")) {
            ps.setInt(1, idUsuario);
            try (ResultSet rs = ps.executeQuery()) { if (rs.next()) totalCitas = rs.getInt(1); }
        } catch (Exception ignored) { }

        try (PreparedStatement ps = conexion.prepareStatement("SELECT COUNT(*) FROM solicitud WHERE id_cliente = ?")) {
            ps.setInt(1, idUsuario);
            try (ResultSet rs = ps.executeQuery()) { if (rs.next()) totalSolicitudes = rs.getInt(1); }
        } catch (Exception ignored) { }

        try (PreparedStatement ps = conexion.prepareStatement("SELECT COUNT(*) FROM favorito WHERE id_usuario = ?")) {
            ps.setInt(1, idUsuario);
            try (ResultSet rs = ps.executeQuery()) { if (rs.next()) totalFavoritos = rs.getInt(1); }
        } catch (Exception ignored) { }

        try { conexion.close(); } catch (Exception ignored) { }
    }
%><!DOCTYPE html>
<html lang="es">
<head>
    <% String hgTitulo = "Mi panel"; %>
    <%@ include file="/jspf/head-comun.jspf" %>
</head>
<body>
<%@ include file="/jspf/panel-header.jspf" %>

<div class="hg-panel-body">
    <div class="hg-panel-hero">
        <span class="hg-eyebrow">Panel de cliente</span>
        <h1>Hola, <%= session.getAttribute("nombreUsuario") %></h1>
        <p>Aqui podras ver tus citas, tus solicitudes y tus propiedades favoritas.</p>
    </div>

    <div class="hg-panel-grid">
        <a class="hg-panel-stat" href="<%= request.getContextPath() %>/cliente/mis-citas.jsp">
            <div class="hg-panel-stat__icon"><i class="bi bi-calendar-check-fill"></i></div>
            <div class="hg-panel-stat__texto"><span>Citas agendadas</span><strong><%= totalCitas %></strong></div>
        </a>
        <a class="hg-panel-stat" href="<%= request.getContextPath() %>/cliente/mis-solicitudes.jsp">
            <div class="hg-panel-stat__icon"><i class="bi bi-clipboard-check-fill"></i></div>
            <div class="hg-panel-stat__texto"><span>Solicitudes radicadas</span><strong><%= totalSolicitudes %></strong></div>
        </a>
        <a class="hg-panel-stat" href="<%= request.getContextPath() %>/cliente/favoritos.jsp">
            <div class="hg-panel-stat__icon"><i class="bi bi-heart-fill"></i></div>
            <div class="hg-panel-stat__texto"><span>Propiedades favoritas</span><strong><%= totalFavoritos %></strong></div>
        </a>
    </div>

    <div class="hg-panel-card">
        <h3 class="hg-panel-card__titulo"><i class="bi bi-lightning-charge-fill"></i> Acciones rapidas</h3>
        <div class="hg-quick-actions">
            <a class="hg-quick-action" href="<%= request.getContextPath() %>/catalogo.jsp">
                <i class="bi bi-search"></i>
                <span>Explorar propiedades</span>
            </a>
            <a class="hg-quick-action" href="<%= request.getContextPath() %>/cliente/perfil.jsp">
                <i class="bi bi-person-gear"></i>
                <span>Editar mi perfil</span>
            </a>
            <a class="hg-quick-action" href="<%= request.getContextPath() %>/cliente/favoritos.jsp">
                <i class="bi bi-heart"></i>
                <span>Mis favoritos</span>
            </a>
        </div>
    </div>
</div>
<%@ include file="/jspf/scripts-panel.jspf" %>
</body>
</html>
