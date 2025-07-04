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