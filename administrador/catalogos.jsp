<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ page import="java.sql.PreparedStatement, java.sql.ResultSet, java.sql.SQLException" %>
<%@ page import="java.util.ArrayList, java.util.List, java.util.Map, java.util.LinkedHashMap" %>
<%
    String[] rolesPermitidos = { "Administrador" };
%>
<%@ include file="/jspf/seguridad.jspf" %>
<%@ include file="/jspf/conexion.jspf" %>
<%
    // =========================================================================
    // Parametrizacion de catalogos: ciudad, tipo_propiedad, caracteristica.
    // Al eliminar, si el catalogo esta en uso por alguna propiedad, la FK
    // con ON DELETE RESTRICT lo impide; ese error se captura y se muestra
    // un mensaje claro en vez de la excepcion SQL.
    // =========================================================================
    List<String> errores = new ArrayList<>();
    String mensaje = null;

    if ("POST".equalsIgnoreCase(request.getMethod()) && conexion != null) {
        String accion = request.getParameter("accion");
        try {
            if ("agregarCiudad".equals(accion)) {
                String nombre = request.getParameter("nombre").trim();
                String depto = request.getParameter("departamento").trim();
                if (nombre.isEmpty() || depto.isEmpty()) {
                    errores.add("Ingresa el nombre de la ciudad y su departamento.");
                } else {
                    try (PreparedStatement ps = conexion.prepareStatement(
                            "INSERT INTO ciudad (nombre_ciudad, departamento) VALUES (?, ?)")) {
                        ps.setString(1, nombre); ps.setString(2, depto); ps.executeUpdate();
                    }
                }
            } else if ("eliminarCiudad".equals(accion)) {
                try (PreparedStatement ps = conexion.prepareStatement("DELETE FROM ciudad WHERE id_ciudad = ?")) {
                    ps.setInt(1, Integer.parseInt(request.getParameter("id"))); ps.executeUpdate();
                }
            } else if ("agregarTipo".equals(accion)) {
                String nombre = request.getParameter("nombre").trim();
                String desc = request.getParameter("descripcion") != null ? request.getParameter("descripcion").trim() : "";
                if (nombre.isEmpty()) {
                    errores.add("Ingresa el nombre del tipo de propiedad.");
                } else {
                    try (PreparedStatement ps = conexion.prepareStatement(
                            "INSERT INTO tipo_propiedad (nombre_tipo, descripcion) VALUES (?, ?)")) {
                        ps.setString(1, nombre);
                        if (desc.isEmpty()) ps.setNull(2, java.sql.Types.VARCHAR); else ps.setString(2, desc);
                        ps.executeUpdate();
                    }
                }
            } else if ("eliminarTipo".equals(accion)) {
                try (PreparedStatement ps = conexion.prepareStatement("DELETE FROM tipo_propiedad WHERE id_tipo = ?")) {
                    ps.setInt(1, Integer.parseInt(request.getParameter("id"))); ps.executeUpdate();
                }
            } else if ("agregarCaracteristica".equals(accion)) {
                String nombre = request.getParameter("nombre").trim();
                String icono = request.getParameter("icono") != null ? request.getParameter("icono").trim() : "";
                if (nombre.isEmpty()) {
                    errores.add("Ingresa el nombre de la caracteristica.");
                } else {
                    try (PreparedStatement ps = conexion.prepareStatement(
                            "INSERT INTO caracteristica (nombre_caracteristica, icono) VALUES (?, ?)")) {
                        ps.setString(1, nombre);
                        if (icono.isEmpty()) ps.setNull(2, java.sql.Types.VARCHAR); else ps.setString(2, icono);
                        ps.executeUpdate();
                    }
                }
            } else if ("eliminarCaracteristica".equals(accion)) {
                try (PreparedStatement ps = conexion.prepareStatement("DELETE FROM caracteristica WHERE id_caracteristica = ?")) {
                    ps.setInt(1, Integer.parseInt(request.getParameter("id"))); ps.executeUpdate();
                }
            }
        } catch (SQLException sqlEx) {
            if ("23000".equals(sqlEx.getSQLState())) {
                String msg = sqlEx.getMessage() != null ? sqlEx.getMessage().toLowerCase() : "";
                if (msg.contains("duplicate")) {
                    errores.add("Ya existe un registro con ese nombre.");
                } else {
                    errores.add("No se puede eliminar: esta en uso por una o mas propiedades.");
                }
            } else {
                errores.add("No fue posible completar la accion. Intenta nuevamente.");
            }
        } catch (Exception ignored) { }

        if (errores.isEmpty()) {
            try { conexion.close(); } catch (Exception ignored) { }
            response.sendRedirect(request.getContextPath() + "/administrador/catalogos.jsp?actualizado=1");
            return;
        }
    }

    if ("1".equals(request.getParameter("actualizado"))) mensaje = "Catalogo actualizado correctamente.";

    List<Map<String, Object>> ciudades = new ArrayList<>();
    List<Map<String, Object>> tipos = new ArrayList<>();
    List<Map<String, Object>> caracteristicas = new ArrayList<>();

    if (conexion != null) {
        try (PreparedStatement ps = conexion.prepareStatement("SELECT id_ciudad, nombre_ciudad, departamento FROM ciudad ORDER BY nombre_ciudad");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String, Object> f = new LinkedHashMap<>();
                f.put("id", rs.getInt(1)); f.put("nombre", rs.getString(2)); f.put("extra", rs.getString(3));
                ciudades.add(f);
            }
        } catch (Exception ignored) { }

        try (PreparedStatement ps = conexion.prepareStatement("SELECT id_tipo, nombre_tipo, descripcion FROM tipo_propiedad ORDER BY nombre_tipo");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String, Object> f = new LinkedHashMap<>();
                f.put("id", rs.getInt(1)); f.put("nombre", rs.getString(2)); f.put("extra", rs.getString(3));
                tipos.add(f);
            }
        } catch (Exception ignored) { }

        try (PreparedStatement ps = conexion.prepareStatement("SELECT id_caracteristica, nombre_caracteristica, icono FROM caracteristica ORDER BY nombre_caracteristica");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String, Object> f = new LinkedHashMap<>();
                f.put("id", rs.getInt(1)); f.put("nombre", rs.getString(2)); f.put("extra", rs.getString(3));
                caracteristicas.add(f);
            }
        } catch (Exception ignored) { }

        try { conexion.close(); } catch (Exception ignored) { }
    }
%><!DOCTYPE html>
<html lang="es">
<head>
    <% String hgTitulo = "Catalogos"; %>
    <%@ include file="/jspf/head-comun.jspf" %>
</head>
<body>
<%@ include file="/jspf/panel-header.jspf" %>

<div class="hg-panel-body">
    <div class="hg-panel-hero">
        <span class="hg-eyebrow">Panel de administracion</span>
        <h1>Catalogos del sistema</h1>
        <p><a href="<%= request.getContextPath() %>/administrador/dashboard-administrador.jsp">&larr; Volver a mi panel</a></p>
    </div>

    <% if (mensaje != null) { %><div class="hg-alert hg-alert--success" style="margin-bottom:20px;"><%= mensaje %></div><% } %>
    <% if (!errores.isEmpty()) { %>
    <div class="hg-alert hg-alert--error" style="margin-bottom:20px;">
        <ul><% for (String err : errores) { %><li><%= err %></li><% } %></ul>
    </div>
    <% } %>

    <div class="hg-reporte-grid">
        <div class="hg-panel-card">
            <h3 style="margin-bottom:14px;">Ciudades</h3>
            <div style="display:flex; flex-direction:column; gap:8px; margin-bottom:16px;">
                <% for (Map<String, Object> c : ciudades) { %>
                <div style="display:flex; justify-content:space-between; align-items:center; padding:8px 0; border-bottom:1px dashed var(--hg-border); font-size:.9rem;">
                    <span><%= c.get("nombre") %> <span style="color:var(--hg-ink-muted);">(<%= c.get("extra") %>)</span></span>
                    <form method="post" action="<%= request.getContextPath() %>/administrador/catalogos.jsp">
                        <input type="hidden" name="accion" value="eliminarCiudad">
                        <input type="hidden" name="id" value="<%= c.get("id") %>">
                        <button class="hg-btn hg-btn--ghost hg-btn--sm" type="submit" style="color:var(--hg-off);"><i class="bi bi-trash3"></i> Eliminar</button>
                    </form>
                </div>
                <% } %>
            </div>
            <form method="post" action="<%= request.getContextPath() %>/administrador/catalogos.jsp" style="display:flex; flex-direction:column; gap:10px;">
                <input type="hidden" name="accion" value="agregarCiudad">
                <input class="form-control" type="text" name="nombre" placeholder="Nombre de la ciudad" maxlength="80" required>
                <input class="form-control" type="text" name="departamento" placeholder="Departamento" maxlength="80" required>
                <button class="hg-btn hg-btn--primary hg-btn--sm" type="submit"><i class="bi bi-plus-lg"></i> Agregar ciudad</button>
            </form>
        </div>

        <div class="hg-panel-card">
            <h3 style="margin-bottom:14px;">Tipos de propiedad</h3>
            <div style="display:flex; flex-direction:column; gap:8px; margin-bottom:16px;">
                <% for (Map<String, Object> t : tipos) { %>
                <div style="display:flex; justify-content:space-between; align-items:center; padding:8px 0; border-bottom:1px dashed var(--hg-border); font-size:.9rem;">
                    <span><%= t.get("nombre") %></span>
                    <form method="post" action="<%= request.getContextPath() %>/administrador/catalogos.jsp">
                        <input type="hidden" name="accion" value="eliminarTipo">
                        <input type="hidden" name="id" value="<%= t.get("id") %>">
                        <button class="hg-btn hg-btn--ghost hg-btn--sm" type="submit" style="color:var(--hg-off);"><i class="bi bi-trash3"></i> Eliminar</button>
                    </form>
                </div>
                <% } %>
            </div>
            <form method="post" action="<%= request.getContextPath() %>/administrador/catalogos.jsp" style="display:flex; flex-direction:column; gap:10px;">
                <input type="hidden" name="accion" value="agregarTipo">
                <input class="form-control" type="text" name="nombre" placeholder="Nombre del tipo" maxlength="40" required>
                <input class="form-control" type="text" name="descripcion" placeholder="Descripcion (opcional)" maxlength="150">
                <button class="hg-btn hg-btn--primary hg-btn--sm" type="submit"><i class="bi bi-plus-lg"></i> Agregar tipo</button>
            </form>
        </div>

        <div class="hg-panel-card">
            <h3 style="margin-bottom:14px;">Caracteristicas</h3>
            <div style="display:flex; flex-direction:column; gap:8px; margin-bottom:16px;">
                <% for (Map<String, Object> car : caracteristicas) { %>
                <div style="display:flex; justify-content:space-between; align-items:center; padding:8px 0; border-bottom:1px dashed var(--hg-border); font-size:.9rem;">
                    <span><%= car.get("nombre") %></span>
                    <form method="post" action="<%= request.getContextPath() %>/administrador/catalogos.jsp">
                        <input type="hidden" name="accion" value="eliminarCaracteristica">
                        <input type="hidden" name="id" value="<%= car.get("id") %>">
                        <button class="hg-btn hg-btn--ghost hg-btn--sm" type="submit" style="color:var(--hg-off);"><i class="bi bi-trash3"></i> Eliminar</button>
                    </form>
                </div>
                <% } %>
            </div>
            <form method="post" action="<%= request.getContextPath() %>/administrador/catalogos.jsp" style="display:flex; flex-direction:column; gap:10px;">
                <input type="hidden" name="accion" value="agregarCaracteristica">
                <input class="form-control" type="text" name="nombre" placeholder="Nombre de la caracteristica" maxlength="50" required>
                <input class="form-control" type="text" name="icono" placeholder="Icono (opcional, ej. bi-water)" maxlength="50">
                <button class="hg-btn hg-btn--primary hg-btn--sm" type="submit"><i class="bi bi-plus-lg"></i> Agregar caracteristica</button>
            </form>
        </div>
    </div>
</div>
<%@ include file="/jspf/scripts-panel.jspf" %>
</body>
</html>
