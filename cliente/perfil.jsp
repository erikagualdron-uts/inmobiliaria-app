<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ page import="java.sql.PreparedStatement, java.sql.ResultSet, java.sql.SQLException" %>
<%@ page import="java.util.ArrayList, java.util.List" %>
<%
    String[] rolesPermitidos = { "Cliente" };
%>
<%@ include file="/jspf/seguridad.jspf" %>
<%@ include file="/jspf/conexion.jspf" %>
<%@ include file="/jspf/utilidades.jspf" %>
<%
    // =========================================================================
    // El cliente actualiza sus propios datos de perfil (relacion 1:1 con
    // usuario). El correo y la contrasena no se editan aqui: son datos de
    // la cuenta, no del perfil.
    // =========================================================================
    int idUsuarioSesion = (Integer) session.getAttribute("idUsuario");
    List<String> errores = new ArrayList<>();
    boolean guardadoExitoso = false;

    String correoCuenta = "";
    String nombres = "", apellidos = "", tipoDocumento = "CC", numeroDocumento = "",
           telefono = "", direccion = "", fotoUrl = "";

    if (conexion != null) {
        try (PreparedStatement ps = conexion.prepareStatement("SELECT correo FROM usuario WHERE id_usuario = ?")) {
            ps.setInt(1, idUsuarioSesion);
            try (ResultSet rs = ps.executeQuery()) { if (rs.next()) correoCuenta = rs.getString(1); }
        } catch (Exception ignored) { }

        if (!"POST".equalsIgnoreCase(request.getMethod())) {
            try (PreparedStatement ps = conexion.prepareStatement(
                    "SELECT nombres, apellidos, tipo_documento, numero_documento, telefono, direccion, foto_url " +
                    "FROM perfil WHERE id_usuario = ?")) {
                ps.setInt(1, idUsuarioSesion);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        nombres = rs.getString("nombres");
                        apellidos = rs.getString("apellidos");
                        tipoDocumento = rs.getString("tipo_documento");
                        numeroDocumento = rs.getString("numero_documento");
                        telefono = rs.getString("telefono") != null ? rs.getString("telefono") : "";
                        direccion = rs.getString("direccion") != null ? rs.getString("direccion") : "";
                        fotoUrl = rs.getString("foto_url") != null ? rs.getString("foto_url") : "";
                    }
                }
            } catch (Exception ignored) { }
        }

        if ("POST".equalsIgnoreCase(request.getMethod())) {
            nombres = valor(request.getParameter("nombres"));
            apellidos = valor(request.getParameter("apellidos"));
            tipoDocumento = valor(request.getParameter("tipoDocumento"));
            numeroDocumento = valor(request.getParameter("numeroDocumento"));
            telefono = valor(request.getParameter("telefono"));
            direccion = valor(request.getParameter("direccion"));
            fotoUrl = valor(request.getParameter("fotoUrl"));

            if (nombres.isEmpty() || !nombres.matches("^[\\p{L} ]{2,80}$")) {
                errores.add("Ingresa un nombre valido (solo letras, entre 2 y 80 caracteres).");
            }
            if (apellidos.isEmpty() || !apellidos.matches("^[\\p{L} ]{2,80}$")) {
                errores.add("Ingresa un apellido valido (solo letras, entre 2 y 80 caracteres).");
            }
            if (!tipoDocumento.matches("^(CC|CE|TI|PAS)$")) {
                errores.add("Selecciona un tipo de documento valido.");
            }
            if (!numeroDocumento.matches("^[0-9]{5,15}$")) {
                errores.add("El numero de documento debe tener entre 5 y 15 digitos.");
            }
            if (!telefono.isEmpty() && !telefono.matches("^[0-9]{7,15}$")) {
                errores.add("El telefono debe contener solo numeros (7 a 15 digitos).");
            }
            if (direccion.length() > 150) {
                errores.add("La direccion no puede superar 150 caracteres.");
            }
            if (!fotoUrl.isEmpty() && !fotoUrl.matches("^https?://.+")) {
                errores.add("La URL de la foto debe iniciar con http:// o https://.");
            }

            if (errores.isEmpty() && conexion != null) {
                try (PreparedStatement ps = conexion.prepareStatement(
                        "UPDATE perfil SET nombres=?, apellidos=?, tipo_documento=?, numero_documento=?, " +
                        "telefono=?, direccion=?, foto_url=? WHERE id_usuario=?")) {
                    ps.setString(1, nombres);
                    ps.setString(2, apellidos);
                    ps.setString(3, tipoDocumento);
                    ps.setString(4, numeroDocumento);
                    if (telefono.isEmpty()) ps.setNull(5, java.sql.Types.VARCHAR); else ps.setString(5, telefono);
                    if (direccion.isEmpty()) ps.setNull(6, java.sql.Types.VARCHAR); else ps.setString(6, direccion);
                    if (fotoUrl.isEmpty()) ps.setNull(7, java.sql.Types.VARCHAR); else ps.setString(7, fotoUrl);
                    ps.setInt(8, idUsuarioSesion);
                    ps.executeUpdate();
                    guardadoExitoso = true;

                    // El nombre mostrado en la barra superior viene de la sesion; se refresca.
                    session.setAttribute("nombreUsuario", nombres);
                } catch (SQLException sqlEx) {
                    if ("23000".equals(sqlEx.getSQLState())) {
                        errores.add("Ese numero de documento ya esta registrado por otra cuenta.");
                    } else {
                        errores.add("No fue posible actualizar tu perfil. Intenta nuevamente.");
                    }
                }
            }
        }

        try { conexion.close(); } catch (Exception ignored) { }
    }
%><!DOCTYPE html>
<html lang="es">
<head>
    <% String hgTitulo = "Mi perfil"; %>
    <%@ include file="/jspf/head-comun.jspf" %>
</head>
<body>
<%@ include file="/jspf/panel-header.jspf" %>

<div class="hg-panel-body" style="max-width:640px;">
    <div class="hg-panel-hero">
        <span class="hg-eyebrow">Panel de cliente</span>
        <h1>Mi perfil</h1>
        <p><a href="<%= request.getContextPath() %>/cliente/dashboard-cliente.jsp">&larr; Volver a mi panel</a></p>
    </div>

    <% if (guardadoExitoso) { %>
    <div class="hg-alert hg-alert--success" style="margin-bottom:20px;">Tu perfil se actualizo correctamente.</div>
    <% } %>
    <% if (!errores.isEmpty()) { %>
    <div class="hg-alert hg-alert--error" style="margin-bottom:20px;">
        <ul><% for (String err : errores) { %><li><%= err %></li><% } %></ul>
    </div>
    <% } %>

    <div class="hg-panel-card">
        <div class="hg-field" style="margin-bottom:18px;">
            <label>Correo (credencial de ingreso, no editable aqui)</label>
            <input class="form-control" type="email" value="<%= correoCuenta %>" disabled>
        </div>

        <form method="post" action="<%= request.getContextPath() %>/cliente/perfil.jsp" style="display:flex; flex-direction:column; gap:16px;">
            <div class="hg-auth__grid">
                <div class="hg-field">
                    <label for="nombres">Nombres</label>
                    <input class="form-control" type="text" id="nombres" name="nombres" value="<%= nombres %>" maxlength="80" required>
                </div>
                <div class="hg-field">
                    <label for="apellidos">Apellidos</label>
                    <input class="form-control" type="text" id="apellidos" name="apellidos" value="<%= apellidos %>" maxlength="80" required>
                </div>
                <div class="hg-field">
                    <label for="tipoDocumento">Tipo de documento</label>
                    <select class="form-select" id="tipoDocumento" name="tipoDocumento">
                        <option value="CC" <%= "CC".equals(tipoDocumento) ? "selected" : "" %>>Cedula de ciudadania</option>
                        <option value="CE" <%= "CE".equals(tipoDocumento) ? "selected" : "" %>>Cedula de extranjeria</option>
                        <option value="TI" <%= "TI".equals(tipoDocumento) ? "selected" : "" %>>Tarjeta de identidad</option>
                        <option value="PAS" <%= "PAS".equals(tipoDocumento) ? "selected" : "" %>>Pasaporte</option>
                    </select>
                </div>
                <div class="hg-field">
                    <label for="numeroDocumento">Numero de documento</label>
                    <input class="form-control" type="text" id="numeroDocumento" name="numeroDocumento" value="<%= numeroDocumento %>" maxlength="15" required>
                </div>
                <div class="hg-field">
                    <label for="telefono">Telefono (opcional)</label>
                    <input class="form-control" type="tel" id="telefono" name="telefono" value="<%= telefono %>" maxlength="20">
                </div>
                <div class="hg-field">
                    <label for="fotoUrl">URL de foto de perfil (opcional)</label>
                    <input class="form-control" type="url" id="fotoUrl" name="fotoUrl" value="<%= fotoUrl %>" maxlength="255" placeholder="https://...">
                </div>
                <div class="hg-field hg-field--full">
                    <label for="direccion">Direccion (opcional)</label>
                    <input class="form-control" type="text" id="direccion" name="direccion" value="<%= direccion %>" maxlength="150">
                </div>
            </div>
            <button class="hg-btn hg-btn--primary" type="submit" style="align-self:flex-start;">Guardar cambios</button>
        </form>
    </div>
</div>
</body>
</html>
