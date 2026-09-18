<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ page import="java.sql.PreparedStatement, java.sql.ResultSet" %>
<%@ page import="java.text.NumberFormat, java.util.Locale" %>
<%@ page import="java.util.ArrayList, java.util.List, java.util.Map, java.util.LinkedHashMap" %>
<%
    String[] rolesPermitidos = { "Inmobiliaria" };
%>
<%@ include file="/jspf/seguridad.jspf" %>
<%@ include file="/jspf/conexion.jspf" %>
<%
    // =========================================================================
    // Listado de propiedades de LA inmobiliaria del agente en sesion. Toda
    // operacion valida que la propiedad pertenezca a esa inmobiliaria antes
    // de tocarla (no basta con el rol: tambien se verifica la propiedad).
    // =========================================================================
    int idUsuarioSesion = (Integer) session.getAttribute("idUsuario");
    Integer idInmobiliaria = null;
    String mensaje = null, mensajeTipo = "success";

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

        // Alternar baja logica (activo <-> inactivo), patron Post/Redirect/Get
        if ("POST".equalsIgnoreCase(request.getMethod()) && "toggleActivo".equals(request.getParameter("accion")) && idInmobiliaria != null) {
            try {
                Integer idPropiedadAccion = Integer.valueOf(request.getParameter("idPropiedad"));
                try (PreparedStatement ps = conexion.prepareStatement(
                        "UPDATE propiedad SET activo = 1 - activo WHERE id_propiedad = ? AND id_inmobiliaria = ?")) {
                    ps.setInt(1, idPropiedadAccion);
                    ps.setInt(2, idInmobiliaria);
                    ps.executeUpdate();
                }
            } catch (Exception ignored) { }
            try { conexion.close(); } catch (Exception ignored) { }
            response.sendRedirect(request.getContextPath() + "/inmobiliaria/mis-propiedades.jsp?actualizado=1");
            return;
        }
    }

    if ("1".equals(request.getParameter("creado"))) { mensaje = "Propiedad publicada con exito."; }
    if ("1".equals(request.getParameter("actualizado"))) { mensaje = "Los cambios se guardaron correctamente."; }

    List<Map<String, Object>> propiedades = new ArrayList<>();
    if (conexion != null && idInmobiliaria != null) {
        try (PreparedStatement ps = conexion.prepareStatement(
                "SELECT p.id_propiedad, p.titulo, p.matricula_inmobiliaria, p.precio, p.operacion, p.estado, p.activo, " +
                "       c.nombre_ciudad, t.nombre_tipo " +
                "FROM propiedad p " +
                "INNER JOIN ciudad c ON c.id_ciudad = p.id_ciudad " +
                "INNER JOIN tipo_propiedad t ON t.id_tipo = p.id_tipo " +
                "WHERE p.id_inmobiliaria = ? " +
                "ORDER BY p.fecha_publicacion DESC")) {
            ps.setInt(1, idInmobiliaria);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> fila = new LinkedHashMap<>();
                    fila.put("id", rs.getInt("id_propiedad"));
                    fila.put("titulo", rs.getString("titulo"));
                    fila.put("matricula", rs.getString("matricula_inmobiliaria"));
                    fila.put("precio", rs.getBigDecimal("precio"));
                    fila.put("operacion", rs.getString("operacion"));
                    fila.put("estado", rs.getString("estado"));
                    fila.put("activo", rs.getInt("activo") == 1);
                    fila.put("ciudad", rs.getString("nombre_ciudad"));
                    fila.put("tipo", rs.getString("nombre_tipo"));
                    propiedades.add(fila);
                }
            }
        } catch (Exception ignored) { }
    }

    if (conexion != null) { try { conexion.close(); } catch (Exception ignored) { } }

    NumberFormat formatoCOP = NumberFormat.getInstance(new Locale("es", "CO"));
%><!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Mis propiedades | Hogaria</title>
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Fraunces:opsz,wght@9..144,500;9..144,600;9..144,700&family=Work+Sans:wght@400;500;600;700&display=swap">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css">
    <link rel="stylesheet" href="<%= request.getContextPath() %>/assets/css/estilos.css">
</head>
<body>
<%@ include file="/jspf/panel-header.jspf" %>

<div class="hg-panel-body">
    <div class="hg-panel-hero" style="display:flex; justify-content:space-between; align-items:flex-end; flex-wrap:wrap; gap:16px;">
        <div>
            <span class="hg-eyebrow">Panel de inmobiliaria</span>
            <h1>Mis propiedades</h1>
            <p>Publica, edita o da de baja los inmuebles de tu inmobiliaria.</p>
        </div>
        <a class="hg-btn hg-btn--primary" href="<%= request.getContextPath() %>/inmobiliaria/propiedad-form.jsp">+ Publicar propiedad</a>
    </div>

    <% if (idInmobiliaria == null) { %>
    <div class="hg-alert hg-alert--error">Tu cuenta aun no esta asociada a ninguna inmobiliaria. Contacta al administrador para poder publicar propiedades.</div>
    <% } else { %>

        <% if (mensaje != null) { %>
        <div class="hg-alert hg-alert--success" style="margin-bottom:20px;"><%= mensaje %></div>
        <% } %>

        <% if (propiedades.isEmpty()) { %>
        <div class="hg-panel-card">
            <div class="hg-panel-empty">
                <div class="hg-panel-empty__icon">🏠</div>
                <p>Aun no has publicado ninguna propiedad.</p>
                <a class="hg-btn hg-btn--primary" href="<%= request.getContextPath() %>/inmobiliaria/propiedad-form.jsp">Publicar la primera</a>
            </div>
        </div>
        <% } else { %>
        <div class="hg-panel-card" style="padding:0; overflow-x:auto;">
            <table class="hg-tabla">
                <thead>
                    <tr>
                        <th>Propiedad</th>
                        <th>Ciudad / Tipo</th>
                        <th>Precio</th>
                        <th>Operacion</th>
                        <th>Estado</th>
                        <th>Publicacion</th>
                        <th>Acciones</th>
                    </tr>
                </thead>
                <tbody>
                    <% for (Map<String, Object> p : propiedades) {
                        boolean activo = (Boolean) p.get("activo");
                        String estadoP = (String) p.get("estado");
                        String operacionP = (String) p.get("operacion");
                        String precioTxt = "$ " + formatoCOP.format(p.get("precio")) + ("arriendo".equals(operacionP) ? " / mes" : "");
                    %>
                    <tr>
                        <td>
                            <strong><%= p.get("titulo") %></strong><br>
                            <span style="color:var(--hg-ink-muted); font-size:.8rem;"><%= p.get("matricula") %></span>
                        </td>
                        <td><%= p.get("ciudad") %><br><span style="color:var(--hg-ink-muted); font-size:.85rem;"><%= p.get("tipo") %></span></td>
                        <td style="font-variant-numeric:tabular-nums;"><%= precioTxt %></td>
                        <td><%= "venta".equals(operacionP) ? "Venta" : "Arriendo" %></td>
                        <td>
                            <span class="hg-badge--estado hg-badge--<%= estadoP %>" style="position:static; display:inline-block;"><%= estadoP.substring(0,1).toUpperCase() + estadoP.substring(1) %></span><br>
                            <span class="hg-badge--estado <%= activo ? "hg-badge--disponible" : "hg-badge--vendido" %>" style="position:static; display:inline-block; margin-top:4px;"><%= activo ? "Activa" : "Dada de baja" %></span>
                        </td>
                        <td>
                            <a href="<%= request.getContextPath() %>/detalle.jsp?id=<%= p.get("id") %>" target="_blank">Ver ficha</a>
                        </td>
                        <td class="hg-tabla__acciones">
                            <a class="hg-btn hg-btn--ghost hg-btn--sm" href="<%= request.getContextPath() %>/inmobiliaria/propiedad-form.jsp?id=<%= p.get("id") %>">Editar</a>
                            <a class="hg-btn hg-btn--ghost hg-btn--sm" href="<%= request.getContextPath() %>/inmobiliaria/propiedad-galeria.jsp?id=<%= p.get("id") %>">Galeria</a>
                            <form method="post" action="<%= request.getContextPath() %>/inmobiliaria/mis-propiedades.jsp" style="display:inline;">
                                <input type="hidden" name="accion" value="toggleActivo">
                                <input type="hidden" name="idPropiedad" value="<%= p.get("id") %>">
                                <button class="hg-btn hg-btn--sm <%= activo ? "hg-btn--ghost" : "hg-btn--primary" %>" type="submit">
                                    <%= activo ? "Dar de baja" : "Reactivar" %>
                                </button>
                            </form>
                        </td>
                    </tr>
                    <% } %>
                </tbody>
            </table>
        </div>
        <% } %>
    <% } %>
</div>
</body>
</html>
