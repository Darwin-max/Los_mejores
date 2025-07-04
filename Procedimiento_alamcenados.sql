 -- Procedimientos almacenados de juan david

-- 16. Consultar cuotas pendientes cliente
DELIMITER //

DROP PROCEDURE IF EXISTS ps_cuotas_pendientes_cliente;

CREATE PROCEDURE ps_cuotas_pendientes_cliente(
    IN p_cliente_id INT
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM cliente WHERE id = p_cliente_id) THEN
        SIGNAL SQLSTATE '40002'
            SET MESSAGE_TEXT = 'El cliente no existe';
    END IF;

    SELECT 
        cm.total_monto,
        cm.total_cuotas,
        cm.fecha
    FROM pago pa
    JOIN cuota_manejo cm ON pa.cliente_id = cm.cliente_id
    WHERE cm.cliente_id = p_cliente_id AND
    pa.estado = 'Pendiente'
    ORDER BY cm.fecha DESC;

END //
DELIMITER ;

CALL ps_cuotas_pendientes_cliente();

-- 17. Cerrar cuenta bancaria
DELIMITER //

DROP PROCEDURE IF EXISTS ps_cerrar_cuenta;

CREATE PROCEDURE ps_cerrar_cuenta(
    IN p_numero_cuenta VARCHAR(10)
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM cuenta_bancaria WHERE numero_cuenta = p_numero_cuenta) THEN
        SIGNAL SQLSTATE '40002'
            SET MESSAGE_TEXT = 'La cuenta bancaria no existe';
    END IF;

    UPDATE cuenta_bancaria 
    SET estado = 'Cerrada', monto = 0 
    WHERE numero_cuenta = p_numero_cuenta;
    
    UPDATE tarjeta 
    SET estado = 'Cerrada' 
    WHERE cuenta_bancaria_id = (
        SELECT id FROM cuenta_bancaria WHERE numero_cuenta = p_numero_cuenta
    );

END //
DELIMITER ;

CALL ps_cerrar_cuenta();

-- 18. Reporte clientes activos
DELIMITER //

DROP PROCEDURE IF EXISTS ps_reporte_clientes_activos;

CREATE PROCEDURE ps_reporte_clientes_activos()
BEGIN
    SELECT 
        c.nombre,
        c.telefono,
        t.numero AS numero_tarjeta,
        cb.monto AS saldo,
        t.estado AS estado_tarjeta
    FROM cliente c
    JOIN tarjeta t ON c.tarjeta_id = t.id
    JOIN cuenta_bancaria cb ON t.cuenta_bancaria_id = cb.id
    WHERE t.estado = 'Activa'
    ORDER BY c.nombre;
END //
DELIMITER ;

CALL ps_reporte_clientes_activos();

-- 19. Aplicar interés a cuentas de inversión
DELIMITER //

DROP PROCEDURE IF EXISTS ps_aplicar_interes_inversion;

CREATE PROCEDURE ps_aplicar_interes_inversion(
    IN p_tasa_mensual DECIMAL(5,2)
)
BEGIN
    IF p_tasa_mensual < 0 THEN
        SIGNAL SQLSTATE '40001'
            SET MESSAGE_TEXT = 'La tasa de interes no puede ser negativa';
    END IF;

    UPDATE cuenta_bancaria cb
    JOIN tipo_cuenta tc ON cb.tipo_cuenta_id = tc.id
    SET cb.monto = cb.monto * (1 + p_tasa_mensual)
    WHERE tc.nombre = 'Inversion' AND cb.estado = 'Activa';

END //
DELIMITER ;

CALL ps_aplicar_interes_inversion();

-- 20. Resumen financiero cliente
DELIMITER //

DROP PROCEDURE IF EXISTS ps_resumen_financiero_cliente //

CREATE PROCEDURE ps_resumen_financiero_cliente(
    IN p_cliente_id INT
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM cliente WHERE id = p_cliente_id) THEN
        SIGNAL SQLSTATE '40002'
            SET MESSAGE_TEXT = 'El cliente no existe';
    END IF;

    SELECT 
        c.nombre,
        cb.monto AS saldo_disponible,
        COALESCE(SUM(p.total), 0) AS total_pagos_pendientes,
        COALESCE(SUM(cm.total_monto), 0) AS total_cuotas_manejo,
        COUNT(DISTINCT p.id) AS pagos_pendientes,
        COUNT(DISTINCT cm.id) AS cuotas_registradas
    FROM cliente c
    JOIN tarjeta t ON c.tarjeta_id = t.id
    JOIN cuenta_bancaria cb ON t.cuenta_bancaria_id = cb.id
    LEFT JOIN pago p ON c.id = p.cliente_id AND p.estado = 'Pendiente'
    LEFT JOIN cuota_manejo cm ON c.id = cm.cliente_id
    WHERE c.id = p_cliente_id
    GROUP BY c.id;
END //
DELIMITER ;

CALL ps_resumen_financiero_cliente(2)

