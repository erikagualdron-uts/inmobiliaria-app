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
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Mi panel | Hogaria</title>
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Fraunces:opsz,wght@9..144,500;9..144,600;9..144,700&family=Work+Sans:wght@400;500;600;700&display=swap">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css">
    <link rel="stylesheet" href="<%= request.getContextPath() %>/assets/css/estilos.css">
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
        <a class="hg-panel-stat" href="<%= request.getContextPath() %>/mis-citas.jsp" style="display:block; text-decoration:none;"><strong><%= totalCitas %></strong><span>Citas agendadas</span></a>
        <a class="hg-panel-stat" href="<%= request.getContextPath() %>/mis-solicitudes.jsp" style="display:block; text-decoration:none;"><strong><%= totalSolicitudes %></strong><span>Solicitudes radicadas</span></a>
        <a class="hg-panel-stat" href="<%= request.getContextPath() %>/favoritos.jsp" style="display:block; text-decoration:none;"><strong><%= totalFavoritos %></strong><span>Propiedades favoritas</span></a>
    </div>

    <div class="hg-panel-card">
        <div class="hg-panel-empty">
            <div class="hg-panel-empty__icon">🚧</div>
            <p><strong>Proximamente:</strong> edicion de tu perfil directamente desde este panel.</p>
        </div>
    </div>
</div>
</body>
</html>
