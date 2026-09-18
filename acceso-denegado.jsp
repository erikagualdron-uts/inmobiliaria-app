<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<%
    boolean haySesion = session.getAttribute("idUsuario") != null;
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <% String hgTitulo = "Acceso restringido"; %>
    <%@ include file="/jspf/head-comun.jspf" %>
</head>
<body>
<div class="hg-container" style="min-height:80vh; display:flex; align-items:center; justify-content:center; text-align:center;">
    <div>
        <span class="hg-eyebrow">Acceso restringido</span>
        <h1 style="font-size:2.4rem; margin-bottom:12px;">No tienes permiso para ver esta pagina</h1>
        <p style="color:var(--hg-ink-muted); max-width:46ch; margin:0 auto 24px;">
            <% if (haySesion) { %>
                Tu cuenta no tiene el rol necesario para acceder a esta seccion.
            <% } else { %>
                Necesitas iniciar sesion con una cuenta autorizada para ver esta seccion.
            <% } %>
        </p>
        <div style="display:flex; gap:12px; justify-content:center; flex-wrap:wrap;">
            <a class="hg-btn hg-btn--primary" href="<%= request.getContextPath() %>/index.jsp">Volver al inicio</a>
            <% if (!haySesion) { %>
            <a class="hg-btn hg-btn--ghost" href="<%= request.getContextPath() %>/login.jsp">Iniciar sesion</a>
            <% } %>
        </div>
    </div>
</div>
</body>
</html>
