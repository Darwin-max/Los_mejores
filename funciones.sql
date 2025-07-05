 -- funciones de juan david

 -- Calcular la cuota de manejo segun tipo de tarjeta y monto de apertura
DELIMITER $$

DROP FUNCTION IF EXISTS fn_calcular_cuota_manejo $$

CREATE FUNCTION fn_calcular_cuota_manejo(
    c_tipo_tarjeta_id INT, c_monto DECIMAL(12,2))
RETURNS DECIMAL(12,2)
DETERMINISTIC
BEGIN
    DECLARE c_interes DECIMAL(5,2);
    DECLARE c_descuento DECIMAL(5,2);
    DECLARE c_monto_total DECIMAL(12,2);
    
    IF NOT EXISTS (SELECT * FROM tipo_tarjeta WHERE id = c_tipo_tarjeta_id) THEN
        SIGNAL SQLSTATE '40002'
            SET MESSAGE_TEXT = 'No existe esa tipo de tarjeta';
    END IF;

    IF NOT EXISTS (SELECT * FROM intereses WHERE monto_minimo <= c_monto AND c_monto <= monto_maximo) THEN
        SIGNAL SQLSTATE '40001'
            SET MESSAGE_TEXT = 'El monto de apertura no es valido';
    END IF;

    SELECT tasa_interes INTO c_interes
    FROM intereses
    WHERE c_monto BETWEEN monto_minimo AND monto_maximo
    LIMIT 1;

    SELECT tasa_descuento INTO c_descuento
    FROM descuento de
    JOIN tipo_tarjeta tt ON tt.descuento_id = de.id
    WHERE tt.id = c_tipo_tarjeta_id
    LIMIT 1;

    SET c_monto_total = c_monto * (1 + c_interes - c_descuento);

    RETURN c_monto_total;
END $$

DELIMITER ;

SELECT fn_calcular_cuota_manejo(1, 100000.00) AS Total_a_pagar;


-- Determinar tasa de interes aplicada a una cuota
DELIMITER $$

DROP FUNCTION IF EXISTS fn_tasa_interes_cuota $$

CREATE FUNCTION fn_tasa_interes_cuota(c_cuota_id INT)
RETURNS DECIMAL(12,2)
DETERMINISTIC
BEGIN
    DECLARE c_monto DECIMAL(12,2);
    DECLARE c_tasa_interes DECIMAL(5,2);
    DECLARE c_interes_aplicado DECIMAL(12,2);

    IF NOT EXISTS (SELECT * FROM cuota_manejo WHERE id = c_cuota_id) THEN
        SIGNAL SQLSTATE '40002'
            SET MESSAGE_TEXT = 'No existe esa cuota de manejo';
    END IF;

    SELECT cb.monto, i.tasa_interes
    INTO c_monto, c_tasa_interes
    FROM cuota_manejo cm
    JOIN tarjeta ta ON cm.tarjeta_id = ta.id
    JOIN intereses i ON cm.interes_id = i.id
    JOIN cuenta_bancaria cb ON ta.cuenta_bancaria_id = cb.id
    WHERE cm.id = c_cuota_id AND cb.estado = 'Activa'
    LIMIT 1;

    SET c_interes_aplicado = (c_monto * c_tasa_interes);

    RETURN c_interes_aplicado;
END $$

DELIMITER ;

SELECT fn_tasa_interes_cuota(1) AS tasa_interes_cuota;



-- Monto total de pagos en estado 'Pendiente'

DELIMITER $$

DROP FUNCTION IF EXISTS fn_total_pagos $$

CREATE FUNCTION fn_total_pagos_pendientes()
RETURNS DECIMAL(12,2)
DETERMINISTIC
BEGIN
    DECLARE p_total DECIMAL(12,2);

    SELECT SUM(total)
    INTO p_total
    FROM pago
    WHERE estado = 'Pendiente';

    RETURN IFNULL(p_total, 0);
END $$

DELIMITER ;

SELECT fn_total_pagos_pendientes() AS total_monto_pagos_pendientes;


-- Sumar pagos efectivos de un cliente
DELIMITER $$

DROP FUNCTION IF EXISTS fn_total_pagado_cliente $$

CREATE FUNCTION fn_total_pagado_cliente(p_cliente_id INT)
RETURNS DECIMAL(12,2)
DETERMINISTIC
BEGIN
    DECLARE p_total_cliente DECIMAL(12,2);

    IF NOT EXISTS (SELECT * FROM cliente WHERE id = p_cliente_id) THEN
        SIGNAL SQLSTATE '40002'
            SET MESSAGE_TEXT = 'No existe ese cliente';
    END IF;

    SELECT SUM(total)
    INTO p_total_cliente
    FROM pago
    WHERE cliente_id = p_cliente_id AND estado = 'Pagado';

    RETURN IFNULL(p_total_cliente, 0);
END $$

DELIMITER ;

SELECT fn_total_pagado_cliente(1) AS total_pagado;


-- Total cuotas y monto por tarjeta
DELIMITER $$

DROP FUNCTION IF EXISTS fn_resumen_cuotas_tarjeta $$

CREATE FUNCTION fn_resumen_cuotas_tarjeta(c_tarjeta_id INT)
RETURNS TEXT
DETERMINISTIC
BEGIN
    DECLARE c_cuotas_totales INT;
    DECLARE c_total_monto DECIMAL(12,2);
    DECLARE resumen TEXT;

    IF NOT EXISTS (SELECT * FROM tarjeta WHERE id = c_tarjeta_id) THEN
        SIGNAL SQLSTATE '40002'
            SET MESSAGE_TEXT = 'No existe esa tarjeta';
    END IF;

    SELECT SUM(cu.total_cuotas), SUM(hcu.total_monto)
    INTO c_cuotas_totales, c_total_monto
    FROM cuota_manejo cu
    JOIN historial_cuotas hcu ON cu.id = hcu.cuota_manejo_id
    WHERE cu.tarjeta_id = c_tarjeta_id;

    SET resumen = CONCAT('Total cuotas: ', c_cuotas_totales, ', Monto total: $', c_total_monto);
    RETURN resumen;
END $$

DELIMITER ;

SELECT fn_resumen_cuotas_tarjeta(1) AS resumen_cuotas_tarjeta;