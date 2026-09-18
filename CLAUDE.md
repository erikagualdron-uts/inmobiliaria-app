# Proyecto: Sistema Web de Inmobiliaria (Parcial Práctico – Programación Java)

## Contexto

Parcial práctico individual de la asignatura Programación Java (UTS). El enunciado
completo está en `docs/enunciado.pdf` (consúltalo si necesitas el texto literal de
algún requisito o la tabla de criterios de evaluación).

Objetivo: aplicación web dinámica para la administración de una inmobiliaria ficticia,
con autenticación por roles, gestión de propiedades, citas y solicitudes.

**Nombre de la inmobiliaria: Hogaria.** Úsalo en el branding de la landing page, el
título del sitio, el logo/texto de marca, los correos de ejemplo, los textos de
bienvenida, etc.

## Cómo debes trabajar conmigo

- Antes de cualquier cambio grande (diseñar el modelo de datos, crear la estructura
  del proyecto, construir un módulo nuevo), muéstrame el plan primero y espera mi
  confirmación antes de generar o modificar código.
- Si te falta información para avanzar (credenciales de MySQL, nombre de la base de
  datos, puerto, algún dato de negocio), pregúntame explícitamente antes de asumir
  un valor por defecto.
- Ve construyendo por módulos completos y probables de compilar/ejecutar, no dejes
  código a medias entre un paso y otro.

## Restricciones técnicas obligatorias

- **Solo JSP puro y archivos JSPF.** No generar Servlets, clases DAO, ni ningún
  archivo `.java`. Toda la lógica (incluyendo conexión JDBC y consultas SQL) va en
  scriptlets `<% %>` dentro de JSP/JSPF.
- La conexión a la base de datos debe estar centralizada en un único JSPF (por
  ejemplo `conexion.jspf`), incluido con `<%@ include file="..." %>` en los JSP que
  la necesiten. La cadena de conexión no debe repetirse en cada archivo.
- Base de datos: **MySQL local**. Agrega el conector MySQL Connector/J (.jar) en
  `WEB-INF/lib`.
- No te limites a generarme los scripts `.sql`: ejecútalos directamente contra mi
  base de datos MySQL local desde la terminal (con el cliente `mysql` o el
  equivalente que tengas disponible, como el de XAMPP), para que las tablas y los
  datos de prueba queden creados de una vez y visibles en phpMyAdmin al abrirlo.
  Pídeme las credenciales (usuario, contraseña, puerto, nombre de la base de datos)
  antes de ejecutar cualquier script.
- Frontend: HTML5, CSS3, JavaScript y Bootstrap. Diseño responsivo (computador,
  tableta, celular).
- Servidor de aplicaciones: Apache Tomcat.
- Contraseñas cifradas con BCrypt, PBKDF2 o SHA-256 con salt. Prohibido texto plano.
- Sesión con `HttpSession`, guardando id de usuario y rol(es) asignados.
- Debe existir control de acceso a rutas privadas: si un usuario no autenticado, o
  autenticado sin el rol requerido, intenta entrar escribiendo la URL directamente,
  debe ser redirigido a una página de acceso denegado. Como no se usan Servlets,
  implementa esta validación al inicio de cada JSP protegido (o en un JSPF de
  seguridad incluido al principio de cada página privada).
- La validación de rol es obligatoria en el servidor, no basta con ocultar opciones
  en la vista.
- Captura los errores de duplicado (por ejemplo, correo ya registrado) y muestra un
  mensaje claro al usuario, nunca una excepción cruda de Java.
- Validaciones generales en todos los formularios: campos obligatorios, formatos
  válidos (correo, teléfono, precio, fechas), y manejo de cualquier excepción SQL
  (no solo duplicados) con mensajes de error comprensibles para el usuario final,
  nunca mostrando la traza de la excepción.

## Roles del sistema

1. **Visitante** (no autenticado): landing page, catálogo público, detalle de
   propiedades sin datos de contacto completos.
2. **Cliente**: buscar/filtrar propiedades, favoritos, agendar citas, radicar
   documentos, consultar estado de trámites, editar su perfil.
3. **Inmobiliaria (agente)**: publicar/editar/dar de baja propiedades, gestionar
   galería e imágenes, características, atender citas, aprobar/rechazar
   documentación, generar reportes de ventas/arriendos.
4. **Administrador**: acceso total, gestión de usuarios y roles, activar/inactivar
   cuentas, parametrizar catálogos (tipos de propiedad, ciudades, características),
   consultar auditoría.

## Módulos mínimos

- Landing page pública con buscador rápido y propiedades destacadas.
- Autenticación: registro, login, logout, redirección automática según rol.
- Dashboards diferenciados por rol.
- Gestión de propiedades: listado con filtros, ficha de detalle con galería,
  formulario de alta/edición, baja lógica del inmueble.
- Gestión de visitas y solicitudes: agendamiento de citas, radicación de documentos,
  aprobación/rechazo por parte de la inmobiliaria.
- Reportes con SQL multi-tabla: propiedades disponibles por ciudad, citas por
  estado, solicitudes por inmobiliaria.

## Modelo de datos (obligatorio, se diseña antes de programar)

Entregables del modelo: MER, modelo relacional normalizado a 3FN, diccionario de
datos, script DDL (con PK, FK y restricciones) y script DML con datos de prueba
(mínimo 10 registros por tabla principal).

- **Relación 1:1**: `usuario` (credenciales y estado de cuenta) y `perfil` (datos
  personales), con `perfil.id_usuario` como `UNIQUE`.
- **Relación 1:N**: inmobiliaria → propiedades, propiedad → imágenes, cliente →
  citas. La FK va en el lado "muchos", con `ON DELETE`/`ON UPDATE` justificados.
- **Relación N:M**: `usuario_rol` (usuario ↔ rol) y `propiedad_caracteristica`
  (propiedad ↔ característica), ambas con llave primaria compuesta.
- Al menos 3 campos `UNIQUE`: `usuario.correo`, `propiedad.matricula_inmobiliaria`,
  `perfil.id_usuario` / `usuario_rol(id_usuario, id_rol)`, y sugerida
  `cita(id_propiedad, fecha_hora)`.
- Entidades sugeridas: `rol`, `usuario`, `usuario_rol`, `perfil`, `inmobiliaria`,
  `ciudad`, `tipo_propiedad`, `propiedad`, `imagen_propiedad`, `caracteristica`,
  `propiedad_caracteristica`, `cita`, `solicitud`, `documento_solicitud`,
  `favorito`, `auditoria`.

## Consultas SQL obligatorias (mínimo 5, documentadas)

- 2 consultas con `INNER JOIN` entre 3 o más tablas.
- 1 consulta que resuelva una relación N:M.
- 1 consulta con `LEFT JOIN`.
- 1 consulta de agregación con `GROUP BY` y `HAVING` para un reporte.

## Imágenes de propiedades

Selecciona tú las fotos, tomadas de bancos gratuitos de uso libre (Unsplash, Pexels
o similares), variadas según el tipo de propiedad (casa, apartamento, local,
oficina, terreno) y sin que se repitan entre registros. Guárdalas como URL en la
base de datos, no como archivo binario.

## Documentación requerida

Además del MER, el modelo relacional, el diccionario de datos y los scripts
DDL/DML, se debe entregar un **diagrama de casos de uso** que muestre las
interacciones de cada rol (visitante, cliente, inmobiliaria, administrador) con
el sistema. El MER y el modelo relacional deben poder exportarse como imagen o
PDF para la entrega final.

## Metodología y Git

No se documenta Scrum (sprints, planning, review, retrospective, tablero): el
proyecto es individual y el profesor eximió de esto a quienes trabajan solos.

Sí se requiere repositorio Git público, con **commits frecuentes y descriptivos**
a medida que avanzamos (no todo en un solo commit al final). Cada vez que
terminemos una parte funcional (modelo de datos, autenticación, un módulo CRUD,
etc.), haz un commit con un mensaje claro de lo que se agregó.

## Valor agregado (libertad creativa)

Primero deben quedar cumplidos todos los requisitos obligatorios de este documento.
Una vez estén cubiertos, tienes libertad para proponerme funcionalidades o detalles
adicionales que mejoren el proyecto (por ejemplo: comparador de propiedades, mapa
de ubicación, notificaciones, chat de contacto, modo oscuro, animaciones sutiles,
estadísticas visuales en el dashboard del administrador, etc.). No los implementes
directamente: primero dime qué se te ocurre y por qué suma valor, y yo decido si
lo incluimos antes de que generes el código.

## Diseño e interfaz

Diseño visual agradable, moderno e innovador, no una plantilla genérica de
Bootstrap por defecto:

- Paleta de colores coherente y profesional, acorde a una inmobiliaria.
- Tipografía y jerarquía visual claras, buen uso de espacios en blanco.
- Landing page atractiva: hero section con buscador destacado, tarjetas visuales
  de propiedades destacadas (imagen, precio, ubicación, características clave).
- Detalles de interacción (hover states, transiciones suaves, iconografía
  consistente) sin sobrecargar de animaciones.
- Dashboards por rol bien organizados: tarjetas, indicadores, estados visuales
  (badges de "disponible", "pendiente", "aprobado", etc.), no solo tablas planas.
- Experiencia consistente y usable en móvil, tableta y escritorio.