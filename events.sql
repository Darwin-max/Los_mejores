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
