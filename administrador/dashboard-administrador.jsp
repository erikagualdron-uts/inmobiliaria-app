<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ page import="java.sql.PreparedStatement, java.sql.ResultSet" %>
<%
    String[] rolesPermitidos = { "Administrador" };
%>
<%@ include file="/jspf/seguridad.jspf" %>
<%@ include file="/jspf/conexion.jspf" %>
<%
    int totalUsuarios = 0, totalPropiedades = 0, totalInmobiliarias = 0, solicitudesPendientes = 0;

    if (conexion != null) {
        try (PreparedStatement ps = conexion.prepareStatement("SELECT COUNT(*) FROM usuario");
             ResultSet rs = ps.executeQuery()) { if (rs.next()) totalUsuarios = rs.getInt(1); } catch (Exception ignored) { }

        try (PreparedStatement ps = conexion.prepareStatement("SELECT COUNT(*) FROM propiedad WHERE activo = 1");
             ResultSet rs = ps.executeQuery()) { if (rs.next()) totalPropiedades = rs.getInt(1); } catch (Exception ignored) { }

        try (PreparedStatement ps = conexion.prepareStatement("SELECT COUNT(*) FROM inmobiliaria");
             ResultSet rs = ps.executeQuery()) { if (rs.next()) totalInmobiliarias = rs.getInt(1); } catch (Exception ignored) { }

        try (PreparedStatement ps = conexion.prepareStatement("SELECT COUNT(*) FROM solicitud WHERE estado IN ('pendiente','en_revision')");
             ResultSet rs = ps.executeQuery()) { if (rs.next()) solicitudesPendientes = rs.getInt(1); } catch (Exception ignored) { }

        try { conexion.close(); } catch (Exception ignored) { }
    }
%><!DOCTYPE html>
<html lang="es">
<head>
    <% String hgTitulo = "Panel de administración"; %>
    <%@ include file="/jspf/head-comun.jspf" %>
</head>
<body>
<%@ include file="/jspf/panel-header.jspf" %>

<div class="hg-panel-body">
    <div class="hg-panel-hero">
        <span class="hg-eyebrow">Panel de administración</span>
        <h1>Hola, <%= session.getAttribute("nombreUsuario") %></h1>
        <p>Visión general de la operación de Hogaria.</p>
    </div>

    <div class="hg-panel-grid">
        <a class="hg-panel-stat" href="<%= request.getContextPath() %>/administrador/usuarios.jsp">
            <div class="hg-panel-stat__icon"><i class="bi bi-people-fill"></i></div>
            <div class="hg-panel-stat__texto"><span>Usuarios registrados</span><strong><%= totalUsuarios %></strong></div>
        </a>
        <a class="hg-panel-stat" href="<%= request.getContextPath() %>/catalogo.jsp">
            <div class="hg-panel-stat__icon"><i class="bi bi-houses-fill"></i></div>
            <div class="hg-panel-stat__texto"><span>Propiedades activas</span><strong><%= totalPropiedades %></strong></div>
        </a>
        <a class="hg-panel-stat" href="<%= request.getContextPath() %>/administrador/reportes.jsp">
            <div class="hg-panel-stat__icon"><i class="bi bi-building-fill"></i></div>
            <div class="hg-panel-stat__texto"><span>Inmobiliarias aliadas</span><strong><%= totalInmobiliarias %></strong></div>
        </a>
        <a class="hg-panel-stat" href="<%= request.getContextPath() %>/administrador/reportes.jsp">
            <div class="hg-panel-stat__icon"><i class="bi bi-clipboard-check-fill"></i></div>
            <div class="hg-panel-stat__texto"><span>Solicitudes por atender</span><strong><%= solicitudesPendientes %></strong></div>
        </a>
    </div>

    <div class="hg-panel-card">
        <h3 class="hg-panel-card__titulo"><i class="bi bi-lightning-charge-fill"></i> Acciones rápidas</h3>
        <div class="hg-quick-actions">
            <a class="hg-quick-action" href="<%= request.getContextPath() %>/administrador/reportes.jsp">
                <i class="bi bi-graph-up-arrow"></i>
                <span>Ver reportes</span>
            </a>
            <a class="hg-quick-action" href="<%= request.getContextPath() %>/administrador/usuarios.jsp">
                <i class="bi bi-people"></i>
                <span>Usuarios y roles</span>
            </a>
            <a class="hg-quick-action" href="<%= request.getContextPath() %>/administrador/catalogos.jsp">
                <i class="bi bi-tags"></i>
                <span>Parametrizar catálogos</span>
            </a>
            <a class="hg-quick-action" href="<%= request.getContextPath() %>/administrador/auditoria.jsp">
                <i class="bi bi-journal-text"></i>
                <span>Consultar auditoría</span>
            </a>
        </div>
    </div>
</div>
<%@ include file="/jspf/scripts-panel.jspf" %>
</body>
</html>
