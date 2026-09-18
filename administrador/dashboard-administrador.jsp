<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%@ page import="java.sql.PreparedStatement, java.sql.ResultSet" %>
<%@ page import="java.util.ArrayList, java.util.List, java.util.Map, java.util.LinkedHashMap" %>
<%
    String[] rolesPermitidos = { "Administrador" };
%>
<%@ include file="/jspf/seguridad.jspf" %>
<%@ include file="/jspf/conexion.jspf" %>
<%@ include file="/jspf/graficos.jspf" %>
<%
    int totalUsuarios = 0, totalPropiedades = 0, totalInmobiliarias = 0, solicitudesPendientes = 0;

    // Mismas 3 consultas ya usadas en administrador/reportes.jsp, reutilizadas
    // aqui para alimentar los graficos del dashboard (disponibilidad por
    // ciudad, citas por estado, solicitudes por inmobiliaria).
    List<Map<String, Object>> porCiudad = new ArrayList<>();
    List<Map<String, Object>> porEstadoCita = new ArrayList<>();
    List<Map<String, Object>> porInmobiliaria = new ArrayList<>();

    if (conexion != null) {
        try (PreparedStatement ps = conexion.prepareStatement("SELECT COUNT(*) FROM usuario");
             ResultSet rs = ps.executeQuery()) { if (rs.next()) totalUsuarios = rs.getInt(1); } catch (Exception ignored) { }

        try (PreparedStatement ps = conexion.prepareStatement("SELECT COUNT(*) FROM propiedad WHERE activo = 1");
             ResultSet rs = ps.executeQuery()) { if (rs.next()) totalPropiedades = rs.getInt(1); } catch (Exception ignored) { }

        try (PreparedStatement ps = conexion.prepareStatement("SELECT COUNT(*) FROM inmobiliaria");
             ResultSet rs = ps.executeQuery()) { if (rs.next()) totalInmobiliarias = rs.getInt(1); } catch (Exception ignored) { }

        try (PreparedStatement ps = conexion.prepareStatement("SELECT COUNT(*) FROM solicitud WHERE estado IN ('pendiente','en_revision')");
             ResultSet rs = ps.executeQuery()) { if (rs.next()) solicitudesPendientes = rs.getInt(1); } catch (Exception ignored) { }

        try (PreparedStatement ps = conexion.prepareStatement(
                "SELECT c.nombre_ciudad, COUNT(*) AS total " +
                "FROM propiedad p INNER JOIN ciudad c ON c.id_ciudad = p.id_ciudad " +
                "WHERE p.estado = 'disponible' AND p.activo = 1 " +
                "GROUP BY c.nombre_ciudad HAVING COUNT(*) >= 1 ORDER BY total DESC");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String, Object> f = new LinkedHashMap<>();
                f.put("etiqueta", rs.getString("nombre_ciudad"));
                f.put("total", rs.getInt("total"));
                porCiudad.add(f);
            }
        } catch (Exception ignored) { }

        try (PreparedStatement ps = conexion.prepareStatement(
                "SELECT estado, COUNT(*) AS total FROM cita GROUP BY estado ORDER BY total DESC");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String, Object> f = new LinkedHashMap<>();
                String estadoCita = rs.getString("estado");
                f.put("etiqueta", estadoCita.substring(0, 1).toUpperCase() + estadoCita.substring(1));
                f.put("total", rs.getInt("total"));
                porEstadoCita.add(f);
            }
        } catch (Exception ignored) { }

        try (PreparedStatement ps = conexion.prepareStatement(
                "SELECT i.nombre_comercial, COUNT(*) AS total " +
                "FROM solicitud s " +
                "INNER JOIN propiedad p ON p.id_propiedad = s.id_propiedad " +
                "INNER JOIN inmobiliaria i ON i.id_inmobiliaria = p.id_inmobiliaria " +
                "GROUP BY i.nombre_comercial ORDER BY total DESC");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String, Object> f = new LinkedHashMap<>();
                f.put("etiqueta", rs.getString("nombre_comercial"));
                f.put("total", rs.getInt("total"));
                porInmobiliaria.add(f);
            }
        } catch (Exception ignored) { }

        try { conexion.close(); } catch (Exception ignored) { }
    }
%><!DOCTYPE html>
<html lang="es">
<head>
    <% String hgTitulo = "Panel de administración"; %>
    <%@ include file="/jspf/head-comun.jspf" %>
</head>
<body>
<%@ include file="/jspf/panel-header.jspf" %>

<div class="hg-panel-body">
    <div class="hg-panel-hero">
        <span class="hg-eyebrow">Panel de administración</span>
        <h1>Hola, <%= session.getAttribute("nombreUsuario") %></h1>
        <p>Visión general de la operación de Hogaria.</p>
    </div>

    <div class="hg-panel-grid">
        <a class="hg-panel-stat" href="<%= request.getContextPath() %>/administrador/usuarios.jsp">
            <div class="hg-panel-stat__icon"><i class="bi bi-people-fill"></i></div>
            <div class="hg-panel-stat__texto"><span>Usuarios registrados</span><strong><%= totalUsuarios %></strong></div>
        </a>
        <a class="hg-panel-stat" href="<%= request.getContextPath() %>/catalogo.jsp">
            <div class="hg-panel-stat__icon"><i class="bi bi-houses-fill"></i></div>
            <div class="hg-panel-stat__texto"><span>Propiedades activas</span><strong><%= totalPropiedades %></strong></div>
        </a>
        <a class="hg-panel-stat" href="<%= request.getContextPath() %>/administrador/reportes.jsp">
            <div class="hg-panel-stat__icon"><i class="bi bi-building-fill"></i></div>
            <div class="hg-panel-stat__texto"><span>Inmobiliarias aliadas</span><strong><%= totalInmobiliarias %></strong></div>
        </a>
        <a class="hg-panel-stat" href="<%= request.getContextPath() %>/administrador/reportes.jsp">
            <div class="hg-panel-stat__icon"><i class="bi bi-clipboard-check-fill"></i></div>
            <div class="hg-panel-stat__texto"><span>Solicitudes por atender</span><strong><%= solicitudesPendientes %></strong></div>
        </a>
    </div>

    <div class="hg-reporte-grid" style="margin-bottom:28px;">
        <div class="hg-panel-card">
            <h3 style="margin-bottom:4px;">Propiedades disponibles por ciudad</h3>
            <p class="hg-reporte-nota">Solo propiedades activas y disponibles</p>
            <% if (porCiudad.isEmpty()) { %>
            <p class="hg-panel-empty" style="padding:20px 0;">Sin datos para mostrar.</p>
            <% } else { %>
            <canvas id="graficoCiudad" role="img" aria-label="Propiedades disponibles por ciudad" height="220"></canvas>
            <% } %>
        </div>

        <div class="hg-panel-card">
            <h3 style="margin-bottom:4px;">Citas por estado</h3>
            <p class="hg-reporte-nota">Todas las citas registradas</p>
            <% if (porEstadoCita.isEmpty()) { %>
            <p class="hg-panel-empty" style="padding:20px 0;">Sin datos para mostrar.</p>
            <% } else { %>
            <canvas id="graficoCitas" role="img" aria-label="Citas por estado" height="220"></canvas>
            <% } %>
        </div>

        <div class="hg-panel-card">
            <h3 style="margin-bottom:4px;">Solicitudes por inmobiliaria</h3>
            <p class="hg-reporte-nota">Total de solicitudes radicadas</p>
            <% if (porInmobiliaria.isEmpty()) { %>
            <p class="hg-panel-empty" style="padding:20px 0;">Sin datos para mostrar.</p>
            <% } else { %>
            <canvas id="graficoInmobiliaria" role="img" aria-label="Solicitudes por inmobiliaria" height="220"></canvas>
            <% } %>
        </div>
    </div>

    <div class="hg-panel-card">
        <h3 class="hg-panel-card__titulo"><i class="bi bi-lightning-charge-fill"></i> Acciones rápidas</h3>
        <div class="hg-quick-actions">
            <a class="hg-quick-action" href="<%= request.getContextPath() %>/administrador/reportes.jsp">
                <i class="bi bi-graph-up-arrow"></i>
                <span>Ver reportes</span>
            </a>
            <a class="hg-quick-action" href="<%= request.getContextPath() %>/administrador/usuarios.jsp">
                <i class="bi bi-people"></i>
                <span>Usuarios y roles</span>
            </a>
            <a class="hg-quick-action" href="<%= request.getContextPath() %>/administrador/catalogos.jsp">
                <i class="bi bi-tags"></i>
                <span>Parametrizar catálogos</span>
            </a>
            <a class="hg-quick-action" href="<%= request.getContextPath() %>/administrador/auditoria.jsp">
                <i class="bi bi-journal-text"></i>
                <span>Consultar auditoría</span>
            </a>
        </div>
    </div>
</div>
<%@ include file="/jspf/scripts-panel.jspf" %>
<% if (!porCiudad.isEmpty() || !porEstadoCita.isEmpty() || !porInmobiliaria.isEmpty()) { %>
<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.4/dist/chart.umd.min.js"></script>
<script>
(function () {
    var colores = hgColoresGrafico();
    Chart.defaults.font.family = "'Inter', 'Segoe UI', sans-serif";
    Chart.defaults.color = colores.textoSuave;

    var elCiudad = document.getElementById('graficoCiudad');
    if (elCiudad) {
        new Chart(elCiudad, {
            type: 'bar',
            data: {
                labels: <%= hgArrayEtiquetasJs(porCiudad, "etiqueta") %>,
                datasets: [{ data: <%= hgArrayValoresJs(porCiudad, "total") %>, backgroundColor: colores.primario, borderRadius: 6, maxBarThickness: 34 }]
            },
            options: {
                plugins: { legend: { display: false } },
                scales: { y: { beginAtZero: true, ticks: { precision: 0 }, grid: { color: colores.borde } }, x: { grid: { display: false } } }
            }
        });
    }

    var elCitas = document.getElementById('graficoCitas');
    if (elCitas) {
        new Chart(elCitas, {
            type: 'doughnut',
            data: {
                labels: <%= hgArrayEtiquetasJs(porEstadoCita, "etiqueta") %>,
                datasets: [{ data: <%= hgArrayValoresJs(porEstadoCita, "total") %>, backgroundColor: colores.serie, borderColor: colores.serie, borderWidth: 1 }]
            },
            options: { plugins: { legend: { position: 'bottom', labels: { boxWidth: 12, padding: 12 } } } }
        });
    }

    var elInmobiliaria = document.getElementById('graficoInmobiliaria');
    if (elInmobiliaria) {
        new Chart(elInmobiliaria, {
            type: 'bar',
            data: {
                labels: <%= hgArrayEtiquetasJs(porInmobiliaria, "etiqueta") %>,
                datasets: [{ data: <%= hgArrayValoresJs(porInmobiliaria, "total") %>, backgroundColor: colores.acento, borderRadius: 6, maxBarThickness: 34 }]
            },
            options: {
                indexAxis: 'y',
                plugins: { legend: { display: false } },
                scales: { x: { beginAtZero: true, ticks: { precision: 0 }, grid: { color: colores.borde } }, y: { grid: { display: false } } }
            }
        });
    }
})();
</script>
<% } %>
</body>
</html>
