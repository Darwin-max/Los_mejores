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