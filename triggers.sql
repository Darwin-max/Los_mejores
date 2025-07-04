-- estos son los TRiggers de juan david

-- 7. Al modificar el monto de apertura de una tarjeta, recalcular cuota
DELIMITER $$

DROP TRIGGER IF EXISTS trg_recalcular_cuota_tarjeta $$

CREATE TRIGGER trg_recalcular_cuota_tarjeta
AFTER UPDATE ON cuenta_bancaria
FOR EACH ROW
BEGIN
    IF OLD.monto != NEW.monto THEN
        UPDATE cuota_manejo cb
        JOIN descuento de ON cb.descuento_id = de.id
        JOIN intereses i ON cb.interes_id = i.id
        SET total_monto = NEW.monto * (1 + i.tasa_interes - de.tasa_descuento)
        WHERE cb.id = NEW.id;
    END IF;

END $$
DELIMITER ;


-- 11. Al actualizar estado de cuenta a 'Bloqueada', bloquear tarjetas
DELIMITER $$

DROP TRIGGER IF EXISTS trg_bloquear_tarjetas_por_cuenta $$

CREATE TRIGGER trg_bloquear_tarjetas_por_cuenta
AFTER UPDATE ON cuenta_bancaria
FOR EACH ROW
BEGIN
    IF NEW.estado = 'Bloqueada' THEN
        UPDATE tarjeta
        SET estado = 'Bloqueada'
        WHERE cuenta_bancaria_id = NEW.id;
    END IF;

END $$
DELIMITER ;


-- 12. Al actualizar estado de cuenta a 'Cerrada', Cerrar tarjetas
DELIMITER $$

DROP TRIGGER IF EXISTS trg_cerrar_tarjetas_por_cuenta $$

CREATE TRIGGER trg_cerrar_tarjetas_por_cuenta
AFTER UPDATE ON cuenta_bancaria
FOR EACH ROW
BEGIN
    IF NEW.estado = 'Cerrada' THEN
        UPDATE tarjeta
        SET estado = 'Cerrada'
        WHERE cuenta_bancaria_id = NEW.id;
    END IF;
    
END $$
DELIMITER ;

-- 13. Al actualizar estado de cuenta a 'Inactiva', desactivar tarjetas
DELIMITER $$

DROP TRIGGER IF EXISTS trg_desactivar_tarjetas_por_cuenta $$

CREATE TRIGGER trg_desactivar_tarjetas_por_cuenta
AFTER UPDATE ON cuenta_bancaria
FOR EACH ROW
BEGIN
    IF NEW.estado = 'Inactiva' THEN
        UPDATE tarjeta
        SET estado = 'Inactiva'
        WHERE cuenta_bancaria_id = NEW.id;
    END IF;
    
END $$
DELIMITER ;

-- 15. Al registrar cuota pagada, revisando el estado del pago, registrar en historial
DELIMITER $$

DROP TRIGGER IF EXISTS trg_registrar_historial_pago $$

CREATE TRIGGER trg_registrar_historial_pago
AFTER UPDATE ON pago
FOR EACH ROW
BEGIN
    DECLARE c_total_cuotas INT;

    SELECT total_cuotas INTO c_total_cuotas
    FROM cuota_manejo
    WHERE cliente_id = NEW.cliente_id;

    IF OLD.estado != 'Pagado' AND NEW.estado = 'Pagado' THEN
        INSERT INTO historial_pagos (pago_id, total_monto, fecha_pago, fecha_creacion)
        VALUES (NEW.id, NEW.total * c_total_cuotas, NEW.fecha ,NOW());
    END IF;

END $$
DELIMITER ;


-- Esto sol los triggers de julian 

--  1 Actualizar estado de cuota al insertar pago
DROP TRIGGER IF EXISTS trg_actualizar_estado_cuota_pago $$

DELIMITER $$

CREATE TRIGGER trg_actualizar_estado_cuota_pago
AFTER INSERT ON pago_cuota_manejo
FOR EACH ROW
BEGIN
    UPDATE registro_cuota
    SET estado_cuota_id = 3, 
    monto_abonado = monto_abonado + NEW.monto_pagado
    WHERE cuota_manejo_id = NEW.cuota_manejo_id;

END $$

DELIMITER ;

SELECT * FROM registro_cuota WHERE cuota_manejo_id = 1;
SELECT * FROM pago_cuota_manejo WHERE cuota_manejo_id = 1;

INSERT INTO pago_cuota_manejo (cuota_manejo_id,fecha_pago,metodo_pago_id,monto_pagado,pago_id) VALUES 
(1,NOW()-INTERVAL 28 DAY,3,15000.00,4);



-- 2 Recalcular cuota al cambiar monto apertura

DROP TRIGGER IF EXISTS trg_recalcular_cuota_monto $$

DELIMITER $$

CREATE TRIGGER trg_recalcular_cuota_monto
AFTER UPDATE ON cuotas_manejo
FOR EACH ROW
BEGIN

    IF NEW.monto_apertura != OLD.monto_apertura THEN
        UPDATE registro_cuota
        SET monto_facturado = NEW.monto_apertura * 0.01
        WHERE cuota_manejo_id = NEW.id;
    END IF;

END $$

DELIMITER ;

SELECT * FROM registro_cuota;
SELECT * FROM cuotas_manejo;

UPDATE cuotas_manejo
SET monto_apertura = 12000.00
WHERE id = 1;

-- 12 Bloquear eliminación de cliente con deudas

DROP TRIGGER IF EXISTS trg_validar_eliminar_cliente $$


DELIMITER $$


CREATE TRIGGER trg_validar_eliminar_cliente
BEFORE DELETE ON clientes
FOR EACH ROW
BEGIN
    DECLARE valor_deudas INT DEFAULT 0;


    SELECT COUNT(*) 
    INTO valor_deudas 
    FROM prestamos p 
    JOIN cuenta c 
    ON p.cuenta_id = c.id 
    WHERE c.cliente_id = OLD.id 
    AND p.saldo_restante > 0;
    
    IF valor_deudas > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede eliminar cliente con deudas';
    END IF;
END$$

DELIMITER ;

SELECT * FROM clientes;


-- 13 Actualizar estado cuenta al cerrar

DROP TRIGGER IF EXISTS trg_cerrar_cuenta $$


DELIMITER $$


CREATE TRIGGER trg_cerrar_cuenta
BEFORE UPDATE ON cuenta
FOR EACH ROW
BEGIN
    IF NEW.fecha_cierre IS NOT NULL AND OLD.fecha_cierre IS NULL THEN
        SET NEW.estado_id = 2;
    END IF;
END$$

DELIMITER ;


-- 19 Generar extracto al hacer transacción
DROP TRIGGER IF EXISTS trg_generar_extracto $$

DELIMITER $$
CREATE TRIGGER trg_generar_extracto
AFTER INSERT ON transacciones
FOR EACH ROW
BEGIN
    INSERT INTO extracto_bancario (cuenta_id, fecha_inicial_extracto, fecha_final_extracto, monto, saldo_post_operacion, tipo_operacion_id, referencia, descripcion, metodo_transaccion_id)
    SELECT NEW.cuenta_origen_id, CURDATE(), CURDATE(), NEW.monto, 
        (SELECT saldo_disponible FROM cuenta WHERE id = NEW.cuenta_origen_id),
        9, NEW.referencia, NEW.descripcion, 1;
END $$
DELIMITER ;