<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ page import="java.sql.PreparedStatement, java.sql.ResultSet" %>
<%@ page import="java.util.ArrayList, java.util.List, java.util.Map, java.util.LinkedHashMap" %>
<%
    String[] rolesPermitidos = { "Inmobiliaria" };
%>
<%@ include file="/jspf/seguridad.jspf" %>
<%@ include file="/jspf/conexion.jspf" %>
<%@ include file="/jspf/graficos.jspf" %>
<%
    int idUsuario = (Integer) session.getAttribute("idUsuario");
    Integer idInmobiliaria = null;
    String nombreInmobiliaria = null;
    int totalPropiedades = 0, citasPendientes = 0, solicitudesPendientes = 0;

    // Mismas 2 consultas ya usadas en inmobiliaria/reportes.jsp, reutilizadas
    // aqui para los graficos del dashboard (propiedades por estado y
    // solicitudes aprobadas por tipo, ambas filtradas por tu inmobiliaria).
    List<Map<String, Object>> porEstado = new ArrayList<>();
    List<Map<String, Object>> solicitudesPorTipo = new ArrayList<>();

    if (conexion != null) {
        try (PreparedStatement ps = conexion.prepareStatement(
                "SELECT u.id_inmobiliaria, i.nombre_comercial FROM usuario u " +
                "LEFT JOIN inmobiliaria i ON i.id_inmobiliaria = u.id_inmobiliaria WHERE u.id_usuario = ?")) {
            ps.setInt(1, idUsuario);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    int idIn = rs.getInt("id_inmobiliaria");
                    if (!rs.wasNull()) idInmobiliaria = idIn;
                    nombreInmobiliaria = rs.getString("nombre_comercial");
                }
            }
        } catch (Exception ignored) { }

        if (idInmobiliaria != null) {
            try (PreparedStatement ps = conexion.prepareStatement(
                    "SELECT COUNT(*) FROM propiedad WHERE id_inmobiliaria = ? AND activo = 1")) {
                ps.setInt(1, idInmobiliaria);
                try (ResultSet rs = ps.executeQuery()) { if (rs.next()) totalPropiedades = rs.getInt(1); }
            } catch (Exception ignored) { }

            try (PreparedStatement ps = conexion.prepareStatement(
                    "SELECT COUNT(*) FROM cita c INNER JOIN propiedad p ON p.id_propiedad = c.id_propiedad " +
                    "WHERE p.id_inmobiliaria = ? AND c.estado = 'pendiente'")) {
                ps.setInt(1, idInmobiliaria);
                try (ResultSet rs = ps.executeQuery()) { if (rs.next()) citasPendientes = rs.getInt(1); }
            } catch (Exception ignored) { }

            try (PreparedStatement ps = conexion.prepareStatement(
                    "SELECT COUNT(*) FROM solicitud s INNER JOIN propiedad p ON p.id_propiedad = s.id_propiedad " +
                    "WHERE p.id_inmobiliaria = ? AND s.estado IN ('pendiente','en_revision')")) {
                ps.setInt(1, idInmobiliaria);
                try (ResultSet rs = ps.executeQuery()) { if (rs.next()) solicitudesPendientes = rs.getInt(1); }
            } catch (Exception ignored) { }

            try (PreparedStatement ps = conexion.prepareStatement(
                    "SELECT estado, COUNT(*) AS total FROM propiedad WHERE id_inmobiliaria = ? GROUP BY estado ORDER BY total DESC")) {
                ps.setInt(1, idInmobiliaria);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        Map<String, Object> f = new LinkedHashMap<>();
                        String estadoP = rs.getString("estado");
                        f.put("etiqueta", estadoP.substring(0, 1).toUpperCase() + estadoP.substring(1));
                        f.put("total", rs.getInt("total"));
                        porEstado.add(f);
                    }
                }
            } catch (Exception ignored) { }

            try (PreparedStatement ps = conexion.prepareStatement(
                    "SELECT s.tipo_solicitud, COUNT(*) AS total FROM solicitud s " +
                    "INNER JOIN propiedad p ON p.id_propiedad = s.id_propiedad " +
                    "WHERE p.id_inmobiliaria = ? AND s.estado = 'aprobada' " +
                    "GROUP BY s.tipo_solicitud")) {
                ps.setInt(1, idInmobiliaria);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        Map<String, Object> f = new LinkedHashMap<>();
                        f.put("etiqueta", "compra".equals(rs.getString(1)) ? "Compra" : "Arriendo");
                        f.put("total", rs.getInt("total"));
                        solicitudesPorTipo.add(f);
                    }
                }
            } catch (Exception ignored) { }
        }

        try { conexion.close(); } catch (Exception ignored) { }
    }
%><!DOCTYPE html>
<html lang="es">
<head>
    <% String hgTitulo = "Panel de la inmobiliaria"; %>
    <%@ include file="/jspf/head-comun.jspf" %>
</head>
<body>
<%@ include file="/jspf/panel-header.jspf" %>

<div class="hg-panel-body">
    <div class="hg-panel-hero">
        <span class="hg-eyebrow">Panel de inmobiliaria</span>
        <h1>Hola, <%= session.getAttribute("nombreUsuario") %></h1>
        <p><% if (nombreInmobiliaria != null) { %>Agente de <strong><%= nombreInmobiliaria %></strong>.<% } else { %>Tu cuenta aún no está asociada a ninguna inmobiliaria; contacta al administrador.<% } %></p>
    </div>

    <div class="hg-panel-grid">
        <a class="hg-panel-stat" href="<%= request.getContextPath() %>/inmobiliaria/mis-propiedades.jsp">
            <div class="hg-panel-stat__icon"><i class="bi bi-houses-fill"></i></div>
            <div class="hg-panel-stat__texto"><span>Propiedades activas</span><strong><%= totalPropiedades %></strong></div>
        </a>
        <a class="hg-panel-stat" href="<%= request.getContextPath() %>/inmobiliaria/citas-recibidas.jsp">
            <div class="hg-panel-stat__icon"><i class="bi bi-calendar-check-fill"></i></div>
            <div class="hg-panel-stat__texto"><span>Citas pendientes por atender</span><strong><%= citasPendientes %></strong></div>
        </a>
        <a class="hg-panel-stat" href="<%= request.getContextPath() %>/inmobiliaria/solicitudes-recibidas.jsp">
            <div class="hg-panel-stat__icon"><i class="bi bi-clipboard-check-fill"></i></div>
            <div class="hg-panel-stat__texto"><span>Solicitudes por revisar</span><strong><%= solicitudesPendientes %></strong></div>
        </a>
    </div>

    <% if (!porEstado.isEmpty() || !solicitudesPorTipo.isEmpty()) { %>
    <div class="hg-reporte-grid" style="grid-template-columns:repeat(2, minmax(0,1fr)); margin-bottom:28px;">
        <div class="hg-panel-card">
            <h3 style="margin-bottom:4px;">Propiedades por estado</h3>
            <p class="hg-reporte-nota">Todas tus propiedades, por estado comercial</p>
            <% if (porEstado.isEmpty()) { %>
            <p class="hg-panel-empty" style="padding:20px 0;">Sin datos para mostrar.</p>
            <% } else { %>
            <canvas id="graficoPropiedadesEstado" role="img" aria-label="Propiedades por estado" height="220"></canvas>
            <% } %>
        </div>
        <div class="hg-panel-card">
            <h3 style="margin-bottom:4px;">Solicitudes aprobadas por tipo</h3>
            <p class="hg-reporte-nota">Compra vs. arriendo</p>
            <% if (solicitudesPorTipo.isEmpty()) { %>
            <p class="hg-panel-empty" style="padding:20px 0;">Sin datos para mostrar.</p>
            <% } else { %>
            <canvas id="graficoSolicitudesTipo" role="img" aria-label="Solicitudes aprobadas por tipo" height="220"></canvas>
            <% } %>
        </div>
    </div>
    <% } %>

    <div class="hg-panel-card">
        <h3 class="hg-panel-card__titulo"><i class="bi bi-lightning-charge-fill"></i> Acciones rápidas</h3>
        <div class="hg-quick-actions">
            <a class="hg-quick-action" href="<%= request.getContextPath() %>/inmobiliaria/propiedad-form.jsp">
                <i class="bi bi-plus-circle"></i>
                <span>Publicar propiedad</span>
            </a>
            <a class="hg-quick-action" href="<%= request.getContextPath() %>/inmobiliaria/mis-propiedades.jsp">
                <i class="bi bi-houses"></i>
                <span>Mis propiedades</span>
            </a>
            <a class="hg-quick-action" href="<%= request.getContextPath() %>/inmobiliaria/reportes.jsp">
                <i class="bi bi-graph-up-arrow"></i>
                <span>Reportes de ventas</span>
            </a>
            <a class="hg-quick-action" href="<%= request.getContextPath() %>/catalogo.jsp" target="_blank">
                <i class="bi bi-eye"></i>
                <span>Ver catálogo público</span>
            </a>
        </div>
    </div>
</div>
<%@ include file="/jspf/scripts-panel.jspf" %>
<% if (!porEstado.isEmpty() || !solicitudesPorTipo.isEmpty()) { %>
<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.4/dist/chart.umd.min.js"></script>
<script>
(function () {
    var colores = hgColoresGrafico();
    Chart.defaults.font.family = "'Inter', 'Segoe UI', sans-serif";
    Chart.defaults.color = colores.textoSuave;

    var elEstado = document.getElementById('graficoPropiedadesEstado');
    if (elEstado) {
        new Chart(elEstado, {
            type: 'doughnut',
            data: {
                labels: <%= hgArrayEtiquetasJs(porEstado, "etiqueta") %>,
                datasets: [{ data: <%= hgArrayValoresJs(porEstado, "total") %>, backgroundColor: colores.serie, borderColor: colores.serie, borderWidth: 1 }]
            },
            options: { plugins: { legend: { position: 'bottom', labels: { boxWidth: 12, padding: 12 } } } }
        });
    }

    var elTipo = document.getElementById('graficoSolicitudesTipo');
    if (elTipo) {
        new Chart(elTipo, {
            type: 'bar',
            data: {
                labels: <%= hgArrayEtiquetasJs(solicitudesPorTipo, "etiqueta") %>,
                datasets: [{ data: <%= hgArrayValoresJs(solicitudesPorTipo, "total") %>, backgroundColor: [colores.primario, colores.acento], borderRadius: 6, maxBarThickness: 48 }]
            },
            options: {
                plugins: { legend: { display: false } },
                scales: { y: { beginAtZero: true, ticks: { precision: 0 }, grid: { color: colores.borde } }, x: { grid: { display: false } } }
            }
        });
    }
})();
</script>
<% } %>
</body>
</html>
