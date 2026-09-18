<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ page import="java.sql.PreparedStatement, java.sql.ResultSet" %>
<%@ page import="java.util.ArrayList, java.util.List, java.util.Map, java.util.LinkedHashMap, java.util.HashSet, java.util.Arrays" %>
<%
    String[] rolesPermitidos = { "Inmobiliaria" };
%>
<%@ include file="/jspf/seguridad.jspf" %>
<%@ include file="/jspf/conexion.jspf" %>
<%@ include file="/jspf/subida-archivos.jspf" %>
<%
    // =========================================================================
    // Administracion de la galeria de imagenes de una propiedad. Se puede
    // subir un archivo desde el equipo o pegar una URL externa (Unsplash,
    // Pexels, etc.); en ambos casos queda guardada como URL en la base de
    // datos. Solo el agente de la inmobiliaria duena del inmueble puede
    // administrarla.
    // =========================================================================
    int idUsuarioSesion = (Integer) session.getAttribute("idUsuario");
    Integer idInmobiliaria = null;
    Integer idPropiedad = null;
    String tituloPropiedad = null;
    List<String> errores = new ArrayList<>();

    try { idPropiedad = Integer.valueOf(request.getParameter("id")); } catch (Exception ignored) { }

    if (conexion != null && idUsuarioSesion > 0) {
        try (PreparedStatement ps = conexion.prepareStatement("SELECT id_inmobiliaria FROM usuario WHERE id_usuario = ?")) {
            ps.setInt(1, idUsuarioSesion);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    int idIn = rs.getInt(1);
                    if (!rs.wasNull()) idInmobiliaria = idIn;
                }
            }
        } catch (Exception ignored) { }
    }

    if (idPropiedad == null || idInmobiliaria == null) {
        response.sendRedirect(request.getContextPath() + "/inmobiliaria/mis-propiedades.jsp");
        return;
    }

    if (conexion != null) {
        try (PreparedStatement ps = conexion.prepareStatement(
                "SELECT titulo FROM propiedad WHERE id_propiedad = ? AND id_inmobiliaria = ?")) {
            ps.setInt(1, idPropiedad);
            ps.setInt(2, idInmobiliaria);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) tituloPropiedad = rs.getString("titulo");
            }
        } catch (Exception ignored) { }
    }

    if (tituloPropiedad == null) {
        response.sendRedirect(request.getContextPath() + "/acceso-denegado.jsp");
        return;
    }

    // Acciones (patron Post/Redirect/Get)
    if ("POST".equalsIgnoreCase(request.getMethod()) && conexion != null) {
        String accion = request.getParameter("accion");

        if ("agregar".equals(accion)) {
            String url = request.getParameter("urlImagen") != null ? request.getParameter("urlImagen").trim() : "";
            boolean esPrincipal = "1".equals(request.getParameter("esPrincipal"));

            String urlFinal = null;
            try {
                String urlSubida = hgGuardarArchivoSubido(request, "archivoImagen", "propiedades",
                        new HashSet<>(Arrays.asList("jpg", "jpeg", "png", "webp")), 5L * 1024 * 1024);
                if (urlSubida != null) {
                    urlFinal = urlSubida;
                } else if (!url.isEmpty() && url.matches("^https?://.+")) {
                    urlFinal = url;
                }
            } catch (IllegalArgumentException iae) {
                errores.add(iae.getMessage());
            }

            if (urlFinal == null && errores.isEmpty()) {
                errores.add("Sube una imagen desde tu equipo o ingresa una URL valida (debe iniciar con http:// o https://).");
            }

            if (errores.isEmpty()) {
                try {
                    if (esPrincipal) {
                        try (PreparedStatement ps = conexion.prepareStatement(
                                "UPDATE imagen_propiedad SET es_principal = 0 WHERE id_propiedad = ?")) {
                            ps.setInt(1, idPropiedad);
                            ps.executeUpdate();
                        }
                    }
                    int siguienteOrden = 1;
                    try (PreparedStatement ps = conexion.prepareStatement(
                            "SELECT COALESCE(MAX(orden), 0) + 1 FROM imagen_propiedad WHERE id_propiedad = ?")) {
                        ps.setInt(1, idPropiedad);
                        try (ResultSet rs = ps.executeQuery()) { if (rs.next()) siguienteOrden = rs.getInt(1); }
                    }
                    try (PreparedStatement ps = conexion.prepareStatement(
                            "INSERT INTO imagen_propiedad (id_propiedad, url_imagen, orden, es_principal) VALUES (?, ?, ?, ?)")) {
                        ps.setInt(1, idPropiedad);
                        ps.setString(2, urlFinal);
                        ps.setInt(3, siguienteOrden);
                        ps.setBoolean(4, esPrincipal);
                        ps.executeUpdate();
                    }
                } catch (Exception e) {
                    errores.add("No fue posible agregar la imagen. Intenta nuevamente.");
                }
            }
        } else if ("eliminar".equals(accion)) {
            try {
                int idImagen = Integer.parseInt(request.getParameter("idImagen"));
                try (PreparedStatement ps = conexion.prepareStatement(
                        "DELETE FROM imagen_propiedad WHERE id_imagen = ? AND id_propiedad = ?")) {
                    ps.setInt(1, idImagen);
                    ps.setInt(2, idPropiedad);
                    ps.executeUpdate();
                }
            } catch (Exception ignored) { }
        } else if ("marcarPrincipal".equals(accion)) {
            try {
                int idImagen = Integer.parseInt(request.getParameter("idImagen"));
                try (PreparedStatement ps = conexion.prepareStatement(
                        "UPDATE imagen_propiedad SET es_principal = 0 WHERE id_propiedad = ?")) {
                    ps.setInt(1, idPropiedad);
                    ps.executeUpdate();
                }
                try (PreparedStatement ps = conexion.prepareStatement(
                        "UPDATE imagen_propiedad SET es_principal = 1 WHERE id_imagen = ? AND id_propiedad = ?")) {
                    ps.setInt(1, idImagen);
                    ps.setInt(2, idPropiedad);
                    ps.executeUpdate();
                }
            } catch (Exception ignored) { }
        }

        if (errores.isEmpty()) {
            try { conexion.close(); } catch (Exception ignored) { }
            response.sendRedirect(request.getContextPath() + "/inmobiliaria/propiedad-galeria.jsp?id=" + idPropiedad);
            return;
        }
    }

    List<Map<String, Object>> imagenes = new ArrayList<>();
    if (conexion != null) {
        try (PreparedStatement ps = conexion.prepareStatement(
                "SELECT id_imagen, url_imagen, orden, es_principal FROM imagen_propiedad " +
                "WHERE id_propiedad = ? ORDER BY es_principal DESC, orden ASC")) {
            ps.setInt(1, idPropiedad);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> f = new LinkedHashMap<>();
                    f.put("id", rs.getInt("id_imagen"));
                    f.put("url", rs.getString("url_imagen"));
                    f.put("principal", rs.getBoolean("es_principal"));
                    imagenes.add(f);
                }
            }
        } catch (Exception ignored) { }
        try { conexion.close(); } catch (Exception ignored) { }
    }

    boolean esNueva = "1".equals(request.getParameter("nuevo"));
%><!DOCTYPE html>
<html lang="es">
<head>
    <% String hgTitulo = tituloPropiedad; %>
    <%@ include file="/jspf/head-comun.jspf" %>
</head>
<body>
<%@ include file="/jspf/panel-header.jspf" %>

<div class="hg-panel-body" style="max-width:820px;">
    <div class="hg-panel-hero">
        <span class="hg-eyebrow">Panel de inmobiliaria</span>
        <h1>Galeria: <%= tituloPropiedad %></h1>
        <p><a href="<%= request.getContextPath() %>/inmobiliaria/mis-propiedades.jsp">&larr; Volver a mis propiedades</a></p>
    </div>

    <% if (esNueva) { %>
    <div class="hg-alert hg-alert--success" style="margin-bottom:20px;">Propiedad publicada. Ahora agrega al menos una foto para que se muestre en el catalogo.</div>
    <% } %>

    <% if (!errores.isEmpty()) { %>
    <div class="hg-alert hg-alert--error" style="margin-bottom:20px;">
        <ul><% for (String err : errores) { %><li><%= err %></li><% } %></ul>
    </div>
    <% } %>

    <% if (imagenes.isEmpty()) { %>
    <div class="hg-panel-card" style="margin-bottom:24px;">
        <div class="hg-panel-empty">
            <div class="hg-panel-empty__icon"><i class="bi bi-images"></i></div>
            <p>Esta propiedad todavia no tiene fotos.</p>
        </div>
    </div>
    <% } else { %>
    <div class="hg-galeria-grid">
        <% for (Map<String, Object> img : imagenes) {
            boolean principal = (Boolean) img.get("principal");
        %>
        <div class="hg-galeria-item">
            <% if (principal) { %><span class="hg-galeria-item__principal">Principal</span><% } %>
            <img src="<%= img.get("url") %>" alt="Foto de <%= tituloPropiedad %>">
            <div class="hg-galeria-item__bar">
                <% if (!principal) { %>
                <form method="post" action="<%= request.getContextPath() %>/inmobiliaria/propiedad-galeria.jsp?id=<%= idPropiedad %>">
                    <input type="hidden" name="accion" value="marcarPrincipal">
                    <input type="hidden" name="idImagen" value="<%= img.get("id") %>">
                    <button class="hg-btn hg-btn--ghost hg-btn--sm" type="submit"><i class="bi bi-star-fill"></i> Hacer principal</button>
                </form>
                <% } else { %><span></span><% } %>
                <form method="post" action="<%= request.getContextPath() %>/inmobiliaria/propiedad-galeria.jsp?id=<%= idPropiedad %>">
                    <input type="hidden" name="accion" value="eliminar">
                    <input type="hidden" name="idImagen" value="<%= img.get("id") %>">
                    <button class="hg-btn hg-btn--ghost hg-btn--sm" type="submit" style="color:var(--hg-off);"><i class="bi bi-trash3"></i> Eliminar</button>
                </form>
            </div>
        </div>
        <% } %>
    </div>
    <% } %>

    <div class="hg-panel-card">
        <h3 style="margin-bottom:14px;"><i class="bi bi-image-fill"></i> Agregar imagen</h3>
        <form method="post" action="<%= request.getContextPath() %>/inmobiliaria/propiedad-galeria.jsp?id=<%= idPropiedad %>" enctype="multipart/form-data" style="display:flex; flex-direction:column; gap:14px;">
            <input type="hidden" name="accion" value="agregar">
            <div class="hg-o-alternativa">
                <div class="hg-field">
                    <label for="archivoImagen"><i class="bi bi-upload"></i> Subir desde el equipo (JPG, PNG o WEBP, max. 5MB)</label>
                    <input class="form-control" type="file" id="archivoImagen" name="archivoImagen" accept=".jpg,.jpeg,.png,.webp">
                </div>
                <span class="hg-o-alternativa__o">o</span>
                <div class="hg-field">
                    <label for="urlImagen"><i class="bi bi-link-45deg"></i> URL de la imagen (Unsplash, Pexels, etc.)</label>
                    <input class="form-control" type="url" id="urlImagen" name="urlImagen" placeholder="https://images.unsplash.com/...">
                </div>
            </div>
            <label class="hg-checkbox" style="align-self:flex-start;">
                <input type="checkbox" name="esPrincipal" value="1" <%= imagenes.isEmpty() ? "checked" : "" %>>
                Usar como foto principal
            </label>
            <button class="hg-btn hg-btn--primary" type="submit" style="align-self:flex-start;"><i class="bi bi-plus-lg"></i> Agregar imagen</button>
        </form>
    </div>
</div>
</body>
</html>
