<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" isErrorPage="true" %>
<%
    // La traza nunca se muestra al usuario final; queda solo en el log del
    // servidor para que el equipo tecnico pueda diagnosticar el problema.
    if (exception != null) {
        exception.printStackTrace();
    }
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <% String hgTitulo = "Algo salió mal"; %>
    <%@ include file="/jspf/head-comun.jspf" %>
</head>
<body>
<div class="hg-container" style="min-height:80vh; display:flex; align-items:center; justify-content:center; text-align:center;">
    <div>
        <span class="hg-eyebrow">Error 500</span>
        <h1 style="font-size:2.4rem; margin-bottom:12px;">Tuvimos un inconveniente</h1>
        <p style="color:var(--hg-ink-muted); max-width:46ch; margin:0 auto 24px;">
            Algo no salió como esperábamos. Ya quedó registrado; por favor intenta nuevamente en unos minutos.
        </p>
        <a class="hg-btn hg-btn--primary" href="<%= request.getContextPath() %>/index.jsp">Volver al inicio</a>
    </div>
</div>
</body>
</html>
