<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ page import="java.sql.PreparedStatement, java.sql.ResultSet, java.sql.SQLException, java.sql.Statement, java.sql.Types" %>
<%@ page import="java.math.BigDecimal" %>
<%@ page import="java.util.ArrayList, java.util.List, java.util.Map, java.util.LinkedHashMap, java.util.HashSet, java.util.Set, java.util.Arrays" %>
<%
    String[] rolesPermitidos = { "Inmobiliaria" };
%>
<%@ include file="/jspf/seguridad.jspf" %>
<%@ include file="/jspf/conexion.jspf" %>
<%@ include file="/jspf/subida-archivos.jspf" %>
<%@ include file="/jspf/auditoria.jspf" %>
<%
    // =========================================================================
    // Alta y edicion de propiedades. Sin "id" en la query string se crea una
    // propiedad nueva; con "id" se edita, siempre que pertenezca a la
    // inmobiliaria del agente en sesion.
    // =========================================================================
    int idUsuarioSesion = (Integer) session.getAttribute("idUsuario");
    Integer idInmobiliaria = null;

    if (conexion != null) {
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

    if (idInmobiliaria == null) {
        response.sendRedirect(request.getContextPath() + "/inmobiliaria/mis-propiedades.jsp");
        return;
    }

    Integer idPropiedadEdicion = null;
    try {
        String idParam = request.getParameter("id");
        if (idParam != null && !idParam.trim().isEmpty()) idPropiedadEdicion = Integer.valueOf(idParam.trim());
    } catch (NumberFormatException ignored) { }
    boolean esEdicion = idPropiedadEdicion != null;

    // Si es edicion, confirmar que la propiedad pertenece a esta inmobiliaria
    if (esEdicion && conexion != null) {
        boolean pertenece = false;
        try (PreparedStatement ps = conexion.prepareStatement(
                "SELECT 1 FROM propiedad WHERE id_propiedad = ? AND id_inmobiliaria = ?")) {
            ps.setInt(1, idPropiedadEdicion);
            ps.setInt(2, idInmobiliaria);
            try (ResultSet rs = ps.executeQuery()) { pertenece = rs.next(); }
        } catch (Exception ignored) { }
        if (!pertenece) {
            response.sendRedirect(request.getContextPath() + "/acceso-denegado.jsp");
            return;
        }
    }

    List<Map<String, Object>> ciudades = new ArrayList<>();
    List<Map<String, Object>> tipos = new ArrayList<>();
    List<Map<String, Object>> caracteristicasCatalogo = new ArrayList<>();

    List<String> errores = new ArrayList<>();
    boolean guardadoExitoso = false;

    // Valores del formulario (para repoblar si hay errores, o precargar en edicion)
    String matricula = "", titulo = "", descripcion = "", direccion = "", idCiudad = "", idTipo = "",
           precio = "", area = "", habitaciones = "", banos = "", parqueaderos = "", operacion = "venta", estado = "disponible";
    Set<String> caracteristicasSeleccionadas = new HashSet<>();

    if (conexion != null) {
        try (PreparedStatement ps = conexion.prepareStatement("SELECT id_ciudad, nombre_ciudad FROM ciudad ORDER BY nombre_ciudad");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String, Object> f = new LinkedHashMap<>();
                f.put("id", rs.getInt("id_ciudad")); f.put("nombre", rs.getString("nombre_ciudad"));
                ciudades.add(f);
            }
        } catch (Exception ignored) { }

        try (PreparedStatement ps = conexion.prepareStatement("SELECT id_tipo, nombre_tipo FROM tipo_propiedad ORDER BY nombre_tipo");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String, Object> f = new LinkedHashMap<>();
                f.put("id", rs.getInt("id_tipo")); f.put("nombre", rs.getString("nombre_tipo"));
                tipos.add(f);
            }
        } catch (Exception ignored) { }

        try (PreparedStatement ps = conexion.prepareStatement("SELECT id_caracteristica, nombre_caracteristica FROM caracteristica ORDER BY nombre_caracteristica");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String, Object> f = new LinkedHashMap<>();
                f.put("id", rs.getInt("id_caracteristica")); f.put("nombre", rs.getString("nombre_caracteristica"));
                caracteristicasCatalogo.add(f);
            }
        } catch (Exception ignored) { }

        if (esEdicion && !"POST".equalsIgnoreCase(request.getMethod())) {
            try (PreparedStatement ps = conexion.prepareStatement(
                    "SELECT matricula_inmobiliaria, titulo, descripcion, direccion, id_ciudad, id_tipo, precio, area_m2, " +
                    "       num_habitaciones, num_banos, num_parqueaderos, operacion, estado " +
                    "FROM propiedad WHERE id_propiedad = ?")) {
                ps.setInt(1, idPropiedadEdicion);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        matricula = rs.getString("matricula_inmobiliaria");
                        titulo = rs.getString("titulo");
                        descripcion = rs.getString("descripcion") != null ? rs.getString("descripcion") : "";
                        direccion = rs.getString("direccion");
                        idCiudad = String.valueOf(rs.getInt("id_ciudad"));
                        idTipo = String.valueOf(rs.getInt("id_tipo"));
                        precio = rs.getBigDecimal("precio").toPlainString();
                        area = rs.getBigDecimal("area_m2").toPlainString();
                        Object hab = rs.getObject("num_habitaciones"); habitaciones = hab != null ? hab.toString() : "";
                        Object bn = rs.getObject("num_banos"); banos = bn != null ? bn.toString() : "";
                        Object pq = rs.getObject("num_parqueaderos"); parqueaderos = pq != null ? pq.toString() : "0";
                        operacion = rs.getString("operacion");
                        estado = rs.getString("estado");
                    }
                }
            } catch (Exception ignored) { }

            try (PreparedStatement ps = conexion.prepareStatement(
                    "SELECT id_caracteristica FROM propiedad_caracteristica WHERE id_propiedad = ?")) {
                ps.setInt(1, idPropiedadEdicion);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) caracteristicasSeleccionadas.add(String.valueOf(rs.getInt(1)));
                }
            } catch (Exception ignored) { }
        }

        if ("POST".equalsIgnoreCase(request.getMethod())) {
            matricula = valorSeguro(request.getParameter("matricula"));
            titulo = valorSeguro(request.getParameter("titulo"));
            descripcion = valorSeguro(request.getParameter("descripcion"));
            direccion = valorSeguro(request.getParameter("direccion"));
            idCiudad = valorSeguro(request.getParameter("idCiudad"));
            idTipo = valorSeguro(request.getParameter("idTipo"));
            precio = valorSeguro(request.getParameter("precio"));
            area = valorSeguro(request.getParameter("area"));
            habitaciones = valorSeguro(request.getParameter("habitaciones"));
            banos = valorSeguro(request.getParameter("banos"));
            parqueaderos = valorSeguro(request.getParameter("parqueaderos"));
            operacion = valorSeguro(request.getParameter("operacion"));
            estado = esEdicion ? valorSeguro(request.getParameter("estado")) : "disponible";
            String[] caracteristicasParam = request.getParameterValues("caracteristicas");
            caracteristicasSeleccionadas = new HashSet<>();
            if (caracteristicasParam != null) {
                for (String c : caracteristicasParam) caracteristicasSeleccionadas.add(c);
            }

            BigDecimal precioNum = null, areaNum = null;
            Integer habNum = null, banosNum = null, parqNum = null;

            if (matricula.isEmpty() || !matricula.matches("^[A-Za-z0-9-]{4,30}$")) {
                errores.add("La matrícula inmobiliaria debe tener entre 4 y 30 caracteres (letras, números y guiones).");
            }
            if (titulo.isEmpty() || titulo.length() < 5 || titulo.length() > 120) {
                errores.add("El título debe tener entre 5 y 120 caracteres.");
            }
            if (direccion.isEmpty() || direccion.length() > 150) {
                errores.add("Ingresa una dirección válida (máximo 150 caracteres).");
            }
            if (idCiudad.isEmpty()) errores.add("Selecciona una ciudad.");
            if (idTipo.isEmpty()) errores.add("Selecciona un tipo de propiedad.");
            if (!operacion.equals("venta") && !operacion.equals("arriendo")) errores.add("Selecciona una operación válida.");
            if (!estado.matches("^(disponible|reservado|vendido|arrendado)$")) errores.add("Selecciona un estado válido.");

            try { precioNum = new BigDecimal(precio); if (precioNum.signum() <= 0) throw new NumberFormatException(); }
            catch (Exception e) { errores.add("Ingresa un precio válido, mayor a cero."); }

            try { areaNum = new BigDecimal(area); if (areaNum.signum() <= 0) throw new NumberFormatException(); }
            catch (Exception e) { errores.add("Ingresa un área válida, mayor a cero."); }

            if (!habitaciones.isEmpty()) {
                try { habNum = Integer.valueOf(habitaciones); if (habNum < 0) throw new NumberFormatException(); }
                catch (Exception e) { errores.add("El número de habitaciones no es válido."); }
            }
            if (!banos.isEmpty()) {
                try { banosNum = Integer.valueOf(banos); if (banosNum < 0) throw new NumberFormatException(); }
                catch (Exception e) { errores.add("El número de baños no es válido."); }
            }
            try { parqNum = parqueaderos.isEmpty() ? 0 : Integer.valueOf(parqueaderos); if (parqNum < 0) throw new NumberFormatException(); }
            catch (Exception e) { errores.add("El número de parqueaderos no es válido."); }

            // Galeria de imagenes (solo aplica al publicar una propiedad nueva;
            // en edicion las fotos se administran aparte en propiedad-galeria.jsp).
            // El formulario combina archivos subidos y URL pegadas en un solo
            // orden; "ordenTipos" (ej. "file,url,file") le dice al servidor en
            // que secuencia intercalar los archivos guardados y las URL.
            List<String> urlsImagenesFinal = new ArrayList<>();
            int indicePrincipalFinal = -1;

            if (errores.isEmpty() && !esEdicion) {
                String ordenTiposParam = request.getParameter("ordenTipos");
                if (ordenTiposParam != null && !ordenTiposParam.trim().isEmpty()) {
                    String[] urlImagenesParam = request.getParameterValues("urlImagenes");
                    List<String> archivosGuardados = null;
                    try {
                        archivosGuardados = hgGuardarArchivosMultiples(request, "imagenes", "propiedades",
                                new HashSet<>(Arrays.asList("jpg", "jpeg", "png", "webp")), 5L * 1024 * 1024);
                    } catch (IllegalArgumentException iae) {
                        errores.add(iae.getMessage());
                    }

                    int idxArchivo = 0, idxUrl = 0;
                    for (String tipo : ordenTiposParam.split(",")) {
                        if ("file".equals(tipo)) {
                            if (archivosGuardados != null && idxArchivo < archivosGuardados.size()) {
                                urlsImagenesFinal.add(archivosGuardados.get(idxArchivo));
                            }
                            idxArchivo++;
                        } else if ("url".equals(tipo)) {
                            String urlImg = (urlImagenesParam != null && idxUrl < urlImagenesParam.length)
                                    ? urlImagenesParam[idxUrl].trim() : "";
                            idxUrl++;
                            if (urlImg.matches("^https?://.+")) {
                                urlsImagenesFinal.add(urlImg);
                            } else {
                                errores.add("Una de las URL de imagen ingresadas no es válida.");
                            }
                        }
                    }

                    try {
                        indicePrincipalFinal = Integer.parseInt(request.getParameter("indicePrincipal"));
                    } catch (Exception ignored) { indicePrincipalFinal = -1; }
                    if (indicePrincipalFinal < 0 || indicePrincipalFinal >= urlsImagenesFinal.size()) {
                        indicePrincipalFinal = urlsImagenesFinal.isEmpty() ? -1 : 0;
                    }
                }
            }

            if (errores.isEmpty()) {
                try {
                    conexion.setAutoCommit(false);
                    int idCiudadNum = Integer.parseInt(idCiudad);
                    int idTipoNum = Integer.parseInt(idTipo);
                    int idPropiedadFinal;

                    if (esEdicion) {
                        try (PreparedStatement ps = conexion.prepareStatement(
                                "UPDATE propiedad SET matricula_inmobiliaria=?, titulo=?, descripcion=?, direccion=?, " +
                                "id_ciudad=?, id_tipo=?, precio=?, area_m2=?, num_habitaciones=?, num_banos=?, " +
                                "num_parqueaderos=?, operacion=?, estado=? WHERE id_propiedad=? AND id_inmobiliaria=?")) {
                            ps.setString(1, matricula);
                            ps.setString(2, titulo);
                            if (descripcion.isEmpty()) ps.setNull(3, Types.LONGVARCHAR); else ps.setString(3, descripcion);
                            ps.setString(4, direccion);
                            ps.setInt(5, idCiudadNum);
                            ps.setInt(6, idTipoNum);
                            ps.setBigDecimal(7, precioNum);
                            ps.setBigDecimal(8, areaNum);
                            if (habNum == null) ps.setNull(9, Types.TINYINT); else ps.setInt(9, habNum);
                            if (banosNum == null) ps.setNull(10, Types.TINYINT); else ps.setInt(10, banosNum);
                            ps.setInt(11, parqNum);
                            ps.setString(12, operacion);
                            ps.setString(13, estado);
                            ps.setInt(14, idPropiedadEdicion);
                            ps.setInt(15, idInmobiliaria);
                            ps.executeUpdate();
                        }
                        idPropiedadFinal = idPropiedadEdicion;

                        try (PreparedStatement ps = conexion.prepareStatement(
                                "DELETE FROM propiedad_caracteristica WHERE id_propiedad = ?")) {
                            ps.setInt(1, idPropiedadFinal);
                            ps.executeUpdate();
                        }
                    } else {
                        try (PreparedStatement ps = conexion.prepareStatement(
                                "INSERT INTO propiedad (id_inmobiliaria, id_ciudad, id_tipo, matricula_inmobiliaria, titulo, " +
                                "descripcion, direccion, precio, area_m2, num_habitaciones, num_banos, num_parqueaderos, " +
                                "operacion, estado, activo) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'disponible', 1)",
                                Statement.RETURN_GENERATED_KEYS)) {
                            ps.setInt(1, idInmobiliaria);
                            ps.setInt(2, idCiudadNum);
                            ps.setInt(3, idTipoNum);
                            ps.setString(4, matricula);
                            ps.setString(5, titulo);
                            if (descripcion.isEmpty()) ps.setNull(6, Types.LONGVARCHAR); else ps.setString(6, descripcion);
                            ps.setString(7, direccion);
                            ps.setBigDecimal(8, precioNum);
                            ps.setBigDecimal(9, areaNum);
                            if (habNum == null) ps.setNull(10, Types.TINYINT); else ps.setInt(10, habNum);
                            if (banosNum == null) ps.setNull(11, Types.TINYINT); else ps.setInt(11, banosNum);
                            ps.setInt(12, parqNum);
                            ps.setString(13, operacion);
                            ps.executeUpdate();
                            try (ResultSet keys = ps.getGeneratedKeys()) { keys.next(); idPropiedadFinal = keys.getInt(1); }
                        }
                    }

                    try (PreparedStatement ps = conexion.prepareStatement(
                            "INSERT INTO propiedad_caracteristica (id_propiedad, id_caracteristica) VALUES (?, ?)")) {
                        for (String idCarStr : caracteristicasSeleccionadas) {
                            ps.setInt(1, idPropiedadFinal);
                            ps.setInt(2, Integer.parseInt(idCarStr));
                            ps.addBatch();
                        }
                        if (!caracteristicasSeleccionadas.isEmpty()) ps.executeBatch();
                    }

                    if (!esEdicion && !urlsImagenesFinal.isEmpty()) {
                        try (PreparedStatement ps = conexion.prepareStatement(
                                "INSERT INTO imagen_propiedad (id_propiedad, url_imagen, orden, es_principal) VALUES (?, ?, ?, ?)")) {
                            for (int i = 0; i < urlsImagenesFinal.size(); i++) {
                                ps.setInt(1, idPropiedadFinal);
                                ps.setString(2, urlsImagenesFinal.get(i));
                                ps.setInt(3, i + 1);
                                ps.setBoolean(4, i == indicePrincipalFinal);
                                ps.addBatch();
                            }
                            ps.executeBatch();
                        }
                    }

                    hgRegistrarAuditoria(conexion, request, idUsuarioSesion,
                            esEdicion ? "actualizacion_propiedad" : "creacion_propiedad", "propiedad",
                            (esEdicion ? "Actualizó" : "Publicó") + " la propiedad " + matricula + ".");

                    conexion.commit();
                    guardadoExitoso = true;

                    try { conexion.close(); } catch (Exception ignored) { }
                    if (esEdicion) {
                        response.sendRedirect(request.getContextPath() + "/inmobiliaria/mis-propiedades.jsp?actualizado=1");
                    } else if (!urlsImagenesFinal.isEmpty()) {
                        response.sendRedirect(request.getContextPath() + "/inmobiliaria/mis-propiedades.jsp?creado=1");
                    } else {
                        response.sendRedirect(request.getContextPath() + "/inmobiliaria/propiedad-galeria.jsp?id=" + idPropiedadFinal + "&nuevo=1");
                    }
                    return;

                } catch (SQLException sqlEx) {
                    try { conexion.rollback(); } catch (SQLException ignored) { }
                    String msg = sqlEx.getMessage() != null ? sqlEx.getMessage().toLowerCase() : "";
                    if ("23000".equals(sqlEx.getSQLState()) && msg.contains("matricula")) {
                        errores.add("Ya existe una propiedad publicada con esa matrícula inmobiliaria.");
                    } else {
                        errores.add("No fue posible guardar la propiedad. Intenta nuevamente.");
                    }
                } finally {
                    try { conexion.setAutoCommit(true); } catch (SQLException ignored) { }
                }
            }
        }

        try { if (conexion != null && !conexion.isClosed()) conexion.close(); } catch (Exception ignored) { }
    }
%><!DOCTYPE html>
<html lang="es">
<head>
    <% String hgTitulo = (esEdicion ? "Editar propiedad" : "Publicar propiedad"); %>
    <%@ include file="/jspf/head-comun.jspf" %>
</head>
<body>
<%@ include file="/jspf/panel-header.jspf" %>

<div class="hg-panel-body" style="max-width:820px;">
    <div class="hg-panel-hero">
        <span class="hg-eyebrow">Panel de inmobiliaria</span>
        <h1><%= esEdicion ? "Editar propiedad" : "Publicar nueva propiedad" %></h1>
        <p><a href="<%= request.getContextPath() %>/inmobiliaria/mis-propiedades.jsp">&larr; Volver a mis propiedades</a></p>
    </div>

    <% if (!errores.isEmpty()) { %>
    <div class="hg-alert hg-alert--error" style="margin-bottom:20px;">
        <ul>
            <% for (String err : errores) { %><li><%= err %></li><% } %>
        </ul>
    </div>
    <% } %>

    <div class="hg-panel-card">
        <form method="post" enctype="multipart/form-data" action="<%= request.getContextPath() %>/inmobiliaria/propiedad-form.jsp<%= esEdicion ? "?id=" + idPropiedadEdicion : "" %>" class="js-form-cargando">
            <div class="hg-auth__grid" style="margin-bottom:16px;">
                <div class="hg-field">
                    <label for="matricula">Matrícula inmobiliaria</label>
                    <input class="form-control" type="text" id="matricula" name="matricula" value="<%= matricula %>" maxlength="30" required>
                </div>
                <div class="hg-field">
                    <label for="operacion">Operación</label>
                    <select class="form-select" id="operacion" name="operacion">
                        <option value="venta" <%= "venta".equals(operacion) ? "selected" : "" %>>Venta</option>
                        <option value="arriendo" <%= "arriendo".equals(operacion) ? "selected" : "" %>>Arriendo</option>
                    </select>
                </div>
                <div class="hg-field hg-field--full">
                    <label for="titulo">Título del anuncio</label>
                    <input class="form-control" type="text" id="titulo" name="titulo" value="<%= titulo %>" maxlength="120" required>
                </div>
                <div class="hg-field hg-field--full">
                    <label for="descripcion">Descripción</label>
                    <textarea class="form-control" id="descripcion" name="descripcion" rows="4"><%= descripcion %></textarea>
                </div>
                <div class="hg-field hg-field--full">
                    <label for="direccion">Dirección</label>
                    <input class="form-control" type="text" id="direccion" name="direccion" value="<%= direccion %>" maxlength="150" required>
                </div>
                <div class="hg-field">
                    <label for="idCiudad">Ciudad</label>
                    <select class="form-select" id="idCiudad" name="idCiudad" required>
                        <option value="">Selecciona...</option>
                        <% for (Map<String, Object> c : ciudades) { %>
                        <option value="<%= c.get("id") %>" <%= String.valueOf(c.get("id")).equals(idCiudad) ? "selected" : "" %>><%= c.get("nombre") %></option>
                        <% } %>
                    </select>
                </div>
                <div class="hg-field">
                    <label for="idTipo">Tipo de propiedad</label>
                    <select class="form-select" id="idTipo" name="idTipo" required>
                        <option value="">Selecciona...</option>
                        <% for (Map<String, Object> t : tipos) { %>
                        <option value="<%= t.get("id") %>" <%= String.valueOf(t.get("id")).equals(idTipo) ? "selected" : "" %>><%= t.get("nombre") %></option>
                        <% } %>
                    </select>
                </div>
                <div class="hg-field">
                    <label for="precio">Precio (COP)</label>
                    <input class="form-control" type="number" id="precio" name="precio" min="0" step="1000" value="<%= precio %>" required>
                </div>
                <div class="hg-field">
                    <label for="area">Área (m²)</label>
                    <input class="form-control" type="number" id="area" name="area" min="0" step="0.1" value="<%= area %>" required>
                </div>
                <div class="hg-field">
                    <label for="habitaciones">Habitaciones</label>
                    <input class="form-control" type="number" id="habitaciones" name="habitaciones" min="0" step="1" value="<%= habitaciones %>">
                </div>
                <div class="hg-field">
                    <label for="banos">Baños</label>
                    <input class="form-control" type="number" id="banos" name="banos" min="0" step="1" value="<%= banos %>">
                </div>
                <div class="hg-field">
                    <label for="parqueaderos">Parqueaderos</label>
                    <input class="form-control" type="number" id="parqueaderos" name="parqueaderos" min="0" step="1" value="<%= parqueaderos.isEmpty() ? "0" : parqueaderos %>">
                </div>
                <% if (esEdicion) { %>
                <div class="hg-field">
                    <label for="estado">Estado comercial</label>
                    <select class="form-select" id="estado" name="estado">
                        <option value="disponible" <%= "disponible".equals(estado) ? "selected" : "" %>>Disponible</option>
                        <option value="reservado" <%= "reservado".equals(estado) ? "selected" : "" %>>Reservado</option>
                        <option value="vendido" <%= "vendido".equals(estado) ? "selected" : "" %>>Vendido</option>
                        <option value="arrendado" <%= "arrendado".equals(estado) ? "selected" : "" %>>Arrendado</option>
                    </select>
                </div>
                <% } %>
            </div>

            <label style="display:block; margin-bottom:8px; font-weight:600; font-size:.9rem;">Características</label>
            <div class="hg-detalle__caracteristicas" style="margin-bottom:24px;">
                <% for (Map<String, Object> car : caracteristicasCatalogo) {
                    String idCarStr = String.valueOf(car.get("id"));
                    boolean marcada = caracteristicasSeleccionadas.contains(idCarStr);
                %>
                <label class="hg-checkbox">
                    <input type="checkbox" name="caracteristicas" value="<%= idCarStr %>" <%= marcada ? "checked" : "" %>>
                    <%= car.get("nombre") %>
                </label>
                <% } %>
            </div>

            <% if (!esEdicion) { %>
            <label style="display:block; margin-bottom:8px; font-weight:600; font-size:.9rem;">Galería de imágenes</label>
            <p style="color:var(--hg-ink-muted); font-size:.85rem; margin-top:-4px; margin-bottom:12px;">Sube fotos desde tu equipo o pega enlaces de imágenes; puedes combinar ambas formas. La primera que agregues queda como portada, pero puedes cambiarla.</p>

            <div class="hg-o-alternativa" style="margin-bottom:14px;">
                <div class="hg-field">
                    <label for="inputArchivos"><i class="bi bi-upload"></i> Subir desde el equipo (JPG, PNG o WEBP, max. 5MB c/u)</label>
                    <input class="form-control" type="file" id="inputArchivos" name="imagenes" accept=".jpg,.jpeg,.png,.webp" multiple>
                </div>
                <span class="hg-o-alternativa__o">o</span>
                <div class="hg-field">
                    <label for="urlImagenNueva"><i class="bi bi-link-45deg"></i> URL de la imagen</label>
                    <div style="display:flex; gap:8px;">
                        <input class="form-control" type="url" id="urlImagenNueva" placeholder="https://images.unsplash.com/...">
                        <button type="button" id="btnAgregarLink" class="hg-btn hg-btn--ghost hg-btn--sm"><i class="bi bi-plus-lg"></i> Agregar</button>
                    </div>
                </div>
            </div>

            <div id="galeriaError" class="hg-alert hg-alert--error" style="display:none; margin-bottom:14px;"></div>

            <div id="galeriaVacio" class="hg-panel-empty" style="margin-bottom:24px;">
                <div class="hg-panel-empty__icon"><i class="bi bi-images"></i></div>
                <p>Aún no has agregado imágenes. Puedes publicar sin fotos y agregarlas después.</p>
            </div>
            <div id="galeriaPreview" class="hg-galeria-grid" style="display:none;"></div>

            <div id="urlImagenesOcultos"></div>
            <input type="hidden" id="ordenTiposOculto" name="ordenTipos" value="">
            <input type="hidden" id="indicePrincipalOculto" name="indicePrincipal" value="">
            <% } %>

            <button class="hg-btn hg-btn--primary" type="submit"><i class="bi bi-check-lg"></i> <%= esEdicion ? "Guardar cambios" : "Publicar propiedad" %></button>
        </form>
    </div>
</div>
<%@ include file="/jspf/scripts-panel.jspf" %>
<% if (!esEdicion) { %>
<script>
(function () {
    var LIMITE_IMAGENES = 10;
    var EXTENSIONES_VALIDAS = ['jpg', 'jpeg', 'png', 'webp'];
    var TAMANO_MAXIMO = 5 * 1024 * 1024;

    var galeria = [];
    var principalId = null;
    var contadorId = 0;

    var inputArchivos = document.getElementById('inputArchivos');
    var inputUrlNueva = document.getElementById('urlImagenNueva');
    var btnAgregarLink = document.getElementById('btnAgregarLink');
    var contenedorPreview = document.getElementById('galeriaPreview');
    var contenedorVacio = document.getElementById('galeriaVacio');
    var cajaError = document.getElementById('galeriaError');
    var contenedorUrlsOcultos = document.getElementById('urlImagenesOcultos');
    var campoOrdenTipos = document.getElementById('ordenTiposOculto');
    var campoIndicePrincipal = document.getElementById('indicePrincipalOculto');

    function mostrarError(msg) {
        cajaError.textContent = msg;
        cajaError.style.display = 'block';
    }
    function limpiarError() {
        cajaError.style.display = 'none';
        cajaError.textContent = '';
    }
    function extensionValida(nombre) {
        var idx = nombre.lastIndexOf('.');
        if (idx < 0) return false;
        return EXTENSIONES_VALIDAS.indexOf(nombre.substring(idx + 1).toLowerCase()) !== -1;
    }

    inputArchivos.addEventListener('change', function () {
        limpiarError();
        var archivos = Array.prototype.slice.call(inputArchivos.files);
        for (var i = 0; i < archivos.length; i++) {
            if (galeria.length >= LIMITE_IMAGENES) {
                mostrarError('Solo puedes agregar hasta ' + LIMITE_IMAGENES + ' imágenes.');
                break;
            }
            var f = archivos[i];
            if (!extensionValida(f.name)) {
                mostrarError('"' + f.name + '" no es un formato válido (solo JPG, PNG o WEBP).');
                continue;
            }
            if (f.size > TAMANO_MAXIMO) {
                mostrarError('"' + f.name + '" supera el tamaño máximo de 5MB.');
                continue;
            }
            var item = { id: contadorId++, tipo: 'file', file: f, previewUrl: URL.createObjectURL(f) };
            if (galeria.length === 0) principalId = item.id;
            galeria.push(item);
        }
        renderGaleria();
    });

    btnAgregarLink.addEventListener('click', function () {
        limpiarError();
        var url = inputUrlNueva.value.trim();
        if (!/^https?:\/\/.+/i.test(url)) {
            mostrarError('Ingresa una URL válida (debe iniciar con http:// o https://).');
            return;
        }
        if (galeria.length >= LIMITE_IMAGENES) {
            mostrarError('Solo puedes agregar hasta ' + LIMITE_IMAGENES + ' imágenes.');
            return;
        }
        var item = { id: contadorId++, tipo: 'url', url: url, previewUrl: url };
        if (galeria.length === 0) principalId = item.id;
        galeria.push(item);
        inputUrlNueva.value = '';
        renderGaleria();
    });

    contenedorPreview.addEventListener('click', function (e) {
        var btn = e.target.closest('button[data-accion]');
        if (!btn) return;
        var tarjeta = btn.closest('[data-id]');
        var id = Number(tarjeta.getAttribute('data-id'));
        if (btn.getAttribute('data-accion') === 'principal') {
            principalId = id;
        } else if (btn.getAttribute('data-accion') === 'quitar') {
            for (var i = 0; i < galeria.length; i++) {
                if (galeria[i].id === id) {
                    if (galeria[i].tipo === 'file') URL.revokeObjectURL(galeria[i].previewUrl);
                    galeria.splice(i, 1);
                    break;
                }
            }
            if (principalId === id) {
                principalId = galeria.length ? galeria[0].id : null;
            }
        }
        renderGaleria();
    });

    function renderGaleria() {
        contenedorVacio.style.display = galeria.length === 0 ? 'block' : 'none';
        contenedorPreview.style.display = galeria.length === 0 ? 'none' : 'grid';
        contenedorPreview.innerHTML = '';
        galeria.forEach(function (item) {
            var esPrincipal = item.id === principalId;

            var tarjeta = document.createElement('div');
            tarjeta.className = 'hg-galeria-item';
            tarjeta.setAttribute('data-id', item.id);

            if (esPrincipal) {
                var badge = document.createElement('span');
                badge.className = 'hg-galeria-item__principal';
                badge.textContent = 'Principal';
                tarjeta.appendChild(badge);
            }

            // Se asigna como propiedad (no via innerHTML) para que una URL con
            // caracteres especiales nunca pueda inyectar markup en la pagina.
            var img = document.createElement('img');
            img.src = item.previewUrl;
            img.alt = 'Vista previa';
            tarjeta.appendChild(img);

            var barra = document.createElement('div');
            barra.className = 'hg-galeria-item__bar';

            if (esPrincipal) {
                barra.appendChild(document.createElement('span'));
            } else {
                var btnPrincipal = document.createElement('button');
                btnPrincipal.type = 'button';
                btnPrincipal.className = 'hg-btn hg-btn--ghost hg-btn--sm';
                btnPrincipal.setAttribute('data-accion', 'principal');
                btnPrincipal.innerHTML = '<i class="bi bi-star-fill"></i> Hacer principal';
                barra.appendChild(btnPrincipal);
            }

            var btnQuitar = document.createElement('button');
            btnQuitar.type = 'button';
            btnQuitar.className = 'hg-btn hg-btn--ghost hg-btn--sm';
            btnQuitar.style.color = 'var(--hg-off)';
            btnQuitar.setAttribute('data-accion', 'quitar');
            btnQuitar.innerHTML = '<i class="bi bi-trash3"></i> Quitar';
            barra.appendChild(btnQuitar);

            tarjeta.appendChild(barra);
            contenedorPreview.appendChild(tarjeta);
        });
        actualizarCamposOcultos();
    }

    function actualizarCamposOcultos() {
        var dt = new DataTransfer();
        contenedorUrlsOcultos.innerHTML = '';
        var tipos = [];
        var indicePrincipal = -1;
        galeria.forEach(function (item, i) {
            tipos.push(item.tipo);
            if (item.id === principalId) indicePrincipal = i;
            if (item.tipo === 'file') {
                dt.items.add(item.file);
            } else {
                var oculto = document.createElement('input');
                oculto.type = 'hidden';
                oculto.name = 'urlImagenes';
                oculto.value = item.url;
                contenedorUrlsOcultos.appendChild(oculto);
            }
        });
        inputArchivos.files = dt.files;
        campoOrdenTipos.value = tipos.join(',');
        campoIndicePrincipal.value = indicePrincipal;
    }
})();
</script>
<% } %>
</body>
</html>
<%!
    private String valorSeguro(String s) {
        return s == null ? "" : s.trim();
    }
%>
