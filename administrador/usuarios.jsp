<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ page import="java.sql.PreparedStatement, java.sql.ResultSet, java.sql.SQLException" %>
<%@ page import="java.util.ArrayList, java.util.List, java.util.Map, java.util.LinkedHashMap, java.util.HashSet, java.util.Set" %>
<%
    String[] rolesPermitidos = { "Administrador" };
%>
<%@ include file="/jspf/seguridad.jspf" %>
<%@ include file="/jspf/conexion.jspf" %>
<%
    // =========================================================================
    // Gestion de usuarios: activar/inactivar cuentas, asignar/revocar roles
    // y asociar un agente a una inmobiliaria. El administrador no puede
    // quitarse a si mismo el rol de Administrador ni desactivar su propia
    // cuenta (evita bloquearse por accidente).
    // =========================================================================
    int idUsuarioSesion = (Integer) session.getAttribute("idUsuario");
    List<String> errores = new ArrayList<>();
    String mensaje = null;

    List<Map<String, Object>> catalogoRoles = new ArrayList<>();
    List<Map<String, Object>> catalogoInmobiliarias = new ArrayList<>();
    if (conexion != null) {
        try (PreparedStatement ps = conexion.prepareStatement("SELECT id_rol, nombre_rol FROM rol ORDER BY id_rol");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String, Object> f = new LinkedHashMap<>();
                f.put("id", rs.getInt(1)); f.put("nombre", rs.getString(2));
                catalogoRoles.add(f);
            }
        } catch (Exception ignored) { }

        try (PreparedStatement ps = conexion.prepareStatement("SELECT id_inmobiliaria, nombre_comercial FROM inmobiliaria ORDER BY nombre_comercial");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String, Object> f = new LinkedHashMap<>();
                f.put("id", rs.getInt(1)); f.put("nombre", rs.getString(2));
                catalogoInmobiliarias.add(f);
            }
        } catch (Exception ignored) { }
    }

    if ("POST".equalsIgnoreCase(request.getMethod()) && "actualizarUsuario".equals(request.getParameter("accion")) && conexion != null) {
        try {
            int idUsuarioEditar = Integer.parseInt(request.getParameter("idUsuario"));
            String nuevoEstado = request.getParameter("estado");
            String idInmobiliariaParam = request.getParameter("idInmobiliaria");
            String[] rolesParam = request.getParameterValues("roles");
            Set<String> nuevosRoles = new HashSet<>();
            if (rolesParam != null) for (String r : rolesParam) nuevosRoles.add(r);

            if (!nuevoEstado.matches("^(activo|inactivo|bloqueado)$")) {
                errores.add("Estado invalido.");
            }

            boolean tendrianAdministrador = false;
            for (Map<String, Object> r : catalogoRoles) {
                if ("Administrador".equals(r.get("nombre")) && nuevosRoles.contains(String.valueOf(r.get("id")))) {
                    tendrianAdministrador = true;
                }
            }
            if (idUsuarioEditar == idUsuarioSesion && (!tendrianAdministrador || !"activo".equals(nuevoEstado))) {
                errores.add("No puedes quitarte a ti mismo el rol de Administrador ni desactivar tu propia cuenta.");
            }

            if (errores.isEmpty()) {
                Integer idInmobiliariaFinal = null;
                if (idInmobiliariaParam != null && !idInmobiliariaParam.trim().isEmpty()) {
                    idInmobiliariaFinal = Integer.valueOf(idInmobiliariaParam.trim());
                }

                conexion.setAutoCommit(false);
                try (PreparedStatement ps = conexion.prepareStatement(
                        "UPDATE usuario SET estado = ?, id_inmobiliaria = ? WHERE id_usuario = ?")) {
                    ps.setString(1, nuevoEstado);
                    if (idInmobiliariaFinal == null) ps.setNull(2, java.sql.Types.INTEGER); else ps.setInt(2, idInmobiliariaFinal);
                    ps.setInt(3, idUsuarioEditar);
                    ps.executeUpdate();
                }
                try (PreparedStatement ps = conexion.prepareStatement("DELETE FROM usuario_rol WHERE id_usuario = ?")) {
                    ps.setInt(1, idUsuarioEditar);
                    ps.executeUpdate();
                }
                try (PreparedStatement ps = conexion.prepareStatement(
                        "INSERT INTO usuario_rol (id_usuario, id_rol) VALUES (?, ?)")) {
                    for (String idRolStr : nuevosRoles) {
                        ps.setInt(1, idUsuarioEditar);
                        ps.setInt(2, Integer.parseInt(idRolStr));
                        ps.addBatch();
                    }
                    if (!nuevosRoles.isEmpty()) ps.executeBatch();
                }
                conexion.commit();
                conexion.setAutoCommit(true);
            }
        } catch (SQLException sqlEx) {
            try { conexion.rollback(); conexion.setAutoCommit(true); } catch (SQLException ignored) { }
            errores.add("No fue posible actualizar el usuario. Intenta nuevamente.");
        } catch (Exception ignored) { }

        if (errores.isEmpty()) {
            try { conexion.close(); } catch (Exception ignored) { }
            response.sendRedirect(request.getContextPath() + "/administrador/usuarios.jsp?actualizado=1");
            return;
        }
    }

    if ("1".equals(request.getParameter("actualizado"))) mensaje = "Usuario actualizado correctamente.";

    List<Map<String, Object>> usuarios = new ArrayList<>();
    if (conexion != null) {
        try (PreparedStatement ps = conexion.prepareStatement(
                "SELECT u.id_usuario, u.correo, u.estado, u.id_inmobiliaria, per.nombres, per.apellidos " +
                "FROM usuario u LEFT JOIN perfil per ON per.id_usuario = u.id_usuario " +
                "ORDER BY u.id_usuario")) {
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> f = new LinkedHashMap<>();
                    int idU = rs.getInt("id_usuario");
                    f.put("id", idU);
                    f.put("correo", rs.getString("correo"));
                    f.put("estado", rs.getString("estado"));
                    int idInm = rs.getInt("id_inmobiliaria");
                    f.put("idInmobiliaria", rs.wasNull() ? null : idInm);
                    String nombres = rs.getString("nombres"), apellidos = rs.getString("apellidos");
                    f.put("nombreCompleto", nombres != null ? nombres + " " + apellidos : "(sin perfil)");

                    Set<String> rolesUsuario = new HashSet<>();
                    try (PreparedStatement psRol = conexion.prepareStatement(
                            "SELECT id_rol FROM usuario_rol WHERE id_usuario = ?")) {
                        psRol.setInt(1, idU);
                        try (ResultSet rsRol = psRol.executeQuery()) {
                            while (rsRol.next()) rolesUsuario.add(String.valueOf(rsRol.getInt(1)));
                        }
                    }
                    f.put("roles", rolesUsuario);
                    usuarios.add(f);
                }
            }
        } catch (Exception ignored) { }
        try { conexion.close(); } catch (Exception ignored) { }
    }
%><!DOCTYPE html>
<html lang="es">
<head>
    <% String hgTitulo = "Usuarios"; %>
    <%@ include file="/jspf/head-comun.jspf" %>
</head>
<body>
<%@ include file="/jspf/panel-header.jspf" %>

<div class="hg-panel-body">
    <div class="hg-panel-hero">
        <span class="hg-eyebrow">Panel de administracion</span>
        <h1>Usuarios y roles</h1>
        <p><a href="<%= request.getContextPath() %>/administrador/dashboard-administrador.jsp">&larr; Volver a mi panel</a></p>
    </div>

    <% if (mensaje != null) { %><div class="hg-alert hg-alert--success" style="margin-bottom:20px;"><%= mensaje %></div><% } %>
    <% if (!errores.isEmpty()) { %>
    <div class="hg-alert hg-alert--error" style="margin-bottom:20px;">
        <ul><% for (String err : errores) { %><li><%= err %></li><% } %></ul>
    </div>
    <% } %>

    <div style="display:flex; flex-direction:column; gap:14px;">
        <% for (Map<String, Object> u : usuarios) {
            String estadoU = (String) u.get("estado");
            @SuppressWarnings("unchecked")
            Set<String> rolesU = (Set<String>) u.get("roles");
            Object idInmU = u.get("idInmobiliaria");
        %>
        <div class="hg-panel-card">
            <details>
                <summary style="cursor:pointer; display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:10px;">
                    <span>
                        <strong><%= u.get("nombreCompleto") %></strong>
                        <span style="color:var(--hg-ink-muted); font-size:.86rem;"> &middot; <%= u.get("correo") %></span>
                    </span>
                    <span style="display:flex; gap:6px; flex-wrap:wrap;">
                        <span class="hg-badge--estado <%= "activo".equals(estadoU) ? "hg-badge--disponible" : "hg-badge--vendido" %>" style="position:static; display:inline-block;"><%= estadoU.substring(0,1).toUpperCase() + estadoU.substring(1) %></span>
                        <% for (Map<String, Object> r : catalogoRoles) { if (rolesU.contains(String.valueOf(r.get("id")))) { %>
                        <span class="hg-panel-topbar__role" style="position:static;"><%= r.get("nombre") %></span>
                        <% } } %>
                    </span>
                </summary>

                <form method="post" action="<%= request.getContextPath() %>/administrador/usuarios.jsp" style="margin-top:16px; display:flex; flex-direction:column; gap:14px;">
                    <input type="hidden" name="accion" value="actualizarUsuario">
                    <input type="hidden" name="idUsuario" value="<%= u.get("id") %>">

                    <div class="hg-auth__grid">
                        <div class="hg-field">
                            <label>Estado de la cuenta</label>
                            <select class="form-select" name="estado">
                                <option value="activo" <%= "activo".equals(estadoU) ? "selected" : "" %>>Activo</option>
                                <option value="inactivo" <%= "inactivo".equals(estadoU) ? "selected" : "" %>>Inactivo</option>
                                <option value="bloqueado" <%= "bloqueado".equals(estadoU) ? "selected" : "" %>>Bloqueado</option>
                            </select>
                        </div>
                        <div class="hg-field">
                            <label>Inmobiliaria (solo si tiene rol Inmobiliaria)</label>
                            <select class="form-select" name="idInmobiliaria">
                                <option value="">Ninguna</option>
                                <% for (Map<String, Object> in : catalogoInmobiliarias) { %>
                                <option value="<%= in.get("id") %>" <%= in.get("id").toString().equals(String.valueOf(idInmU)) ? "selected" : "" %>><%= in.get("nombre") %></option>
                                <% } %>
                            </select>
                        </div>
                    </div>

                    <div>
                        <label style="display:block; margin-bottom:8px; font-weight:600; font-size:.9rem;">Roles</label>
                        <% for (Map<String, Object> r : catalogoRoles) {
                            String idRolStr = String.valueOf(r.get("id"));
                        %>
                        <label class="hg-checkbox">
                            <input type="checkbox" name="roles" value="<%= idRolStr %>" <%= rolesU.contains(idRolStr) ? "checked" : "" %>>
                            <%= r.get("nombre") %>
                        </label>
                        <% } %>
                    </div>

                    <button class="hg-btn hg-btn--primary hg-btn--sm" type="submit" style="align-self:flex-start;">Guardar cambios</button>
                </form>
            </details>
        </div>
        <% } %>
    </div>
</div>
</body>
</html>
