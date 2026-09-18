-- =====================================================================
-- Hogaria - Sistema Web de Inmobiliaria
-- Script DDL: creacion de base de datos y estructura de tablas
-- Motor: MySQL / MariaDB (probado en MariaDB 10.4, XAMPP)
-- =====================================================================

DROP DATABASE IF EXISTS hogaria_db;
CREATE DATABASE hogaria_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE hogaria_db;

-- =====================================================================
-- 1. CATALOGOS BASE
-- =====================================================================

CREATE TABLE ciudad (
    id_ciudad      INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nombre_ciudad  VARCHAR(80)  NOT NULL,
    departamento   VARCHAR(80)  NOT NULL,
    CONSTRAINT uq_ciudad_nombre UNIQUE (nombre_ciudad)
) ENGINE=InnoDB CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE tipo_propiedad (
    id_tipo      INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nombre_tipo  VARCHAR(40)  NOT NULL,
    descripcion  VARCHAR(150) NULL,
    CONSTRAINT uq_tipo_propiedad_nombre UNIQUE (nombre_tipo)
) ENGINE=InnoDB CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE caracteristica (
    id_caracteristica      INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nombre_caracteristica  VARCHAR(50) NOT NULL,
    icono                  VARCHAR(50) NULL,
    CONSTRAINT uq_caracteristica_nombre UNIQUE (nombre_caracteristica)
) ENGINE=InnoDB CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE inmobiliaria (
    id_inmobiliaria   INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nombre_comercial  VARCHAR(100) NOT NULL,
    nit               VARCHAR(20)  NOT NULL,
    telefono          VARCHAR(20)  NULL,
    direccion         VARCHAR(150) NULL,
    logo_url          VARCHAR(255) NULL,
    fecha_registro    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_inmobiliaria_nit UNIQUE (nit)
) ENGINE=InnoDB CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE rol (
    id_rol       INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nombre_rol   VARCHAR(30)  NOT NULL,
    descripcion  VARCHAR(150) NULL,
    CONSTRAINT uq_rol_nombre UNIQUE (nombre_rol)
) ENGINE=InnoDB CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- =====================================================================
-- 2. USUARIOS, PERFIL Y ROLES
-- =====================================================================

CREATE TABLE usuario (
    id_usuario         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    correo             VARCHAR(120) NOT NULL,
    contrasena_hash    VARCHAR(255) NOT NULL, -- formato: "<salt_hex>:<sha256_hex>"
    id_inmobiliaria    INT UNSIGNED NULL,      -- solo para usuarios con rol Inmobiliaria (agente)
    estado             ENUM('activo','inactivo','bloqueado') NOT NULL DEFAULT 'activo',
    intentos_fallidos  TINYINT UNSIGNED NOT NULL DEFAULT 0,
    fecha_registro     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_usuario_correo UNIQUE (correo),
    CONSTRAINT fk_usuario_inmobiliaria
        FOREIGN KEY (id_inmobiliaria) REFERENCES inmobiliaria (id_inmobiliaria)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE usuario_rol (
    id_usuario        INT UNSIGNED NOT NULL,
    id_rol            INT UNSIGNED NOT NULL,
    fecha_asignacion  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_usuario, id_rol),
    CONSTRAINT fk_usuario_rol_usuario
        FOREIGN KEY (id_usuario) REFERENCES usuario (id_usuario)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_usuario_rol_rol
        FOREIGN KEY (id_rol) REFERENCES rol (id_rol)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE perfil (
    id_perfil         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_usuario        INT UNSIGNED NOT NULL,
    nombres           VARCHAR(80)  NOT NULL,
    apellidos         VARCHAR(80)  NOT NULL,
    tipo_documento    ENUM('CC','CE','TI','PAS') NOT NULL DEFAULT 'CC',
    numero_documento  VARCHAR(20)  NOT NULL,
    telefono          VARCHAR(20)  NULL,
    direccion         VARCHAR(150) NULL,
    foto_url          VARCHAR(255) NULL,
    CONSTRAINT uq_perfil_usuario UNIQUE (id_usuario),
    CONSTRAINT uq_perfil_documento UNIQUE (numero_documento),
    CONSTRAINT fk_perfil_usuario
        FOREIGN KEY (id_usuario) REFERENCES usuario (id_usuario)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- =====================================================================
-- 3. PROPIEDADES
-- =====================================================================

CREATE TABLE propiedad (
    id_propiedad            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_inmobiliaria         INT UNSIGNED NOT NULL,
    id_ciudad               INT UNSIGNED NOT NULL,
    id_tipo                 INT UNSIGNED NOT NULL,
    matricula_inmobiliaria  VARCHAR(30)  NOT NULL,
    titulo                  VARCHAR(120) NOT NULL,
    descripcion             TEXT NULL,
    direccion               VARCHAR(150) NOT NULL,
    precio                  DECIMAL(14,2) NOT NULL,
    area_m2                 DECIMAL(8,2)  NOT NULL,
    num_habitaciones        TINYINT UNSIGNED NULL,
    num_banos               TINYINT UNSIGNED NULL,
    num_parqueaderos        TINYINT UNSIGNED NOT NULL DEFAULT 0,
    operacion               ENUM('venta','arriendo') NOT NULL,
    estado                  ENUM('disponible','reservado','vendido','arrendado') NOT NULL DEFAULT 'disponible',
    activo                  TINYINT(1) NOT NULL DEFAULT 1, -- baja logica
    fecha_publicacion       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_propiedad_matricula UNIQUE (matricula_inmobiliaria),
    CONSTRAINT fk_propiedad_inmobiliaria
        FOREIGN KEY (id_inmobiliaria) REFERENCES inmobiliaria (id_inmobiliaria)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_propiedad_ciudad
        FOREIGN KEY (id_ciudad) REFERENCES ciudad (id_ciudad)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_propiedad_tipo
        FOREIGN KEY (id_tipo) REFERENCES tipo_propiedad (id_tipo)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_propiedad_precio CHECK (precio > 0),
    CONSTRAINT chk_propiedad_area CHECK (area_m2 > 0)
) ENGINE=InnoDB CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE imagen_propiedad (
    id_imagen     INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_propiedad  INT UNSIGNED NOT NULL,
    url_imagen    VARCHAR(255) NOT NULL,
    orden         TINYINT UNSIGNED NOT NULL DEFAULT 1,
    es_principal  TINYINT(1) NOT NULL DEFAULT 0,
    CONSTRAINT fk_imagen_propiedad
        FOREIGN KEY (id_propiedad) REFERENCES propiedad (id_propiedad)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE propiedad_caracteristica (
    id_propiedad       INT UNSIGNED NOT NULL,
    id_caracteristica  INT UNSIGNED NOT NULL,
    valor              VARCHAR(50) NULL,
    PRIMARY KEY (id_propiedad, id_caracteristica),
    CONSTRAINT fk_propcar_propiedad
        FOREIGN KEY (id_propiedad) REFERENCES propiedad (id_propiedad)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_propcar_caracteristica
        FOREIGN KEY (id_caracteristica) REFERENCES caracteristica (id_caracteristica)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE favorito (
    id_usuario      INT UNSIGNED NOT NULL,
    id_propiedad    INT UNSIGNED NOT NULL,
    fecha_agregado  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_usuario, id_propiedad),
    CONSTRAINT fk_favorito_usuario
        FOREIGN KEY (id_usuario) REFERENCES usuario (id_usuario)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_favorito_propiedad
        FOREIGN KEY (id_propiedad) REFERENCES propiedad (id_propiedad)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- =====================================================================
-- 4. OPERACION: CITAS Y SOLICITUDES
-- =====================================================================

CREATE TABLE cita (
    id_cita           INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_propiedad      INT UNSIGNED NOT NULL,
    id_cliente        INT UNSIGNED NOT NULL,
    fecha_hora        DATETIME NOT NULL,
    estado            ENUM('pendiente','confirmada','rechazada','realizada','cancelada') NOT NULL DEFAULT 'pendiente',
    observaciones     VARCHAR(255) NULL,
    fecha_solicitud   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_cita_propiedad_fecha UNIQUE (id_propiedad, fecha_hora),
    CONSTRAINT fk_cita_propiedad
        FOREIGN KEY (id_propiedad) REFERENCES propiedad (id_propiedad)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_cita_cliente
        FOREIGN KEY (id_cliente) REFERENCES usuario (id_usuario)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE solicitud (
    id_solicitud     INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_propiedad     INT UNSIGNED NOT NULL,
    id_cliente       INT UNSIGNED NOT NULL,
    tipo_solicitud   ENUM('compra','arriendo') NOT NULL,
    estado           ENUM('pendiente','en_revision','aprobada','rechazada') NOT NULL DEFAULT 'pendiente',
    fecha_solicitud  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    observaciones    VARCHAR(255) NULL,
    CONSTRAINT fk_solicitud_propiedad
        FOREIGN KEY (id_propiedad) REFERENCES propiedad (id_propiedad)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_solicitud_cliente
        FOREIGN KEY (id_cliente) REFERENCES usuario (id_usuario)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE documento_solicitud (
    id_documento      INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_solicitud      INT UNSIGNED NOT NULL,
    nombre_documento  VARCHAR(100) NOT NULL,
    url_documento     VARCHAR(255) NOT NULL,
    estado            ENUM('pendiente','aprobado','rechazado') NOT NULL DEFAULT 'pendiente',
    fecha_carga       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_documento_solicitud
        FOREIGN KEY (id_solicitud) REFERENCES solicitud (id_solicitud)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- =====================================================================
-- 5. AUDITORIA
-- =====================================================================

CREATE TABLE auditoria (
    id_auditoria     INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_usuario       INT UNSIGNED NULL,
    accion           VARCHAR(100) NOT NULL,
    tabla_afectada   VARCHAR(50) NULL,
    descripcion      VARCHAR(255) NULL,
    fecha_hora       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ip_origen        VARCHAR(45) NULL,
    CONSTRAINT fk_auditoria_usuario
        FOREIGN KEY (id_usuario) REFERENCES usuario (id_usuario)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- =====================================================================
-- INDICES ADICIONALES DE APOYO A CONSULTAS FRECUENTES
-- =====================================================================

CREATE INDEX idx_propiedad_estado_activo ON propiedad (estado, activo);
CREATE INDEX idx_cita_estado ON cita (estado);
CREATE INDEX idx_solicitud_estado ON solicitud (estado);
