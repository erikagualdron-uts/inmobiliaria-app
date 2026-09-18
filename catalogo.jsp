<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ page import="java.sql.PreparedStatement, java.sql.ResultSet" %>
<%@ page import="java.math.BigDecimal" %>
<%@ page import="java.util.ArrayList, java.util.List, java.util.Map, java.util.LinkedHashMap" %>
<%@ include file="/jspf/conexion.jspf" %>
<%
    // =========================================================================
    // Catalogo publico con filtros. Los mismos parametros que envia el
    // buscador de la landing (ciudad, tipo, operacion, precioMax) se leen
    // aqui, mas los filtros propios de esta pagina (precio minimo,
    // habitaciones minimas y orden).
    // =========================================================================
    List<Map<String, Object>> ciudades = new ArrayList<>();
    List<Map<String, Object>> tipos = new ArrayList<>();
    List<Map<String, Object>> resultados = new ArrayList<>();

    String fCiudad = request.getParameter("ciudad") != null ? request.getParameter("ciudad").trim() : "";
    String fTipo = request.getParameter("tipo") != null ? request.getParameter("tipo").trim() : "";
    String fOperacion = request.getParameter("operacion") != null ? request.getParameter("operacion").trim() : "";
    String fPrecioMin = request.getParameter("precioMin") != null ? request.getParameter("precioMin").trim() : "";
    String fPrecioMax = request.getParameter("precioMax") != null ? request.getParameter("precioMax").trim() : "";
    String fHabitaciones = request.getParameter("habitaciones") != null ? request.getParameter("habitaciones").trim() : "";
    String fOrden = request.getParameter("orden") != null ? request.getParameter("orden").trim() : "recientes";

    if (!"venta".equals(fOperacion) && !"arriendo".equals(fOperacion)) fOperacion = "";
    if (!"precio_asc".equals(fOrden) && !"precio_desc".equals(fOrden)) fOrden = "recientes";

    Integer idCiudadFiltro = null, idTipoFiltro = null, habitacionesFiltro = null;
    BigDecimal precioMinFiltro = null, precioMaxFiltro = null;
    try { if (!fCiudad.isEmpty()) idCiudadFiltro = Integer.valueOf(fCiudad); } catch (NumberFormatException ignored) { }
    try { if (!fTipo.isEmpty()) idTipoFiltro = Integer.valueOf(fTipo); } catch (NumberFormatException ignored) { }
    try { if (!fHabitaciones.isEmpty()) habitacionesFiltro = Integer.valueOf(fHabitaciones); } catch (NumberFormatException ignored) { }
    try { if (!fPrecioMin.isEmpty()) precioMinFiltro = new BigDecimal(fPrecioMin); } catch (NumberFormatException ignored) { }
    try { if (!fPrecioMax.isEmpty()) precioMaxFiltro = new BigDecimal(fPrecioMax); } catch (NumberFormatException ignored) { }

    if (conexion != null) {
        try (PreparedStatement ps = conexion.prepareStatement("SELECT id_ciudad, nombre_ciudad FROM ciudad ORDER BY nombre_ciudad");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String, Object> f = new LinkedHashMap<>();
                f.put("id", rs.getInt("id_ciudad"));
                f.put("nombre", rs.getString("nombre_ciudad"));
                ciudades.add(f);
            }
        } catch (Exception ignored) { }

        try (PreparedStatement ps = conexion.prepareStatement("SELECT id_tipo, nombre_tipo FROM tipo_propiedad ORDER BY nombre_tipo");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String, Object> f = new LinkedHashMap<>();
                f.put("id", rs.getInt("id_tipo"));
                f.put("nombre", rs.getString("nombre_tipo"));
                tipos.add(f);
            }
        } catch (Exception ignored) { }

        StringBuilder sql = new StringBuilder(
            "SELECT p.id_propiedad, p.titulo, p.precio, p.operacion, p.estado, " +
            "       p.num_habitaciones, p.num_banos, p.area_m2, " +
            "       c.nombre_ciudad, t.nombre_tipo, img.url_imagen " +
            "FROM propiedad p " +
            "INNER JOIN ciudad c ON c.id_ciudad = p.id_ciudad " +
            "INNER JOIN tipo_propiedad t ON t.id_tipo = p.id_tipo " +
            "LEFT JOIN imagen_propiedad img ON img.id_propiedad = p.id_propiedad AND img.es_principal = 1 " +
            "WHERE p.activo = 1 AND p.estado = 'disponible' ");
        List<Object> parametros = new ArrayList<>();

        if (idCiudadFiltro != null) { sql.append("AND p.id_ciudad = ? "); parametros.add(idCiudadFiltro); }
        if (idTipoFiltro != null) { sql.append("AND p.id_tipo = ? "); parametros.add(idTipoFiltro); }
        if (!fOperacion.isEmpty()) { sql.append("AND p.operacion = ? "); parametros.add(fOperacion); }
        if (precioMinFiltro != null) { sql.append("AND p.precio >= ? "); parametros.add(precioMinFiltro); }
        if (precioMaxFiltro != null) { sql.append("AND p.precio <= ? "); parametros.add(precioMaxFiltro); }
        if (habitacionesFiltro != null) { sql.append("AND p.num_habitaciones >= ? "); parametros.add(habitacionesFiltro); }

        if ("precio_asc".equals(fOrden)) sql.append("ORDER BY p.precio ASC");
        else if ("precio_desc".equals(fOrden)) sql.append("ORDER BY p.precio DESC");
        else sql.append("ORDER BY p.fecha_publicacion DESC");

        try (PreparedStatement ps = conexion.prepareStatement(sql.toString())) {
            for (int i = 0; i < parametros.size(); i++) {
                ps.setObject(i + 1, parametros.get(i));
            }
            try (ResultSet rs = ps.executeQuery()) {
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
                    resultados.add(fila);
                }
            }
        } catch (Exception ignored) { }

        try { conexion.close(); } catch (Exception ignored) { }
    }
%><!DOCTYPE html>
<html lang="es">
<head>
    <% String hgTitulo = "Catalogo de propiedades"; %>
    <%@ include file="/jspf/head-comun.jspf" %>
</head>
<body>
<%@ include file="/jspf/header.jspf" %>

<section class="hg-section" style="padding-top:40px;">
    <div class="hg-container">
        <div class="hg-section__head">
            <div>
                <span class="hg-eyebrow">Catalogo</span>
                <h2>Encuentra tu proxima propiedad</h2>
                <p><%= resultados.size() %> propiedad<%= resultados.size() == 1 ? "" : "es" %> disponible<%= resultados.size() == 1 ? "" : "s" %> con los filtros seleccionados.</p>
            </div>
        </div>

        <form class="hg-search hg-search--catalogo" method="get" action="<%= request.getContextPath() %>/catalogo.jsp">
            <div class="hg-field">
                <label for="f-ciudad">Ciudad</label>
                <select class="form-select" id="f-ciudad" name="ciudad">
                    <option value="">Todas</option>
                    <% for (Map<String, Object> c : ciudades) { %>
                    <option value="<%= c.get("id") %>" <%= String.valueOf(c.get("id")).equals(fCiudad) ? "selected" : "" %>><%= c.get("nombre") %></option>
                    <% } %>
                </select>
            </div>
            <div class="hg-field">
                <label for="f-tipo">Tipo</label>
                <select class="form-select" id="f-tipo" name="tipo">
                    <option value="">Todos</option>
                    <% for (Map<String, Object> t : tipos) { %>
                    <option value="<%= t.get("id") %>" <%= String.valueOf(t.get("id")).equals(fTipo) ? "selected" : "" %>><%= t.get("nombre") %></option>
                    <% } %>
                </select>
            </div>
            <div class="hg-field">
                <label for="f-operacion">Operacion</label>
                <select class="form-select" id="f-operacion" name="operacion">
                    <option value="">Venta o arriendo</option>
                    <option value="venta" <%= "venta".equals(fOperacion) ? "selected" : "" %>>Venta</option>
                    <option value="arriendo" <%= "arriendo".equals(fOperacion) ? "selected" : "" %>>Arriendo</option>
                </select>
            </div>
            <div class="hg-field">
                <label for="f-precioMin">Precio minimo</label>
                <input class="form-control" type="number" id="f-precioMin" name="precioMin" min="0" step="100000" value="<%= fPrecioMin %>">
            </div>
            <div class="hg-field">
                <label for="f-precioMax">Precio maximo</label>
                <input class="form-control" type="number" id="f-precioMax" name="precioMax" min="0" step="100000" value="<%= fPrecioMax %>">
            </div>
            <div class="hg-field">
                <label for="f-habitaciones">Habitaciones minimas</label>
                <input class="form-control" type="number" id="f-habitaciones" name="habitaciones" min="0" step="1" value="<%= fHabitaciones %>">
            </div>
            <div class="hg-field">
                <label for="f-orden">Ordenar por</label>
                <select class="form-select" id="f-orden" name="orden">
                    <option value="recientes" <%= "recientes".equals(fOrden) ? "selected" : "" %>>Mas recientes</option>
                    <option value="precio_asc" <%= "precio_asc".equals(fOrden) ? "selected" : "" %>>Precio: menor a mayor</option>
                    <option value="precio_desc" <%= "precio_desc".equals(fOrden) ? "selected" : "" %>>Precio: mayor a menor</option>
                </select>
            </div>
            <button class="hg-btn hg-btn--primary" type="submit">Filtrar</button>
            <a class="hg-btn hg-btn--ghost" href="<%= request.getContextPath() %>/catalogo.jsp" style="text-align:center;">Limpiar</a>
        </form>

        <% if (resultados.isEmpty()) { %>
        <div class="hg-panel-empty">
            <div class="hg-panel-empty__icon">🔍</div>
            <p>No encontramos propiedades con esos filtros. Intenta ampliar tu busqueda.</p>
        </div>
        <% } else { %>
        <div class="row g-4">
            <% for (Map<String, Object> prop : resultados) { %>
            <%@ include file="/jspf/tarjeta-propiedad.jspf" %>
            <% } %>
        </div>
        <% } %>
    </div>
</section>

<%@ include file="/jspf/footer.jspf" %>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script src="<%= request.getContextPath() %>/assets/js/main.js"></script>
</body>
</html>
