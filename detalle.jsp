<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ page import="java.sql.PreparedStatement, java.sql.ResultSet" %>
<%@ page import="java.text.NumberFormat, java.util.Locale" %>
<%@ page import="java.util.ArrayList, java.util.List, java.util.Map, java.util.LinkedHashMap" %>
<%@ include file="/jspf/conexion.jspf" %>
<%
    // =========================================================================
    // Ficha de detalle de una propiedad: galeria, especificaciones,
    // caracteristicas (N:M) y datos de la inmobiliaria. Los datos de
    // contacto completos solo se muestran a usuarios autenticados; un
    // visitante ve el resto de la ficha sin restricciones.
    // =========================================================================
    Integer idPropiedad = null;
    try { idPropiedad = Integer.valueOf(request.getParameter("id")); } catch (Exception ignored) { }

    if (idPropiedad == null) {
        response.sendRedirect(request.getContextPath() + "/catalogo.jsp");
        return;
    }

    @SuppressWarnings("unchecked")
    List<String> rolesSesionDetalle = (List<String>) session.getAttribute("roles");
    boolean esClienteAutenticado = session.getAttribute("idUsuario") != null
            && rolesSesionDetalle != null && rolesSesionDetalle.contains("Cliente");

    // Alternar favorito (patron Post/Redirect/Get para evitar reenvios al recargar)
    if ("POST".equalsIgnoreCase(request.getMethod()) && "toggleFavorito".equals(request.getParameter("accion"))) {
        if (esClienteAutenticado && conexion != null) {
            int idUsuarioSesion = (Integer) session.getAttribute("idUsuario");
            try (PreparedStatement psCheck = conexion.prepareStatement(
                    "SELECT 1 FROM favorito WHERE id_usuario = ? AND id_propiedad = ?")) {
                psCheck.setInt(1, idUsuarioSesion);
                psCheck.setInt(2, idPropiedad);
                boolean yaEsFavorito;
                try (ResultSet rs = psCheck.executeQuery()) { yaEsFavorito = rs.next(); }

                if (yaEsFavorito) {
                    try (PreparedStatement psDel = conexion.prepareStatement(
                            "DELETE FROM favorito WHERE id_usuario = ? AND id_propiedad = ?")) {
                        psDel.setInt(1, idUsuarioSesion);
                        psDel.setInt(2, idPropiedad);
                        psDel.executeUpdate();
                    }
                } else {
                    try (PreparedStatement psIns = conexion.prepareStatement(
                            "INSERT INTO favorito (id_usuario, id_propiedad) VALUES (?, ?)")) {
                        psIns.setInt(1, idUsuarioSesion);
                        psIns.setInt(2, idPropiedad);
                        psIns.executeUpdate();
                    }
                }
            } catch (Exception ignored) { }
        }
        try { if (conexion != null) conexion.close(); } catch (Exception ignored) { }
        response.sendRedirect(request.getContextPath() + "/detalle.jsp?id=" + idPropiedad);
        return;
    }

    Map<String, Object> propiedad = null;
    List<Map<String, Object>> imagenes = new ArrayList<>();
    List<Map<String, Object>> caracteristicas = new ArrayList<>();
    boolean esFavorito = false;

    if (conexion != null) {
        String sqlPropiedad =
            "SELECT p.id_propiedad, p.titulo, p.descripcion, p.direccion, p.precio, p.operacion, p.estado, " +
            "       p.area_m2, p.num_habitaciones, p.num_banos, p.num_parqueaderos, p.matricula_inmobiliaria, " +
            "       c.nombre_ciudad, t.nombre_tipo, i.nombre_comercial, i.telefono, i.direccion AS direccion_inmobiliaria " +
            "FROM propiedad p " +
            "INNER JOIN ciudad c ON c.id_ciudad = p.id_ciudad " +
            "INNER JOIN tipo_propiedad t ON t.id_tipo = p.id_tipo " +
            "INNER JOIN inmobiliaria i ON i.id_inmobiliaria = p.id_inmobiliaria " +
            "WHERE p.id_propiedad = ? AND p.activo = 1";
        try (PreparedStatement ps = conexion.prepareStatement(sqlPropiedad)) {
            ps.setInt(1, idPropiedad);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    propiedad = new LinkedHashMap<>();
                    propiedad.put("titulo", rs.getString("titulo"));
                    propiedad.put("descripcion", rs.getString("descripcion"));
                    propiedad.put("direccion", rs.getString("direccion"));
                    propiedad.put("precio", rs.getBigDecimal("precio"));
                    propiedad.put("operacion", rs.getString("operacion"));
                    propiedad.put("estado", rs.getString("estado"));
                    propiedad.put("area", rs.getBigDecimal("area_m2"));
                    propiedad.put("habitaciones", rs.getObject("num_habitaciones"));
                    propiedad.put("banos", rs.getObject("num_banos"));
                    propiedad.put("parqueaderos", rs.getObject("num_parqueaderos"));
                    propiedad.put("matricula", rs.getString("matricula_inmobiliaria"));
                    propiedad.put("ciudad", rs.getString("nombre_ciudad"));
                    propiedad.put("tipo", rs.getString("nombre_tipo"));
                    propiedad.put("inmobiliaria", rs.getString("nombre_comercial"));
                    propiedad.put("telefonoInmobiliaria", rs.getString("telefono"));
                    propiedad.put("direccionInmobiliaria", rs.getString("direccion_inmobiliaria"));
                }
            }
        } catch (Exception ignored) { }

        if (propiedad != null) {
            try (PreparedStatement ps = conexion.prepareStatement(
                    "SELECT url_imagen FROM imagen_propiedad WHERE id_propiedad = ? ORDER BY es_principal DESC, orden ASC")) {
                ps.setInt(1, idPropiedad);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        Map<String, Object> img = new LinkedHashMap<>();
                        img.put("url", rs.getString("url_imagen"));
                        imagenes.add(img);
                    }
                }
            } catch (Exception ignored) { }

            // Relacion N:M propiedad <-> caracteristica
            try (PreparedStatement ps = conexion.prepareStatement(
                    "SELECT car.nombre_caracteristica, pc.valor FROM propiedad_caracteristica pc " +
                    "INNER JOIN caracteristica car ON car.id_caracteristica = pc.id_caracteristica " +
                    "WHERE pc.id_propiedad = ? ORDER BY car.nombre_caracteristica")) {
                ps.setInt(1, idPropiedad);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        Map<String, Object> car = new LinkedHashMap<>();
                        car.put("nombre", rs.getString("nombre_caracteristica"));
                        car.put("valor", rs.getString("valor"));
                        caracteristicas.add(car);
                    }
                }
            } catch (Exception ignored) { }

            if (esClienteAutenticado) {
                int idUsuarioSesion = (Integer) session.getAttribute("idUsuario");
                try (PreparedStatement ps = conexion.prepareStatement(
                        "SELECT 1 FROM favorito WHERE id_usuario = ? AND id_propiedad = ?")) {
                    ps.setInt(1, idUsuarioSesion);
                    ps.setInt(2, idPropiedad);
                    try (ResultSet rs = ps.executeQuery()) { esFavorito = rs.next(); }
                } catch (Exception ignored) { }
            }
        }

        try { conexion.close(); } catch (Exception ignored) { }
    }

    if (propiedad == null) {
        response.sendRedirect(request.getContextPath() + "/catalogo.jsp");
        return;
    }

    NumberFormat formatoCOP = NumberFormat.getInstance(new Locale("es", "CO"));
    String operacion = (String) propiedad.get("operacion");
    String estado = (String) propiedad.get("estado");
    String precioTxt = "$ " + formatoCOP.format(propiedad.get("precio")) + ("arriendo".equals(operacion) ? " / mes" : "");
    boolean haySesion = session.getAttribute("idUsuario") != null;
%><!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><%= propiedad.get("titulo") %> | Hogaria</title>
    <link rel="icon" href="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 32 32'%3E%3Cpath d='M4 15L16 5L28 15' stroke='%23D9A441' stroke-width='2.6' fill='none' stroke-linecap='round' stroke-linejoin='round'/%3E%3Cpath d='M7 13V26H25V13' stroke='%231F5C4F' stroke-width='2.6' fill='none' stroke-linecap='round' stroke-linejoin='round'/%3E%3C/svg%3E">
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Fraunces:opsz,wght@9..144,500;9..144,600;9..144,700&family=Work+Sans:wght@400;500;600;700&display=swap">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css">
    <link rel="stylesheet" href="<%= request.getContextPath() %>/assets/css/estilos.css">
</head>
<body>
<%@ include file="/jspf/header.jspf" %>

<section class="hg-section" style="padding-top:32px;">
    <div class="hg-container">
        <a class="hg-auth__back" href="<%= request.getContextPath() %>/catalogo.jsp">&larr; Volver al catalogo</a>

        <div class="hg-detalle">
            <div class="hg-detalle__galeria">
                <% if (imagenes.isEmpty()) { %>
                <div class="hg-detalle__sinfoto">Sin fotografias disponibles</div>
                <% } else { %>
                <div id="carruselPropiedad" class="carousel slide hg-carousel" data-bs-ride="false">
                    <div class="carousel-inner">
                        <% for (int i = 0; i < imagenes.size(); i++) { %>
                        <div class="carousel-item <%= i == 0 ? "active" : "" %>">
                            <img src="<%= imagenes.get(i).get("url") %>" alt="<%= propiedad.get("titulo") %> - foto <%= i + 1 %>">
                        </div>
                        <% } %>
                    </div>
                    <% if (imagenes.size() > 1) { %>
                    <button class="carousel-control-prev" type="button" data-bs-target="#carruselPropiedad" data-bs-slide="prev">
                        <span class="carousel-control-prev-icon" aria-hidden="true"></span>
                    </button>
                    <button class="carousel-control-next" type="button" data-bs-target="#carruselPropiedad" data-bs-slide="next">
                        <span class="carousel-control-next-icon" aria-hidden="true"></span>
                    </button>
                    <div class="carousel-indicators">
                        <% for (int i = 0; i < imagenes.size(); i++) { %>
                        <button type="button" data-bs-target="#carruselPropiedad" data-bs-slide-to="<%= i %>" class="<%= i == 0 ? "active" : "" %>"></button>
                        <% } %>
                    </div>
                    <% } %>
                </div>
                <% } %>
            </div>

            <div class="hg-detalle__info">
                <div class="hg-detalle__badges">
                    <span class="hg-badge" style="position:static;"><%= "venta".equals(operacion) ? "Venta" : "Arriendo" %></span>
                    <span class="hg-badge--estado hg-badge--<%= estado %>" style="position:static;"><%= estado.substring(0, 1).toUpperCase() + estado.substring(1) %></span>
                </div>
                <h1 class="hg-detalle__precio"><%= precioTxt %></h1>
                <h2 class="hg-detalle__titulo"><%= propiedad.get("titulo") %></h2>
                <p class="hg-detalle__loc">📍 <%= propiedad.get("direccion") %>, <%= propiedad.get("ciudad") %> &middot; <%= propiedad.get("tipo") %></p>

                <div class="hg-detalle__specs">
                    <% if (propiedad.get("habitaciones") != null) { %><span>🛏 <%= propiedad.get("habitaciones") %> habitaciones</span><% } %>
                    <% if (propiedad.get("banos") != null) { %><span>🛁 <%= propiedad.get("banos") %> banos</span><% } %>
                    <% if (propiedad.get("parqueaderos") != null && ((Number) propiedad.get("parqueaderos")).intValue() > 0) { %><span>🚗 <%= propiedad.get("parqueaderos") %> parqueaderos</span><% } %>
                    <span>📐 <%= propiedad.get("area") %> m²</span>
                </div>

                <div class="hg-detalle__acciones">
                    <% if (esClienteAutenticado) { %>
                    <form method="post" action="<%= request.getContextPath() %>/detalle.jsp?id=<%= idPropiedad %>">
                        <input type="hidden" name="accion" value="toggleFavorito">
                        <button class="hg-btn <%= esFavorito ? "hg-btn--solid" : "hg-btn--ghost" %>" type="submit">
                            <%= esFavorito ? "♥ En tus favoritos" : "♡ Guardar en favoritos" %>
                        </button>
                    </form>
                    <a class="hg-btn hg-btn--primary" href="<%= request.getContextPath() %>/cliente/agendar-cita.jsp?propiedad=<%= idPropiedad %>">Agendar visita</a>
                    <a class="hg-btn hg-btn--ghost" href="<%= request.getContextPath() %>/cliente/radicar-solicitud.jsp?propiedad=<%= idPropiedad %>">Solicitar <%= "venta".equals(operacion) ? "compra" : "arriendo" %></a>
                    <% } else { %>
                    <a class="hg-btn hg-btn--primary" href="<%= request.getContextPath() %>/login.jsp">Inicia sesion para agendar una visita</a>
                    <% } %>
                </div>
            </div>
        </div>

        <div class="hg-detalle__cuerpo">
            <div class="hg-detalle__descripcion">
                <h3>Descripcion</h3>
                <p><%= propiedad.get("descripcion") != null ? propiedad.get("descripcion") : "Sin descripcion disponible." %></p>

                <% if (!caracteristicas.isEmpty()) { %>
                <h3>Caracteristicas</h3>
                <div class="hg-detalle__caracteristicas">
                    <% for (Map<String, Object> car : caracteristicas) { %>
                    <span class="hg-chip">✓ <%= car.get("nombre") %><%= car.get("valor") != null ? " (" + car.get("valor") + ")" : "" %></span>
                    <% } %>
                </div>
                <% } %>
            </div>

            <div class="hg-detalle__contacto">
                <h3>Publicado por</h3>
                <p class="hg-detalle__inmobiliaria"><%= propiedad.get("inmobiliaria") %></p>
                <p style="color:var(--hg-ink-muted); font-size:.86rem;">Matricula inmobiliaria: <%= propiedad.get("matricula") %></p>

                <% if (haySesion) { %>
                <div class="hg-detalle__contacto-datos">
                    <% if (propiedad.get("telefonoInmobiliaria") != null) { %><p>📞 <%= propiedad.get("telefonoInmobiliaria") %></p><% } %>
                    <% if (propiedad.get("direccionInmobiliaria") != null) { %><p>🏢 <%= propiedad.get("direccionInmobiliaria") %></p><% } %>
                </div>
                <% } else { %>
                <div class="hg-alert" style="margin-top:14px;">
                    <a href="<%= request.getContextPath() %>/login.jsp">Inicia sesion</a> para ver los datos de contacto completos.
                </div>
                <% } %>
            </div>
        </div>
    </div>
</section>

<%@ include file="/jspf/footer.jspf" %>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script src="<%= request.getContextPath() %>/assets/js/main.js"></script>
</body>
</html>
