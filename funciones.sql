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



-- funciones de kevin 




-- 2. Estimar el descuento total aplicado sobre la cuota de manejo.

DELIMITER $$

CREATE FUNCTION EstimarDescuentoTotal(
    cuota_id INT
) RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE descuento_total DECIMAL(10,2);

    -- Calcular el descuento total aplicado
    SELECT monto_base - monto_final_a_pagar INTO descuento_total
    FROM Cuota_Manejo
    WHERE id_cuota = cuota_id;

    RETURN descuento_total;
END$$

DELIMITER ;

-- Ejemplo de uso:
SELECT EstimarDescuentoTotal(6);


-- 3. Calcular el saldo pendiente de pago de un cliente.

DELIMITER $$

CREATE FUNCTION CalcularSaldoPendiente(
    cliente_id INT
) RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE saldo_pendiente DECIMAL(10,2);

    -- Calcular el saldo pendiente sumando las cuotas vencidas
    SELECT SUM(monto_final_a_pagar) INTO saldo_pendiente
    FROM Cuota_Manejo CM
    JOIN Tarjeta T ON CM.tarjeta_id_cuota = T.id_tarjeta
    WHERE T.cliente_id_tarjeta = cliente_id
      AND CM.estado_cuota_id = (SELECT id_estado_cuota FROM Estado_Cuota WHERE nombre_estado_cuota = 'Pendiente');

    RETURN saldo_pendiente;
END$$

DELIMITER ;

-- Ejemplo de uso:
SELECT CalcularSaldoPendiente(6);



-- 19. Calcular el total de pagos realizados por cliente y estado de cuota en el último trimestre.

DELIMITER $$

CREATE FUNCTION TotalPagosPorClienteYEstadoCuotaUltimoTrimestre(
    cliente_id INT,
    estado_cuota_id INT
) RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE total_pagos DECIMAL(10,2);

    SELECT SUM(P.monto_pagado) INTO total_pagos
    FROM Pago P
    JOIN Cuota_Manejo CM ON P.cuota_id_pago = CM.id_cuota
    JOIN Tarjeta T ON CM.tarjeta_id_cuota = T.id_tarjeta
    WHERE T.cliente_id_tarjeta = cliente_id AND CM.estado_cuota_id = estado_cuota_id AND P.fecha_pago >= DATE_SUB(CURDATE(), INTERVAL 3 MONTH);

    RETURN total_pagos;
END$$

DELIMITER ;

-- Ejemplo de uso:
SELECT TotalPagosPorClienteYEstadoCuotaUltimoTrimestre(6, 1);

-- 20. Calcular el total de pagos realizados por cliente y tipo de tarjeta en el último año.

DELIMITER $$

CREATE FUNCTION TotalPagosPorClienteYTipoTarjetaUltimoAnio(
    cliente_id INT,
    tipo_tarjeta_id INT
) RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE total_pagos DECIMAL(10,2);

    SELECT SUM(P.monto_pagado) INTO total_pagos
    FROM Pago P
    JOIN Cuota_Manejo CM ON P.cuota_id_pago = CM.id_cuota
    JOIN Tarjeta T ON CM.tarjeta_id_cuota = T.id_tarjeta
    WHERE T.cliente_id_tarjeta = cliente_id AND T.tipo_tarjeta_id = tipo_tarjeta_id AND YEAR(P.fecha_pago) = YEAR(CURDATE()) - 1;

    RETURN total_pagos;
END$$

DELIMITER ;

-- Ejemplo de uso:
SELECT TotalPagosPorClienteYTipoTarjetaUltimoAnio(6, 2);



-- 12. Calcular el total de cuotas vencidas por cliente y sucursal.

DELIMITER $$

CREATE FUNCTION TotalCuotasVencidasPorClienteYSucursal(
    cliente_id INT,
    sucursal_id INT
) RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE total_cuotas INT;

    SELECT COUNT(CM.id_cuota) INTO total_cuotas
    FROM Cuota_Manejo CM
    JOIN Tarjeta T ON CM.tarjeta_id_cuota = T.id_tarjeta
    JOIN Cliente C ON T.cliente_id_tarjeta = C.id_cliente
    JOIN Usuario U ON C.id_cliente = U.id_usuario
    JOIN Empleado E ON U.id_usuario = E.id_empleado
    JOIN Sucursal S ON E.sucursal_id_empleado = S.id_sucursal
    WHERE T.cliente_id_tarjeta = cliente_id AND S.id_sucursal = sucursal_id AND CM.estado_cuota_id = (SELECT id_estado_cuota FROM Estado_Cuota WHERE nombre_estado_cuota = 'Vencida');

    RETURN total_cuotas;
END$$

DELIMITER ;

-- Ejemplo de uso:
SELECT TotalCuotasVencidasPorClienteYSucursal(6, 1);



 -- funciones: ejercicios santiago


-- Calcular el total pendiente de cuota de manejo de pago de un cliente.
 DELIMITER //

DROP FUNCTION IF EXISTS fn_saldo_pendiente;
CREATE FUNCTION fn_saldo_pendiente(p_cliente_id INT)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE _total_cuota DECIMAL(10,2);
    DECLARE _id_cuota INT;
    DECLARE _total_restante DECIMAL(10,2);
    DECLARE _pagos_clientes DECIMAL(10,2) DEFAULT 0.00;
    DECLARE _pago_individual DECIMAL(10,2);

    DECLARE cur CURSOR FOR
        SELECT IFNULL(p.total_pago, 0)
        FROM Clientes cl
        INNER JOIN Cuentas cu ON cu.cliente_id = cl.id
        INNER JOIN Tarjetas t ON t.cuenta_id = cu.id
        LEFT JOIN Cuotas_de_manejo cm ON cm.tarjeta_id = t.id
        LEFT JOIN Pagos p ON p.cuota_id = cm.id
        WHERE cl.id = p_cliente_id;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    SELECT IFNULL(SUM(cm.monto_total), 0) INTO _total_cuota
    FROM Clientes cl
    INNER JOIN Cuentas cu ON cu.cliente_id = cl.id
    INNER JOIN Tarjetas t ON t.cuenta_id = cu.id
    LEFT JOIN Cuotas_de_manejo cm ON cm.tarjeta_id = t.id
    WHERE cl.id = p_cliente_id;

    IF _total_cuota = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El cliente no paga cuota de manejo';
    END IF;

    OPEN cur;
        read_loop: LOOP
            FETCH cur INTO _pago_individual;
            IF done THEN
                LEAVE read_loop;
            END IF;
            SET _pagos_clientes = _pagos_clientes + IFNULL(_pago_individual, 0);
        END LOOP;

        SET _total_restante = _total_cuota - _pagos_clientes;
    CLOSE cur;

    IF _total_restante < 0 THEN
        SET _total_restante = 0;
    END IF;

    RETURN _total_restante;


END //
DELIMITER ;

SELECT fn_saldo_pendiente(1) AS Total_pendiente;

-- Calcular el total pendiente de las cuotas de credito de un cliente.

DELIMITER //

DROP FUNCTION IF EXISTS fn_cuotas_credito;
CREATE FUNCTION fn_cuotas_credito(p_cliente_id INT)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE _total_deuda DECIMAL(10,2) DEFAULT 0;

    SELECT IFNULL(SUM(cc.valor_cuota), 0) INTO _total_deuda
    FROM Clientes cl
    INNER JOIN Cuentas cu ON cu.cliente_id = cl.id
    INNER JOIN Tarjetas t ON t.cuenta_id = cu.id
    INNER JOIN Movimientos_tarjeta mt ON mt.tarjeta_id = t.id
    LEFT JOIN Cuotas_credito cc ON cc.movimiento_id = mt.id
    WHERE cl.id = p_cliente_id AND cc.estado = 'Pendiente';

    RETURN _total_deuda;
END //

DELIMITER ;

SELECT fn_cuotas_credito(1) AS Total_deuda;

-- Estimar el total de pagos realizados por tipo de tarjeta durante un período determinado.

DELIMITER //

DROP FUNCTION IF EXISTS fn_total_pagos_por_tipo;
CREATE FUNCTION fn_total_pagos_por_tipo(p_tipo_tarjeta_id INT, p_fecha_inicio DATE, p_fecha_fin DATE)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE _total DECIMAL(10,2) DEFAULT 0;

    SELECT IFNULL(SUM(pt.monto), 0) INTO _total
    FROM Pagos_tarjeta pt
    INNER JOIN Cuotas_credito cc ON pt.cuota_credito_id = cc.id
    INNER JOIN Movimientos_tarjeta mt ON cc.movimiento_id = mt.id
    INNER JOIN Tarjetas t ON mt.tarjeta_id = t.id
    WHERE t.tipo_tarjeta_id = p_tipo_tarjeta_id AND pt.fecha_pago BETWEEN p_fecha_inicio AND p_fecha_fin;

    RETURN _total;
END //

DELIMITER ;

SELECT fn_total_pagos_por_tipo(1, '2020-01-01', '2026-01-01')

-- Calcular el monto total de las cuotas de manejo para todos los clientes de un mes.

DELIMITER //

DROP FUNCTION IF EXISTS fn_total_cuotas_manejo_mes;
CREATE FUNCTION fn_total_cuotas_manejo_mes(p_mes INT, p_anio INT)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE _total DECIMAL(10,2) DEFAULT 0;

    SELECT SUM(monto_total) INTO _total
    FROM Cuotas_de_manejo
    WHERE MONTH(vencimiento_cuota) = p_mes AND YEAR(vencimiento_cuota) = p_anio;

    RETURN _total;
END //

DELIMITER ;

SELECT fn_total_cuotas_manejo_mes(6, 2025);


--  Calcular cuánto le falta por pagar a un cliente en cuotas de crédito

DELIMITER //

DROP FUNCTION IF EXISTS fn_total_credito_pendiente_cliente;
CREATE FUNCTION fn_total_credito_pendiente_cliente(p_cliente_id INT)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE _total_credito DECIMAL(10,2) DEFAULT 0.00;
    DECLARE _pagado DECIMAL(10,2) DEFAULT 0.00;
    DECLARE _pendiente DECIMAL(10,2);

    SELECT IFNULL(SUM(cc.valor_cuota), 0) INTO _total_credito
    FROM Clientes cl
    JOIN Cuentas cu ON cu.cliente_id = cl.id
    JOIN Tarjetas t ON t.cuenta_id = cu.id
    JOIN Movimientos_tarjeta mt ON mt.tarjeta_id = t.id
    JOIN Cuotas_credito cc ON cc.movimiento_id = mt.id
    WHERE cl.id = p_cliente_id AND cc.estado = 'Pendiente';

    SELECT IFNULL(SUM(pt.monto), 0) INTO _pagado
    FROM Clientes cl
    JOIN Cuentas cu ON cu.cliente_id = cl.id
    JOIN Tarjetas t ON t.cuenta_id = cu.id
    JOIN Movimientos_tarjeta mt ON mt.tarjeta_id = t.id
    JOIN Cuotas_credito cc ON cc.movimiento_id = mt.id
    JOIN Pagos_tarjeta pt ON pt.cuota_credito_id = cc.id
    WHERE cl.id = p_cliente_id AND cc.estado = 'Pendiente';

    SET _pendiente = _total_credito - _pagado;

    IF _pendiente < 0 THEN
        SET _pendiente = 0;
    END IF;

    RETURN _pendiente;
END //

DELIMITER ;

SELECT fn_total_credito_pendiente_cliente(1) AS Total_pendiente;