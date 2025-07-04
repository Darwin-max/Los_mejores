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

