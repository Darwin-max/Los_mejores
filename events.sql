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
