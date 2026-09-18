<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ page import="java.sql.PreparedStatement, java.sql.ResultSet" %>
<%@ page import="java.text.NumberFormat, java.util.Locale" %>
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

    NumberFormat formatoCOP = NumberFormat.getInstance(new Locale("es", "CO"));
%><!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Hogaria | Encuentra tu proximo hogar</title>
    <meta name="description" content="Hogaria: compra, venta y arriendo de propiedades en las principales ciudades de Colombia.">
    <link rel="icon" href="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 32 32'%3E%3Cpath d='M4 15L16 5L28 15' stroke='%23D9A441' stroke-width='2.6' fill='none' stroke-linecap='round' stroke-linejoin='round'/%3E%3Cpath d='M7 13V26H25V13' stroke='%231F5C4F' stroke-width='2.6' fill='none' stroke-linecap='round' stroke-linejoin='round'/%3E%3C/svg%3E">

    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Fraunces:opsz,wght@9..144,500;9..144,600;9..144,700&family=Work+Sans:wght@400;500;600;700&display=swap">

    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css">
    <link rel="stylesheet" href="<%= request.getContextPath() %>/assets/css/estilos.css">
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
                <h1>Encuentra el lugar donde empieza <em>tu proxima historia</em></h1>
                <p class="hg-hero__lede">Hogaria conecta compradores, arrendatarios e inmobiliarias en un solo lugar: busca por ciudad, tipo y precio, agenda tu visita y haz seguimiento a tu tramite sin salir de la plataforma.</p>

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
                        <label for="f-operacion">Operacion</label>
                        <select class="form-select" id="f-operacion" name="operacion">
                            <option value="">Venta o arriendo</option>
                            <option value="venta">Venta</option>
                            <option value="arriendo">Arriendo</option>
                        </select>
                    </div>
                    <div class="hg-field">
                        <label for="f-precio">Precio maximo</label>
                        <input class="form-control" type="number" id="f-precio" name="precioMax" min="0" step="100000" placeholder="Sin limite">
                    </div>
                    <button class="hg-btn hg-btn--primary" type="submit">Buscar</button>
                    <small class="hg-search__hint text-danger" hidden style="grid-column:1/-1;">Elige al menos un criterio de busqueda (ciudad, tipo u operacion).</small>
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
                <span class="hg-eyebrow">Seleccion Hogaria</span>
                <h2>Propiedades destacadas</h2>
                <p>Los inmuebles mas recientes disponibles ahora mismo en nuestra plataforma.</p>
            </div>
            <a class="hg-btn hg-btn--ghost" href="<%= request.getContextPath() %>/catalogo.jsp">Ver todo el catalogo</a>
        </div>

        <% if (destacadas.isEmpty()) { %>
        <div class="hg-alert">Por ahora no hay propiedades disponibles para mostrar. Vuelve pronto.</div>
        <% } else { %>
        <div class="row g-4">
            <% for (Map<String, Object> prop : destacadas) {
                String estado = (String) prop.get("estado");
                String operacion = (String) prop.get("operacion");
                Object img = prop.get("imagen");
                String imgUrl = img != null ? img.toString() : "https://images.unsplash.com/photo-1568605114967-8130f3a36994?w=800&q=75&auto=format&fit=crop";
                String precioTxt = "$ " + formatoCOP.format(prop.get("precio")) + ("arriendo".equals(operacion) ? " / mes" : "");
                Object hab = prop.get("habitaciones");
                Object banos = prop.get("banos");
            %>
            <div class="col-12 col-md-6 col-lg-4">
                <a class="hg-card" href="<%= request.getContextPath() %>/detalle.jsp?id=<%= prop.get("id") %>" style="text-decoration:none;">
                    <div class="hg-card__media">
                        <img src="<%= imgUrl %>" alt="<%= prop.get("titulo") %>" loading="lazy">
                        <span class="hg-badge"><%= "venta".equals(operacion) ? "Venta" : "Arriendo" %></span>
                        <span class="hg-badge--estado hg-badge--<%= estado %>"><%= estado.substring(0,1).toUpperCase() + estado.substring(1) %></span>
                    </div>
                    <div class="hg-card__body">
                        <span class="hg-card__price"><%= precioTxt %></span>
                        <span class="hg-card__title"><%= prop.get("titulo") %></span>
                        <span class="hg-card__loc">📍 <%= prop.get("ciudad") %> &middot; <%= prop.get("tipo") %></span>
                        <div class="hg-card__feats">
                            <% if (hab != null) { %><span>🛏 <%= hab %></span><% } %>
                            <% if (banos != null) { %><span>🛁 <%= banos %></span><% } %>
                            <span>📐 <%= prop.get("area") %> m²</span>
                        </div>
                    </div>
                </a>
            </div>
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
                <h2>Acompanamos cada paso, desde la busqueda hasta la firma</h2>
                <p style="color:var(--hg-ink-muted); margin-top:14px;">Somos una plataforma que conecta clientes con inmobiliarias aliadas en toda Colombia. Verificamos cada publicacion, hacemos seguimiento a citas y solicitudes, y mantenemos tu informacion protegida en todo momento.</p>
                <ul>
                    <li>🔒 <span><strong>Cuentas seguras:</strong> contrasenas cifradas y control de acceso por rol.</span></li>
                    <li>🏘️ <span><strong>Catalogo verificado:</strong> matricula inmobiliaria unica por publicacion.</span></li>
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
                <span class="hg-eyebrow">Por que Hogaria</span>
                <h2>Todo lo que necesitas en un solo lugar</h2>
            </div>
        </div>
        <div class="row g-4">
            <div class="col-12 col-md-4">
                <div class="hg-feature">
                    <div class="hg-feature__icon">🔍</div>
                    <h3>Busqueda con filtros</h3>
                    <p>Filtra por ciudad, tipo de inmueble, precio y caracteristicas para encontrar justo lo que buscas.</p>
                </div>
            </div>
            <div class="col-12 col-md-4">
                <div class="hg-feature">
                    <div class="hg-feature__icon">📋</div>
                    <h3>Tramites en linea</h3>
                    <p>Radica documentos de compra o arriendo y consulta el estado de tu solicitud en tiempo real.</p>
                </div>
            </div>
            <div class="col-12 col-md-4">
                <div class="hg-feature">
                    <div class="hg-feature__icon">🤝</div>
                    <h3>Inmobiliarias aliadas</h3>
                    <p>Agentes verificados que atienden tus citas y aprueban tu documentacion sin demoras.</p>
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
                <p>Regístrate gratis para agendar citas, radicar solicitudes y llevar el control de tus tramites con Hogaria.</p>
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
