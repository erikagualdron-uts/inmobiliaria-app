<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ page import="java.sql.PreparedStatement, java.sql.ResultSet" %>
<%@ page import="java.util.ArrayList, java.util.List, java.util.Map, java.util.LinkedHashMap" %>
<%
    String[] rolesPermitidos = { "Inmobiliaria" };
%>
<%@ include file="/jspf/seguridad.jspf" %>
<%@ include file="/jspf/conexion.jspf" %>
<%
    int idUsuarioSesion = (Integer) session.getAttribute("idUsuario");
    Integer idInmobiliaria = null;

    if (conexion != null) {
        try (PreparedStatement ps = conexion.prepareStatement("SELECT id_inmobiliaria FROM usuario WHERE id_usuario = ?")) {
            ps.setInt(1, idUsuarioSesion);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) { int idIn = rs.getInt(1); if (!rs.wasNull()) idInmobiliaria = idIn; }
            }
        } catch (Exception ignored) { }
    }

    if ("POST".equalsIgnoreCase(request.getMethod()) && conexion != null && idInmobiliaria != null) {
        String accion = request.getParameter("accion");

        if ("aprobar".equals(accion) || "rechazar".equals(accion) || "revisar".equals(accion)) {
            String nuevoEstado = "aprobar".equals(accion) ? "aprobada" : "rechazar".equals(accion) ? "rechazada" : "en_revision";
            try {
                int idSolicitud = Integer.parseInt(request.getParameter("idSolicitud"));
                try (PreparedStatement ps = conexion.prepareStatement(
                        "UPDATE solicitud s INNER JOIN propiedad p ON p.id_propiedad = s.id_propiedad " +
                        "SET s.estado = ? WHERE s.id_solicitud = ? AND p.id_inmobiliaria = ?")) {
                    ps.setString(1, nuevoEstado);
                    ps.setInt(2, idSolicitud);
                    ps.setInt(3, idInmobiliaria);
                    ps.executeUpdate();
                }
            } catch (Exception ignored) { }
            try { conexion.close(); } catch (Exception ignored) { }
            response.sendRedirect(request.getContextPath() + "/inmobiliaria/solicitudes-recibidas.jsp");
            return;
        }

        if ("aprobarDocumento".equals(accion) || "rechazarDocumento".equals(accion)) {
            String nuevoEstadoDoc = "aprobarDocumento".equals(accion) ? "aprobado" : "rechazado";
            try {
                int idDocumento = Integer.parseInt(request.getParameter("idDocumento"));
                try (PreparedStatement ps = conexion.prepareStatement(
                        "UPDATE documento_solicitud d " +
                        "INNER JOIN solicitud s ON s.id_solicitud = d.id_solicitud " +
                        "INNER JOIN propiedad p ON p.id_propiedad = s.id_propiedad " +
                        "SET d.estado = ? WHERE d.id_documento = ? AND p.id_inmobiliaria = ?")) {
                    ps.setString(1, nuevoEstadoDoc);
                    ps.setInt(2, idDocumento);
                    ps.setInt(3, idInmobiliaria);
                    ps.executeUpdate();
                }
            } catch (Exception ignored) { }
            try { conexion.close(); } catch (Exception ignored) { }
            response.sendRedirect(request.getContextPath() + "/inmobiliaria/solicitudes-recibidas.jsp");
            return;
        }
    }

    List<Map<String, Object>> solicitudes = new ArrayList<>();
    if (conexion != null && idInmobiliaria != null) {
        try (PreparedStatement ps = conexion.prepareStatement(
                "SELECT s.id_solicitud, s.tipo_solicitud, s.estado, s.fecha_solicitud, s.observaciones, " +
                "       p.id_propiedad, p.titulo, per.nombres, per.apellidos, per.telefono " +
                "FROM solicitud s " +
                "INNER JOIN propiedad p ON p.id_propiedad = s.id_propiedad " +
                "INNER JOIN perfil per ON per.id_usuario = s.id_cliente " +
                "WHERE p.id_inmobiliaria = ? " +
                "ORDER BY (s.estado IN ('pendiente','en_revision')) DESC, s.fecha_solicitud DESC")) {
            ps.setInt(1, idInmobiliaria);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> f = new LinkedHashMap<>();
                    int idSolicitud = rs.getInt("id_solicitud");
                    f.put("id", idSolicitud);
                    f.put("tipo", rs.getString("tipo_solicitud"));
                    f.put("estado", rs.getString("estado"));
                    f.put("fecha", rs.getTimestamp("fecha_solicitud"));
                    f.put("observaciones", rs.getString("observaciones"));
                    f.put("idPropiedad", rs.getInt("id_propiedad"));
                    f.put("titulo", rs.getString("titulo"));
                    f.put("cliente", rs.getString("nombres") + " " + rs.getString("apellidos"));
                    f.put("telefono", rs.getString("telefono"));

                    List<Map<String, Object>> documentos = new ArrayList<>();
                    try (PreparedStatement psDoc = conexion.prepareStatement(
                            "SELECT id_documento, nombre_documento, url_documento, estado FROM documento_solicitud WHERE id_solicitud = ? ORDER BY fecha_carga")) {
                        psDoc.setInt(1, idSolicitud);
                        try (ResultSet rsDoc = psDoc.executeQuery()) {
                            while (rsDoc.next()) {
                                Map<String, Object> d = new LinkedHashMap<>();
                                d.put("id", rsDoc.getInt("id_documento"));
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
    <% String hgTitulo = "Solicitudes recibidas"; %>
    <%@ include file="/jspf/head-comun.jspf" %>
</head>
<body>
<%@ include file="/jspf/panel-header.jspf" %>

<div class="hg-panel-body">
    <div class="hg-panel-hero">
        <span class="hg-eyebrow">Panel de inmobiliaria</span>
        <h1>Solicitudes recibidas</h1>
        <p><a href="<%= request.getContextPath() %>/inmobiliaria/dashboard-inmobiliaria.jsp">&larr; Volver a mi panel</a></p>
    </div>

    <% if (idInmobiliaria == null) { %>
    <div class="hg-alert hg-alert--error">Tu cuenta aun no esta asociada a ninguna inmobiliaria.</div>
    <% } else if (solicitudes.isEmpty()) { %>
    <div class="hg-panel-card">
        <div class="hg-panel-empty">
            <div class="hg-panel-empty__icon">📋</div>
            <p>Todavia no tienes solicitudes radicadas.</p>
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
                    <p style="color:var(--hg-ink-muted); font-size:.86rem; margin-top:2px;">
                        <%= s.get("cliente") %> &middot; <%= s.get("telefono") != null ? s.get("telefono") : "sin telefono" %> &middot; <%= "compra".equals(s.get("tipo")) ? "Compra" : "Arriendo" %>
                    </p>
                </div>
                <span class="hg-badge--estado hg-badge--<%= estadoS %>" style="position:static; display:inline-block; height:fit-content;"><%= estadoS.substring(0,1).toUpperCase() + estadoS.substring(1).replace("_", " ") %></span>
            </div>

            <% if (s.get("observaciones") != null) { %>
            <p style="color:var(--hg-ink-muted); font-size:.88rem; margin-bottom:10px;">"<%= s.get("observaciones") %>"</p>
            <% } %>

            <% if (documentos.isEmpty()) { %>
            <p style="color:var(--hg-ink-muted); font-size:.86rem; margin-bottom:12px;">El cliente aun no ha radicado documentos.</p>
            <% } else { %>
            <div style="margin-bottom:12px;">
                <% for (Map<String, Object> d : documentos) {
                    String estadoDoc = (String) d.get("estado");
                %>
                <div style="display:flex; justify-content:space-between; align-items:center; gap:10px; flex-wrap:wrap; padding:8px 0; border-bottom:1px dashed var(--hg-border); font-size:.9rem;">
                    <a href="<%= d.get("url") %>" target="_blank"><%= d.get("nombre") %></a>
                    <div style="display:flex; align-items:center; gap:8px;">
                        <span class="hg-badge--estado hg-badge--<%= estadoDoc %>" style="position:static; display:inline-block;"><%= estadoDoc.substring(0,1).toUpperCase() + estadoDoc.substring(1) %></span>
                        <% if ("pendiente".equals(estadoDoc)) { %>
                        <form method="post" action="<%= request.getContextPath() %>/inmobiliaria/solicitudes-recibidas.jsp" style="display:inline;">
                            <input type="hidden" name="accion" value="aprobarDocumento"><input type="hidden" name="idDocumento" value="<%= d.get("id") %>">
                            <button class="hg-btn hg-btn--ghost hg-btn--sm" type="submit">Aprobar</button>
                        </form>
                        <form method="post" action="<%= request.getContextPath() %>/inmobiliaria/solicitudes-recibidas.jsp" style="display:inline;">
                            <input type="hidden" name="accion" value="rechazarDocumento"><input type="hidden" name="idDocumento" value="<%= d.get("id") %>">
                            <button class="hg-btn hg-btn--ghost hg-btn--sm" type="submit" style="color:var(--hg-off);">Rechazar</button>
                        </form>
                        <% } %>
                    </div>
                </div>
                <% } %>
            </div>
            <% } %>

            <% if ("pendiente".equals(estadoS) || "en_revision".equals(estadoS)) { %>
            <div class="hg-tabla__acciones">
                <% if ("pendiente".equals(estadoS)) { %>
                <form method="post" action="<%= request.getContextPath() %>/inmobiliaria/solicitudes-recibidas.jsp">
                    <input type="hidden" name="accion" value="revisar"><input type="hidden" name="idSolicitud" value="<%= s.get("id") %>">
                    <button class="hg-btn hg-btn--ghost hg-btn--sm" type="submit">Poner en revision</button>
                </form>
                <% } %>
                <form method="post" action="<%= request.getContextPath() %>/inmobiliaria/solicitudes-recibidas.jsp">
                    <input type="hidden" name="accion" value="aprobar"><input type="hidden" name="idSolicitud" value="<%= s.get("id") %>">
                    <button class="hg-btn hg-btn--primary hg-btn--sm" type="submit">Aprobar solicitud</button>
                </form>
                <form method="post" action="<%= request.getContextPath() %>/inmobiliaria/solicitudes-recibidas.jsp">
                    <input type="hidden" name="accion" value="rechazar"><input type="hidden" name="idSolicitud" value="<%= s.get("id") %>">
                    <button class="hg-btn hg-btn--ghost hg-btn--sm" type="submit">Rechazar solicitud</button>
                </form>
            </div>
            <% } %>
        </div>
        <% } %>
    </div>
    <% } %>
</div>
</body>
</html>
