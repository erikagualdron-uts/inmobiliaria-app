<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ page import="java.sql.PreparedStatement, java.sql.ResultSet" %>
<%@ page import="java.util.ArrayList, java.util.List" %>
<%@ include file="/jspf/conexion.jspf" %>
<%@ include file="/jspf/utilidades.jspf" %>
<%
    if (session.getAttribute("idUsuario") != null) {
        response.sendRedirect(request.getContextPath() + "/index.jsp");
        return;
    }

    List<String> errores = new ArrayList<>();
    String correo = "";
    boolean vieneDeRegistro = "1".equals(request.getParameter("registrado"));

    if ("POST".equalsIgnoreCase(request.getMethod())) {
        correo = valor(request.getParameter("correo"));
        String contrasena = valor(request.getParameter("contrasena"));

        if (correo.isEmpty() || contrasena.isEmpty()) {
            errores.add("Ingresa tu correo y tu contrasena.");
        } else if (conexion == null) {
            errores.add(errorConexion != null ? errorConexion : "No fue posible conectar con la base de datos.");
        } else {
            try {
                Integer idUsuarioBd = null;
                String hashBd = null;
                String estadoBd = null;

                try (PreparedStatement ps = conexion.prepareStatement(
                        "SELECT id_usuario, contrasena_hash, estado FROM usuario WHERE correo = ?")) {
                    ps.setString(1, correo);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) {
                            idUsuarioBd = rs.getInt("id_usuario");
                            hashBd = rs.getString("contrasena_hash");
                            estadoBd = rs.getString("estado");
                        }
                    }
                }

                if (idUsuarioBd == null || !verificarClave(contrasena, hashBd)) {
                    errores.add("Correo o contrasena incorrectos.");
                } else if ("bloqueado".equals(estadoBd)) {
                    errores.add("Tu cuenta esta bloqueada temporalmente. Contacta al administrador.");
                } else if ("inactivo".equals(estadoBd)) {
                    errores.add("Tu cuenta esta inactiva. Contacta al administrador.");
                } else {
                    String nombreUsuario = null;
                    try (PreparedStatement ps = conexion.prepareStatement(
                            "SELECT nombres FROM perfil WHERE id_usuario = ?")) {
                        ps.setInt(1, idUsuarioBd);
                        try (ResultSet rs = ps.executeQuery()) {
                            if (rs.next()) nombreUsuario = rs.getString("nombres");
                        }
                    }

                    List<String> roles = new ArrayList<>();
                    try (PreparedStatement ps = conexion.prepareStatement(
                            "SELECT r.nombre_rol FROM usuario_rol ur " +
                            "INNER JOIN rol r ON r.id_rol = ur.id_rol WHERE ur.id_usuario = ?")) {
                        ps.setInt(1, idUsuarioBd);
                        try (ResultSet rs = ps.executeQuery()) {
                            while (rs.next()) roles.add(rs.getString("nombre_rol"));
                        }
                    }

                    session.setAttribute("idUsuario", idUsuarioBd);
                    session.setAttribute("nombreUsuario", nombreUsuario != null ? nombreUsuario : correo);
                    session.setAttribute("roles", roles);

                    String destino = request.getContextPath() + "/cliente/dashboard-cliente.jsp";
                    if (roles.contains("Administrador")) {
                        destino = request.getContextPath() + "/administrador/dashboard-administrador.jsp";
                    } else if (roles.contains("Inmobiliaria")) {
                        destino = request.getContextPath() + "/inmobiliaria/dashboard-inmobiliaria.jsp";
                    }

                    try { conexion.close(); } catch (Exception ignored) { }
                    response.sendRedirect(destino);
                    return;
                }
            } catch (Exception e) {
                errores.add("No fue posible iniciar sesion. Intenta nuevamente.");
            }
        }
    }

    if (conexion != null) {
        try { conexion.close(); } catch (Exception ignored) { }
    }
%><!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Iniciar sesion | Hogaria</title>
    <link rel="icon" href="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 32 32'%3E%3Cpath d='M4 15L16 5L28 15' stroke='%23D9A441' stroke-width='2.6' fill='none' stroke-linecap='round' stroke-linejoin='round'/%3E%3Cpath d='M7 13V26H25V13' stroke='%231F5C4F' stroke-width='2.6' fill='none' stroke-linecap='round' stroke-linejoin='round'/%3E%3C/svg%3E">
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Fraunces:opsz,wght@9..144,500;9..144,600;9..144,700&family=Work+Sans:wght@400;500;600;700&display=swap">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css">
    <link rel="stylesheet" href="<%= request.getContextPath() %>/assets/css/estilos.css">
</head>
<body>
<div class="hg-auth">
    <div class="hg-auth__card">
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

        <h1 class="hg-auth__title">Inicia sesion</h1>
        <p class="hg-auth__subtitle">Ingresa a tu cuenta para gestionar tus tramites con Hogaria.</p>

        <% if (vieneDeRegistro) { %>
        <div class="hg-alert hg-alert--success" style="margin-bottom:18px;">Tu cuenta fue creada con exito. Ahora inicia sesion.</div>
        <% } %>

        <% if (!errores.isEmpty()) { %>
        <div class="hg-alert hg-alert--error" style="margin-bottom:18px;">
            <ul>
                <% for (String err : errores) { %>
                <li><%= err %></li>
                <% } %>
            </ul>
        </div>
        <% } %>

        <form method="post" action="<%= request.getContextPath() %>/login.jsp" novalidate>
            <div class="hg-field">
                <label for="correo">Correo electronico</label>
                <input class="form-control" type="email" id="correo" name="correo" value="<%= correo %>" required>
            </div>
            <div class="hg-field">
                <label for="contrasena">Contrasena</label>
                <input class="form-control" type="password" id="contrasena" name="contrasena" required>
            </div>
            <button class="hg-btn hg-btn--primary hg-btn--block" type="submit">Iniciar sesion</button>
        </form>

        <p class="hg-auth__footer">¿Aun no tienes cuenta? <a href="<%= request.getContextPath() %>/registro.jsp">Registrate gratis</a></p>
    </div>
</div>
</body>
</html>
