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
    <% String hgTitulo = (String) propiedad.get("titulo"); %>
    <%@ include file="/jspf/head-comun.jspf" %>
</head>
<body>
<%@ include file="/jspf/header.jspf" %>

<section class="hg-section" style="padding-top:32px;">
    <div class="hg-container">
        <a class="hg-auth__back" href="<%= request.getContextPath() %>/catalogo.jsp">&larr; Volver al catálogo</a>

        <div class="hg-detalle">
            <div class="hg-detalle__galeria">
                <% if (imagenes.isEmpty()) { %>
                <div class="hg-detalle__sinfoto">Sin fotografías disponibles</div>
                <% } else { %>
                <div id="carruselPropiedad" class="carousel slide hg-carousel" data-bs-ride="false">
                    <div class="carousel-inner">
                        <% for (int i = 0; i < imagenes.size(); i++) { %>
                        <div class="carousel-item <%= i == 0 ? "active" : "" %>">
                            <img src="<%= imagenes.get(i).get("url") %>" alt="<%= propiedad.get("titulo") %> - foto <%= i + 1 %>" class="js-abrir-lightbox" data-indice="<%= i %>">
                            <span class="hg-carousel__zoom"><i class="bi bi-arrows-fullscreen"></i></span>
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

                <div class="modal fade hg-lightbox" id="modalLightbox" tabindex="-1" aria-hidden="true">
                    <div class="modal-dialog modal-dialog-centered">
                        <div class="modal-content">
                            <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Cerrar"></button>
                            <div id="carruselLightbox" class="carousel slide" data-bs-ride="false">
                                <div class="carousel-inner">
                                    <% for (int i = 0; i < imagenes.size(); i++) { %>
                                    <div class="carousel-item <%= i == 0 ? "active" : "" %>">
                                        <img src="<%= imagenes.get(i).get("url") %>" alt="<%= propiedad.get("titulo") %> - foto <%= i + 1 %>">
                                    </div>
                                    <% } %>
                                </div>
                                <% if (imagenes.size() > 1) { %>
                                <button class="carousel-control-prev" type="button" data-bs-target="#carruselLightbox" data-bs-slide="prev">
                                    <span class="carousel-control-prev-icon" aria-hidden="true"></span>
                                </button>
                                <button class="carousel-control-next" type="button" data-bs-target="#carruselLightbox" data-bs-slide="next">
                                    <span class="carousel-control-next-icon" aria-hidden="true"></span>
                                </button>
                                <div class="carousel-indicators">
                                    <% for (int i = 0; i < imagenes.size(); i++) { %>
                                    <button type="button" data-bs-target="#carruselLightbox" data-bs-slide-to="<%= i %>" class="<%= i == 0 ? "active" : "" %>"></button>
                                    <% } %>
                                </div>
                                <% } %>
                            </div>
                        </div>
                    </div>
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
                <p class="hg-detalle__loc"><i class="bi bi-geo-alt"></i> <%= propiedad.get("direccion") %>, <%= propiedad.get("ciudad") %> &middot; <%= propiedad.get("tipo") %></p>

                <div class="hg-detalle__specs">
                    <% if (propiedad.get("habitaciones") != null) { %><span><i class="bi bi-door-open"></i> <%= propiedad.get("habitaciones") %> habitaciones</span><% } %>
                    <% if (propiedad.get("banos") != null) { %><span><i class="bi bi-droplet"></i> <%= propiedad.get("banos") %> baños</span><% } %>
                    <% if (propiedad.get("parqueaderos") != null && ((Number) propiedad.get("parqueaderos")).intValue() > 0) { %><span><i class="bi bi-car-front"></i> <%= propiedad.get("parqueaderos") %> parqueaderos</span><% } %>
                    <span><i class="bi bi-rulers"></i> <%= propiedad.get("area") %> m²</span>
                </div>

                <div class="hg-detalle__acciones">
                    <% if (esClienteAutenticado) { %>
                    <form method="post" action="<%= request.getContextPath() %>/detalle.jsp?id=<%= idPropiedad %>" id="formFavorito" data-id-propiedad="<%= idPropiedad %>">
                        <input type="hidden" name="accion" value="toggleFavorito">
                        <button class="hg-btn <%= esFavorito ? "hg-btn--solid" : "hg-btn--ghost" %>" type="submit" id="btnFavorito" data-favorito="<%= esFavorito %>">
                            <i class="bi <%= esFavorito ? "bi-heart-fill" : "bi-heart" %>" id="iconoFavorito"></i>
                            <span id="textoFavorito"><%= esFavorito ? "En tus favoritos" : "Guardar en favoritos" %></span>
                        </button>
                    </form>
                    <a class="hg-btn hg-btn--primary" href="<%= request.getContextPath() %>/cliente/agendar-cita.jsp?propiedad=<%= idPropiedad %>"><i class="bi bi-calendar-plus"></i> Agendar visita</a>
                    <a class="hg-btn hg-btn--ghost" href="<%= request.getContextPath() %>/cliente/radicar-solicitud.jsp?propiedad=<%= idPropiedad %>"><i class="bi bi-clipboard-check"></i> Solicitar <%= "venta".equals(operacion) ? "compra" : "arriendo" %></a>
                    <% } else { %>
                    <a class="hg-btn hg-btn--primary" href="<%= request.getContextPath() %>/login.jsp"><i class="bi bi-box-arrow-in-right"></i> Inicia sesión para agendar una visita</a>
                    <% } %>
                </div>
            </div>
        </div>

        <div class="hg-detalle__cuerpo">
            <div class="hg-detalle__descripcion">
                <h3>Descripción</h3>
                <p><%= propiedad.get("descripcion") != null ? propiedad.get("descripcion") : "Sin descripción disponible." %></p>

                <% if (!caracteristicas.isEmpty()) { %>
                <h3>Características</h3>
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
                <p style="color:var(--hg-ink-muted); font-size:.86rem;">Matrícula inmobiliaria: <%= propiedad.get("matricula") %></p>

                <% if (haySesion) { %>
                <div class="hg-detalle__contacto-datos">
                    <% if (propiedad.get("telefonoInmobiliaria") != null) { %><p>📞 <%= propiedad.get("telefonoInmobiliaria") %></p><% } %>
                    <% if (propiedad.get("direccionInmobiliaria") != null) { %><p>🏢 <%= propiedad.get("direccionInmobiliaria") %></p><% } %>
                </div>
                <% } else { %>
                <div class="hg-alert" style="margin-top:14px;">
                    <a href="<%= request.getContextPath() %>/login.jsp">Inicia sesión</a> para ver los datos de contacto completos.
                </div>
                <% } %>
            </div>
        </div>
    </div>
</section>

<%@ include file="/jspf/footer.jspf" %>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script src="<%= request.getContextPath() %>/assets/js/main.js"></script>
<script>
(function () {
    // Favorito: interceptamos el envio del formulario y lo cambiamos por
    // fetch() al endpoint favorito-toggle.jsp, para no recargar la pagina.
    // Si el fetch falla (red caida, sesion vencida, etc.) hacemos submit()
    // normal como respaldo -- el formulario sigue siendo 100% funcional.
    var formFavorito = document.getElementById('formFavorito');
    var botonFavorito = document.getElementById('btnFavorito');
    var iconoFavorito = document.getElementById('iconoFavorito');
    var textoFavorito = document.getElementById('textoFavorito');

    if (formFavorito && botonFavorito) {
        formFavorito.addEventListener('submit', function (evt) {
            evt.preventDefault();
            if (botonFavorito.disabled) return;
            botonFavorito.disabled = true;

            var idPropiedad = formFavorito.getAttribute('data-id-propiedad');
            fetch('<%= request.getContextPath() %>/favorito-toggle.jsp', {
                method: 'POST',
                headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                body: 'idPropiedad=' + encodeURIComponent(idPropiedad)
            })
                .then(function (resp) { if (!resp.ok) throw new Error('fallo'); return resp.json(); })
                .then(function (datos) {
                    var esFavorito = !!datos.favorito;
                    botonFavorito.classList.toggle('hg-btn--solid', esFavorito);
                    botonFavorito.classList.toggle('hg-btn--ghost', !esFavorito);
                    botonFavorito.setAttribute('data-favorito', esFavorito);
                    iconoFavorito.classList.toggle('bi-heart-fill', esFavorito);
                    iconoFavorito.classList.toggle('bi-heart', !esFavorito);
                    textoFavorito.textContent = esFavorito ? 'En tus favoritos' : 'Guardar en favoritos';
                    iconoFavorito.classList.remove('hg-heart-animar');
                    void iconoFavorito.offsetWidth;
                    iconoFavorito.classList.add('hg-heart-animar');
                })
                .catch(function () { formFavorito.submit(); })
                .finally(function () { botonFavorito.disabled = false; });
        });
    }

    // Lightbox: clic en cualquier foto de la galeria abre el modal en esa
    // misma diapositiva, con navegacion entre todas las fotos.
    var modalLightboxEl = document.getElementById('modalLightbox');
    if (modalLightboxEl && window.bootstrap) {
        var modalLightbox = new bootstrap.Modal(modalLightboxEl);
        var carruselLightboxEl = document.getElementById('carruselLightbox');
        var carruselLightbox = carruselLightboxEl ? bootstrap.Carousel.getOrCreateInstance(carruselLightboxEl) : null;

        document.querySelectorAll('.js-abrir-lightbox').forEach(function (img) {
            img.addEventListener('click', function () {
                var indice = parseInt(img.getAttribute('data-indice'), 10) || 0;
                if (carruselLightbox) carruselLightbox.to(indice);
                modalLightbox.show();
            });
        });
    }
})();
</script>
</body>
</html>
