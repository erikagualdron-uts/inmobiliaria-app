<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ page import="java.sql.PreparedStatement, java.sql.ResultSet, java.sql.SQLException, java.sql.Statement" %>
<%@ page import="java.util.ArrayList, java.util.List" %>
<%@ include file="/jspf/conexion.jspf" %>
<%@ include file="/jspf/utilidades.jspf" %>
<%
    // Si ya hay una sesion activa, no tiene sentido mostrar el registro
    if (session.getAttribute("idUsuario") != null) {
        response.sendRedirect(request.getContextPath() + "/index.jsp");
        return;
    }

    List<String> errores = new ArrayList<>();
    boolean registroExitoso = false;

    String nombres = "", apellidos = "", tipoDocumento = "CC", numeroDocumento = "",
           correo = "", telefono = "", direccion = "";

    if ("POST".equalsIgnoreCase(request.getMethod())) {
        nombres = valor(request.getParameter("nombres"));
        apellidos = valor(request.getParameter("apellidos"));
        tipoDocumento = valor(request.getParameter("tipoDocumento"));
        numeroDocumento = valor(request.getParameter("numeroDocumento"));
        correo = valor(request.getParameter("correo"));
        telefono = valor(request.getParameter("telefono"));
        direccion = valor(request.getParameter("direccion"));
        String contrasena = valor(request.getParameter("contrasena"));
        String confirmarContrasena = valor(request.getParameter("confirmarContrasena"));

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
        if (!correo.matches("^[\\w.+-]+@[\\w-]+\\.[a-zA-Z]{2,}$")) {
            errores.add("Ingresa un correo electronico valido.");
        }
        if (!telefono.isEmpty() && !telefono.matches("^[0-9]{7,15}$")) {
            errores.add("El telefono debe contener solo numeros (7 a 15 digitos).");
        }
        if (direccion.length() > 150) {
            errores.add("La direccion no puede superar 150 caracteres.");
        }
        if (contrasena.length() < 8) {
            errores.add("La contrasena debe tener minimo 8 caracteres.");
        }
        if (!contrasena.equals(confirmarContrasena)) {
            errores.add("Las contrasenas no coinciden.");
        }

        if (errores.isEmpty()) {
            if (conexion == null) {
                errores.add(errorConexion != null ? errorConexion : "No fue posible conectar con la base de datos.");
            } else {
                try {
                    conexion.setAutoCommit(false);
                    String hashClave = generarHashClave(contrasena);
                    int idUsuarioNuevo;

                    try (PreparedStatement psUsuario = conexion.prepareStatement(
                            "INSERT INTO usuario (correo, contrasena_hash, estado) VALUES (?, ?, 'activo')",
                            Statement.RETURN_GENERATED_KEYS)) {
                        psUsuario.setString(1, correo);
                        psUsuario.setString(2, hashClave);
                        psUsuario.executeUpdate();
                        try (ResultSet keys = psUsuario.getGeneratedKeys()) {
                            keys.next();
                            idUsuarioNuevo = keys.getInt(1);
                        }
                    }

                    try (PreparedStatement psPerfil = conexion.prepareStatement(
                            "INSERT INTO perfil (id_usuario, nombres, apellidos, tipo_documento, numero_documento, telefono, direccion) " +
                            "VALUES (?, ?, ?, ?, ?, ?, ?)")) {
                        psPerfil.setInt(1, idUsuarioNuevo);
                        psPerfil.setString(2, nombres);
                        psPerfil.setString(3, apellidos);
                        psPerfil.setString(4, tipoDocumento);
                        psPerfil.setString(5, numeroDocumento);
                        if (telefono.isEmpty()) psPerfil.setNull(6, java.sql.Types.VARCHAR); else psPerfil.setString(6, telefono);
                        if (direccion.isEmpty()) psPerfil.setNull(7, java.sql.Types.VARCHAR); else psPerfil.setString(7, direccion);
                        psPerfil.executeUpdate();
                    }

                    try (PreparedStatement psRol = conexion.prepareStatement(
                            "INSERT INTO usuario_rol (id_usuario, id_rol) SELECT ?, id_rol FROM rol WHERE nombre_rol = 'Cliente'")) {
                        psRol.setInt(1, idUsuarioNuevo);
                        psRol.executeUpdate();
                    }

                    conexion.commit();
                    registroExitoso = true;

                } catch (SQLException sqlEx) {
                    try { conexion.rollback(); } catch (SQLException ignored) { }
                    String msg = sqlEx.getMessage() != null ? sqlEx.getMessage().toLowerCase() : "";
                    if ("23000".equals(sqlEx.getSQLState()) && msg.contains("correo")) {
                        errores.add("Este correo ya se encuentra registrado.");
                    } else if ("23000".equals(sqlEx.getSQLState()) && msg.contains("documento")) {
                        errores.add("Este numero de documento ya esta registrado.");
                    } else if ("23000".equals(sqlEx.getSQLState())) {
                        errores.add("Ya existe un registro con esos datos.");
                    } else {
                        errores.add("No fue posible completar el registro. Intenta nuevamente.");
                    }
                } finally {
                    try { conexion.setAutoCommit(true); } catch (SQLException ignored) { }
                }
            }
        }
    }

    if (conexion != null) {
        try { conexion.close(); } catch (Exception ignored) { }
    }
%><!DOCTYPE html>
<html lang="es">
<head>
    <% String hgTitulo = "Crear cuenta"; %>
    <%@ include file="/jspf/head-comun.jspf" %>
</head>
<body>
<div class="hg-auth">
    <div class="hg-auth__card hg-auth__card--wide">
        <a class="hg-auth__back" href="<%= request.getContextPath() %>/index.jsp">&larr; Volver al inicio</a>
        <div class="hg-auth__brand">
            <span class="hg-brand" style="color:var(--hg-primary-dark);">
                <svg width="26" height="26" viewBox="0 0 32 32" fill="none" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
                    <path d="M4 15L16 5L28 15" stroke="#D9A441" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"/>
                    <path d="M7 13V26H25V13" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"/>
                    <path d="M13 26V19H19V26" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"/>
                </svg>
                Hogaria
            </span>
        </div>

        <% if (registroExitoso) { %>
            <h1 class="hg-auth__title">Cuenta creada con exito</h1>
            <p class="hg-auth__subtitle">Ya puedes iniciar sesion con tu correo y contrasena.</p>
            <div class="hg-alert hg-alert--success" style="margin-bottom:18px;">Tu cuenta quedo registrada como Cliente. Bienvenido a Hogaria.</div>
            <a class="hg-btn hg-btn--primary hg-btn--block" href="<%= request.getContextPath() %>/login.jsp?registrado=1">Ir a iniciar sesion</a>
        <% } else { %>
            <h1 class="hg-auth__title">Crea tu cuenta</h1>
            <p class="hg-auth__subtitle">Guarda favoritos, agenda citas y radica tus solicitudes con Hogaria.</p>

            <% if (!errores.isEmpty()) { %>
            <div class="hg-alert hg-alert--error" style="margin-bottom:18px;">
                <ul>
                    <% for (String err : errores) { %>
                    <li><%= err %></li>
                    <% } %>
                </ul>
            </div>
            <% } %>

            <form method="post" action="<%= request.getContextPath() %>/registro.jsp" novalidate>
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
                    <div class="hg-field hg-field--full">
                        <label for="correo">Correo electronico</label>
                        <input class="form-control" type="email" id="correo" name="correo" value="<%= correo %>" maxlength="120" required>
                    </div>
                    <div class="hg-field">
                        <label for="telefono">Telefono (opcional)</label>
                        <input class="form-control" type="tel" id="telefono" name="telefono" value="<%= telefono %>" maxlength="20">
                    </div>
                    <div class="hg-field">
                        <label for="direccion">Direccion (opcional)</label>
                        <input class="form-control" type="text" id="direccion" name="direccion" value="<%= direccion %>" maxlength="150">
                    </div>
                    <div class="hg-field">
                        <label for="contrasena">Contrasena</label>
                        <input class="form-control" type="password" id="contrasena" name="contrasena" minlength="8" required>
                    </div>
                    <div class="hg-field">
                        <label for="confirmarContrasena">Confirmar contrasena</label>
                        <input class="form-control" type="password" id="confirmarContrasena" name="confirmarContrasena" minlength="8" required>
                    </div>
                </div>
                <button class="hg-btn hg-btn--primary hg-btn--block" type="submit">Crear cuenta</button>
            </form>

            <p class="hg-auth__footer">¿Ya tienes cuenta? <a href="<%= request.getContextPath() %>/login.jsp">Inicia sesion</a></p>
        <% } %>
    </div>
</div>
</body>
</html>
