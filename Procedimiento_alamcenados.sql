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

 -- EJERCICIOS DE PROCEDIMIENTOS DEL SEÑOR JULIAN 


-- Crea un procedimiento almacenado llamado cuota_manejo_calc_descuento que registre una nueva cuota de manejo para una tarjeta bancaria específica,
-- aplicando automáticamente un descuento según las características del cliente y la tarjeta asociada

 DROP PROCEDURE IF EXISTS cuota_manejo_calc_descuento;

DELIMITER $$

CREATE PROCEDURE cuota_manejo_calc_descuento (
    IN p_tarjeta_id BIGINT,
    IN p_tipo_cuota_manejo_id BIGINT,
    IN p_monto_apertura DECIMAL(15,2),
    IN p_fecha_inicio TIMESTAMP,
    IN p_frecuencia_pago_id BIGINT,
    IN p_fecha_fin DATE,
    IN p_activo BOOLEAN
)
BEGIN
    -- Variables para manejar los datos de la tarjeta a asignarle la cuota de manejo
    DECLARE vttid BIGINT; --tipo tarjeta
    DECLARE vntid BIGINT; --nivel tarjeta
    DECLARE vctid BIGINT; --tipo cliente
    
    -- Variables para el descuento
    DECLARE vdid BIGINT DEFAULT 1; -- Descuento por defecto
    DECLARE vdv DECIMAL(15,2);--valor descuento
    DECLARE vdt VARCHAR(20);--tipo valor
    
    -- Variables para manejar los calculos
    DECLARE vda DECIMAL(15,2) DEFAULT 0.00; --descuento aplicado
    DECLARE vmf DECIMAL(15,2); --monto final
    DECLARE vcmid BIGINT; --cuota manejo id
    
    -- Variables para manejo de errores
    DECLARE verrmsg VARCHAR(255);
    DECLARE exit handler FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        GET DIAGNOSTICS CONDITION 1 verrmsg = MESSAGE_TEXT;
        SELECT CONCAT('Error: ', verrmsg) as resultado;
    END;

    START TRANSACTION;
    
    -- Se obtiene la informacion de la tarjeta y del cliente del que vamos a asignarle la nueva cuota de manejo
    SELECT 
        tb.tipo_tarjeta_id,
        tb.nivel_tarjeta_id,
        c.tipo_cliente_id
    INTO 
        vttid,
        vntid,
        vctid
    FROM tarjetas_bancarias tb
    JOIN cuenta_tarjeta ct ON tb.id = ct.tarjeta_id
    JOIN cuenta cu ON ct.cuenta_id = cu.id
    JOIN clientes c ON cu.cliente_id = c.id
    WHERE tb.id = p_tarjeta_id
    LIMIT 1;
    
    -- Validamos que exista la tarjeta
    IF vttid IS NULL THEN
        SET verrmsg = CONCAT('Tarjeta con ID ', p_tarjeta_id, ' no encontrada');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = verrmsg;
    END IF;
    
    -- A corde a las reglas de negocio actuales se va a definir que descuento se va a asignar:
    SET vdid = CASE
        -- Clientes VIP (tipo_cliente_id = 4) - Descuento VIP en todos los niveles altos
        WHEN vctid = 4 AND vntid >= 4 THEN 8  -- DESC_VIP
        WHEN vctid = 4 AND vntid >= 2 THEN 4  -- DESC_CONV
        
        -- Tarjetas empresariales (nivel 7) - Descuento empresarial
        WHEN vntid = 7 THEN 10  -- DESC_EMP
        
        -- Tarjetas premium (niveles 4,5,6) - Descuentos especiales
        WHEN vntid >= 4 THEN 8   -- DESC_VIP
        WHEN vntid = 3 THEN 3    -- DESC_CUO_MAN (Exención)
        
        -- Tarjetas Gold (nivel 2) con diferentes tipos
        WHEN vntid = 2 AND vttid = 4 THEN 4  -- Empresarial -> DESC_CONV
        WHEN vntid = 2 AND vttid = 5 THEN 7  -- Nomina -> DESC_NOM
        WHEN vntid = 2 AND vttid = 6 THEN 5  -- Virtual -> CASHBACK
        WHEN vntid = 2 THEN 2    -- Otras Gold -> DESC_DEB_AUT
        
        -- Tarjetas basicas (nivel 1) - Descuento minimo
        ELSE 1  -- DESC_USO
    END;
    
    -- Obtener informacion del descuento
    SELECT valor, tipo_valor 
    INTO vdv, vdt
    FROM descuento 
    WHERE id = vdid AND activo = TRUE;
    
    -- Calcular el descuento aplicado
    IF vdt = 'PORCENTAJE' THEN
        SET vda = p_monto_apertura * (vdv / 100);
    ELSEIF vdt = 'MONTO_FIJO' THEN
        SET vda = LEAST(vdv, p_monto_apertura);
    END IF;
    
    -- Calcular monto final
    SET vmf = p_monto_apertura - vda;
    
    -- Asegurar que el monto final no sea negativo
    IF vmf < 0 THEN
        SET vmf = 0;
        SET vda = p_monto_apertura;
    END IF;
    
    -- Insertar la cuota de manejo
    INSERT INTO cuotas_manejo (tarjeta_id,tipo_cuota_manejo_id,monto_apertura,fecha_inicio,frecuencia_pago_id,fecha_fin,activo) VALUES 
    (p_tarjeta_id,p_tipo_cuota_manejo_id,p_monto_apertura,p_fecha_inicio,p_frecuencia_pago_id,p_fecha_fin,p_activo);
    
    -- Obtener el ID de la cuota creada
    SET vcmid = LAST_INSERT_ID();
    
    -- Insertar el descuento aplicado (solo si hay descuento)
    IF vda > 0 THEN
        INSERT INTO descuentos_aplicados (tarjeta_id,descuento_id,monto_inicial,descuento_aplicado,monto_con_descuento,fecha_aplicado) VALUES 
        (p_tarjeta_id,vdid,p_monto_apertura,vda,vmf,NOW());
    END IF;
    
    COMMIT;
    
    -- Retornar información del proceso
    SELECT 
        vcmid as cuota_id,
        p_tarjeta_id as tarjeta_id,
        p_monto_apertura as monto_original,
        vda as descuento_aplicado,
        vmf as monto_final,
        (SELECT nombre FROM descuento WHERE id = vdid) as tipo_descuento,
        CONCAT(ROUND((vda/p_monto_apertura)*100,2), '%') as porcentaje_descuento,
        'Cuota creada exitosamente' as mensaje;
        
END $$

DELIMITER ;

CALL cuota_manejo_calc_descuento(
    1,                    -- tarjeta clasica
    1,                    -- periodica
    15000.00,            -- monto_apertura
    NOW(),               -- fecha_inicio
    4,                   -- mensual
    '2025-12-31',        -- fecha_fin
    TRUE                 -- activo
);

CALL cuota_manejo_calc_descuento(
    4,                    -- tarjeta platino
    2,                    -- por producto
    25000.00,            -- monto_apertura
    NOW(),               -- fecha_inicio
    4,                   -- mensual
    '2025-12-31',        -- fecha_fin
    TRUE                 -- activo
);




-- 2. aplicar_descuento_fijo
-- Aplicar un descuento de monto fijo a una cuota específica
-- Parámetros: cuota_id, monto_descuento


-- SELECT * FROM descuento WHERE tipo_valor = 'MONTO_FIJO';
-- SELECT tarjeta_id
-- FROM cuotas_manejo
-- WHERE id = 2;


DROP PROCEDURE IF EXISTS aplicar_descuento_fijo;

DELIMITER $$


CREATE PROCEDURE aplicar_descuento_fijo(
    IN p_cuota_id BIGINT,
    IN p_monto_descuento DECIMAL(15,2)
)
BEGIN

    DECLARE vtid BIGINT; -- Tarjeta id
    DECLARE vmacm BIGINT; -- valor monto apertura cuota manejo
    DECLARE vda DECIMAL(15,2); -- valor descuento aplicado


    DECLARE vce INT DEFAULT 0; -- validador de que exista la cuota UnU
    DECLARE verrmsg VARCHAR(255);
    

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        GET DIAGNOSTICS CONDITION 1 verrmsg = MESSAGE_TEXT;
        SELECT CONCAT('Error: ', verrmsg) AS resultado;
    END;



    START TRANSACTION;



    IF p_monto_descuento <= 0 THEN
            SIGNAL SQLSTATE '45000' 
            SET MESSAGE_TEXT = 'El monto del descuento debe ser mayor a cero';
        END IF;






    SELECT tarjeta_id, monto_apertura, 1
    INTO vtid, vmacm, vce
    FROM cuotas_manejo
    WHERE id = p_cuota_id
    AND activo = TRUE;


    IF vce = 0 THEN
            SIGNAL SQLSTATE '45000' 
            SET MESSAGE_TEXT = 'Cuota de manejo no encontrada o inactiva';
        END IF;


    IF p_monto_descuento > vmacm THEN
        SET vda = 0.00; -- si el descuento es mayor la cuota queda en $0
    ELSE
        SET vda = vmacm - p_monto_descuento; -- monto final despues de aplicar el fukin descuento
    END IF;


    IF EXISTS (
            SELECT 1 FROM descuentos_aplicados 
            WHERE tarjeta_id = vtid 
            AND DATE(fecha_aplicado) = CURDATE()
        ) THEN
            SIGNAL SQLSTATE '45000' 
            SET MESSAGE_TEXT = 'Ya existe un descuento aplicado para esta tarjeta';
        END IF;




    INSERT INTO descuentos_aplicados (descuento_aplicado,descuento_id,fecha_aplicado,monto_con_descuento,monto_inicial,tarjeta_id) VALUES 
    (LEAST(p_monto_descuento, vmacm), 1, NOW(), vda, vmacm, vtid);



    COMMIT;


    SELECT
        p_cuota_id AS cuota_id,
        vtid AS tarjeta_id,
        vmacm AS monto_original,
        LEAST(p_monto_descuento, vmacm) AS descuento_aplicado,
        vda AS monto_final,
        CONCAT('$', FORMAT(LEAST(p_monto_descuento, vmacm), 0)) AS descuento_formato,
        CONCAT(ROUND((LEAST(p_monto_descuento, vmacm) / vmacm) * 100, 2), '%') AS porcentaje_descuento,
        CASE 
            WHEN p_monto_descuento >= vmacm THEN 'Cuota completamente exonerada'
            ELSE 'Descuento aplicado exitosamente'
        END AS mensaje;




END $$


DELIMITER ;

CALL aplicar_descuento_fijo(1, 500.00);
CALL aplicar_descuento_fijo(2, 1000.00);
CALL aplicar_descuento_fijo(3, 50000.00);

SELECT 
    da.id,
    tb.numero AS tarjeta,
    da.monto_inicial,
    da.descuento_aplicado,
    da.monto_con_descuento,
    da.fecha_aplicado,
    CONCAT(c.primer_nombre, ' ', c.primer_apellido) AS cliente
FROM descuentos_aplicados da
JOIN tarjetas_bancarias tb ON da.tarjeta_id = tb.id
JOIN cuenta_tarjeta ct ON tb.id = ct.tarjeta_id
JOIN cuenta cu ON ct.cuenta_id = cu.id
JOIN clientes c ON cu.cliente_id = c.id
WHERE da.descuento_id = 1 -- Solo descuentos por uso (fijos)
ORDER BY da.fecha_aplicado DESC
LIMIT 5;

SHOW PROCEDURE STATUS WHERE Name = 'aplicar_descuento_fijo';

-- 6. registrar_pago_efectivo
-- Registrar un pago simple en efectivo
-- Parámetros: cuenta_id, monto, descripcion

DESCRIBE pagos;
SELECT * FROM metodos_de_pago; -- 1
SELECT * FROM tipos_pago; -- 10
SELECT * FROM estados_pago; -- 2
SELECT * FROM metodos_transaccion; -- 1
SELECT * FROM pagos; 

DROP PROCEDURE IF EXISTS registrar_pago_efectivo;

DELIMITER $$

CREATE PROCEDURE registrar_pago_efectivo(
    IN p_cuenta_id BIGINT,
    IN p_monto DECIMAL(15,2),
    IN p_descripcion VARCHAR(120)
)
BEGIN
    DECLARE vr VARCHAR(40); -- referencia de pago
    START TRANSACTION;

    SET vr = fn_generar_codigo_unico();


    INSERT INTO pagos (cuenta_id,descripcion,estado_pago_id,fecha_pago,metodo_transaccion_id,monto,referencia,tipo_pago_id) VALUES 
    (p_cuenta_id, p_descripcion, 2, NOW(), 1, p_monto, vr, 10);

    COMMIT;

END $$

DELIMITER ;

SELECT id FROM cuenta;
CALL registrar_pago_efectivo(1, 1000, 'pq si');

SELECT * FROM pagos WHERE cuenta_id = 1;



-- 16. listar_tarjetas_activas
-- Mostrar todas las tarjetas con estado ACTIVA
-- Parámetros: cliente_id (opcional)

SELECT * FROM estados;
SELECT * FROM tarjetas_bancarias;
SELECT *
FROM tarjetas_bancarias
LEFT JOIN cuenta_tarjeta ON tarjetas_bancarias.id = cuenta_tarjeta.tarjeta_id
LEFT JOIN cuenta ON cuenta_tarjeta.cuenta_id = cuenta.id
WHERE tarjetas_bancarias.estado_id = 4
    AND (cuenta.cliente_id = p_cliente_id OR p_cliente_id IS NULL);




DROP PROCEDURE IF EXISTS listar_tarjetas_activas;

DELIMITER $$

CREATE PROCEDURE listar_tarjetas_activas(
    IN p_cliente_id BIGINT
)
BEGIN

    START TRANSACTION;

    SELECT *
    FROM tarjetas_bancarias
    LEFT JOIN cuenta_tarjeta ON tarjetas_bancarias.id = cuenta_tarjeta.tarjeta_id
    LEFT JOIN cuenta ON cuenta_tarjeta.cuenta_id = cuenta.id
    WHERE tarjetas_bancarias.estado_id = 4
    AND (cuenta.cliente_id = p_cliente_id OR p_cliente_id IS NULL);



    COMMIT;

END $$

DELIMITER ;

CALL listar_tarjetas_activas(NULL);
CALL listar_tarjetas_activas(1);



-- 18. generar_referencia_pago
-- Generar una referencia única para un nuevo pago
-- Parámetros: prefijo (ej: "PAY")

DROP PROCEDURE IF EXISTS generar_referencia_pago;


-- SELECT * FROM pagos;
DELIMITER $$

CREATE PROCEDURE generar_referencia_pago(
    IN p_prefijo VARCHAR(10),
    OUT nueva_referencia VARCHAR(40)
)
BEGIN

    DECLARE ultimo_numero_referencia BIGINT DEFAULT 0;

    START TRANSACTION;


    SELECT
        COALESCE(
            CAST(SUBSTRING(referencia, LENGTH(p_prefijo)+1) + 0 AS UNSIGNED),
            0
        ) INTO ultimo_numero_referencia
    FROM pagos
    WHERE LEFT(referencia, LENGTH(p_prefijo)) = p_prefijo
    ORDER BY id DESC
    LIMIT 1;



    SET nueva_referencia = CONCAT(p_prefijo, LPAD(ultimo_numero_referencia + 1, 3, '0'));
    
    
    COMMIT;

END $$

DELIMITER ;

CALL generar_referencia_pago('PAY', @ref);
SELECT @ref AS nueva_referencia;

 -- Procedimientos almacenados de kevin

-- 1. Registrar una nueva cuota de manejo calculando automáticamente el descuento.

DELIMITER $$

CREATE PROCEDURE RegistrarCuotaManejo(
    IN tarjeta_id INT,
    IN monto_base DECIMAL(10,2),
    IN fecha_vencimiento DATE
)
BEGIN
    DECLARE descuento_id INT;
    DECLARE porcentaje_descuento DECIMAL(5,4);
    DECLARE monto_final DECIMAL(10,2);

    -- Obtener el descuento aplicable
    SELECT TD.id_tipo_descuento, TD.porcentaje_descuento
    INTO descuento_id, porcentaje_descuento
    FROM Tarjeta_Descuento_Historico TDH
    JOIN Tipo_Descuento TD ON TDH.tipo_descuento_id = TD.id_tipo_descuento
    WHERE TDH.tarjeta_id_descuento = tarjeta_id
      AND CURDATE() BETWEEN TDH.fecha_inicio_aplicacion AND IFNULL(TDH.fecha_fin_aplicacion, CURDATE())
    LIMIT 1;

    -- Calcular el monto final con descuento
    IF descuento_id IS NOT NULL THEN
        SET monto_final = monto_base * (1 - porcentaje_descuento);
    ELSE
        SET monto_final = monto_base;
    END IF;

    -- Insertar la nueva cuota de manejo
    INSERT INTO Cuota_Manejo (
        tarjeta_id_cuota, fecha_generacion, monto_base, id_tarjeta_descuento_historico, monto_final_a_pagar, fecha_vencimiento_pago, estado_cuota_id
    ) VALUES (
        tarjeta_id, CURDATE(), monto_base, descuento_id, monto_final, fecha_vencimiento, 1
    );
END$$

DELIMITER ;

CALL RegistrarCuotaManejo(1, 100.00, '2024-12-31');

SELECT * FROM Cuota_Manejo;


-- 2. Procesar pagos y actualizar el historial de pagos de los clientes.

DELIMITER $$

CREATE PROCEDURE ProcesarPago(
    IN cuota_id INT,
    IN monto_pagado DECIMAL(10,2),
    IN metodo_pago_id INT,
    IN referencia_transaccion VARCHAR(100),
    IN empleado_id INT
)
BEGIN
    DECLARE estado_cuota INT;

    -- Insertar el pago
    INSERT INTO Pago (
        cuota_id_pago, monto_pagado, fecha_pago, metodo_pago_id, referencia_transaccion, empleado_registro_id
    ) VALUES (
        cuota_id, monto_pagado, NOW(), metodo_pago_id, referencia_transaccion, empleado_id
    );

    -- Actualizar el estado de la cuota
    SELECT estado_cuota_id INTO estado_cuota
    FROM Cuota_Manejo
    WHERE id_cuota = cuota_id;

    IF estado_cuota = 1 THEN -- Pendiente
        UPDATE Cuota_Manejo
        SET estado_cuota_id = 2 -- Pagada
        WHERE id_cuota = cuota_id;
    END IF;

    -- Registrar en el historial de pagos
    INSERT INTO Historial_Pagos (
        pago_id_historial, fecha_registro_historial, tipo_evento_id_historial, observaciones
    ) VALUES (
        LAST_INSERT_ID(), NOW(), 1, CONCAT('Pago registrado para la cuota ', cuota_id)
    );
END$$

DELIMITER ;

CALL ProcesarPago(1, 100.00, 1, 'TRN001-C1-P1', 4);

SELECT * FROM Pago;


-- 5. Registrar nuevos clientes y tarjetas automáticamente con los datos de apertura.

DELIMITER $$

DROP PROCEDURE IF EXISTS RegistrarClienteYTarjeta;
CREATE PROCEDURE RegistrarClienteYTarjeta(
    IN nombre_completo VARCHAR(100),
    IN correo_electronico VARCHAR(100),
    IN numero_identificacion VARCHAR(30),
    IN tipo_tarjeta_id INT,
    IN marca_tarjeta_id INT,
    IN cuenta_id INT,
    IN linea_credito DECIMAL(18,2),
    IN fecha_vencimiento DATE
)
BEGIN
    DECLARE cliente_id INT;

    -- Registrar el cliente
    INSERT INTO Usuario (
        nombre_completo, correo_electronico, username, password_hash, rol_id_usuario, activo
    ) VALUES (
        nombre_completo, correo_electronico, numero_identificacion, SHA2(numero_identificacion, 256), 3, TRUE
    );

    SET cliente_id = LAST_INSERT_ID();

    INSERT INTO Cliente (
        id_cliente, fecha_registro, numero_identificacion
    ) VALUES (
        cliente_id, CURDATE(), numero_identificacion
    );

    -- Registrar la tarjeta
    INSERT INTO Tarjeta (
        cliente_id_tarjeta, tipo_tarjeta_id, marca_tarjeta_id, cuenta_id_tarjeta, numero_tarjeta_hash, ultimos_4_digitos, fecha_emision, fecha_vencimiento, estado_tarjeta_id, linea_credito
    ) VALUES (
        cliente_id, tipo_tarjeta_id, marca_tarjeta_id, cuenta_id, SHA2(CONCAT(cliente_id, CURDATE()), 256), RIGHT(numero_identificacion, 4), CURDATE(), fecha_vencimiento, 1, linea_credito
    );
END$$

DELIMITER ;

CALL RegistrarClienteYTarjeta(
    'Carlos Gómez', 
    'carlos.gomez@banco.com', 
    '1020304050', 
    2, -- Tipo de tarjeta (Crédito)
    1, -- Marca de tarjeta (Visa)
    3, -- ID de cuenta asociada
    5000.00, -- Línea de crédito
    '2025-12-31' -- Fecha de vencimiento
);
SELECT * FROM Usuario;

SELECT * FROM Cliente;

SELECT * FROM Tarjeta;


-- 15. Generar un reporte detallado de pagos por cliente, sucursal y método de pago.

DELIMITER $$

CREATE PROCEDURE ReportePagosDetallado(
    IN fecha_inicio DATE,
    IN fecha_fin DATE
)
BEGIN
    SELECT 
        U.nombre_completo AS cliente,
        S.nombre_sucursal AS sucursal,
        MP.nombre_metodo_pago AS metodo_pago,
        COUNT(P.id_pago) AS total_pagos,
        SUM(P.monto_pagado) AS monto_total
    FROM Pago P
    JOIN Cuota_Manejo CM ON P.cuota_id_pago = CM.id_cuota
    JOIN Tarjeta T ON CM.tarjeta_id_cuota = T.id_tarjeta
    JOIN Cliente C ON T.cliente_id_tarjeta = C.id_cliente
    JOIN Usuario U ON C.id_cliente = U.id_usuario
    JOIN Empleado E ON P.empleado_registro_id = E.id_empleado
    JOIN Sucursal S ON E.sucursal_id_empleado = S.id_sucursal
    JOIN Metodo_Pago MP ON P.metodo_pago_id = MP.id_metodo_pago
    WHERE P.fecha_pago BETWEEN fecha_inicio AND fecha_fin
    GROUP BY U.nombre_completo, S.nombre_sucursal, MP.nombre_metodo_pago
    ORDER BY monto_total DESC;
END$$

DELIMITER ;

CALL ReportePagosDetallado('2024-01-01', '2024-12-31');



-- 20. Generar un reporte de clientes con tarjetas activas, cuotas vencidas y pagos realizados en el último año.

DELIMITER $$

CREATE PROCEDURE ReporteClientesTarjetasActivasCuotasVencidasPagos(
    IN anio INT
)
BEGIN
    SELECT 
        U.nombre_completo AS cliente,
        T.id_tarjeta AS tarjeta_id,
        T.ultimos_4_digitos AS ultimos_digitos_tarjeta,
        COUNT(CM.id_cuota) AS total_cuotas_vencidas,
        SUM(CM.monto_final_a_pagar) AS monto_total_vencido,
        COUNT(P.id_pago) AS total_pagos_realizados,
        SUM(P.monto_pagado) AS monto_total_pagado
    FROM Usuario U
    JOIN Cliente C ON U.id_usuario = C.id_cliente
    JOIN Tarjeta T ON C.id_cliente = T.cliente_id_tarjeta
    JOIN Estado_Tarjeta ET ON T.estado_tarjeta_id = ET.id_estado_tarjeta
    JOIN Cuota_Manejo CM ON T.id_tarjeta = CM.tarjeta_id_cuota
    LEFT JOIN Pago P ON CM.id_cuota = P.cuota_id_pago
    WHERE ET.nombre_estado_tarjeta = 'Activa'
      AND CM.fecha_vencimiento_pago < CURDATE()
      AND YEAR(P.fecha_pago) = anio
    GROUP BY U.nombre_completo, T.id_tarjeta, T.ultimos_4_digitos
    ORDER BY monto_total_vencido DESC, monto_total_pagado DESC;
END$$

DELIMITER ;

CALL ReporteClientesTarjetasActivasCuotasVencidasPagos(2024);