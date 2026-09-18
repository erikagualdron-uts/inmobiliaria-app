<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ page import="java.sql.PreparedStatement, java.sql.ResultSet" %>
<%@ page import="java.util.ArrayList, java.util.List, java.util.Map, java.util.LinkedHashMap, java.util.HashSet, java.util.Arrays" %>
<%
    String[] rolesPermitidos = { "Cliente" };
%>
<%@ include file="/jspf/seguridad.jspf" %>
<%@ include file="/jspf/conexion.jspf" %>
<%@ include file="/jspf/subida-archivos.jspf" %>
<%@ include file="/jspf/auditoria.jspf" %>
<%
    int idUsuarioSesion = (Integer) session.getAttribute("idUsuario");
    List<String> errores = new ArrayList<>();

    // Radicar un nuevo documento sobre una solicitud propia (Post/Redirect/Get).
    // Acepta un archivo subido desde el PC o, alternativamente, una URL.
    if ("POST".equalsIgnoreCase(request.getMethod()) && "radicarDocumento".equals(request.getParameter("accion")) && conexion != null) {
        try {
            int idSolicitud = Integer.parseInt(request.getParameter("idSolicitud"));
            String nombreDocumento = request.getParameter("nombreDocumento") != null ? request.getParameter("nombreDocumento").trim() : "";
            String urlDocumento = request.getParameter("urlDocumento") != null ? request.getParameter("urlDocumento").trim() : "";

            boolean pertenece = false;
            try (PreparedStatement ps = conexion.prepareStatement(
                    "SELECT 1 FROM solicitud WHERE id_solicitud = ? AND id_cliente = ?")) {
                ps.setInt(1, idSolicitud);
                ps.setInt(2, idUsuarioSesion);
                try (ResultSet rs = ps.executeQuery()) { pertenece = rs.next(); }
            }

            if (!pertenece) {
                response.sendRedirect(request.getContextPath() + "/acceso-denegado.jsp");
                return;
            }

            String urlFinal = null;
            try {
                String urlSubida = hgGuardarArchivoSubido(request, "archivoDocumento", "documentos",
                        new HashSet<>(Arrays.asList("pdf", "jpg", "jpeg", "png", "doc", "docx")), 5L * 1024 * 1024);
                if (urlSubida != null) {
                    urlFinal = urlSubida;
                } else if (!urlDocumento.isEmpty() && urlDocumento.matches("^https?://.+")) {
                    urlFinal = urlDocumento;
                }
            } catch (IllegalArgumentException iae) {
                errores.add(iae.getMessage());
            }

            if (nombreDocumento.isEmpty()) {
                errores.add("Ingresa un nombre para el documento.");
            }
            if (urlFinal == null && errores.isEmpty()) {
                errores.add("Sube un archivo desde tu equipo o ingresa una URL válida (debe iniciar con http:// o https://).");
            }

            if (errores.isEmpty()) {
                try (PreparedStatement ps = conexion.prepareStatement(
                        "INSERT INTO documento_solicitud (id_solicitud, nombre_documento, url_documento, estado) " +
                        "VALUES (?, ?, ?, 'pendiente')")) {
                    ps.setInt(1, idSolicitud);
                    ps.setString(2, nombreDocumento);
                    ps.setString(3, urlFinal);
                    ps.executeUpdate();
                }
                hgRegistrarAuditoria(conexion, request, idUsuarioSesion, "radicacion_documento", "documento_solicitud",
                        "Cargó el documento " + nombreDocumento + ".");
            }
        } catch (Exception e) {
            if (errores.isEmpty()) errores.add("No fue posible radicar el documento. Intenta nuevamente.");
        }

        if (errores.isEmpty()) {
            try { conexion.close(); } catch (Exception ignored) { }
            response.sendRedirect(request.getContextPath() + "/cliente/mis-solicitudes.jsp");
            return;
        }
    }

    List<Map<String, Object>> solicitudes = new ArrayList<>();
    if (conexion != null) {
        try (PreparedStatement ps = conexion.prepareStatement(
                "SELECT s.id_solicitud, s.tipo_solicitud, s.estado, s.fecha_solicitud, s.observaciones, " +
                "       p.id_propiedad, p.titulo, ciu.nombre_ciudad " +
                "FROM solicitud s " +
                "INNER JOIN propiedad p ON p.id_propiedad = s.id_propiedad " +
                "INNER JOIN ciudad ciu ON ciu.id_ciudad = p.id_ciudad " +
                "WHERE s.id_cliente = ? " +
                "ORDER BY s.fecha_solicitud DESC")) {
            ps.setInt(1, idUsuarioSesion);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> f = new LinkedHashMap<>();
                    f.put("id", rs.getInt("id_solicitud"));
                    f.put("tipo", rs.getString("tipo_solicitud"));
                    f.put("estado", rs.getString("estado"));
                    f.put("fecha", rs.getTimestamp("fecha_solicitud"));
                    f.put("observaciones", rs.getString("observaciones"));
                    f.put("idPropiedad", rs.getInt("id_propiedad"));
                    f.put("titulo", rs.getString("titulo"));
                    f.put("ciudad", rs.getString("nombre_ciudad"));

                    List<Map<String, Object>> documentos = new ArrayList<>();
                    try (PreparedStatement psDoc = conexion.prepareStatement(
                            "SELECT nombre_documento, url_documento, estado FROM documento_solicitud WHERE id_solicitud = ? ORDER BY fecha_carga")) {
                        psDoc.setInt(1, rs.getInt("id_solicitud"));
                        try (ResultSet rsDoc = psDoc.executeQuery()) {
                            while (rsDoc.next()) {
                                Map<String, Object> d = new LinkedHashMap<>();
                                d.put("nombre", rsDoc.getString("nombre_documento"));
                                d.put("url", rsDoc.getString("url_documento"));
                                d.put("estado", rsDoc.getString("estado"));
                                documentos.add(d);
                            }
                        }
                    } catch (Exception ignored) { }
                    f.put("documentos", documentos);

                    solicitudes.add(f);
                }
            }
        } catch (Exception ignored) { }
        try { conexion.close(); } catch (Exception ignored) { }
    }
%><!DOCTYPE html>
<html lang="es">
<head>
    <% String hgTitulo = "Mis solicitudes"; %>
    <%@ include file="/jspf/head-comun.jspf" %>
</head>
<body>
<%@ include file="/jspf/panel-header.jspf" %>

<div class="hg-panel-body">
    <div class="hg-panel-hero">
        <span class="hg-eyebrow">Panel de cliente</span>
        <h1>Mis solicitudes</h1>
        <p><a href="<%= request.getContextPath() %>/cliente/dashboard-cliente.jsp">&larr; Volver a mi panel</a></p>
    </div>

    <% if (!errores.isEmpty()) { %>
    <div class="hg-alert hg-alert--error" style="margin-bottom:20px;">
        <ul><% for (String err : errores) { %><li><%= err %></li><% } %></ul>
    </div>
    <% } %>

    <% if (solicitudes.isEmpty()) { %>
    <div class="hg-panel-card">
        <div class="hg-panel-empty">
            <div class="hg-panel-empty__icon"><i class="bi bi-clipboard"></i></div>
            <p>Aún no has radicado ninguna solicitud de compra o arriendo.</p>
            <a class="hg-btn hg-btn--primary" href="<%= request.getContextPath() %>/catalogo.jsp">Explorar propiedades</a>
        </div>
    </div>
    <% } else { %>
    <div style="display:flex; flex-direction:column; gap:18px;">
        <% for (Map<String, Object> s : solicitudes) {
            String estadoS = (String) s.get("estado");
            @SuppressWarnings("unchecked")
            List<Map<String, Object>> documentos = (List<Map<String, Object>>) s.get("documentos");
        %>
        <div class="hg-panel-card">
            <div style="display:flex; justify-content:space-between; flex-wrap:wrap; gap:10px; margin-bottom:10px;">
                <div>
                    <a href="<%= request.getContextPath() %>/detalle.jsp?id=<%= s.get("idPropiedad") %>" style="font-weight:600;"><%= s.get("titulo") %></a>
                    <p style="color:var(--hg-ink-muted); font-size:.86rem; margin-top:2px;"><%= s.get("ciudad") %> &middot; <%= "compra".equals(s.get("tipo")) ? "Compra" : "Arriendo" %></p>
                </div>
                <span class="hg-badge--estado hg-badge--<%= estadoS %>" style="position:static; display:inline-block; height:fit-content;"><%= estadoS.substring(0,1).toUpperCase() + estadoS.substring(1).replace("_", " ") %></span>
            </div>

            <% if (!documentos.isEmpty()) { %>
            <div style="margin-bottom:12px;">
                <% for (Map<String, Object> d : documentos) { %>
                <div style="display:flex; justify-content:space-between; align-items:center; padding:8px 0; border-bottom:1px dashed var(--hg-border); font-size:.9rem;">
                    <a href="<%= d.get("url") %>" target="_blank"><%= d.get("nombre") %></a>
                    <span class="hg-badge--estado hg-badge--<%= d.get("estado") %>" style="position:static; display:inline-block;"><%= d.get("estado").toString().substring(0,1).toUpperCase() + d.get("estado").toString().substring(1) %></span>
                </div>
                <% } %>
            </div>
            <% } %>

            <details>
                <summary style="cursor:pointer; color:var(--hg-primary); font-size:.9rem; font-weight:600;"><i class="bi bi-plus-circle"></i> Radicar documento</summary>
                <form method="post" action="<%= request.getContextPath() %>/cliente/mis-solicitudes.jsp" enctype="multipart/form-data" style="display:flex; flex-direction:column; gap:10px; margin-top:12px;">
                    <input type="hidden" name="accion" value="radicarDocumento">
                    <input type="hidden" name="idSolicitud" value="<%= s.get("id") %>">
                    <input class="form-control" type="text" name="nombreDocumento" placeholder="Ej. Cédula de ciudadanía" required>
                    <div class="hg-o-alternativa">
                        <div class="hg-field">
                            <label><i class="bi bi-upload"></i> Subir archivo (PDF, JPG, PNG o Word, max. 5MB)</label>
                            <input class="form-control" type="file" name="archivoDocumento" accept=".pdf,.jpg,.jpeg,.png,.doc,.docx">
                        </div>
                        <span class="hg-o-alternativa__o">o</span>
                        <div class="hg-field">
                            <label><i class="bi bi-link-45deg"></i> Pega la URL del documento</label>
                            <input class="form-control" type="url" name="urlDocumento" placeholder="https://...">
                        </div>
                    </div>
                    <button class="hg-btn hg-btn--ghost hg-btn--sm" type="submit" style="align-self:flex-start;"><i class="bi bi-send"></i> Agregar</button>
                </form>
            </details>
        </div>
        <% } %>
    </div>
    <% } %>
</div>
<%@ include file="/jspf/scripts-panel.jspf" %>
</body>
</html>
