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


 -- funciones de julian 



-- fn_generar_codigo_unico
-- generar codigo unico para usarse en facturas y demas


DELIMITER $$
DROP FUNCTION IF EXISTS fn_generar_codigo_unico $$
CREATE FUNCTION fn_generar_codigo_unico()
RETURNS VARCHAR(255)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE codigo_complejo VARCHAR(255);
    DECLARE nums_lista TEXT DEFAULT '';
    DECLARE i INT DEFAULT 1;
    DECLARE finCiclo INT DEFAULT 36;
    DECLARE num INT;
    WHILE i <= finCiclo DO
        SET num = FLOOR(RAND() * 9) + 1;
        SET nums_lista = CONCAT(nums_lista, IF(nums_lista = '', '', ''), num);
        SET i = i + 1;
    END WHILE;
    SET codigo_complejo = CONCAT('PAY-', nums_lista);
    RETURN codigo_complejo;
END$$
DELIMITER ;
SELECT fn_generar_codigo_unico();


-- Estimar el total de pagos realizados por tipo de tarjeta durante un período determinado.


DELIMITER $$
DROP FUNCTION IF EXISTS fn_total_pagos_tarjeta $$
CREATE FUNCTION fn_total_pagos_tarjeta(
    f_tarjeta_id BIGINT,
    f_fecha_inicio DATE,
    f_fecha_fin DATE
) 
RETURNS DECIMAL(15,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_total_cuotas DECIMAL(15,2) DEFAULT 0.00;
    DECLARE v_total_credito DECIMAL(15,2) DEFAULT 0.00;
    DECLARE v_total_final DECIMAL(15,2) DEFAULT 0.00;
    
    SELECT IFNULL(SUM(pcm.monto_pagado), 0.00) INTO v_total_cuotas
        FROM tarjetas_bancarias tb
        JOIN cuotas_manejo cm ON tb.id = cm.tarjeta_id
        JOIN pago_cuota_manejo pcm ON cm.id = pcm.cuota_manejo_id
        JOIN pagos p ON pcm.pago_id = p.id
        WHERE tb.id = f_tarjeta_id
        AND p.estado_pago_id = 2  
        AND (p_fecha_inicio IS NULL OR DATE(p.fecha_pago) >= f_fecha_inicio)
        AND (p_fecha_fin IS NULL OR DATE(p.fecha_pago) <= f_fecha_fin);
    
    SET v_total_final = v_total_cuotas + v_total_credito;
    
    RETURN v_total_final;
END $$
DELIMITER ;

SELECT fn_total_pagos_tarjeta(1, NULL, NULL);


-- Determinar el nivel de riesgo crediticio de un cliente basado en su historial de pagos y mora en préstamos.

SELECT * FROM cuotas_prestamo;
SELECT * FROM estados_cuota;

DELIMITER $$
DROP FUNCTION IF EXISTS fn_nivel_riesgo_cliente $$
CREATE FUNCTION fn_nivel_riesgo_cliente(
    f_cliente_id BIGINT
)
RETURNS VARCHAR(20)
READS SQL DATA
DETERMINISTIC
BEGIN

    DECLARE valor_cuotas_mora INT DEFAULT 0;
    DECLARE valor_total_cuotas INT DEFAULT 0;
    DECLARE valor_porcentaje_mora DECIMAL(5,2) DEFAULT 0.00;
    DECLARE valor_nivel_riesgo VARCHAR(20) DEFAULT 'BAJO';

    SELECT
        COUNT(CASE WHEN cp.estado_cuota_id = 6 THEN 1 END),
        COUNT (*)
        INTO valor_cuotas_mora, valor_total_cuotas
    FROM cuotas_prestamo cp
    JOIN prestamos pr ON cp.prestamo_id = pr.id
    JOIN cuenta c ON pr.cuenta_id = c.id
    WHERE c.cliente_id = f_cliente_id;

    IF valor_total_cuotas > 0 THEN
        SET valor_porcentaje_mora = (valor_cuotas_mora/valor_total_cuotas) * 100;

        IF valor_porcentaje_mora >= 30 THEN
            SET valor_nivel_riesgo = 'ALTO';
        ELSEIF valor_porcentaje_mora >= 15 THEN
            SET valor_nivel_riesgo = 'MEDIO';
        ELSE
            SET valor_nivel_riesgo = 'BAJO';
        END IF;
    END IF;

    RETURN valor_nivel_riesgo;

END $$


DELIMITER ;
SELECT * FROM cuotas_prestamo;
SELECT fn_nivel_riesgo_cliente(5);


--  Días para vencimiento de tarjeta

SELECT DATEDIFF(fecha_vencimiento, CURDATE())
FROM tarjetas_bancarias
WHERE id = 1;

DROP FUNCTION IF EXISTS fn_dias_vencimiento_tarjeta $$

DELIMITER $$

CREATE FUNCTION fn_dias_vencimiento_tarjeta(
    f_tarjeta_id BIGINT
)
RETURNS INT
READS SQL DATA
DETERMINISTIC
BEGIN

    DECLARE valor_dias_transcurridos INT DEFAULT 0;

    SELECT DATEDIFF(fecha_vencimiento, CURDATE()) INTO valor_dias_transcurridos
    FROM tarjetas_bancarias
    WHERE id = f_tarjeta_id;

    RETURN valor_dias_transcurridos;

END $$

DELIMITER ;
SELECT fn_dias_vencimiento_tarjeta(1);

-- Calcular el interés acumulado de un préstamo desde su fecha de desembolso hasta una fecha específica.

DROP FUNCTION fn_calcular_interes_fecha $$

DELIMITER $$

CREATE FUNCTION fn_calcular_interes_fecha(
    f_prestamo_id BIGINT,
    f_fecha_calculo DATE
)
RETURNS DECIMAL(15,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE valor_monto_prestamo DECIMAL(15,2);
    DECLARE valor_tasa_interes DECIMAL(8,6);
    DECLARE valor_dias_pasados INT;
    DECLARE valor_interes_acumulado DECIMAL(15,2) DEFAULT 0.00;

    SELECT pr.monto_aprobado, i.valor, DATEDIFF(f_fecha_calculo, DATE(pr.fecha_desembolso))
    INTO valor_monto_prestamo, valor_tasa_interes, valor_dias_pasados
    FROM prestamos pr
    JOIN interes i ON pr.interes_id = i.id
    WHERE pr.id = f_prestamo_id
    AND pr.fecha_desembolso IS NOT NULL;

    IF valor_dias_pasados > 0 THEN
        SET valor_interes_acumulado = valor_monto_prestamo * valor_tasa_interes * (valor_dias_pasados/365);
    END IF;

    RETURN valor_interes_acumulado;
END $$

DELIMITER ;

SELECT fn_calcular_interes_fecha(1, '2025-06-30') AS interes_calculado;