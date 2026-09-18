-- =====================================================================
-- Hogaria - Incremento de datos de prueba
-- Agrega 4 propiedades disponibles (repartidas entre las 3
-- inmobiliarias) para que el catalogo publico muestre 12 propiedades
-- visibles en total, sin tocar las 4 propiedades existentes que estan
-- a proposito en reservado/vendido/arrendado/baja logica (se usan para
-- demostrar esas funciones, incluido el reporte de ventas y arriendos
-- de la inmobiliaria).
-- =====================================================================

USE hogaria_db;

INSERT INTO propiedad
(id_inmobiliaria, id_ciudad, id_tipo, matricula_inmobiliaria, titulo, descripcion, direccion, precio, area_m2, num_habitaciones, num_banos, num_parqueaderos, operacion, estado, activo, fecha_publicacion)
VALUES
(2, 7, 2, 'MI-CAL-0013', 'Apartamento moderno en Zona Norte',
   'Apartamento con acabados modernos, cerca a centros comerciales y parques.',
   'Av 6N #28-15, Cali', 380000000.00, 88.00, 3, 2, 1, 'venta', 'disponible', 1, '2025-04-02 09:00:00'),

(3, 9, 1, 'MI-CTG-0014', 'Casa colonial en el centro historico',
   'Casa colonial restaurada, ideal para vivienda o negocio boutique.',
   'Cl del Arsenal #6-40, Cartagena', 8500000.00, 180.00, 4, 3, 2, 'arriendo', 'disponible', 1, '2025-04-05 10:30:00'),

(1, 1, 4, 'MI-BGA-0015', 'Oficina ejecutiva en Cabecera',
   'Oficina lista para operar, edificio con porteria y parqueadero de visitantes.',
   'Cra 33 #52-10, Bucaramanga', 2800000.00, 60.00, NULL, 1, 1, 'arriendo', 'disponible', 1, '2025-04-08 11:15:00'),

(2, 6, 3, 'MI-MED-0016', 'Local comercial en Provenza',
   'Local esquinero de alto flujo peatonal, zona gastronomica y comercial.',
   'Cra 37 #8A-20, Medellin', 650000000.00, 90.00, NULL, 1, 0, 'venta', 'disponible', 1, '2025-04-10 08:45:00');

-- Nota: se referencia cada propiedad por su matricula (UNIQUE) en vez del
-- id_propiedad, porque el contador AUTO_INCREMENT puede no coincidir con
-- "cantidad de filas + 1" si la tabla ya tuvo inserciones y borrados
-- previos (p. ej. datos de prueba). Esto hace el script seguro sin
-- importar el estado previo del contador.

INSERT INTO imagen_propiedad (id_propiedad, url_imagen, orden, es_principal) VALUES
((SELECT id_propiedad FROM propiedad WHERE matricula_inmobiliaria = 'MI-CAL-0013'), 'https://images.unsplash.com/photo-1571508601891-ca5e7a713859?w=1200&q=80&auto=format&fit=crop', 1, 1),
((SELECT id_propiedad FROM propiedad WHERE matricula_inmobiliaria = 'MI-CAL-0013'), 'https://images.unsplash.com/photo-1502672023488-70e25813eb80?w=1200&q=80&auto=format&fit=crop', 2, 0),

((SELECT id_propiedad FROM propiedad WHERE matricula_inmobiliaria = 'MI-CTG-0014'), 'https://images.unsplash.com/photo-1602343168117-bb8ffe3e2e9f?w=1200&q=80&auto=format&fit=crop', 1, 1),
((SELECT id_propiedad FROM propiedad WHERE matricula_inmobiliaria = 'MI-CTG-0014'), 'https://images.unsplash.com/photo-1567496898669-ee935f5f647a?w=1200&q=80&auto=format&fit=crop', 2, 0),

((SELECT id_propiedad FROM propiedad WHERE matricula_inmobiliaria = 'MI-BGA-0015'), 'https://images.unsplash.com/photo-1497215842964-222b430dc094?w=1200&q=80&auto=format&fit=crop', 1, 1),
((SELECT id_propiedad FROM propiedad WHERE matricula_inmobiliaria = 'MI-BGA-0015'), 'https://images.unsplash.com/photo-1518481612222-68bbe828ecd1?w=1200&q=80&auto=format&fit=crop', 2, 0),

((SELECT id_propiedad FROM propiedad WHERE matricula_inmobiliaria = 'MI-MED-0016'), 'https://images.unsplash.com/photo-1604014237800-1c9102c219da?w=1200&q=80&auto=format&fit=crop', 1, 1),
((SELECT id_propiedad FROM propiedad WHERE matricula_inmobiliaria = 'MI-MED-0016'), 'https://images.unsplash.com/photo-1580913428023-02c695666d61?w=1200&q=80&auto=format&fit=crop', 2, 0);

INSERT INTO propiedad_caracteristica (id_propiedad, id_caracteristica, valor) VALUES
((SELECT id_propiedad FROM propiedad WHERE matricula_inmobiliaria = 'MI-CAL-0013'), 2, '1'),
((SELECT id_propiedad FROM propiedad WHERE matricula_inmobiliaria = 'MI-CAL-0013'), 3, NULL),
((SELECT id_propiedad FROM propiedad WHERE matricula_inmobiliaria = 'MI-CAL-0013'), 6, NULL),
((SELECT id_propiedad FROM propiedad WHERE matricula_inmobiliaria = 'MI-CTG-0014'), 1, NULL),
((SELECT id_propiedad FROM propiedad WHERE matricula_inmobiliaria = 'MI-CTG-0014'), 5, NULL),
((SELECT id_propiedad FROM propiedad WHERE matricula_inmobiliaria = 'MI-CTG-0014'), 2, '2'),
((SELECT id_propiedad FROM propiedad WHERE matricula_inmobiliaria = 'MI-BGA-0015'), 3, NULL),
((SELECT id_propiedad FROM propiedad WHERE matricula_inmobiliaria = 'MI-BGA-0015'), 9, NULL),
((SELECT id_propiedad FROM propiedad WHERE matricula_inmobiliaria = 'MI-BGA-0015'), 7, NULL),
((SELECT id_propiedad FROM propiedad WHERE matricula_inmobiliaria = 'MI-MED-0016'), 2, NULL),
((SELECT id_propiedad FROM propiedad WHERE matricula_inmobiliaria = 'MI-MED-0016'), 9, NULL);
