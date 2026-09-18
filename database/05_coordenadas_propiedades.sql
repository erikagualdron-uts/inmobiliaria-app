-- =====================================================================
-- Hogaria - Mapa de ubicacion: coordenadas de las propiedades
-- Migracion puntual: agrega latitud/longitud a propiedad y rellena las
-- 16 propiedades que ya existian en la base de datos (creadas antes de
-- esta columna). 01_ddl_hogaria.sql y 02/03_dml ya quedan actualizados
-- de raiz para instalaciones nuevas; este script deja consistente una
-- base de datos que ya tenia los datos sembrados de antes.
--
-- No hay direcciones geocodificadas reales, asi que cada coordenada se
-- genero aleatoriamente DENTRO del area urbana real de la ciudad de la
-- propiedad (ver jspf/geo.jspf para el mismo criterio aplicado a
-- propiedades nuevas), para que el mapa se vea coherente aunque el dato
-- sea simulado.
-- =====================================================================

USE hogaria_db;

ALTER TABLE propiedad
    ADD COLUMN latitud DECIMAL(10,7) NULL AFTER direccion,
    ADD COLUMN longitud DECIMAL(10,7) NULL AFTER latitud;

UPDATE propiedad SET latitud = 7.1201685,  longitud = -73.1341246 WHERE matricula_inmobiliaria = 'MI-BGA-0001';
UPDATE propiedad SET latitud = 7.0487515,  longitud = -73.0960716 WHERE matricula_inmobiliaria = 'MI-FLB-0002';
UPDATE propiedad SET latitud = 7.1255059,  longitud = -73.1113155 WHERE matricula_inmobiliaria = 'MI-BGA-0003';
UPDATE propiedad SET latitud = 4.7684359,  longitud = -74.1313061 WHERE matricula_inmobiliaria = 'MI-BOG-0004';
UPDATE propiedad SET latitud = 6.2437537,  longitud = -75.6032122 WHERE matricula_inmobiliaria = 'MI-MED-0005';
UPDATE propiedad SET latitud = 6.2274910,  longitud = -75.5746787 WHERE matricula_inmobiliaria = 'MI-MED-0006';
UPDATE propiedad SET latitud = 3.3921229,  longitud = -76.5470756 WHERE matricula_inmobiliaria = 'MI-CAL-0007';
UPDATE propiedad SET latitud = 10.9854919, longitud = -74.7818541 WHERE matricula_inmobiliaria = 'MI-BAQ-0008';
UPDATE propiedad SET latitud = 10.4010220, longitud = -75.4987514 WHERE matricula_inmobiliaria = 'MI-CTG-0009';
UPDATE propiedad SET latitud = 7.0823772,  longitud = -73.1848050 WHERE matricula_inmobiliaria = 'MI-GIR-0010';
UPDATE propiedad SET latitud = 7.0062619,  longitud = -73.0435837 WHERE matricula_inmobiliaria = 'MI-PIE-0011';
UPDATE propiedad SET latitud = 6.3303113,  longitud = -75.5745582 WHERE matricula_inmobiliaria = 'MI-BEL-0012';
UPDATE propiedad SET latitud = 3.4665770,  longitud = -76.5381214 WHERE matricula_inmobiliaria = 'MI-CAL-0013';
UPDATE propiedad SET latitud = 10.3946373, longitud = -75.5332299 WHERE matricula_inmobiliaria = 'MI-CTG-0014';
UPDATE propiedad SET latitud = 7.1316122,  longitud = -73.1138696 WHERE matricula_inmobiliaria = 'MI-BGA-0015';
UPDATE propiedad SET latitud = 6.2745703,  longitud = -75.5612161 WHERE matricula_inmobiliaria = 'MI-MED-0016';
