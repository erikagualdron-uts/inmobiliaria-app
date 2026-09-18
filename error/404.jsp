<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Pagina no encontrada | Hogaria</title>
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Fraunces:opsz,wght@9..144,600&family=Work+Sans:wght@400;600&display=swap">
    <link rel="stylesheet" href="<%= request.getContextPath() %>/assets/css/estilos.css">
</head>
<body>
<div class="hg-container" style="min-height:80vh; display:flex; align-items:center; justify-content:center; text-align:center;">
    <div>
        <span class="hg-eyebrow">Error 404</span>
        <h1 style="font-size:2.4rem; margin-bottom:12px;">Esta pagina no existe</h1>
        <p style="color:var(--hg-ink-muted); max-width:46ch; margin:0 auto 24px;">
            Puede que el enlace este mal escrito o que la propiedad ya no este disponible.
        </p>
        <a class="hg-btn hg-btn--primary" href="<%= request.getContextPath() %>/index.jsp">Volver al inicio</a>
    </div>
</div>
</body>
</html>
