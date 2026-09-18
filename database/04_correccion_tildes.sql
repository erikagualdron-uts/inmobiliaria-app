-- =====================================================================
-- Hogaria - Correccion de tildes y enes faltantes en los datos de prueba
-- Corrige por completo (no solo nombres de ciudad) los valores de texto
-- insertados por 02_dml_hogaria.sql y 03_dml_propiedades_adicionales.sql
-- que se habian escrito sin acentos ni ñ. Es un script de migracion
-- puntual: 02 y 03 ya quedan corregidos de raiz para instalaciones
-- nuevas, este archivo deja consistente una base de datos que ya tenia
-- los datos sembrados con la ortografia anterior.
-- =====================================================================

USE hogaria_db;

-- 1. ROL
UPDATE rol SET descripcion = 'Navega el catálogo público sin autenticarse.' WHERE nombre_rol = 'Visitante';
UPDATE rol SET descripcion = 'Agente que publica y administra propiedades y trámites.' WHERE nombre_rol = 'Inmobiliaria';
UPDATE rol SET descripcion = 'Acceso total: usuarios, roles, catálogos y auditoría.' WHERE nombre_rol = 'Administrador';

-- 2. CIUDAD
UPDATE ciudad SET nombre_ciudad = 'Girón' WHERE nombre_ciudad = 'Giron';
UPDATE ciudad SET nombre_ciudad = 'Bogotá' WHERE nombre_ciudad = 'Bogota';
UPDATE ciudad SET nombre_ciudad = 'Medellín' WHERE nombre_ciudad = 'Medellin';
UPDATE ciudad SET departamento = 'Atlántico' WHERE departamento = 'Atlantico';
UPDATE ciudad SET departamento = 'Bolívar' WHERE departamento = 'Bolivar';

-- 4. CARACTERISTICA
UPDATE caracteristica SET nombre_caracteristica = 'Jardín' WHERE nombre_caracteristica = 'Jardin';
UPDATE caracteristica SET nombre_caracteristica = 'Balcón' WHERE nombre_caracteristica = 'Balcon';

-- 5. INMOBILIARIA
UPDATE inmobiliaria SET nombre_comercial = 'Raíces Inmobiliaria' WHERE nombre_comercial = 'Raices Inmobiliaria';
UPDATE inmobiliaria SET direccion = 'Cra 43A #10-20, Medellín' WHERE direccion = 'Cra 43A #10-20, Medellin';

-- 8. PERFIL
UPDATE perfil SET nombres = 'Andrés' WHERE id_usuario = 4;
UPDATE perfil SET nombres = 'María' WHERE id_usuario = 7;
UPDATE perfil SET apellidos = 'Martínez Rojas' WHERE id_usuario = 1;
UPDATE perfil SET apellidos = 'Pinzón Duarte' WHERE id_usuario = 2;
UPDATE perfil SET apellidos = 'Gómez Rueda' WHERE id_usuario = 3;
UPDATE perfil SET apellidos = 'Castañeda Ríos', direccion = 'Cra 43A #10-20, Medellín' WHERE id_usuario = 4;
UPDATE perfil SET apellidos = 'Ortiz Marín' WHERE id_usuario = 5;
UPDATE perfil SET apellidos = 'Pérez López' WHERE id_usuario = 6;
UPDATE perfil SET apellidos = 'Rodríguez Sánchez' WHERE id_usuario = 7;
UPDATE perfil SET apellidos = 'Vargas Cortés' WHERE id_usuario = 8;
UPDATE perfil SET direccion = 'Cra 15 #33-20, Bogotá' WHERE id_usuario = 9;
UPDATE perfil SET direccion = 'Cl 70 #52-30, Medellín' WHERE id_usuario = 10;
UPDATE perfil SET apellidos = 'Cárdenas Niño' WHERE id_usuario = 11;

-- 9. PROPIEDAD (identificadas por matricula_inmobiliaria, UNIQUE y estable)
UPDATE propiedad SET titulo = 'Casa campestre en Cañaveral' WHERE matricula_inmobiliaria = 'MI-BGA-0001';
UPDATE propiedad SET titulo = 'Apartamento moderno en Cañaveral Real' WHERE matricula_inmobiliaria = 'MI-FLB-0002';
UPDATE propiedad SET direccion = 'Cra 13 #58-20, Bogotá' WHERE matricula_inmobiliaria = 'MI-BOG-0004';
UPDATE propiedad SET direccion = 'Cl 10 #35-40, Medellín' WHERE matricula_inmobiliaria = 'MI-MED-0005';
UPDATE propiedad SET
    descripcion = 'Apartamento en piso alto con vista panorámica y excelente iluminación.',
    direccion = 'Cra 76 #34-10, Medellín'
    WHERE matricula_inmobiliaria = 'MI-MED-0006';
UPDATE propiedad SET descripcion = 'Oficina lista para operar, con recepción y sala de juntas independiente.' WHERE matricula_inmobiliaria = 'MI-CAL-0007';
UPDATE propiedad SET direccion = 'Vía al Mar Km 5, Barranquilla' WHERE matricula_inmobiliaria = 'MI-BAQ-0008';
UPDATE propiedad SET
    titulo = 'Lote urbanizable en Girón',
    descripcion = 'Lote plano con servicios cercanos, ideal para proyecto de vivienda o inversión.',
    direccion = 'Vereda Chocoa, Girón'
    WHERE matricula_inmobiliaria = 'MI-GIR-0010';
UPDATE propiedad SET
    titulo = 'Casa finca con vista a las montañas',
    descripcion = 'Casa finca con vista panorámica, árboles frutales y amplio jardín.'
    WHERE matricula_inmobiliaria = 'MI-PIE-0011';
UPDATE propiedad SET
    titulo = 'Local esquinero en Niquía',
    descripcion = 'Local esquinero con buena visibilidad, cerca a la estación del metro.'
    WHERE matricula_inmobiliaria = 'MI-BEL-0012';
UPDATE propiedad SET titulo = 'Casa colonial en el centro histórico' WHERE matricula_inmobiliaria = 'MI-CTG-0014';
UPDATE propiedad SET descripcion = 'Oficina lista para operar, edificio con portería y parqueadero de visitantes.' WHERE matricula_inmobiliaria = 'MI-BGA-0015';
UPDATE propiedad SET
    descripcion = 'Local esquinero de alto flujo peatonal, zona gastronómica y comercial.',
    direccion = 'Cra 37 #8A-20, Medellín'
    WHERE matricula_inmobiliaria = 'MI-MED-0016';

-- 12. CITA
UPDATE cita SET observaciones = 'Cliente reprogramará para otra fecha.' WHERE observaciones = 'Cliente reprogramara para otra fecha.';

-- 13. SOLICITUD
UPDATE solicitud SET observaciones = 'Documentación completa y verificada.' WHERE observaciones = 'Documentacion completa y verificada.';
UPDATE solicitud SET observaciones = 'Depósito de garantía recibido.' WHERE observaciones = 'Deposito de garantia recibido.';

-- 14. DOCUMENTO_SOLICITUD
UPDATE documento_solicitud SET nombre_documento = 'Cédula de ciudadanía' WHERE nombre_documento = 'Cedula de ciudadania';
UPDATE documento_solicitud SET nombre_documento = 'Codeudor - Cédula' WHERE nombre_documento = 'Codeudor - Cedula';

-- 16. AUDITORIA
UPDATE auditoria SET descripcion = 'Inicio de sesión exitoso.' WHERE descripcion = 'Inicio de sesion exitoso.';
UPDATE auditoria SET descripcion = 'Publicó la propiedad MI-BGA-0001.' WHERE descripcion = 'Publico la propiedad MI-BGA-0001.';
UPDATE auditoria SET descripcion = 'Publicó la propiedad MI-FLB-0002.' WHERE descripcion = 'Publico la propiedad MI-FLB-0002.';
UPDATE auditoria SET descripcion = 'Actualizó el estado de MI-MED-0006 a reservado.' WHERE descripcion = 'Actualizo el estado de MI-MED-0006 a reservado.';
UPDATE auditoria SET descripcion = 'Asignó rol Inmobiliaria a agente@raicesinmobiliaria.com.' WHERE descripcion = 'Asigno rol Inmobiliaria a agente@raicesinmobiliaria.com.';
UPDATE auditoria SET descripcion = 'Aprobó la solicitud de compra #1.' WHERE descripcion = 'Aprobo la solicitud de compra #1.';
UPDATE auditoria SET descripcion = 'Se registró como nuevo cliente.' WHERE descripcion = 'Se registro como nuevo cliente.';
UPDATE auditoria SET descripcion = 'Rechazó la solicitud de arriendo #12.' WHERE descripcion = 'Rechazo la solicitud de arriendo #12.';
UPDATE auditoria SET descripcion = 'Bloqueó temporalmente la cuenta cliente6@gmail.com.' WHERE descripcion = 'Bloqueo temporalmente la cuenta cliente6@gmail.com.';
UPDATE auditoria SET descripcion = 'Cargó el documento Certificado de ingresos.' WHERE descripcion = 'Cargo el documento Certificado de ingresos.';
UPDATE auditoria SET descripcion = 'Consultó el reporte de auditoría del sistema.' WHERE descripcion = 'Consulto el reporte de auditoria del sistema.';
