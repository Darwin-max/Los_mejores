-- =============================================
--                DATABASE
-- =============================================

CREATE DATABASE banco_cl_kawaii DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE banco_cl_kawaii;

SHOW TABLES;

-- =============================================
--               DROP TABLES
-- =============================================
-- Eliminar tablas en orden correcto para evitar errores de FK

DROP TABLE IF EXISTS alerta_pago;

DROP TABLE IF EXISTS historial_pagos;

DROP TABLE IF EXISTS historial_cuotas;

DROP TABLE IF EXISTS cuota_manejo;

DROP TABLE IF EXISTS pago;

DROP TABLE IF EXISTS cliente;

DROP TABLE IF EXISTS tarjeta;

DROP TABLE IF EXISTS tipo_tarjeta;

DROP TABLE IF EXISTS intereses;

DROP TABLE IF EXISTS descuento;

DROP TABLE IF EXISTS cuenta_bancaria;

DROP TABLE IF EXISTS tipo_cuenta;

DROP TABLE IF EXISTS reporte_cuotas_manejo;


-- =============================================
--        TABLAS DE CATALOGOS/LOOKUPS
-- =============================================

-- 1. Tipo Cuenta
CREATE TABLE tipo_cuenta (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    nombre ENUM('Ahorros', 'Corriente', 'Inversion') NOT NULL,
    INDEX (nombre)
);

-- 2. Descuento
CREATE TABLE descuento (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    nombre ENUM('Basico', 'Platino', 'Diamante') NOT NULL,
    tasa_descuento DECIMAL(5,2) NOT NULL, -- Representa el porcentaje (%)
    INDEX (nombre)
);

-- 3. Intereses
CREATE TABLE intereses (
    id INT AUTO_INCREMENT PRIMARY KEY,
    monto_minimo DECIMAL(12,2) NOT NULL,
    monto_maximo DECIMAL(12,2) NOT NULL,
    tasa_interes DECIMAL(5,2) NOT NULL -- Representa el porcentaje (%)
);

-- 4. Tipo Tarjeta
CREATE TABLE tipo_tarjeta (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    nombre ENUM('Joven', 'Joven Kawaii', 'Joven Uwusito', 'Nomina', 'Nomina Kawaii', 'Nomina Uwusita', 'Visa', 'Visa Kawaii', 'Visa Uwusita') NOT NULL,
    descuento_id INT NOT NULL,
    INDEX (nombre)
);

-- 5. Cuenta Bancaria
CREATE TABLE cuenta_bancaria (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    numero_cuenta VARCHAR(10) NOT NULL UNIQUE,
    tipo_cuenta_id INT NOT NULL,
    monto DECIMAL(10,2) NOT NULL,
    estado ENUM('Activa', 'Inactiva', 'Bloqueada', 'Cerrada') DEFAULT 'Activa',
    fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX (numero_cuenta, estado)
);

-- 6. Tarjeta
CREATE TABLE tarjeta (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    numero VARCHAR(16) NOT NULL UNIQUE,
    tipo_tarjeta_id INT NOT NULL,
    cuenta_bancaria_id INT NOT NULL,
    fecha_activacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_expiracion DATETIME NOT NULL,
    estado ENUM('Activa', 'Inactiva', 'Bloqueada', 'Cerrada') DEFAULT 'Activa',
    INDEX (numero, estado)
);

-- 7. Cliente
CREATE TABLE cliente (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    telefono VARCHAR(10) NOT NULL UNIQUE,
    correo VARCHAR(100) NOT NULL UNIQUE,
    direccion VARCHAR(100) NOT NULL,
    tarjeta_id INT NOT NULL UNIQUE,
    INDEX (nombre, telefono)
);

-- 8. Cuota Manejo
CREATE TABLE cuota_manejo (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    cliente_id INT NOT NULL,
    tarjeta_id INT NOT NULL,
    interes_id INT NOT NULL,
    descuento_id INT NOT NULL,
    total_cuotas INT NOT NULL,
    total_monto DECIMAL(10,2) NOT NULL,
    fecha DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX (cliente_id, fecha)
);

-- 9. Pago
CREATE TABLE pago (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    cliente_id INT NOT NULL,
    tarjeta_id INT NOT NULL,
    total DECIMAL(10,2) NOT NULL,
    fecha DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    estado ENUM('Pendiente', 'Pagado', 'Vencido') NOT NULL DEFAULT 'Pendiente',
    INDEX (cliente_id, estado)
);

-- 10. Historial Pagos
CREATE TABLE historial_pagos (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    pago_id INT NOT NULL,
    total_monto DECIMAL(10,2) NOT NULL,
    fecha_pago DATETIME NOT NULL,
    fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX (fecha_pago)
);

-- 11. Historial Cuotas
CREATE TABLE historial_cuotas (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    cuota_manejo_id INT NOT NULL,
    total_monto DECIMAL(10,2) NOT NULL,
    fecha_cuota DATETIME NOT NULL,
    fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX (fecha_cuota)
);

-- 12. Alerta Pago
CREATE TABLE alerta_pago (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    cliente_id INT NOT NULL,
    correo_cliente VARCHAR(100) NOT NULL,
    pago_id INT NOT NULL,
    total DECIMAL(10,2) NOT NULL,
    fecha_pago DATETIME NOT NULL,
    fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX (cliente_id)
);

-- 13. Reporte Cuotas Manejo
CREATE TABLE reporte_cuotas_manejo (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    fecha_generacion DATETIME NOT NULL,
    total_monto DECIMAL(15,2) NOT NULL
);

-- LLaves foraneas

ALTER TABLE cuota_manejo ADD CONSTRAINT cuota_manejo_cliente_id
    FOREIGN KEY (cliente_id) REFERENCES cliente(id);

ALTER TABLE cuota_manejo ADD CONSTRAINT cuota_manejo_tarjeta_id
    FOREIGN KEY (tarjeta_id) REFERENCES tarjeta(id);

ALTER TABLE cuota_manejo ADD CONSTRAINT cuota_manejo_interes_id
    FOREIGN KEY (interes_id) REFERENCES intereses(id);

ALTER TABLE cuota_manejo ADD CONSTRAINT cuota_manejo_descuento_id
    FOREIGN KEY (descuento_id) REFERENCES descuento(id);

ALTER TABLE pago ADD CONSTRAINT pago_cliente_id
    FOREIGN KEY (cliente_id) REFERENCES cliente(id);

ALTER TABLE pago ADD CONSTRAINT pago_tarjeta_id
    FOREIGN KEY (tarjeta_id) REFERENCES tarjeta(id);

ALTER TABLE historial_pagos ADD CONSTRAINT historial_pagos_pago_id
    FOREIGN KEY (pago_id) REFERENCES pago(id);

ALTER TABLE historial_cuotas ADD CONSTRAINT historial_cuotas_cuota_manejo_id
    FOREIGN KEY (cuota_manejo_id) REFERENCES cuota_manejo(id);

ALTER TABLE tarjeta ADD CONSTRAINT tarjeta_tipo_tarjeta_id
    FOREIGN KEY (tipo_tarjeta_id) REFERENCES tipo_tarjeta(id);

ALTER TABLE tarjeta ADD CONSTRAINT tarjeta_cuenta_bancaria_id
    FOREIGN KEY (cuenta_bancaria_id) REFERENCES cuenta_bancaria(id);

ALTER TABLE tipo_tarjeta ADD CONSTRAINT tipo_tarjeta_descuento_id
    FOREIGN KEY (descuento_id) REFERENCES descuento(id);

ALTER TABLE cuenta_bancaria ADD CONSTRAINT cuenta_bancaria_tipo_cuenta_id
    FOREIGN KEY (tipo_cuenta_id) REFERENCES tipo_cuenta(id);

ALTER TABLE cliente ADD CONSTRAINT cliente_tarjeta_id
    FOREIGN KEY (tarjeta_id) REFERENCES tarjeta(id);

ALTER TABLE alerta_pago ADD CONSTRAINT alerta_pago_cliente_id
    FOREIGN KEY (cliente_id) REFERENCES cliente(id);

ALTER TABLE alerta_pago ADD CONSTRAINT alerta_pago_pago_id
    FOREIGN KEY (pago_id) REFERENCES pago(id);