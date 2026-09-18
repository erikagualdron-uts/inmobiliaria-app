-- =====================================================================
-- Hogaria - Sistema Web de Inmobiliaria
-- Script DML: datos de prueba
--
-- Convencion de contrasenas (para pruebas de login del modulo de
-- autenticacion): contrasena_hash guarda "<salt_hex>:<sha256_hex>",
-- donde sha256_hex = SHA2(CONCAT(salt_hex, contrasena_plana), 256).
-- Contrasenas de prueba (texto plano, solo para que puedas iniciar
-- sesion una vez se construya el login):
--   Administrador -> admin@hogaria.com          / Admin#2026
--   Agentes       -> agente1@hogaria.com         / Agente#2026
--                    agente2@hogaria.com         / Agente#2026
--                    agente@viviendatotal.com    / Agente#2026
--                    agente@raicesinmobiliaria.com / Agente#2026
--   Clientes      -> cliente1@gmail.com ... cliente6@gmail.com / Cliente#2026
-- =====================================================================

USE hogaria_db;

-- =====================================================================
-- 1. ROL
-- =====================================================================
INSERT INTO rol (nombre_rol, descripcion) VALUES
('Visitante',     'Navega el catálogo público sin autenticarse.'),
('Cliente',       'Busca propiedades, agenda citas y radica solicitudes.'),
('Inmobiliaria',  'Agente que publica y administra propiedades y trámites.'),
('Administrador', 'Acceso total: usuarios, roles, catálogos y auditoría.');

-- =====================================================================
-- 2. CIUDAD
-- =====================================================================
INSERT INTO ciudad (nombre_ciudad, departamento) VALUES
('Bucaramanga',   'Santander'),
('Floridablanca', 'Santander'),
('Girón',         'Santander'),
('Piedecuesta',   'Santander'),
('Bogotá',        'Cundinamarca'),
('Medellín',      'Antioquia'),
('Cali',          'Valle del Cauca'),
('Barranquilla',  'Atlántico'),
('Cartagena',     'Bolívar'),
('Bello',         'Antioquia');

-- =====================================================================
-- 3. TIPO_PROPIEDAD
-- =====================================================================
INSERT INTO tipo_propiedad (nombre_tipo, descripcion) VALUES
('Casa',             'Vivienda unifamiliar independiente.'),
('Apartamento',      'Unidad residencial en edificio o conjunto.'),
('Local comercial',  'Espacio para actividad comercial.'),
('Oficina',          'Espacio para actividad administrativa o profesional.'),
('Terreno',          'Lote sin construir, urbano o rural.');

-- =====================================================================
-- 4. CARACTERISTICA
-- =====================================================================
INSERT INTO caracteristica (nombre_caracteristica, icono) VALUES
('Piscina',              'bi-water'),
('Parqueadero',          'bi-p-square'),
('Ascensor',             'bi-arrow-up-square'),
('Gimnasio',             'bi-bicycle'),
('Jardín',               'bi-tree'),
('Balcón',               'bi-door-open'),
('Seguridad 24 horas',   'bi-shield-check'),
('Zona BBQ',             'bi-fire'),
('Aire acondicionado',   'bi-snow'),
('Amoblado',             'bi-house-gear');

-- =====================================================================
-- 5. INMOBILIARIA
-- =====================================================================
INSERT INTO inmobiliaria (nombre_comercial, nit, telefono, direccion, logo_url, fecha_registro) VALUES
('Hogaria',                '900123456-7', '6076001122', 'Cra 27 #38-45, Bucaramanga',      'https://images.unsplash.com/photo-1560518883-ce09059eeffa?w=200&q=80', '2025-01-05 08:00:00'),
('Vivienda Total S.A.S.',  '900234567-8', '6042223344', 'Cra 43A #10-20, Medellín',         'https://images.unsplash.com/photo-1560518883-ce09059eeffa?w=200&q=80', '2025-01-08 09:00:00'),
('Raíces Inmobiliaria',    '900345678-9', '6053334455', 'Cl 5 #8-30, Cartagena',            'https://images.unsplash.com/photo-1560518883-ce09059eeffa?w=200&q=80', '2025-01-10 10:00:00');

-- =====================================================================
-- 6. USUARIO  (id_usuario 1..11, autoincremental en este orden)
-- =====================================================================
INSERT INTO usuario (correo, contrasena_hash, id_inmobiliaria, estado, intentos_fallidos, fecha_registro) VALUES
('admin@hogaria.com',              CONCAT('4f3a9c21b6d84e10', ':', SHA2(CONCAT('4f3a9c21b6d84e10','Admin#2026'),256)),   NULL, 'activo', 0, '2025-01-06 08:00:00'),
('agente1@hogaria.com',            CONCAT('8b2e7f0159ac3d64', ':', SHA2(CONCAT('8b2e7f0159ac3d64','Agente#2026'),256)),  1,    'activo', 0, '2025-01-07 09:00:00'),
('agente2@hogaria.com',            CONCAT('1c9d4a7e2f836b50', ':', SHA2(CONCAT('1c9d4a7e2f836b50','Agente#2026'),256)),  1,    'activo', 0, '2025-01-07 09:15:00'),
('agente@viviendatotal.com',       CONCAT('6a2f8d1c9e047b35', ':', SHA2(CONCAT('6a2f8d1c9e047b35','Agente#2026'),256)),  2,    'activo', 0, '2025-01-08 09:30:00'),
('agente@raicesinmobiliaria.com',  CONCAT('3e7b1f9a6c208d54', ':', SHA2(CONCAT('3e7b1f9a6c208d54','Agente#2026'),256)),  3,    'activo', 0, '2025-01-10 10:15:00'),
('cliente1@gmail.com',             CONCAT('9d4c2a7f1e806b39', ':', SHA2(CONCAT('9d4c2a7f1e806b39','Cliente#2026'),256)), NULL, 'activo', 0, '2025-02-01 12:00:00'),
('cliente2@gmail.com',             CONCAT('2f8a3d9c1b607e45', ':', SHA2(CONCAT('2f8a3d9c1b607e45','Cliente#2026'),256)), NULL, 'activo', 0, '2025-02-02 12:10:00'),
('cliente3@gmail.com',             CONCAT('7c1e9b4a2f508d36', ':', SHA2(CONCAT('7c1e9b4a2f508d36','Cliente#2026'),256)), NULL, 'activo', 0, '2025-02-03 12:20:00'),
('cliente4@gmail.com',             CONCAT('4b9d2f7a1c608e53', ':', SHA2(CONCAT('4b9d2f7a1c608e53','Cliente#2026'),256)), NULL, 'activo', 0, '2025-02-04 12:30:00'),
('cliente5@gmail.com',             CONCAT('8e3a1c9f2d704b56', ':', SHA2(CONCAT('8e3a1c9f2d704b56','Cliente#2026'),256)), NULL, 'activo', 0, '2025-02-05 12:40:00'),
('cliente6@gmail.com',             CONCAT('1a7f4c9d2e806b38', ':', SHA2(CONCAT('1a7f4c9d2e806b38','Cliente#2026'),256)), NULL, 'inactivo', 2, '2025-02-06 12:50:00');

-- =====================================================================
-- 7. USUARIO_ROL
-- =====================================================================
INSERT INTO usuario_rol (id_usuario, id_rol, fecha_asignacion) VALUES
(1, 4, '2025-01-06 08:00:00'), -- admin -> Administrador
(2, 3, '2025-01-07 09:00:00'),
(3, 3, '2025-01-07 09:15:00'),
(4, 3, '2025-01-08 09:30:00'),
(5, 3, '2025-01-10 10:15:00'),
(6, 2, '2025-02-01 12:00:00'),
(7, 2, '2025-02-02 12:10:00'),
(8, 2, '2025-02-03 12:20:00'),
(9, 2, '2025-02-04 12:30:00'),
(10,2, '2025-02-05 12:40:00'),
(11,2, '2025-02-06 12:50:00');

-- =====================================================================
-- 8. PERFIL  (1:1 con usuario)
-- =====================================================================
INSERT INTO perfil (id_usuario, nombres, apellidos, tipo_documento, numero_documento, telefono, direccion) VALUES
(1,  'Laura',     'Martínez Rojas',    'CC', '63489215',  '3001234567', 'Cra 27 #45-12, Bucaramanga'),
(2,  'Carlos',    'Pinzón Duarte',     'CC', '91234567',  '3012345678', 'Cl 56 #22-10, Bucaramanga'),
(3,  'Valentina', 'Gómez Rueda',       'CC', '63512890',  '3023456789', 'Cra 33 #40-18, Floridablanca'),
(4,  'Andrés',    'Castañeda Ríos',    'CC', '71234567',  '3034567890', 'Cra 43A #10-20, Medellín'),
(5,  'Daniela',   'Ortiz Marín',       'CC', '43598721',  '3045678901', 'Cl 5 #8-30, Cartagena'),
(6,  'Juan',      'Pérez López',       'CC', '1098765432','3101234567', 'Cl 30 #12-40, Bucaramanga'),
(7,  'María',     'Rodríguez Sánchez', 'CC', '1102345678','3112345678', 'Cra 10 #20-15, Floridablanca'),
(8,  'Santiago',  'Vargas Cortés',     'CC', '1099876543','3123456789', 'Cl 45 #9-22, Bucaramanga'),
(9,  'Camila',    'Herrera Buitrago',  'CC', '1105678234','3134567890', 'Cra 15 #33-20, Bogotá'),
(10, 'Diego',     'Moreno Salazar',    'CC', '1096543210','3145678901', 'Cl 70 #52-30, Medellín'),
(11, 'Isabella',  'Cárdenas Niño',     'CC', '1101234987','3156789012', 'Cra 8 #12-40, Cartagena');

-- =====================================================================
-- 9. PROPIEDAD  (id_propiedad 1..12)
-- =====================================================================
INSERT INTO propiedad
(id_inmobiliaria, id_ciudad, id_tipo, matricula_inmobiliaria, titulo, descripcion, direccion, latitud, longitud, precio, area_m2, num_habitaciones, num_banos, num_parqueaderos, operacion, estado, activo, fecha_publicacion)
VALUES
(1, 1,  1, 'MI-BGA-0001', 'Casa campestre en Cañaveral',
   'Amplia casa campestre de dos plantas con zonas verdes, ideal para familias grandes.',
   'Cra 27 #103-45, Bucaramanga', 7.1201685, -73.1341246, 480000000.00, 220.00, 4, 3, 2, 'venta', 'disponible', 1, '2025-03-01 09:00:00'),

(1, 2,  2, 'MI-FLB-0002', 'Apartamento moderno en Cañaveral Real',
   'Apartamento de acabados modernos, muy cerca a centros comerciales y colegios.',
   'Cl 30 #12-08, Floridablanca', 7.0487515, -73.0960716, 350000000.00, 85.00, 3, 2, 1, 'venta', 'disponible', 1, '2025-03-03 10:00:00'),

(1, 1,  3, 'MI-BGA-0003', 'Local comercial en el centro de Cabecera',
   'Local esquinero con excelente flujo peatonal, apto para comercio o servicios.',
   'Cra 33 #45-20, Bucaramanga', 7.1255059, -73.1113155, 2500000.00, 60.00, NULL, 1, 0, 'arriendo', 'disponible', 0, '2025-03-05 11:00:00'),

(1, 5,  2, 'MI-BOG-0004', 'Apartaestudio en Chapinero Central',
   'Apartaestudio funcional, ideal para estudiantes o profesionales solos.',
   'Cra 13 #58-20, Bogotá', 4.7684359, -74.1313061, 1800000.00, 45.00, 1, 1, 0, 'arriendo', 'disponible', 1, '2025-03-06 12:00:00'),

(2, 6,  1, 'MI-MED-0005', 'Casa de lujo en El Poblado',
   'Casa con acabados de lujo, piscina privada y zona social amplia.',
   'Cl 10 #35-40, Medellín', 6.2437537, -75.6032122, 950000000.00, 300.00, 5, 4, 3, 'venta', 'disponible', 1, '2025-03-08 09:30:00'),

(2, 6,  2, 'MI-MED-0006', 'Apartamento con vista en Laureles',
   'Apartamento en piso alto con vista panorámica y excelente iluminación.',
   'Cra 76 #34-10, Medellín', 6.2274910, -75.5746787, 420000000.00, 90.00, 3, 2, 1, 'venta', 'reservado', 1, '2025-03-10 10:30:00'),

(2, 7,  4, 'MI-CAL-0007', 'Oficina ejecutiva Zona Norte',
   'Oficina lista para operar, con recepción y sala de juntas independiente.',
   'Av 6N #23-50, Cali', 3.3921229, -76.5470756, 3200000.00, 70.00, NULL, 1, 1, 'arriendo', 'disponible', 1, '2025-03-11 14:00:00'),

(3, 8,  1, 'MI-BAQ-0008', 'Casa frente al mar en Puerto Colombia',
   'Casa de playa con acceso directo a la orilla y terraza con zona BBQ.',
   'Vía al Mar Km 5, Barranquilla', 10.9854919, -74.7818541, 1200000000.00, 250.00, 4, 3, 2, 'venta', 'disponible', 1, '2025-03-12 08:45:00'),

(3, 9,  2, 'MI-CTG-0009', 'Apartamento amoblado en Bocagrande',
   'Apartamento totalmente amoblado, a pasos de la playa y zona hotelera.',
   'Cra 1 #8-45, Cartagena', 10.4010220, -75.4987514, 6500000.00, 75.00, 2, 2, 1, 'arriendo', 'disponible', 1, '2025-03-13 09:15:00'),

(3, 3,  5, 'MI-GIR-0010', 'Lote urbanizable en Girón',
   'Lote plano con servicios cercanos, ideal para proyecto de vivienda o inversión.',
   'Vereda Chocoa, Girón', 7.0823772, -73.1848050, 180000000.00, 500.00, NULL, NULL, 0, 'venta', 'disponible', 1, '2025-03-14 10:00:00'),

(1, 4,  1, 'MI-PIE-0011', 'Casa finca con vista a las montañas',
   'Casa finca con vista panorámica, árboles frutales y amplio jardín.',
   'Vereda Sevilla, Piedecuesta', 7.0062619, -73.0435837, 620000000.00, 400.00, 4, 3, 4, 'venta', 'vendido', 1, '2025-03-15 11:20:00'),

(1, 10, 3, 'MI-BEL-0012', 'Local esquinero en Niquía',
   'Local esquinero con buena visibilidad, cerca a la estación del metro.',
   'Cl 50 #45-10, Bello', 6.3303113, -75.5745582, 1900000.00, 55.00, NULL, 1, 0, 'arriendo', 'arrendado', 1, '2025-03-16 13:40:00');

-- =====================================================================
-- 10. IMAGEN_PROPIEDAD  (2 imagenes por propiedad, sin repetir entre registros)
-- =====================================================================
INSERT INTO imagen_propiedad (id_propiedad, url_imagen, orden, es_principal) VALUES
(1, 'https://images.unsplash.com/photo-1580587771525-78b9dba3b914?w=1200&q=80&auto=format&fit=crop', 1, 1),
(1, 'https://images.unsplash.com/photo-1568605114967-8130f3a36994?w=1200&q=80&auto=format&fit=crop', 2, 0),

(2, 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=1200&q=80&auto=format&fit=crop', 1, 1),
(2, 'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=1200&q=80&auto=format&fit=crop', 2, 0),

(3, 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=1200&q=80&auto=format&fit=crop', 1, 1),
(3, 'https://images.unsplash.com/photo-1604719312566-8912e9227c6a?w=1200&q=80&auto=format&fit=crop', 2, 0),

(4, 'https://images.unsplash.com/photo-1493809842364-78817add7ffb?w=1200&q=80&auto=format&fit=crop', 1, 1),
(4, 'https://images.unsplash.com/photo-1484154218962-a197022b5858?w=1200&q=80&auto=format&fit=crop', 2, 0),

(5, 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=1200&q=80&auto=format&fit=crop', 1, 1),
(5, 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=1200&q=80&auto=format&fit=crop', 2, 0),

(6, 'https://images.unsplash.com/photo-1502005229762-cf1b2da7c5d6?w=1200&q=80&auto=format&fit=crop', 1, 1),
(6, 'https://images.unsplash.com/photo-1556020685-ae41abfc9365?w=1200&q=80&auto=format&fit=crop', 2, 0),

(7, 'https://images.unsplash.com/photo-1497366811353-6870744d04b2?w=1200&q=80&auto=format&fit=crop', 1, 1),
(7, 'https://images.unsplash.com/photo-1497215728101-856f4ea42174?w=1200&q=80&auto=format&fit=crop', 2, 0),

(8, 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=1200&q=80&auto=format&fit=crop', 1, 1),
(8, 'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=1200&q=80&auto=format&fit=crop', 2, 0),

(9, 'https://images.unsplash.com/photo-1554995207-c18c203602cb?w=1200&q=80&auto=format&fit=crop', 1, 1),
(9, 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=1200&q=80&auto=format&fit=crop', 2, 0),

(10, 'https://images.unsplash.com/photo-1500382017468-9049fed747ef?w=1200&q=80&auto=format&fit=crop', 1, 1),
(10, 'https://images.unsplash.com/photo-1500534623283-312aade485b7?w=1200&q=80&auto=format&fit=crop', 2, 0),

(11, 'https://images.unsplash.com/photo-1583608205776-bfd35f0d9f83?w=1200&q=80&auto=format&fit=crop', 1, 1),
(11, 'https://images.unsplash.com/photo-1570129477492-45c003edd2be?w=1200&q=80&auto=format&fit=crop', 2, 0),

(12, 'https://images.unsplash.com/photo-1555529669-e69e7aa0ba9a?w=1200&q=80&auto=format&fit=crop', 1, 1),
(12, 'https://images.unsplash.com/photo-1521737604893-d14cc237f11d?w=1200&q=80&auto=format&fit=crop', 2, 0);

-- =====================================================================
-- 11. PROPIEDAD_CARACTERISTICA  (N:M) - la propiedad 10 se deja sin
--     caracteristicas a proposito, para ilustrar el caso "sin coincidencias"
--     util en la consulta LEFT JOIN / de verificacion.
-- =====================================================================
INSERT INTO propiedad_caracteristica (id_propiedad, id_caracteristica, valor) VALUES
(1, 1, NULL), (1, 2, '2'), (1, 5, NULL), (1, 8, NULL),
(2, 2, '1'),  (2, 3, NULL), (2, 6, NULL),
(3, 2, NULL), (3, 9, NULL),
(4, 3, NULL), (4, 10, NULL),
(5, 1, NULL), (5, 2, '3'), (5, 4, NULL), (5, 7, NULL),
(6, 2, '1'),  (6, 3, NULL), (6, 4, NULL),
(7, 3, NULL), (7, 9, NULL), (7, 7, NULL),
(8, 1, NULL), (8, 5, NULL), (8, 2, '2'), (8, 8, NULL),
(9, 6, NULL), (9, 10, NULL), (9, 9, NULL),
(11, 1, NULL), (11, 2, '4'), (11, 8, NULL), (11, 7, NULL),
(12, 2, NULL), (12, 9, NULL);

-- =====================================================================
-- 12. CITA  (uso de usuario 1 y 6..11 como clientes)
-- =====================================================================
INSERT INTO cita (id_propiedad, id_cliente, fecha_hora, estado, observaciones, fecha_solicitud) VALUES
(1,  6,  '2025-11-05 10:00:00', 'confirmada', 'Cliente interesado en compra de contado.', '2025-10-28 08:00:00'),
(1,  7,  '2025-11-06 15:00:00', 'pendiente',  NULL,                                      '2025-10-29 09:00:00'),
(2,  8,  '2025-11-07 09:30:00', 'pendiente',  NULL,                                      '2025-10-29 09:30:00'),
(2,  6,  '2025-11-10 14:00:00', 'realizada',  'Visita realizada, cliente satisfecho.',   '2025-10-30 10:00:00'),
(4,  9,  '2025-11-08 11:00:00', 'confirmada', NULL,                                      '2025-10-30 11:00:00'),
(5,  7,  '2025-11-09 16:00:00', 'pendiente',  NULL,                                      '2025-10-31 08:20:00'),
(5,  10, '2025-11-12 10:00:00', 'cancelada',  'Cliente reprogramará para otra fecha.',   '2025-10-31 09:00:00'),
(6,  11, '2025-11-11 13:00:00', 'confirmada', NULL,                                      '2025-11-01 07:45:00'),
(8,  8,  '2025-11-13 09:00:00', 'pendiente',  NULL,                                      '2025-11-02 12:00:00'),
(9,  9,  '2025-11-14 17:00:00', 'rechazada',  'Horario no disponible para el agente.',   '2025-11-02 12:30:00'),
(11, 10, '2025-11-15 10:30:00', 'pendiente',  NULL,                                      '2025-11-03 08:00:00'),
(12, 6,  '2025-11-16 12:00:00', 'confirmada', NULL,                                      '2025-11-03 09:10:00');

-- =====================================================================
-- 13. SOLICITUD
-- =====================================================================
INSERT INTO solicitud (id_propiedad, id_cliente, tipo_solicitud, estado, fecha_solicitud, observaciones) VALUES
(1,  6,  'compra',   'aprobada',    '2025-10-20 09:00:00', 'Documentación completa y verificada.'),
(2,  7,  'compra',   'en_revision', '2025-10-21 10:00:00', NULL),
(3,  8,  'arriendo', 'pendiente',   '2025-10-22 11:00:00', NULL),
(4,  9,  'arriendo', 'aprobada',    '2025-10-22 12:00:00', 'Contrato listo para firma.'),
(5,  10, 'compra',   'pendiente',   '2025-10-23 09:30:00', NULL),
(6,  11, 'compra',   'rechazada',   '2025-10-23 10:30:00', 'Capacidad de pago insuficiente.'),
(7,  6,  'arriendo', 'en_revision', '2025-10-24 08:15:00', NULL),
(8,  7,  'compra',   'pendiente',   '2025-10-25 09:45:00', NULL),
(9,  8,  'arriendo', 'aprobada',    '2025-10-26 10:15:00', 'Depósito de garantía recibido.'),
(10, 9,  'compra',   'pendiente',   '2025-10-27 11:30:00', NULL),
(11, 10, 'compra',   'en_revision', '2025-10-28 12:45:00', NULL),
(12, 11, 'arriendo', 'rechazada',   '2025-10-28 13:15:00', 'Referencias no verificables.');

-- =====================================================================
-- 14. DOCUMENTO_SOLICITUD
-- =====================================================================
INSERT INTO documento_solicitud (id_solicitud, nombre_documento, url_documento, estado, fecha_carga) VALUES
(1,  'Cédula de ciudadanía',       'https://docs.hogaria.test/sol1/cedula.pdf',       'aprobado',  '2025-10-20 09:10:00'),
(1,  'Carta laboral',              'https://docs.hogaria.test/sol1/laboral.pdf',      'aprobado',  '2025-10-20 09:15:00'),
(2,  'Cédula de ciudadanía',       'https://docs.hogaria.test/sol2/cedula.pdf',       'aprobado',  '2025-10-21 10:10:00'),
(2,  'Certificado de ingresos',    'https://docs.hogaria.test/sol2/ingresos.pdf',     'pendiente', '2025-10-21 10:20:00'),
(3,  'Cédula de ciudadanía',       'https://docs.hogaria.test/sol3/cedula.pdf',       'pendiente', '2025-10-22 11:05:00'),
(4,  'Cédula de ciudadanía',       'https://docs.hogaria.test/sol4/cedula.pdf',       'aprobado',  '2025-10-22 12:05:00'),
(4,  'Referencia bancaria',        'https://docs.hogaria.test/sol4/referencia.pdf',   'aprobado',  '2025-10-22 12:10:00'),
(5,  'Cédula de ciudadanía',       'https://docs.hogaria.test/sol5/cedula.pdf',       'pendiente', '2025-10-23 09:35:00'),
(6,  'Cédula de ciudadanía',       'https://docs.hogaria.test/sol6/cedula.pdf',       'rechazado', '2025-10-23 10:35:00'),
(7,  'Cédula de ciudadanía',       'https://docs.hogaria.test/sol7/cedula.pdf',       'pendiente', '2025-10-24 08:20:00'),
(8,  'Cédula de ciudadanía',       'https://docs.hogaria.test/sol8/cedula.pdf',       'pendiente', '2025-10-25 09:50:00'),
(9,  'Cédula de ciudadanía',       'https://docs.hogaria.test/sol9/cedula.pdf',       'aprobado',  '2025-10-26 10:20:00'),
(9,  'Codeudor - Cédula',          'https://docs.hogaria.test/sol9/codeudor.pdf',     'aprobado',  '2025-10-26 10:25:00'),
(10, 'Cédula de ciudadanía',       'https://docs.hogaria.test/sol10/cedula.pdf',      'pendiente', '2025-10-27 11:35:00'),
(11, 'Cédula de ciudadanía',       'https://docs.hogaria.test/sol11/cedula.pdf',      'aprobado',  '2025-10-28 12:50:00'),
(12, 'Cédula de ciudadanía',       'https://docs.hogaria.test/sol12/cedula.pdf',      'rechazado', '2025-10-28 13:20:00');

-- =====================================================================
-- 15. FAVORITO
-- =====================================================================
INSERT INTO favorito (id_usuario, id_propiedad, fecha_agregado) VALUES
(6,  1,  '2025-10-15 08:00:00'),
(6,  2,  '2025-10-16 08:10:00'),
(7,  1,  '2025-10-17 08:20:00'),
(7,  5,  '2025-10-18 08:30:00'),
(8,  2,  '2025-10-19 08:40:00'),
(8,  8,  '2025-10-20 08:50:00'),
(9,  4,  '2025-10-21 09:00:00'),
(9,  9,  '2025-10-22 09:10:00'),
(10, 5,  '2025-10-23 09:20:00'),
(10, 11, '2025-10-24 09:30:00'),
(11, 6,  '2025-10-25 09:40:00'),
(11, 12, '2025-10-26 09:50:00');

-- =====================================================================
-- 16. AUDITORIA
-- =====================================================================
INSERT INTO auditoria (id_usuario, accion, tabla_afectada, descripcion, fecha_hora, ip_origen) VALUES
(1, 'login',                  NULL,                  'Inicio de sesión exitoso.',                                   '2025-11-01 07:55:00', '190.85.23.10'),
(2, 'creacion_propiedad',     'propiedad',           'Publicó la propiedad MI-BGA-0001.',                           '2025-03-01 09:00:00', '186.30.15.22'),
(3, 'creacion_propiedad',     'propiedad',           'Publicó la propiedad MI-FLB-0002.',                           '2025-03-03 10:00:00', '186.30.15.40'),
(4, 'actualizacion_propiedad','propiedad',           'Actualizó el estado de MI-MED-0006 a reservado.',             '2025-04-01 15:00:00', '200.14.10.5'),
(1, 'asignacion_rol',         'usuario_rol',         'Asignó rol Inmobiliaria a agente@raicesinmobiliaria.com.',    '2025-01-10 10:15:00', '190.85.23.10'),
(2, 'aprobacion_solicitud',   'solicitud',           'Aprobó la solicitud de compra #1.',                           '2025-10-20 09:05:00', '186.30.15.22'),
(6, 'login',                  NULL,                  'Inicio de sesión exitoso.',                                   '2025-10-15 07:50:00', '181.52.10.3'),
(7, 'registro_usuario',       'usuario',             'Se registró como nuevo cliente.',                             '2025-02-02 12:10:00', '181.52.11.9'),
(5, 'rechazo_solicitud',      'solicitud',           'Rechazó la solicitud de arriendo #12.',                       '2025-10-28 13:15:00', '200.75.44.2'),
(1, 'bloqueo_cuenta',         'usuario',             'Bloqueó temporalmente la cuenta cliente6@gmail.com.',         '2025-11-02 16:00:00', '190.85.23.10'),
(9, 'radicacion_documento',   'documento_solicitud', 'Cargó el documento Certificado de ingresos.',                 '2025-10-21 10:20:00', '191.90.12.7'),
(1, 'consulta_auditoria',     'auditoria',           'Consultó el reporte de auditoría del sistema.',               '2025-11-03 09:00:00', '190.85.23.10');
