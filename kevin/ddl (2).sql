-- ================================================================================= --
-- SECCIÓN 1: GESTIÓN DE USUARIOS, ROLES Y PERMISOS
-- ================================================================================= --

-- 1: Categoriza los roles en grupos generales (Ej: roles de sistema, roles de negocio).
CREATE TABLE `Tipo_Rol` (
    `id_tipo_rol` INT(11) NOT NULL AUTO_INCREMENT,
    `nombre_tipo_rol` VARCHAR(50) NOT NULL,
    `descripcion` TEXT,
    PRIMARY KEY (`id_tipo_rol`),
    UNIQUE KEY `uq_nombre_tipo_rol` (`nombre_tipo_rol`)
);

-- 2: Define los roles específicos que pueden ser asignados a los usuarios del sistema.
CREATE TABLE `Rol_Usuario` (
    `id_rol` INT(11) NOT NULL AUTO_INCREMENT,
    `nombre_rol` VARCHAR(50) NOT NULL,
    `tipo_rol_id` INT(11) NOT NULL,
    `descripcion` TEXT,
    PRIMARY KEY (`id_rol`),
    UNIQUE KEY `uq_nombre_rol` (`nombre_rol`),
    KEY `idx_tipo_rol_id` (`tipo_rol_id`),
    CONSTRAINT `fk_rol_tipo` FOREIGN KEY (`tipo_rol_id`) REFERENCES `Tipo_Rol` (`id_tipo_rol`) ON DELETE CASCADE ON UPDATE CASCADE
);

-- 3: Tabla central que almacena la información de todas las personas que interactúan con el sistema.
CREATE TABLE `Usuario` (
    `id_usuario` INT(11) NOT NULL AUTO_INCREMENT,
    `username` VARCHAR(50) NOT NULL,
    `password_hash` VARCHAR(255) NOT NULL,
    `nombre_completo` VARCHAR(100) NOT NULL,
    `correo_electronico` VARCHAR(100) NOT NULL,
    `rol_id_usuario` INT(11) NOT NULL,
    `fecha_creacion` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `activo` BOOLEAN NOT NULL DEFAULT TRUE,
    PRIMARY KEY (`id_usuario`),
    UNIQUE KEY `uq_username` (`username`),
    UNIQUE KEY `uq_correo_electronico` (`correo_electronico`),
    KEY `idx_rol_id_usuario` (`rol_id_usuario`),
    CONSTRAINT `fk_usuario_rol` FOREIGN KEY (`rol_id_usuario`) REFERENCES `Rol_Usuario` (`id_rol`) ON DELETE CASCADE ON UPDATE CASCADE
);

-- ================================================================================= --
-- SECCIÓN 2: ENTIDADES PRINCIPALES (CLIENTES, EMPLEADOS Y SUCURSALES)
-- ================================================================================= --

-- 4: Almacena información específica de los usuarios que son clientes de la entidad.
CREATE TABLE `Cliente` (
    `id_cliente` INT(11) NOT NULL,
    `fecha_registro` DATE NOT NULL,
    `numero_identificacion` VARCHAR(30) NOT NULL,
    PRIMARY KEY (`id_cliente`),
    UNIQUE KEY `uq_numero_identificacion` (`numero_identificacion`),
    CONSTRAINT `fk_cliente_usuario` FOREIGN KEY (`id_cliente`) REFERENCES `Usuario` (`id_usuario`) ON DELETE CASCADE ON UPDATE CASCADE
);

-- 5: Registra las diferentes sucursales o agencias físicas de la entidad.
CREATE TABLE `Sucursal` (
    `id_sucursal` INT(11) NOT NULL AUTO_INCREMENT,
    `nombre_sucursal` VARCHAR(100) NOT NULL,
    `direccion_id_sucursal` INT(11) NOT NULL,
    PRIMARY KEY (`id_sucursal`),
    UNIQUE KEY `uq_nombre_sucursal` (`nombre_sucursal`),
    KEY `idx_direccion_id_sucursal` (`direccion_id_sucursal`)
);

-- 6: Almacena información específica de los usuarios que son empleados.
CREATE TABLE `Empleado` (
    `id_empleado` INT(11) NOT NULL,
    `cargo` VARCHAR(30) NOT NULL,
    `fecha_ingreso` DATE NOT NULL,
    `sucursal_id_empleado` INT(11) NOT NULL,
    PRIMARY KEY (`id_empleado`),
    KEY `idx_sucursal_id_empleado` (`sucursal_id_empleado`),
    CONSTRAINT `fk_empleado_usuario` FOREIGN KEY (`id_empleado`) REFERENCES `Usuario` (`id_usuario`) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_empleado_sucursal` FOREIGN KEY (`sucursal_id_empleado`) REFERENCES `Sucursal` (`id_sucursal`) ON DELETE CASCADE ON UPDATE CASCADE
);

-- ================================================================================= --
-- SECCIÓN 3: GEOGRAFÍA Y DIRECCIONES
-- ================================================================================= --

-- 7: Catálogo de países según el estándar ISO 3166-1.
CREATE TABLE `Pais` (
    `id_pais` INT(11) NOT NULL AUTO_INCREMENT,
    `nombre_pais` VARCHAR(60) NOT NULL,
    `codigo_iso` CHAR(2) NOT NULL,
    PRIMARY KEY (`id_pais`),
    UNIQUE KEY `uq_nombre_pais` (`nombre_pais`),
    UNIQUE KEY `uq_codigo_iso` (`codigo_iso`)
);

-- 8: Catálogo de divisiones administrativas de primer nivel (estados, provincias, etc.).
CREATE TABLE `Departamento` (
    `id_departamento` INT(11) NOT NULL AUTO_INCREMENT,
    `id_pais_departamento` INT(11) NOT NULL,
    `nombre_departamento` VARCHAR(100) NOT NULL,
    PRIMARY KEY (`id_departamento`),
    KEY `idx_id_pais_departamento` (`id_pais_departamento`),
    CONSTRAINT `fk_departamento_pais` FOREIGN KEY (`id_pais_departamento`) REFERENCES `Pais` (`id_pais`) ON DELETE CASCADE ON UPDATE CASCADE
);

-- 9: Catálogo de ciudades o municipios dentro de un departamento.
CREATE TABLE `Ciudad` (
    `id_ciudad` INT(11) NOT NULL AUTO_INCREMENT,
    `id_departamento_ciudad` INT(11) NOT NULL,
    `nombre_ciudad` VARCHAR(100) NOT NULL,
    PRIMARY KEY (`id_ciudad`),
    KEY `idx_id_departamento_ciudad` (`id_departamento_ciudad`),
    CONSTRAINT `fk_ciudad_departamento` FOREIGN KEY (`id_departamento_ciudad`) REFERENCES `Departamento` (`id_departamento`) ON DELETE CASCADE ON UPDATE CASCADE
);

-- 10: Almacena direcciones postales completas y estructuradas.
CREATE TABLE `Direccion` (
    `id_direccion` INT(11) NOT NULL AUTO_INCREMENT,
    `calle_principal` VARCHAR(255) NOT NULL,
    `numero_o_interseccion` VARCHAR(50),
    `complemento` VARCHAR(255),
    `codigo_postal` VARCHAR(20),
    `ciudad_id_direccion` INT(11) NOT NULL,
    PRIMARY KEY (`id_direccion`),
    KEY `idx_ciudad_id_direccion` (`ciudad_id_direccion`),
    CONSTRAINT `fk_direccion_ciudad` FOREIGN KEY (`ciudad_id_direccion`) REFERENCES `Ciudad` (`id_ciudad`) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Resuelve dependencia circular entre Sucursal y Direccion.
ALTER TABLE `Sucursal`
ADD CONSTRAINT `fk_sucursal_direccion` FOREIGN KEY (`direccion_id_sucursal`) REFERENCES `Direccion` (`id_direccion`) ON DELETE CASCADE ON UPDATE CASCADE;

-- 11: Tabla de enlace para asociar múltiples direcciones a un mismo usuario.
CREATE TABLE `Direccion_Usuario` (
    `id_direccion_usuario` INT(11) NOT NULL AUTO_INCREMENT,
    `usuario_id_direccion` INT(11) NOT NULL,
    `direccion_id_usuario` INT(11) NOT NULL,
    `tipo_uso_direccion` VARCHAR(50),
    `es_principal` BOOLEAN NOT NULL DEFAULT FALSE,
    PRIMARY KEY (`id_direccion_usuario`),
    KEY `idx_usuario_id_direccion` (`usuario_id_direccion`),
    KEY `idx_direccion_id_usuario` (`direccion_id_usuario`),
    CONSTRAINT `fk_dirusuario_usuario` FOREIGN KEY (`usuario_id_direccion`) REFERENCES `Usuario` (`id_usuario`) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_dirusuario_direccion` FOREIGN KEY (`direccion_id_usuario`) REFERENCES `Direccion` (`id_direccion`) ON DELETE CASCADE ON UPDATE CASCADE
);

-- ================================================================================= --
-- SECCIÓN 4: INFORMACIÓN DE CONTACTO (TELÉFONOS)
-- ================================================================================= --

-- 12: Catálogo para clasificar los números de teléfono (Ej: Móvil, Casa, Trabajo).
CREATE TABLE `Tipo_Telefono` (
    `id_tipo_telefono` INT(11) NOT NULL AUTO_INCREMENT,
    `nombre_tipo_telefono` VARCHAR(100) NOT NULL,
    `descripcion` TEXT,
    PRIMARY KEY (`id_tipo_telefono`),
    UNIQUE KEY `uq_nombre_tipo_telefono` (`nombre_tipo_telefono`)
);

-- 13: Almacena los prefijos telefónicos internacionales por país.
CREATE TABLE `Prefijo_Telefonico` (
    `id_prefijo` INT(11) NOT NULL AUTO_INCREMENT,
    `pais_id_prefijo` INT(11) NOT NULL,
    `codigo_pais_telefonico` VARCHAR(5) NOT NULL,
    PRIMARY KEY (`id_prefijo`),
    KEY `idx_pais_id_prefijo` (`pais_id_prefijo`),
    CONSTRAINT `fk_prefijo_pais` FOREIGN KEY (`pais_id_prefijo`) REFERENCES `Pais` (`id_pais`) ON DELETE CASCADE ON UPDATE CASCADE
);

-- 14: Tabla de enlace para asociar múltiples teléfonos a un usuario.
CREATE TABLE `Telefono_Usuario` (
    `id_telefono_usuario` INT(11) NOT NULL AUTO_INCREMENT,
    `usuario_id_telefono` INT(11) NOT NULL,
    `id_tipo_telefono` INT(11) NOT NULL,
    `prefijo_id_telefono` INT(11) NOT NULL,
    `numero_local` VARCHAR(15) NOT NULL,
    `es_principal` BOOLEAN NOT NULL,
    PRIMARY KEY (`id_telefono_usuario`),
    KEY `idx_usuario_id_telefono` (`usuario_id_telefono`),
    KEY `idx_id_tipo_telefono_usu` (`id_tipo_telefono`),
    KEY `idx_prefijo_id_telefono_usu` (`prefijo_id_telefono`),
    CONSTRAINT `fk_telusuario_usuario` FOREIGN KEY (`usuario_id_telefono`) REFERENCES `Usuario` (`id_usuario`) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_telusuario_tipo` FOREIGN KEY (`id_tipo_telefono`) REFERENCES `Tipo_Telefono` (`id_tipo_telefono`) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_telusuario_prefijo` FOREIGN KEY (`prefijo_id_telefono`) REFERENCES `Prefijo_Telefonico` (`id_prefijo`) ON DELETE CASCADE ON UPDATE CASCADE
);

-- 15: Tabla de enlace para asociar múltiples teléfonos a una sucursal.
CREATE TABLE `Telefono_Sucursal` (
    `id_telefono_sucursal` INT(11) NOT NULL AUTO_INCREMENT,
    `sucursal_id_telefono` INT(11) NOT NULL,
    `tipo_telefono_id_sucursal` INT(11) NOT NULL,
    `prefijo_telefono_id_sucursal` INT(11) NOT NULL,
    `numero_local` VARCHAR(15) NOT NULL,
    `es_principal` BOOLEAN NOT NULL,
    PRIMARY KEY (`id_telefono_sucursal`),
    KEY `idx_sucursal_id_telefono` (`sucursal_id_telefono`),
    KEY `idx_tipo_telefono_id_suc` (`tipo_telefono_id_sucursal`),
    KEY `idx_prefijo_telefono_id_suc` (
        `prefijo_telefono_id_sucursal`
    ),
    CONSTRAINT `fk_telsucursal_sucursal` FOREIGN KEY (`sucursal_id_telefono`) REFERENCES `Sucursal` (`id_sucursal`) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_telsucursal_tipo` FOREIGN KEY (`tipo_telefono_id_sucursal`) REFERENCES `Tipo_Telefono` (`id_tipo_telefono`) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_telsucursal_prefijo` FOREIGN KEY (
        `prefijo_telefono_id_sucursal`
    ) REFERENCES `Prefijo_Telefonico` (`id_prefijo`) ON DELETE CASCADE ON UPDATE CASCADE
);

-- ================================================================================= --
-- SECCIÓN 5: GESTIÓN DE CUENTAS BANCARIAS
-- ================================================================================= --

-- 16: Catálogo de los posibles estados de una cuenta bancaria (Ej: Activa, Bloqueada, Cerrada).
CREATE TABLE `Estado_Cuenta` (
    `id_estado_cuenta` INT(11) NOT NULL AUTO_INCREMENT,
    `nombre_estado` VARCHAR(50) NOT NULL,
    `descripcion` TEXT,
    PRIMARY KEY (`id_estado_cuenta`),
    UNIQUE KEY `uq_nombre_estado` (`nombre_estado`)
);

-- 17: Catálogo para los tipos de cuentas bancarias (Ej: Ahorros, Corriente).
CREATE TABLE `Tipo_Cuenta_Bancaria` (
    `id_tipo_cuenta` INT(11) NOT NULL AUTO_INCREMENT,
    `nombre_tipo` VARCHAR(50) NOT NULL,
    `descripcion` TEXT,
    PRIMARY KEY (`id_tipo_cuenta`),
    UNIQUE KEY `uq_nombre_tipo_cta` (`nombre_tipo`)
);

-- 18: Catálogo de monedas y sus códigos ISO (Ej: USD, COP, EUR).
CREATE TABLE `Moneda` (
    `id_moneda` INT(11) NOT NULL AUTO_INCREMENT,
    `codigo_iso_moneda` VARCHAR(3) NOT NULL,
    `nombre_moneda` VARCHAR(50) NOT NULL,
    `simbolo` VARCHAR(5),
    PRIMARY KEY (`id_moneda`),
    UNIQUE KEY `uq_codigo_iso_moneda` (`codigo_iso_moneda`)
);

-- 19: Almacena la información de las cuentas bancarias de los clientes.
CREATE TABLE `Cuenta_Bancaria` (
    `id_cuenta` INT(11) NOT NULL AUTO_INCREMENT,
    `cliente_id_cuenta` INT(11) NOT NULL,
    `numero_cuenta` VARCHAR(20) NOT NULL,
    `tipo_cuenta_id` INT(11) NOT NULL,
    `fecha_apertura` DATE NOT NULL,
    `estado_cuenta_id` INT(11) NOT NULL,
    `saldo_actual` DECIMAL(18, 2) NOT NULL DEFAULT 0.00,
    `moneda_id` INT(11) NOT NULL,
    PRIMARY KEY (`id_cuenta`),
    UNIQUE KEY `uq_numero_cuenta` (`numero_cuenta`),
    KEY `idx_cliente_id_cuenta` (`cliente_id_cuenta`),
    KEY `idx_tipo_cuenta_id` (`tipo_cuenta_id`),
    KEY `idx_estado_cuenta_id` (`estado_cuenta_id`),
    KEY `idx_moneda_id` (`moneda_id`),
    CONSTRAINT `fk_cuenta_cliente` FOREIGN KEY (`cliente_id_cuenta`) REFERENCES `Cliente` (`id_cliente`) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_cuenta_tipocuenta` FOREIGN KEY (`tipo_cuenta_id`) REFERENCES `Tipo_Cuenta_Bancaria` (`id_tipo_cuenta`) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_cuenta_estadocuenta` FOREIGN KEY (`estado_cuenta_id`) REFERENCES `Estado_Cuenta` (`id_estado_cuenta`) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_cuenta_moneda` FOREIGN KEY (`moneda_id`) REFERENCES `Moneda` (`id_moneda`) ON DELETE CASCADE ON UPDATE CASCADE
);

-- ================================================================================= --
-- SECCIÓN 6: MOVIMIENTOS Y SALDOS DE CUENTAS
-- ================================================================================= --

-- 20: Catálogo para los tipos de transacciones (Ej: Depósito, Retiro, Transferencia).
CREATE TABLE `Tipo_Movimiento_Cuenta` (
    `id_tipo_movimiento` INT(11) NOT NULL AUTO_INCREMENT,
    `nombre_tipo` VARCHAR(50) NOT NULL,
    `es_debito` BOOLEAN NOT NULL,
    `descripcion` TEXT,
    PRIMARY KEY (`id_tipo_movimiento`),
    UNIQUE KEY `uq_nombre_tipo_mov` (`nombre_tipo`)
);

-- 21: Registra cada cambio en el saldo de una cuenta bancaria, creando un estado de cuenta.
CREATE TABLE `Historial_Saldo_Cuenta` (
    `id_historial_saldo` INT(11) NOT NULL AUTO_INCREMENT,
    `cuenta_id_saldo` INT(11) NOT NULL,
    `fecha_registro` DATETIME NOT NULL,
    `saldo_anterior` DECIMAL(18, 2) NOT NULL,
    `monto_movimiento` DECIMAL(18, 2) NOT NULL,
    `saldo_resultante` DECIMAL(18, 2) NOT NULL,
    `tipo_movimiento_id` INT(11) NOT NULL,
    `id_referencia_transaccion` BIGINT,
    PRIMARY KEY (`id_historial_saldo`),
    KEY `idx_cuenta_id_saldo` (`cuenta_id_saldo`),
    KEY `idx_tipo_movimiento_id` (`tipo_movimiento_id`),
    CONSTRAINT `fk_historial_cuenta` FOREIGN KEY (`cuenta_id_saldo`) REFERENCES `Cuenta_Bancaria` (`id_cuenta`) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_historial_tipomovimiento` FOREIGN KEY (`tipo_movimiento_id`) REFERENCES `Tipo_Movimiento_Cuenta` (`id_tipo_movimiento`) ON DELETE CASCADE ON UPDATE CASCADE
);

-- ================================================================================= --
-- SECCIÓN 7: GESTIÓN DE TARJETAS
-- ================================================================================= --

-- 22: Catálogo para los tipos de tarjetas (Ej: Débito, Crédito).
CREATE TABLE `Tipo_Tarjeta` (
    `id_tipo_tarjeta` INT(11) NOT NULL AUTO_INCREMENT,
    `nombre_tipo_tarjeta` VARCHAR(50) NOT NULL,
    `descripcion` TEXT,
    PRIMARY KEY (`id_tipo_tarjeta`),
    UNIQUE KEY `uq_nombre_tipo_tarjeta` (`nombre_tipo_tarjeta`)
);

-- 23: Catálogo de los posibles estados de una tarjeta (Ej: Activa, Extraviada, Vencida).
CREATE TABLE `Estado_Tarjeta` (
    `id_estado_tarjeta` INT(11) NOT NULL AUTO_INCREMENT,
    `nombre_estado_tarjeta` VARCHAR(50) NOT NULL,
    `descripcion` TEXT,
    PRIMARY KEY (`id_estado_tarjeta`),
    UNIQUE KEY `uq_nombre_estado_tarjeta` (`nombre_estado_tarjeta`)
);

-- 24: Catálogo de las marcas o franquicias de tarjetas (Ej: Visa, Mastercard).
CREATE TABLE `Marca_Tarjeta` (
    `id_marca_tarjeta` INT(11) NOT NULL AUTO_INCREMENT,
    `nombre_marca` VARCHAR(50) NOT NULL,
    `descripcion` TEXT,
    PRIMARY KEY (`id_marca_tarjeta`),
    UNIQUE KEY `uq_nombre_marca` (`nombre_marca`)
);

-- 25: Almacena la información de las tarjetas de crédito o débito asociadas a los clientes.
CREATE TABLE `Tarjeta` (
    `id_tarjeta` INT(11) NOT NULL AUTO_INCREMENT,
    `cliente_id_tarjeta` INT(11) NOT NULL,
    `tipo_tarjeta_id` INT(11) NOT NULL,
    `marca_tarjeta_id` INT(11) NOT NULL,
    `cuenta_id_tarjeta` INT(11) NOT NULL,
    `numero_tarjeta_hash` VARCHAR(255) NOT NULL,
    `ultimos_4_digitos` VARCHAR(4) NOT NULL,
    `fecha_emision` DATE NOT NULL,
    `fecha_vencimiento` DATE NOT NULL,
    `estado_tarjeta_id` INT(11) NOT NULL,
    `linea_credito` DECIMAL(18, 2) NOT NULL,
    PRIMARY KEY (`id_tarjeta`),
    UNIQUE KEY `uq_numero_tarjeta_hash` (`numero_tarjeta_hash`),
    KEY `idx_cliente_id_tarjeta` (`cliente_id_tarjeta`),
    KEY `idx_tipo_tarjeta_id` (`tipo_tarjeta_id`),
    KEY `idx_marca_tarjeta_id` (`marca_tarjeta_id`),
    KEY `idx_cuenta_id_tarjeta` (`cuenta_id_tarjeta`),
    KEY `idx_estado_tarjeta_id` (`estado_tarjeta_id`),
    CONSTRAINT `fk_tarjeta_cliente` FOREIGN KEY (`cliente_id_tarjeta`) REFERENCES `Cliente` (`id_cliente`) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_tarjeta_tipotarjeta` FOREIGN KEY (`tipo_tarjeta_id`) REFERENCES `Tipo_Tarjeta` (`id_tipo_tarjeta`) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_tarjeta_marcatarjeta` FOREIGN KEY (`marca_tarjeta_id`) REFERENCES `Marca_Tarjeta` (`id_marca_tarjeta`) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_tarjeta_cuenta` FOREIGN KEY (`cuenta_id_tarjeta`) REFERENCES `Cuenta_Bancaria` (`id_cuenta`) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_tarjeta_estadotarjeta` FOREIGN KEY (`estado_tarjeta_id`) REFERENCES `Estado_Tarjeta` (`id_estado_tarjeta`) ON DELETE CASCADE ON UPDATE CASCADE
);

-- 26: Registra los cambios en la línea de crédito de una tarjeta a lo largo del tiempo.
CREATE TABLE `Historial_Linea_Credito_Tarjeta` (
    `id_historial_linea` INT(11) NOT NULL AUTO_INCREMENT,
    `tarjeta_id_historial` INT(11) NOT NULL,
    `fecha_cambio` DATETIME NOT NULL,
    `linea_anterior` DECIMAL(18, 2) NOT NULL,
    `linea_actual` DECIMAL(18, 2) NOT NULL,
    `motivo_cambio` VARCHAR(255),
    `id_registrado_por_empleado` INT(11) NOT NULL,
    PRIMARY KEY (`id_historial_linea`),
    KEY `idx_tarjeta_id_historial` (`tarjeta_id_historial`),
    KEY `idx_id_registrado_por_empleado` (`id_registrado_por_empleado`),
    CONSTRAINT `fk_histlinea_tarjeta` FOREIGN KEY (`tarjeta_id_historial`) REFERENCES `Tarjeta` (`id_tarjeta`) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_histlinea_empleado` FOREIGN KEY (`id_registrado_por_empleado`) REFERENCES `Empleado` (`id_empleado`) ON DELETE CASCADE ON UPDATE CASCADE
);

-- ================================================================================= --
-- SECCIÓN 8: GESTIÓN DE CUOTAS Y PAGOS
-- ================================================================================= --

-- 27: Catálogo de los tipos de descuentos aplicables a las cuotas de manejo.
CREATE TABLE `Tipo_Descuento` (
    `id_tipo_descuento` INT(11) NOT NULL AUTO_INCREMENT,
    `nombre_descuento` VARCHAR(50) NOT NULL,
    `porcentaje_descuento` DECIMAL(5, 4) NOT NULL,
    PRIMARY KEY (`id_tipo_descuento`),
    UNIQUE KEY `uq_nombre_descuento` (`nombre_descuento`)
);

-- 28: Tabla de enlace que aplica un tipo de descuento a una tarjeta durante un período específico.
CREATE TABLE `Tarjeta_Descuento_Historico` (
    `id_tarjeta_descuento_historico` INT(11) NOT NULL AUTO_INCREMENT,
    `tarjeta_id_descuento` INT(11) NOT NULL,
    `tipo_descuento_id` INT(11) NOT NULL,
    `fecha_inicio_aplicacion` DATE NOT NULL,
    `fecha_fin_aplicacion` DATE,
    PRIMARY KEY (
        `id_tarjeta_descuento_historico`
    ),
    KEY `idx_tarjeta_id_descuento` (`tarjeta_id_descuento`),
    KEY `idx_tipo_descuento_id` (`tipo_descuento_id`),
    CONSTRAINT `fk_descuhist_tarjeta` FOREIGN KEY (`tarjeta_id_descuento`) REFERENCES `Tarjeta` (`id_tarjeta`) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_descuhist_tipodescuento` FOREIGN KEY (`tipo_descuento_id`) REFERENCES `Tipo_Descuento` (`id_tipo_descuento`) ON DELETE CASCADE ON UPDATE CASCADE
);

-- 29: Catálogo de los posibles estados de una cuota de manejo (Ej: Pendiente, Pagada, Vencida).
CREATE TABLE `Estado_Cuota` (
    `id_estado_cuota` INT(11) NOT NULL AUTO_INCREMENT,
    `nombre_estado_cuota` VARCHAR(50) NOT NULL,
    `descripcion` TEXT,
    PRIMARY KEY (`id_estado_cuota`),
    UNIQUE KEY `uq_nombre_estado_cuota` (`nombre_estado_cuota`)
);

-- 30: Registra las cuotas de manejo generadas para cada tarjeta de crédito.
CREATE TABLE `Cuota_Manejo` (
    `id_cuota` INT(11) NOT NULL AUTO_INCREMENT,
    `tarjeta_id_cuota` INT(11) NOT NULL,
    `fecha_generacion` DATE NOT NULL,
    `monto_base` DECIMAL(10, 2) NOT NULL,
    `id_tarjeta_descuento_historico` INT(11),
    `monto_final_a_pagar` DECIMAL(10, 2) NOT NULL,
    `fecha_vencimiento_pago` DATE NOT NULL,
    `estado_cuota_id` INT(11) NOT NULL,
    PRIMARY KEY (`id_cuota`),
    KEY `idx_tarjeta_id_cuota` (`tarjeta_id_cuota`),
    KEY `idx_id_tarjeta_descuento_historico` (
        `id_tarjeta_descuento_historico`
    ),
    KEY `idx_estado_cuota_id` (`estado_cuota_id`),
    CONSTRAINT `fk_cuota_tarjeta` FOREIGN KEY (`tarjeta_id_cuota`) REFERENCES `Tarjeta` (`id_tarjeta`) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_cuota_descuentohistorico` FOREIGN KEY (
        `id_tarjeta_descuento_historico`
    ) REFERENCES `Tarjeta_Descuento_Historico` (
        `id_tarjeta_descuento_historico`
    ) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_cuota_estadocuota` FOREIGN KEY (`estado_cuota_id`) REFERENCES `Estado_Cuota` (`id_estado_cuota`) ON DELETE CASCADE ON UPDATE CASCADE
);

-- 31: Categoriza los métodos de pago (Ej: En línea, Presencial, Débito automático).
CREATE TABLE `Tipo_Metodo_Pago` (
    `id_tipo_metodo_pago` INT(11) NOT NULL AUTO_INCREMENT,
    `nombre_tipo` VARCHAR(50) NOT NULL,
    `descripcion` TEXT,
    PRIMARY KEY (`id_tipo_metodo_pago`),
    UNIQUE KEY `uq_nombre_tipo_met_pago` (`nombre_tipo`)
);

-- 32: Catálogo de los métodos de pago específicos (Ej: Tarjeta de Crédito, PSE, Efectivo).
CREATE TABLE `Metodo_Pago` (
    `id_metodo_pago` INT(11) NOT NULL AUTO_INCREMENT,
    `nombre_metodo_pago` VARCHAR(50) NOT NULL,
    `tipo_metodo_pago_id` INT(11) NOT NULL,
    `descripcion` TEXT,
    PRIMARY KEY (`id_metodo_pago`),
    UNIQUE KEY `uq_nombre_metodo_pago` (`nombre_metodo_pago`),
    KEY `idx_tipo_metodo_pago_id` (`tipo_metodo_pago_id`),
    CONSTRAINT `fk_metodopago_tipometodo` FOREIGN KEY (`tipo_metodo_pago_id`) REFERENCES `Tipo_Metodo_Pago` (`id_tipo_metodo_pago`) ON DELETE CASCADE ON UPDATE CASCADE
);

-- 33: Registra cada pago realizado por un cliente para saldar una cuota de manejo.
CREATE TABLE `Pago` (
    `id_pago` INT(11) NOT NULL AUTO_INCREMENT,
    `cuota_id_pago` INT(11) NOT NULL,
    `monto_pagado` DECIMAL(10, 2) NOT NULL,
    `fecha_pago` DATETIME NOT NULL,
    `metodo_pago_id` INT(11) NOT NULL,
    `referencia_transaccion` VARCHAR(100),
    `empleado_registro_id` INT(11),
    PRIMARY KEY (`id_pago`),
    KEY `idx_cuota_id_pago` (`cuota_id_pago`),
    KEY `idx_metodo_pago_id` (`metodo_pago_id`),
    KEY `idx_empleado_registro_id` (`empleado_registro_id`),
    CONSTRAINT `fk_pago_cuota` FOREIGN KEY (`cuota_id_pago`) REFERENCES `Cuota_Manejo` (`id_cuota`) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_pago_metodopago` FOREIGN KEY (`metodo_pago_id`) REFERENCES `Metodo_Pago` (`id_metodo_pago`) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_pago_empleado` FOREIGN KEY (`empleado_registro_id`) REFERENCES `Empleado` (`id_empleado`) ON DELETE CASCADE ON UPDATE CASCADE
);

-- ================================================================================= --
-- SECCIÓN 9: HISTORIAL Y AUDITORÍA
-- ================================================================================= --

-- 34: Catálogo para clasificar los eventos en el historial de un pago (Ej: Pago registrado, Pago revertido).
CREATE TABLE `Tipo_Evento_Historial_Pago` (
    `id_tipo_evento` INT(11) NOT NULL AUTO_INCREMENT,
    `nombre_evento` VARCHAR(50) NOT NULL,
    `descripcion` TEXT,
    PRIMARY KEY (`id_tipo_evento`),
    UNIQUE KEY `uq_nombre_evento_hist` (`nombre_evento`)
);

-- 35: Registra el ciclo de vida y los eventos asociados a un pago específico.
CREATE TABLE `Historial_Pagos` (
    `id_historial_pago` INT(11) NOT NULL AUTO_INCREMENT,
    `pago_id_historial` INT(11) NOT NULL,
    `fecha_registro_historial` DATETIME NOT NULL,
    `tipo_evento_id_historial` INT(11) NOT NULL,
    `observaciones` TEXT,
    PRIMARY KEY (`id_historial_pago`),
    KEY `idx_pago_id_historial` (`pago_id_historial`),
    KEY `idx_tipo_evento_id_historial` (`tipo_evento_id_historial`),
    CONSTRAINT `fk_histpago_pago` FOREIGN KEY (`pago_id_historial`) REFERENCES `Pago` (`id_pago`) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_histpago_tipoevento` FOREIGN KEY (`tipo_evento_id_historial`) REFERENCES `Tipo_Evento_Historial_Pago` (`id_tipo_evento`) ON DELETE CASCADE ON UPDATE CASCADE
);

-- 36: Tabla para registrar todas las acciones importantes realizadas en el sistema por los usuarios.
CREATE TABLE `Auditoria_Sistema` (
    `id_auditoria` INT(11) NOT NULL AUTO_INCREMENT,
    `fecha_hora` DATETIME NOT NULL,
    `usuario_id_auditoria` INT(11),
    `accion` VARCHAR(100) NOT NULL,
    `tabla_afectada` VARCHAR(50),
    `id_registro_afectado` BIGINT,
    `detalles_json` JSON,
    `ip_origen` VARCHAR(45),
    PRIMARY KEY (`id_auditoria`),
    KEY `idx_usuario_id_auditoria` (`usuario_id_auditoria`),
    KEY `idx_tabla_afectada` (`tabla_afectada`),
    KEY `idx_fecha_hora` (`fecha_hora`),
    CONSTRAINT `fk_auditoria_usuario` FOREIGN KEY (`usuario_id_auditoria`) REFERENCES `Usuario` (`id_usuario`) ON DELETE CASCADE ON UPDATE CASCADE
);