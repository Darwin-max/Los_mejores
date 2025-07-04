-- estos son los events de julian

-- 7 Verificar tarjetas próximas a vencer
DELIMITER $$
CREATE EVENT evt_verificar_vencimiento_tarjetas
ON SCHEDULE EVERY 1 MONTH
STARTS '2025-01-01 10:00:00'
DO
BEGIN
    UPDATE tarjetas_bancarias 
    SET estado_id = 7 
    WHERE fecha_vencimiento <= CURDATE();
END $$
DELIMITER ;


-- 9 Actualizar estados de préstamos
DELIMITER $$
CREATE EVENT evt_actualizar_estados_prestamos
ON SCHEDULE EVERY 1 DAY
STARTS '2025-01-01 01:30:00'
DO
BEGIN
    UPDATE prestamos 
    SET estado_id = 16 
    WHERE saldo_restante = 0;
END $$
DELIMITER ;


-- 10 Generar cuotas mensuales automáticas
DELIMITER $$
CREATE EVENT evt_generar_cuotas_mensuales
ON SCHEDULE EVERY 1 MONTH
STARTS '2025-01-01 00:30:00'
DO
BEGIN
    INSERT INTO registro_cuota (cuota_manejo_id, fecha_ultimo_cobro, monto_facturado, fecha_corte, fecha_limite_pago, estado_cuota_id, monto_a_pagar)
    SELECT id, NOW(), monto_apertura, CURDATE(), DATE_ADD(CURDATE(), INTERVAL 15 DAY), 2, monto_apertura
    FROM cuotas_manejo 
    WHERE activo = TRUE;
END $$
DELIMITER ;


-- 15 Renovar tarjetas automáticamente
DELIMITER $$
CREATE EVENT evt_renovar_tarjetas_automaticas
ON SCHEDULE EVERY 1 MONTH
STARTS '2025-01-01 07:00:00'
DO
BEGIN
    UPDATE tarjetas_bancarias 
    SET fecha_vencimiento = DATE_ADD(fecha_vencimiento, INTERVAL 3 YEAR)
    WHERE fecha_vencimiento <= DATE_ADD(CURDATE(), INTERVAL 3 MONTH);
END $$
DELIMITER ;


-- 20 Notificar vencimientos próximos
DELIMITER $$
CREATE EVENT evt_notificar_vencimientos
ON SCHEDULE EVERY 1 WEEK
STARTS '2025-01-01 09:00:00'
DO
BEGIN
    INSERT INTO historial_tarjetas (tarjeta_id, evento_id, descripcion)
    SELECT id, 1, 'Tarjeta proxima a vencer'
    FROM tarjetas_bancarias 
    WHERE fecha_vencimiento <= DATE_ADD(CURDATE(), INTERVAL 90 DAY);
END $$

-- este son los mejores eventos de juan david 


-- 8. Actualizar pagos pendientes a 'Vencido' si tienen más de un año de antigüedad
DELIMITER $$

DROP EVENT IF EXISTS evt_actualizar_pagos_pendientes_antiguos $$

CREATE EVENT evt_actualizar_pagos_pendientes_antiguos
ON SCHEDULE EVERY 1 DAY
ENABLE
DO
BEGIN
    UPDATE pago SET estado = 'Vencido'
    WHERE estado = 'Pendiente' AND
    fecha < DATE_SUB(CURDATE(), INTERVAL 1 YEAR);

END $$

DELIMITER ;


-- 12. Generar reporte mensual de cuotas de manejo
DELIMITER $$

DROP EVENT IF EXISTS evt_generar_reporte_cuotas_manejo  $$

CREATE EVENT evt_generar_reporte_cuotas_manejo
ON SCHEDULE EVERY 1 MONTH STARTS CURRENT_DATE + INTERVAL 1 MONT
ENABLE
DO
BEGIN
    INSERT INTO reporte_cuotas_manejo (fecha_generacion, total_cuotas)
    SELECT NOW(), SUM(total_monto) FROM cuota_manejo;

END $$

DELIMITER ;

-- 14. Desactivar tarjetas sin movimiento en 6 meses
DELIMITER $$

DROP EVENT IF EXISTS evt_desactivar_tarjetas_inactivas $$

CREATE EVENT evt_desactivar_tarjetas_inactivas
ON SCHEDULE EVERY 1 MONTH
ENABLE
DO
BEGIN
    UPDATE tarjeta
    SET estado = 'Inactiva'
    WHERE id NOT IN (
        SELECT DISTINCT tarjeta_id FROM pago
        WHERE fecha > DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
    ) AND estado = 'Activa';

END $$

DELIMITER ;


-- 15. Activar tarjetas con movimiento reciente en 6 meses

DELIMITER $$

DROP EVENT IF EXISTS evt_activar_tarjetas_activas_recientes $$

CREATE EVENT evt_activar_tarjetas_activas_recientes
ON SCHEDULE EVERY 1 MONTH
ENABLE
DO
BEGIN
    UPDATE tarjeta
    SET estado = 'Activa'
    WHERE id IN (
        SELECT DISTINCT tarjeta_id FROM pago
        WHERE fecha > DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
    )
    AND estado = 'Inactiva';
END $$

DELIMITER ;


-- 18. Verificar y ajustar montos negativos
DELIMITER $$

DROP EVENT IF EXISTS evt_ajuste_montos_negativos $$

CREATE EVENT evt_ajuste_montos_negativos
ON SCHEDULE EVERY 1 WEEK
ENABLE
DO
BEGIN
    UPDATE cuenta_bancaria
    SET monto = 0, estado = 'Bloqueada'
    WHERE monto < 0;

END $$

DELIMITER ;


-- Eventos de kevin 

-- 13. Generar un reporte de clientes con pagos pendientes.

CREATE EVENT GenerarReporteClientesConPagosPendientes
ON SCHEDULE EVERY 1 MONTH
DO
INSERT INTO Reporte_Clientes_Pendientes (cliente_id, total_pendiente)
SELECT cliente_id_tarjeta, SUM(monto_final_a_pagar)
FROM Cuota_Manejo CM
JOIN Tarjeta T ON CM.tarjeta_id_cuota = T.id_tarjeta
WHERE CM.estado_cuota_id = (SELECT id_estado_cuota FROM Estado_Cuota WHERE nombre_estado_cuota = 'Pendiente')
GROUP BY cliente_id_tarjeta;


-- 15. Actualizar el estado de las tarjetas con más de 3 cuotas vencidas.

CREATE EVENT ActualizarEstadoTarjetasConMultiplesCuotasVencidas
ON SCHEDULE EVERY 1 DAY
DO
UPDATE Tarjeta
SET estado_tarjeta_id = (SELECT id_estado_tarjeta FROM Estado_Tarjeta WHERE nombre_estado_tarjeta = 'Bloqueada')
WHERE id_tarjeta IN (
    SELECT tarjeta_id_cuota
    FROM Cuota_Manejo
    WHERE estado_cuota_id = (SELECT id_estado_cuota FROM Estado_Cuota WHERE nombre_estado_cuota = 'Vencida')
    GROUP BY tarjeta_id_cuota
    HAVING COUNT(*) > 3
);



-- 19. Actualizar el estado de las cuentas usando cursores.

CREATE EVENT ActualizarEstadoCuentasConCursores
ON SCHEDULE EVERY 1 DAY
DO
BEGIN
    DECLARE cuenta_id INT;
    DECLARE saldo DECIMAL(10,2);
    DECLARE cuenta_cursor CURSOR FOR SELECT id_cuenta, saldo_actual FROM Cuenta_Bancaria;

    OPEN cuenta_cursor;
    FETCH cuenta_cursor INTO cuenta_id, saldo;

    WHILE saldo IS NOT NULL DO
        IF saldo < 0 THEN
            UPDATE Cuenta_Bancaria SET estado_cuenta_id = (SELECT id_estado_cuenta FROM Estado_Cuenta WHERE nombre_estado = 'Bloqueada') WHERE id_cuenta = cuenta_id;
        END IF;
        FETCH cuenta_cursor INTO cuenta_id, saldo;
    END WHILE;

    CLOSE cuenta_cursor;
END;


-- 20. Generar un reporte de pagos por cliente usando cursores.

CREATE EVENT GenerarReportePagosPorClienteConCursores
ON SCHEDULE EVERY 1 MONTH
DO
BEGIN
    DECLARE cliente_id INT;
    DECLARE total_pagado DECIMAL(10,2);
    DECLARE cliente_cursor CURSOR FOR SELECT cliente_id_tarjeta, SUM(P.monto_pagado) FROM Pago P JOIN Tarjeta T ON P.cuota_id_pago = T.id_tarjeta GROUP BY cliente_id_tarjeta;

    OPEN cliente_cursor;
    FETCH cliente_cursor INTO cliente_id, total_pagado;

    WHILE cliente_id IS NOT NULL DO
        INSERT INTO Reporte_Pagos_Clientes (cliente_id, total_pagado) VALUES (cliente_id, total_pagado);
        FETCH cliente_cursor INTO cliente_id, total_pagado;
    END WHILE;

    CLOSE cliente_cursor;
END;

SHOW EVENTS;



-- eventos de santigo


-- Insertar seguridad por defecto en tarjetas sin PIN

DELIMITER //

DROP EVENT IF EXISTS ev_insertar_pin_defecto;
CREATE EVENT IF NOT EXISTS ev_insertar_pin_defecto
ON SCHEDULE EVERY 1 DAY
DO
BEGIN
    INSERT INTO Seguridad_tarjetas (tarjeta_id, pin)
    SELECT t.id, '1234'
    FROM Tarjetas t
    LEFT JOIN Seguridad_tarjetas s ON t.id = s.tarjeta_id
    WHERE s.id IS NULL;
END //

DELIMITER ;


-- Evento para actualizar el estado de las tarjetas vencidas

DELIMITER //

DROP EVENT IF EXISTS ev_actualizar_tarjetas_vencidas;
CREATE EVENT IF NOT EXISTS ev_actualizar_tarjetas_vencidas
ON SCHEDULE EVERY 1 DAY
DO
BEGIN
    UPDATE Tarjetas
    SET estado = 'Vencida'
    WHERE fecha_expiracion < CURDATE() AND estado <> 'Vencida';
END //

DELIMITER ;


--  Cambiar automaticamente el estado de las cuotas de manejo si no se han pagado
DELIMITER //

DROP EVENT IF EXISTS ev_actualizar_estado_cuotas_manejo;
CREATE EVENT IF NOT EXISTS ev_actualizar_estado_cuotas_manejo
ON SCHEDULE EVERY 1 DAY
DO
BEGIN
    UPDATE Cuotas_de_manejo
    SET estado = 'Pendiente'
    WHERE vencimiento_cuota < CURDATE() AND estado <> 'Pago';
END //

DELIMITER ;


-- Cambiar estado a 'Bloqueada' si la tarjeta tiene saldo negativo

DELIMITER //

DROP EVENT IF EXISTS ev_bloquear_tarjetas_saldo_negativo;
CREATE EVENT IF NOT EXISTS ev_bloquear_tarjetas_saldo_negativo
ON SCHEDULE EVERY 1 DAY
DO
BEGIN
    UPDATE Tarjetas
    SET estado = 'Bloqueada'
    WHERE saldo < 0 AND estado = 'Activa';
END //

DELIMITER ;


-- Eliminar historial de pagos con estado 'Inicio' mayor a 1 año

DELIMITER //

DROP EVENT IF EXISTS ev_limpiar_historial_inicial;
CREATE EVENT IF NOT EXISTS ev_limpiar_historial_inicial
ON SCHEDULE EVERY 1 DAY
DO
BEGIN
    DELETE FROM Historial_de_pagos
    WHERE estado_anterior = 'Inicio' AND fecha_cambio < CURDATE() - INTERVAL 1 YEAR;
END //

DELIMITER ;