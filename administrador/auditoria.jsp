<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ page import="java.sql.PreparedStatement, java.sql.ResultSet" %>
<%@ page import="java.time.format.DateTimeFormatter" %>
<%@ page import="java.util.ArrayList, java.util.List, java.util.Map, java.util.LinkedHashMap" %>
<%
    String[] rolesPermitidos = { "Administrador" };
%>
<%@ include file="/jspf/seguridad.jspf" %>
<%@ include file="/jspf/conexion.jspf" %>
<%
    List<Map<String, Object>> eventos = new ArrayList<>();
    List<String> accionesCatalogo = new ArrayList<>();
    if (conexion != null) {
        try (PreparedStatement ps = conexion.prepareStatement(
                "SELECT a.fecha_hora, a.accion, a.tabla_afectada, a.descripcion, a.ip_origen, " +
                "       u.correo, per.nombres, per.apellidos " +
                "FROM auditoria a " +
                "LEFT JOIN usuario u ON u.id_usuario = a.id_usuario " +
                "LEFT JOIN perfil per ON per.id_usuario = a.id_usuario " +
                "ORDER BY a.fecha_hora DESC LIMIT 200");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String, Object> f = new LinkedHashMap<>();
                f.put("fecha", rs.getTimestamp("fecha_hora"));
                f.put("accion", rs.getString("accion"));
                f.put("tabla", rs.getString("tabla_afectada"));
                f.put("descripcion", rs.getString("descripcion"));
                f.put("ip", rs.getString("ip_origen"));
                f.put("correo", rs.getString("correo"));
                String nombres = rs.getString("nombres"), apellidos = rs.getString("apellidos");
                f.put("nombreCompleto", nombres != null ? nombres + " " + apellidos : null);
                eventos.add(f);
            }
        } catch (Exception ignored) { }

        try (PreparedStatement ps = conexion.prepareStatement("SELECT DISTINCT accion FROM auditoria ORDER BY accion");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) accionesCatalogo.add(rs.getString(1));
        } catch (Exception ignored) { }

        try { conexion.close(); } catch (Exception ignored) { }
    }
    DateTimeFormatter formatoFecha = DateTimeFormatter.ofPattern("dd/MM/yyyy hh:mm a");
    DateTimeFormatter formatoFechaISO = DateTimeFormatter.ofPattern("yyyy-MM-dd");
%><!DOCTYPE html>
<html lang="es">
<head>
    <% String hgTitulo = "Auditoria"; %>
    <%@ include file="/jspf/head-comun.jspf" %>
</head>
<body>
<%@ include file="/jspf/panel-header.jspf" %>

<div class="hg-panel-body">
    <div class="hg-panel-hero">
        <span class="hg-eyebrow">Panel de administracion</span>
        <h1>Auditoria del sistema</h1>
        <p><a href="<%= request.getContextPath() %>/administrador/dashboard-administrador.jsp">&larr; Volver a mi panel</a></p>
    </div>

    <% if (eventos.isEmpty()) { %>
    <div class="hg-panel-card">
        <div class="hg-panel-empty">
            <div class="hg-panel-empty__icon"><i class="bi bi-journal-text"></i></div>
            <p>Aun no hay eventos de auditoria registrados.</p>
        </div>
    </div>
    <% } else { %>

    <div class="hg-panel-card" style="margin-bottom:18px;">
        <div class="hg-panel-grid" style="margin-bottom:0; align-items:end;">
            <div class="hg-field">
                <label for="filtroUsuario"><i class="bi bi-search"></i> Buscar por usuario (correo o nombre)</label>
                <input class="form-control" type="text" id="filtroUsuario" placeholder="Ej. Laura, admin@hogaria.com...">
            </div>
            <div class="hg-field">
                <label for="filtroAccion">Tipo de accion</label>
                <select class="form-select" id="filtroAccion">
                    <option value="">Todas las acciones</option>
                    <% for (String accionRaw : accionesCatalogo) { %>
                    <option value="<%= accionRaw %>"><%= accionEtiqueta(accionRaw) %></option>
                    <% } %>
                </select>
            </div>
            <div class="hg-field">
                <label for="filtroDesde">Desde</label>
                <input class="form-control" type="date" id="filtroDesde">
            </div>
            <div class="hg-field">
                <label for="filtroHasta">Hasta</label>
                <input class="form-control" type="date" id="filtroHasta">
            </div>
        </div>
    </div>

    <div class="hg-panel-card" style="padding:0; overflow-x:auto;">
        <table class="hg-tabla">
            <thead><tr><th>Fecha</th><th>Usuario</th><th>Accion</th><th>Tabla</th><th>Descripcion</th><th>IP</th></tr></thead>
            <tbody id="cuerpoAuditoria">
                <% for (Map<String, Object> e : eventos) {
                    String accionRaw = (String) e.get("accion");
                    String correoE = (String) e.get("correo");
                    String nombreE = (String) e.get("nombreCompleto");
                    String textoUsuario = ((nombreE != null ? nombreE : "") + " " + (correoE != null ? correoE : "")).toLowerCase();
                    String fechaISO = ((java.sql.Timestamp) e.get("fecha")).toLocalDateTime().format(formatoFechaISO);
                %>
                <tr data-usuario="<%= textoUsuario %>" data-accion="<%= accionRaw %>" data-fecha="<%= fechaISO %>">
                    <td style="font-variant-numeric:tabular-nums; white-space:nowrap;"><%= ((java.sql.Timestamp) e.get("fecha")).toLocalDateTime().format(formatoFecha) %></td>
                    <td>
                        <% if (nombreE != null) { %><strong><%= nombreE %></strong><br><span style="color:var(--hg-ink-muted); font-size:.82rem;"><%= correoE %></span>
                        <% } else { %><%= correoE != null ? correoE : "(usuario eliminado)" %><% } %>
                    </td>
                    <td><span class="hg-badge--estado hg-badge--accion-<%= accionColorClase(accionRaw) %>" style="position:static; display:inline-block;"><%= accionEtiqueta(accionRaw) %></span></td>
                    <td style="color:var(--hg-ink-muted);"><%= e.get("tabla") != null ? e.get("tabla") : "-" %></td>
                    <td style="color:var(--hg-ink-muted); font-size:.88rem;"><%= e.get("descripcion") != null ? e.get("descripcion") : "-" %></td>
                    <td style="color:var(--hg-ink-muted); font-size:.82rem;"><%= e.get("ip") != null ? e.get("ip") : "-" %></td>
                </tr>
                <% } %>
            </tbody>
        </table>
        <div id="auditoriaSinResultados" class="hg-panel-empty" style="padding:32px 20px;" hidden>
            <div class="hg-panel-empty__icon"><i class="bi bi-search"></i></div>
            <p>No se encontraron eventos con esos filtros.</p>
        </div>
    </div>
    <% } %>
</div>
<%@ include file="/jspf/scripts-panel.jspf" %>
<% if (!eventos.isEmpty()) { %>
<script>
(function () {
    // Filtrado 100% en el cliente sobre las filas ya renderizadas por el
    // JSP (igual que en administrador/usuarios.jsp): cada <tr> trae
    // data-usuario/data-accion/data-fecha y los tres filtros se combinan
    // con AND en cada tecla/cambio, sin recargar la pagina.
    var campoUsuario = document.getElementById('filtroUsuario');
    var campoAccion = document.getElementById('filtroAccion');
    var campoDesde = document.getElementById('filtroDesde');
    var campoHasta = document.getElementById('filtroHasta');
    var filas = document.querySelectorAll('#cuerpoAuditoria tr');
    var sinResultados = document.getElementById('auditoriaSinResultados');

    function aplicarFiltros() {
        var texto = campoUsuario.value.trim().toLowerCase();
        var accion = campoAccion.value;
        var desde = campoDesde.value;
        var hasta = campoHasta.value;
        var visibles = 0;

        filas.forEach(function (fila) {
            var fecha = fila.getAttribute('data-fecha');
            var coincideUsuario = !texto || fila.getAttribute('data-usuario').indexOf(texto) !== -1;
            var coincideAccion = !accion || fila.getAttribute('data-accion') === accion;
            var coincideDesde = !desde || fecha >= desde;
            var coincideHasta = !hasta || fecha <= hasta;
            var visible = coincideUsuario && coincideAccion && coincideDesde && coincideHasta;
            fila.hidden = !visible;
            if (visible) visibles++;
        });

        sinResultados.hidden = visibles !== 0;
    }

    campoUsuario.addEventListener('input', aplicarFiltros);
    campoAccion.addEventListener('change', aplicarFiltros);
    campoDesde.addEventListener('change', aplicarFiltros);
    campoHasta.addEventListener('change', aplicarFiltros);
})();
</script>
<% } %>
</body>
</html>
<%!
    // =========================================================================
    // Traduce el valor tecnico de auditoria.accion a texto legible y a una
    // clase de color semantica ya usada en el resto de la app (ok/warn/off)
    // mas una categoria neutra "info" para eventos de solo lectura o de
    // cambios administrativos sin una connotacion positiva/negativa clara.
    // Cualquier accion nueva que no este en el mapa cae en un fallback
    // legible en vez de romper la pagina.
    // =========================================================================
    private String accionEtiqueta(String accion) {
        if (accion == null) return "-";
        switch (accion) {
            case "login": return "Inicio de sesion";
            case "registro_usuario": return "Registro de usuario";
            case "creacion_propiedad": return "Creacion de propiedad";
            case "actualizacion_propiedad": return "Actualizacion de propiedad";
            case "aprobacion_solicitud": return "Aprobacion de solicitud";
            case "rechazo_solicitud": return "Rechazo de solicitud";
            case "asignacion_rol": return "Asignacion de rol";
            case "bloqueo_cuenta": return "Bloqueo de cuenta";
            case "radicacion_documento": return "Radicacion de documento";
            case "consulta_auditoria": return "Consulta de auditoria";
            default: return accion.replace('_', ' ');
        }
    }

    private String accionColorClase(String accion) {
        if (accion == null) return "info";
        switch (accion) {
            case "creacion_propiedad":
            case "aprobacion_solicitud":
            case "registro_usuario":
                return "ok";
            case "rechazo_solicitud":
            case "bloqueo_cuenta":
                return "off";
            case "radicacion_documento":
                return "warn";
            default:
                return "info";
        }
    }
%>
