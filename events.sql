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


