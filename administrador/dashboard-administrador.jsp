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
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Panel de administracion | Hogaria</title>
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Fraunces:opsz,wght@9..144,500;9..144,600;9..144,700&family=Work+Sans:wght@400;500;600;700&display=swap">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css">
    <link rel="stylesheet" href="<%= request.getContextPath() %>/assets/css/estilos.css">
</head>
<body>
<%@ include file="/jspf/panel-header.jspf" %>

<div class="hg-panel-body">
    <div class="hg-panel-hero">
        <span class="hg-eyebrow">Panel de administracion</span>
        <h1>Hola, <%= session.getAttribute("nombreUsuario") %></h1>
        <p>Vision general de la operacion de Hogaria.</p>
    </div>

    <div class="hg-panel-grid">
        <a class="hg-panel-stat" href="<%= request.getContextPath() %>/administrador/usuarios.jsp" style="display:block; text-decoration:none;"><strong><%= totalUsuarios %></strong><span>Usuarios registrados</span></a>
        <a class="hg-panel-stat" href="<%= request.getContextPath() %>/catalogo.jsp" style="display:block; text-decoration:none;"><strong><%= totalPropiedades %></strong><span>Propiedades activas</span></a>
        <a class="hg-panel-stat" href="<%= request.getContextPath() %>/administrador/reportes.jsp" style="display:block; text-decoration:none;"><strong><%= totalInmobiliarias %></strong><span>Inmobiliarias aliadas</span></a>
        <a class="hg-panel-stat" href="<%= request.getContextPath() %>/administrador/reportes.jsp" style="display:block; text-decoration:none;"><strong><%= solicitudesPendientes %></strong><span>Solicitudes por atender</span></a>
    </div>

    <div class="hg-panel-card" style="display:flex; gap:14px; flex-wrap:wrap;">
        <a class="hg-btn hg-btn--primary" href="<%= request.getContextPath() %>/administrador/reportes.jsp">📊 Ver reportes</a>
        <a class="hg-btn hg-btn--ghost" href="<%= request.getContextPath() %>/administrador/usuarios.jsp">👤 Gestionar usuarios y roles</a>
        <a class="hg-btn hg-btn--ghost" href="<%= request.getContextPath() %>/administrador/catalogos.jsp">🗂️ Parametrizar catalogos</a>
        <a class="hg-btn hg-btn--ghost" href="<%= request.getContextPath() %>/administrador/auditoria.jsp">🗒️ Consultar auditoria</a>
    </div>
</div>
</body>
</html>
