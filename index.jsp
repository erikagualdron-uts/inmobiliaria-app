<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ page import="java.sql.PreparedStatement, java.sql.ResultSet" %>
<%@ page import="java.util.ArrayList, java.util.List, java.util.Map, java.util.LinkedHashMap" %>
<%@ include file="/jspf/conexion.jspf" %>
<%
    // =========================================================================
    // Landing page publica: buscador rapido + propiedades destacadas.
    // Toda la logica de datos vive aqui mismo (scriptlets), sin DAOs ni
    // Servlets, tal como exige el proyecto. La conexion viene ya abierta
    // desde /jspf/conexion.jspf (variables "conexion" y "errorConexion").
    // =========================================================================
    List<Map<String, Object>> ciudades = new ArrayList<>();
    List<Map<String, Object>> tipos = new ArrayList<>();
    List<Map<String, Object>> destacadas = new ArrayList<>();
    int totalPropiedades = 0, totalCiudades = 0, totalInmobiliarias = 0;

    if (conexion != null) {
        try (PreparedStatement ps = conexion.prepareStatement(
                "SELECT id_ciudad, nombre_ciudad FROM ciudad ORDER BY nombre_ciudad");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String, Object> fila = new LinkedHashMap<>();
                fila.put("id", rs.getInt("id_ciudad"));
                fila.put("nombre", rs.getString("nombre_ciudad"));
                ciudades.add(fila);
            }
        } catch (Exception e) {
            errorConexion = "No fue posible cargar el listado de ciudades.";
        }

        try (PreparedStatement ps = conexion.prepareStatement(
                "SELECT id_tipo, nombre_tipo FROM tipo_propiedad ORDER BY nombre_tipo");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String, Object> fila = new LinkedHashMap<>();
                fila.put("id", rs.getInt("id_tipo"));
                fila.put("nombre", rs.getString("nombre_tipo"));
                tipos.add(fila);
            }
        } catch (Exception e) {
            errorConexion = "No fue posible cargar los tipos de propiedad.";
        }

        String sqlDestacadas =
            "SELECT p.id_propiedad, p.titulo, p.precio, p.operacion, p.estado, " +
            "       p.num_habitaciones, p.num_banos, p.area_m2, " +
            "       c.nombre_ciudad, t.nombre_tipo, img.url_imagen " +
            "FROM propiedad p " +
            "INNER JOIN ciudad c ON c.id_ciudad = p.id_ciudad " +
            "INNER JOIN tipo_propiedad t ON t.id_tipo = p.id_tipo " +
            "LEFT JOIN imagen_propiedad img ON img.id_propiedad = p.id_propiedad AND img.es_principal = 1 " +
            "WHERE p.activo = 1 AND p.estado = 'disponible' " +
            "ORDER BY p.fecha_publicacion DESC " +
            "LIMIT 6";
        try (PreparedStatement ps = conexion.prepareStatement(sqlDestacadas);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String, Object> fila = new LinkedHashMap<>();
                fila.put("id", rs.getInt("id_propiedad"));
                fila.put("titulo", rs.getString("titulo"));
                fila.put("precio", rs.getBigDecimal("precio"));
                fila.put("operacion", rs.getString("operacion"));
                fila.put("estado", rs.getString("estado"));
                fila.put("habitaciones", rs.getObject("num_habitaciones"));
                fila.put("banos", rs.getObject("num_banos"));
                fila.put("area", rs.getBigDecimal("area_m2"));
                fila.put("ciudad", rs.getString("nombre_ciudad"));
                fila.put("tipo", rs.getString("nombre_tipo"));
                fila.put("imagen", rs.getString("url_imagen"));
                destacadas.add(fila);
            }
        } catch (Exception e) {
            errorConexion = "No fue posible cargar las propiedades destacadas.";
        }

        try (PreparedStatement ps = conexion.prepareStatement("SELECT COUNT(*) FROM propiedad WHERE activo = 1");
             ResultSet rs = ps.executeQuery()) { if (rs.next()) totalPropiedades = rs.getInt(1); } catch (Exception ignored) { }

        try (PreparedStatement ps = conexion.prepareStatement("SELECT COUNT(*) FROM ciudad");
             ResultSet rs = ps.executeQuery()) { if (rs.next()) totalCiudades = rs.getInt(1); } catch (Exception ignored) { }

        try (PreparedStatement ps = conexion.prepareStatement("SELECT COUNT(*) FROM inmobiliaria");
             ResultSet rs = ps.executeQuery()) { if (rs.next()) totalInmobiliarias = rs.getInt(1); } catch (Exception ignored) { }

        try { conexion.close(); } catch (Exception ignored) { }
    }
%><!DOCTYPE html>
<html lang="es">
<head>
    <% String hgTitulo = "Encuentra tu próximo hogar"; %>
    <%@ include file="/jspf/head-comun.jspf" %>
    <meta name="description" content="Hogaria: compra, venta y arriendo de propiedades en las principales ciudades de Colombia.">
</head>
<body>

<%@ include file="/jspf/header.jspf" %>

<% if (errorConexion != null) { %>
<div class="hg-container" style="padding-top:20px;">
    <div class="hg-alert hg-alert--error"><%= errorConexion %></div>
</div>
<% } %>

<!-- ============================= HERO ============================= -->
<section class="hg-hero" id="inicio">
    <div class="hg-container">
        <div class="hg-hero__inner">
            <div>
                <span class="hg-eyebrow">Inmobiliaria digital</span>
                <h1>Encuentra el lugar donde empieza <em>tu próxima historia</em></h1>
                <p class="hg-hero__lede">Hogaria conecta compradores, arrendatarios e inmobiliarias en un solo lugar: busca por ciudad, tipo y precio, agenda tu visita y haz seguimiento a tu trámite sin salir de la plataforma.</p>

                <div class="hg-hero__stats">
                    <div><strong><%= totalPropiedades %></strong><span>Propiedades activas</span></div>
                    <div><strong><%= totalCiudades %></strong><span>Ciudades cubiertas</span></div>
                    <div><strong><%= totalInmobiliarias %></strong><span>Inmobiliarias aliadas</span></div>
                </div>

                <form class="hg-search" id="hg-search-form" action="<%= request.getContextPath() %>/catalogo.jsp" method="get">
                    <div class="hg-field">
                        <label for="f-ciudad">Ciudad</label>
                        <select class="form-select" id="f-ciudad" name="ciudad">
                            <option value="">Todas</option>
                            <% for (Map<String, Object> c : ciudades) { %>
                            <option value="<%= c.get("id") %>"><%= c.get("nombre") %></option>
                            <% } %>
                        </select>
                    </div>
                    <div class="hg-field">
                        <label for="f-tipo">Tipo</label>
                        <select class="form-select" id="f-tipo" name="tipo">
                            <option value="">Todos</option>
                            <% for (Map<String, Object> t : tipos) { %>
                            <option value="<%= t.get("id") %>"><%= t.get("nombre") %></option>
                            <% } %>
                        </select>
                    </div>
                    <div class="hg-field">
                        <label for="f-operacion">Operación</label>
                        <select class="form-select" id="f-operacion" name="operacion">
                            <option value="">Venta o arriendo</option>
                            <option value="venta">Venta</option>
                            <option value="arriendo">Arriendo</option>
                        </select>
                    </div>
                    <div class="hg-field">
                        <label for="f-precio">Precio máximo</label>
                        <input class="form-control" type="number" id="f-precio" name="precioMax" min="0" step="100000" placeholder="Sin límite">
                    </div>
                    <button class="hg-btn hg-btn--primary" type="submit">Buscar</button>
                    <small class="hg-search__hint text-danger" hidden style="grid-column:1/-1;">Elige al menos un criterio de búsqueda (ciudad, tipo u operación).</small>
                </form>
            </div>

            <div class="hg-hero__media">
                <img src="https://images.unsplash.com/photo-1600210492493-0946911123ea?w=1000&q=80&auto=format&fit=crop" alt="Casa moderna disponible en Hogaria">
                <div class="hg-hero__media-badge">
                    <strong>+<%= totalPropiedades %> inmuebles</strong>
                    listos para visitar
                </div>
            </div>
        </div>
    </div>
</section>

<!-- ========================= DESTACADAS ========================= -->
<section class="hg-section hg-section--muted" id="destacadas">
    <div class="hg-container">
        <div class="hg-section__head">
            <div>
                <span class="hg-eyebrow">Selección Hogaria</span>
                <h2>Propiedades destacadas</h2>
                <p>Los inmuebles más recientes disponibles ahora mismo en nuestra plataforma.</p>
            </div>
            <a class="hg-btn hg-btn--ghost" href="<%= request.getContextPath() %>/catalogo.jsp">Ver todo el catálogo</a>
        </div>

        <% if (destacadas.isEmpty()) { %>
        <div class="hg-alert">Por ahora no hay propiedades disponibles para mostrar. Vuelve pronto.</div>
        <% } else { %>
        <div class="row g-4">
            <% for (Map<String, Object> prop : destacadas) { %>
            <%@ include file="/jspf/tarjeta-propiedad.jspf" %>
            <% } %>
        </div>
        <% } %>
    </div>
</section>

<!-- ============================ NOSOTROS ============================ -->
<section class="hg-section" id="nosotros">
    <div class="hg-container">
        <div class="hg-about">
            <div class="hg-about__media">
                <img src="https://images.unsplash.com/photo-1554224155-6726b3ff858f?w=900&q=80&auto=format&fit=crop" alt="Entrega de llaves de una propiedad Hogaria">
            </div>
            <div>
                <span class="hg-eyebrow">Sobre Hogaria</span>
                <h2>Acompañamos cada paso, desde la búsqueda hasta la firma</h2>
                <p style="color:var(--hg-ink-muted); margin-top:14px;">Somos una plataforma que conecta clientes con inmobiliarias aliadas en toda Colombia. Verificamos cada publicación, hacemos seguimiento a citas y solicitudes, y mantenemos tu información protegida en todo momento.</p>
                <ul>
                    <li>🔒 <span><strong>Cuentas seguras:</strong> contraseñas cifradas y control de acceso por rol.</span></li>
                    <li>🏘️ <span><strong>Catálogo verificado:</strong> matrícula inmobiliaria única por publicación.</span></li>
                    <li>📅 <span><strong>Citas sin cruces:</strong> agenda visitas sin duplicar horarios sobre el mismo inmueble.</span></li>
                </ul>
            </div>
        </div>
    </div>
</section>

<!-- ============================ FEATURES ============================ -->
<section class="hg-section hg-section--muted">
    <div class="hg-container">
        <div class="hg-section__head">
            <div>
                <span class="hg-eyebrow">Por qué Hogaria</span>
                <h2>Todo lo que necesitas en un solo lugar</h2>
            </div>
        </div>
        <div class="row g-4">
            <div class="col-12 col-md-4">
                <div class="hg-feature">
                    <div class="hg-feature__icon">🔍</div>
                    <h3>Búsqueda con filtros</h3>
                    <p>Filtra por ciudad, tipo de inmueble, precio y características para encontrar justo lo que buscas.</p>
                </div>
            </div>
            <div class="col-12 col-md-4">
                <div class="hg-feature">
                    <div class="hg-feature__icon">📋</div>
                    <h3>Trámites en línea</h3>
                    <p>Radica documentos de compra o arriendo y consulta el estado de tu solicitud en tiempo real.</p>
                </div>
            </div>
            <div class="col-12 col-md-4">
                <div class="hg-feature">
                    <div class="hg-feature__icon">🤝</div>
                    <h3>Inmobiliarias aliadas</h3>
                    <p>Agentes verificados que atienden tus citas y aprueban tu documentación sin demoras.</p>
                </div>
            </div>
        </div>
    </div>
</section>

<!-- =============================== CTA =============================== -->
<section class="hg-section">
    <div class="hg-container">
        <div class="hg-cta">
            <div>
                <h2>Crea tu cuenta y guarda tus propiedades favoritas</h2>
                <p>Regístrate gratis para agendar citas, radicar solicitudes y llevar el control de tus trámites con Hogaria.</p>
            </div>
            <a class="hg-btn hg-btn--solid" href="<%= request.getContextPath() %>/registro.jsp">Crear cuenta gratis</a>
        </div>
    </div>
</section>

<%@ include file="/jspf/footer.jspf" %>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script src="<%= request.getContextPath() %>/assets/js/main.js"></script>
</body>
</html>
