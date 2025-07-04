
-- 1. Muestra el tipo, nivel de una tarjeta y el tipo de cliente que la tiene
SELECT 
        tb.tipo_tarjeta_id,
        tb.nivel_tarjeta_id,
        c.tipo_cliente_id
    FROM tarjetas_bancarias tb
    JOIN cuenta_tarjeta ct ON tb.id = ct.tarjeta_id
    JOIN cuenta cu ON ct.cuenta_id = cu.id
    JOIN clientes c ON cu.cliente_id = c.id
    WHERE tb.id = 1
    LIMIT 1;


-- 2 Muestra las 10 ultimas cuotas de manejo con info de la tarjeta, el cliente y el descuento aplicado 
SELECT 
    'Resultado procedimiento' as titulo,
    cm.id as cuota_id,
    tb.numero as tarjeta,
    nt.nombre as nivel_tarjeta,
    tt.nombre as tipo_tarjeta,
    tc.nombre as tipo_cliente,
    cm.monto_apertura,
    da.descuento_aplicado,
    da.monto_con_descuento,
    d.nombre as tipo_descuento,
    CONCAT(d.valor, ' ', d.tipo_valor) as descuento_config
FROM cuotas_manejo cm
JOIN tarjetas_bancarias tb ON cm.tarjeta_id = tb.id
JOIN nivel_tarjeta nt ON tb.nivel_tarjeta_id = nt.id
JOIN tipo_tarjetas tt ON tb.tipo_tarjeta_id = tt.id
JOIN cuenta_tarjeta ct ON tb.id = ct.tarjeta_id
JOIN cuenta cu ON ct.cuenta_id = cu.id
JOIN clientes c ON cu.cliente_id = c.id
JOIN tipo_cliente tc ON c.tipo_cliente_id = tc.id
LEFT JOIN descuentos_aplicados da ON cm.tarjeta_id = da.tarjeta_id 
    AND da.fecha_aplicado >= cm.fecha_inicio
LEFT JOIN descuento d ON da.descuento_id = d.id
ORDER BY cm.fecha_inicio DESC
LIMIT 10;

-- 3 Muestra las 5 cuotas de manejo mas recientes con el numero de la tarjeta, monto, tipo de cuota, fecha y nombre del cliente
SELECT 
    cm.id,
    tb.numero AS tarjeta,
    cm.monto_apertura,
    tcm.nombre AS tipo_cuota,
    cm.fecha_inicio,
    CONCAT(c.primer_nombre, ' ', c.primer_apellido) AS cliente
FROM cuotas_manejo cm
JOIN tarjetas_bancarias tb ON cm.tarjeta_id = tb.id
JOIN tipo_cuota_de_manejo tcm ON cm.tipo_cuota_manejo_id = tcm.id
JOIN cuenta_tarjeta ct ON tb.id = ct.tarjeta_id
JOIN cuenta cu ON ct.cuenta_id = cu.id
JOIN clientes c ON cu.cliente_id = c.id
ORDER BY cm.fecha_inicio DESC
LIMIT 5;


-- 4 Muestra los ultimos 5 descuentos aplicados de tipo fijo, 
-- incluyendo el numero de tarjeta, monto antes y despues del descuento, fecha y nombre del cliente.
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


-- 5 Muestra el saldo disponible y el ID de la cuenta del cliente
SELECT saldo_disponible, id AS cuenta_id
FROM cuenta
WHERE cliente_id = 1;


-- 6 Muestra toda la información de las tarjetas con estado 4 
-- que esten asociadas a una cuenta del cliente
SELECT *
FROM tarjetas_bancarias
LEFT JOIN cuenta_tarjeta ON tarjetas_bancarias.id = cuenta_tarjeta.tarjeta_id
LEFT JOIN cuenta ON cuenta_tarjeta.cuenta_id = cuenta.id
WHERE tarjetas_bancarias.estado_id = 4
    AND (cuenta.cliente_id = 1);


-- 7 Saca el numero de una referencia que empieza con 'PAY' en la tabla pagos, 
-- lo convierte a numero y muestra el mas reciente si no hay, devuelve 
SELECT
        COALESCE(
            CAST(SUBSTRING(referencia, LENGTH('PAY')+1) + 0 AS UNSIGNED),
            0
        )
    FROM pagos
    WHERE LEFT(referencia, LENGTH('PAY')) = 'PAY'
    ORDER BY id DESC
    LIMIT 1;


-- 8 Muestra la suma total pagada para la cuota de manejo si no hay pagos, devuelve 0
SELECT COALESCE(SUM(monto_pagado),0)
    FROM pago_cuota_manejo
    WHERE cuota_manejo_id = 1;

-- 9 Muestra los valores de todos los descuentos que son de tipo porcentaje
SELECT valor 
    FROM descuento
    WHERE tipo_valor = 'PORCENTAJE';


-- 10 Muestra la suma total abonada a la cuota de manejo 

SELECT SUM(monto_abonado)
    FROM registro_cuota
    WHERE cuota_manejo_id = 1;

-- 11 Muestra la suma total pagada para la tarjeta en pagos aprobadosrealizados entre 2024 y 2027, si no hay pagos devuelve 0

SELECT IFNULL(SUM(pcm.monto_pagado), 0.00)
        FROM tarjetas_bancarias tb
        JOIN cuotas_manejo cm ON tb.id = cm.tarjeta_id
        JOIN pago_cuota_manejo pcm ON cm.id = pcm.cuota_manejo_id
        JOIN pagos p ON pcm.pago_id = p.id
        WHERE tb.id = 1
        AND p.estado_pago_id = 2  
        AND (DATE(p.fecha_pago) >= '2024-01-01')
        AND (DATE(p.fecha_pago) <= '2027-01-01');

-- 12 Muestra el total facturado en junio de 2024, si no hay datos devuelve 0
SELECT IFNULL(SUM(rc.monto_facturado), 0.00)
    FROM registro_cuota rc
    WHERE YEAR(rc.fecha_corte) = 2024
    AND MONTH(rc.fecha_corte) = 6;

-- 13 Muestra cuantas cuotas de prestamo del cliente estan en estado 6 y cuantas cuotas tiene en total
SELECT
        COUNT(CASE WHEN cp.estado_cuota_id = 6 THEN 1 END),
        COUNT (*)
    FROM cuotas_prestamo cp
    JOIN prestamos pr ON cp.prestamo_id = pr.id
    JOIN cuenta c ON pr.cuenta_id = c.id
    WHERE c.cliente_id = 1;

-- 14 Muestra el monto aprobado, el valor del interes y los dias que han pasado desde el desembolso del prestamo hasta el 1 de enero de 2024

SELECT pr.monto_aprobado, i.valor, DATEDIFF('2024-01-01', DATE(pr.fecha_desembolso))
    FROM prestamos pr
    JOIN interes i ON pr.interes_id = i.id
    WHERE pr.id = 1
    AND pr.fecha_desembolso IS NOT NULL;

-- 15 Cuenta cuantas transacciones ha tenido la cuenta en el ultimo mes, ya sea su origen o destino

SELECT COUNT(*) 
    FROM transacciones t
    WHERE (t.cuenta_origen_id = 2 OR t.cuenta_destino_id = 2)
    AND t.fecha_operacion >= DATE_SUB(CURDATE(), INTERVAL 1 MONTH);

-- 16 Calcula el 20% del total pagado en estado aprobado por el cliente si no hay pagos devuelve 0

SELECT IFNULL(SUM(monto), 0.00) *0.20
FROM pagos p
JOIN cuenta c ON p.cuenta_id = c.tipo_cuenta_id
WHERE c.cliente_id = 1
AND p.estado_pago_id = 2;

-- 17 Muestra el tipo de cliente mas comun, segun la cantidad de clientes que pertenecen a cada tipo

SELECT tc.nombre
FROM clientes c
JOIN tipo_cliente tc
ON c.tipo_cliente_id = tc.id
GROUP BY tc.nombre
ORDER BY COUNT(*) DESC
LIMIT 1;

-- 18 Muestra cuantos prestamos tiene el cliente que tienen saldo pendiente por pagar

SELECT COUNT(*) 
    FROM prestamos p
    JOIN cuenta c ON p.cuenta_id = c.id
    WHERE c.cliente_id = 1
    AND p.saldo_restante > 0;

-- 19 Obtener el listado de todas las tarjetas de los clientes junto con su cuota de manejo
SELECT * FROM tarjetas_bancarias 
JOIN cuotas_manejo ON tarjetas_bancarias.id = cuotas_manejo.tarjeta_id
JOIN cuenta_tarjeta ON cuenta_tarjeta.tarjeta_id = tarjetas_bancarias.id
JOIN cuenta ON cuenta.id = cuenta_tarjeta.cuenta_id
JOIN clientes ON clientes.id = cuenta.cliente_id;

-- 20 Consultar el historial de pagos de un cliente específico.
SELECT * FROM historial_de_pagos 
JOIN pagos ON pagos.id = historial_de_pagos.pago_id
WHERE pagos.cuenta_id = 1;

-- 21 Muestra toda la informacion relacionada con cuotas de manejo, tarjetas, descuentos aplicados y datos del cliente, 
-- uniendo todas las tablas vinculadas a una tarjeta bancaria
SELECT * FROM cuotas_manejo
JOIN tarjetas_bancarias ON cuotas_manejo.tarjeta_id = tarjetas_bancarias.id
JOIN descuentos_aplicados ON tarjetas_bancarias.id = descuentos_aplicados.tarjeta_id
JOIN cuenta_tarjeta ON cuenta_tarjeta.tarjeta_id = tarjetas_bancarias.id
JOIN cuenta ON cuenta.id = cuenta_tarjeta.cuenta_id
JOIN clientes ON clientes.id = cuenta.cliente_id;

-- 22 Muestra toda la informacion de las tarjetas activas este mes, incluyendo tipo, marca, nivel,
-- cuotas, estados, cuenta y cliente asociado, ordenadas por tipo de tarjeta y numero
SELECT *
FROM tarjetas_bancarias
JOIN tipo_tarjetas ON tarjetas_bancarias.tipo_tarjeta_id = tipo_tarjetas.id
JOIN marca_tarjeta ON tarjetas_bancarias.marca_tarjeta_id = marca_tarjeta.id
JOIN nivel_tarjeta ON tarjetas_bancarias.nivel_tarjeta_id = nivel_tarjeta.id
JOIN cuotas_manejo ON tarjetas_bancarias.id = cuotas_manejo.tarjeta_id
JOIN registro_cuota ON cuotas_manejo.id = registro_cuota.cuota_manejo_id
JOIN estados_cuota ON registro_cuota.estado_cuota_id = estados_cuota.id
JOIN cuenta_tarjeta ON tarjetas_bancarias.id = cuenta_tarjeta.tarjeta_id
JOIN cuenta ON cuenta_tarjeta.cuenta_id = cuenta.id
JOIN clientes ON cuenta.cliente_id = clientes.id
WHERE YEAR(registro_cuota.fecha_corte) = YEAR(NOW())
AND MONTH(registro_cuota.fecha_corte) = MONTH(NOW())
ORDER BY tipo_tarjetas.nombre, tarjetas_bancarias.numero;

-- 23 Muestra los clientes que tienen deudas activas en los ultimos 3 meses,
-- cuotas por pagar con saldo pendiente y en estado 2 o 5, incluyendo su informacion personal y tipo de cliente
SELECT DISTINCT
    *
FROM clientes 
JOIN tipo_cliente  ON clientes.tipo_cliente_id = tipo_cliente.id
JOIN cuenta  ON clientes.id = cuenta.cliente_id
JOIN cuenta_tarjeta  ON cuenta.id = cuenta_tarjeta.cuenta_id
JOIN tarjetas_bancarias  ON cuenta_tarjeta.tarjeta_id = tarjetas_bancarias.id
JOIN cuotas_manejo  ON tarjetas_bancarias.id = cuotas_manejo.tarjeta_id
JOIN registro_cuota ON cuotas_manejo.id = registro_cuota.cuota_manejo_id
WHERE registro_cuota.fecha_corte >= DATE_SUB(CURDATE(), INTERVAL 3 MONTH)
AND (registro_cuota.monto_a_pagar - registro_cuota.monto_abonado) > 0  
AND registro_cuota.estado_cuota_id IN (2, 5)
GROUP BY clientes.id, clientes.nit, clientes.primer_nombre, clientes.primer_apellido, clientes.email, clientes.num_contacto, tipo_cliente.nombre;

-- 24 Generar un reporte con los descuentos aplicados durante un año.
SELECT 
    *
FROM descuento 
LEFT JOIN descuentos_aplicados  ON descuento.id = descuentos_aplicados.descuento_id
    AND YEAR(descuentos_aplicados.fecha_aplicado) = 2024 
LEFT JOIN tarjetas_bancarias  ON descuentos_aplicados.tarjeta_id = tarjetas_bancarias.id
LEFT JOIN tipo_tarjetas  ON tarjetas_bancarias.tipo_tarjeta_id = tipo_tarjetas.id
WHERE descuento.activo = TRUE
GROUP BY descuento.id, descuento.codigo, descuento.nombre, descuento.descripcion, descuento.tipo_valor, descuento.valor;

-- 25 Generar un reporte que muestre el total de pagos realizados por tipo de tarjeta.
SELECT 
    tipo_tarjetas.codigo AS codigo_tipo,
    tipo_tarjetas.nombre AS tipo_tarjeta,
    tipo_tarjetas.descripcion,
    COUNT(DISTINCT pago_cuota_manejo.id) AS total_pagos_cuotas_manejo,
    COUNT(DISTINCT CASE WHEN pagos.tipo_pago_id = 3 THEN pagos.id END) AS total_pagos_credito,
    (COUNT(DISTINCT pago_cuota_manejo.id) + COUNT(DISTINCT CASE WHEN pagos.tipo_pago_id = 3 THEN pagos.id END)) AS total_pagos_general,
    (COALESCE(SUM(pago_cuota_manejo.monto_pagado), 0) + 
    COALESCE(SUM(CASE WHEN pagos.tipo_pago_id = 3 THEN pagos.monto END), 0)) AS monto_total_general,
    COUNT(DISTINCT clientes.id) AS clientes_que_pagaron,
    MIN(pago_cuota_manejo.fecha_pago) AS primer_pago_registrado,
    MAX(pago_cuota_manejo.fecha_pago) AS ultimo_pago_registrado
FROM tipo_tarjetas 
LEFT JOIN tarjetas_bancarias  ON tipo_tarjetas.id = tarjetas_bancarias.tipo_tarjeta_id
LEFT JOIN cuotas_manejo  ON tarjetas_bancarias.id = cuotas_manejo.tarjeta_id
LEFT JOIN pago_cuota_manejo  ON cuotas_manejo.id = pago_cuota_manejo.cuota_manejo_id
LEFT JOIN cuenta_tarjeta  ON tarjetas_bancarias.id = cuenta_tarjeta.tarjeta_id
LEFT JOIN cuenta  ON cuenta_tarjeta.cuenta_id = cuenta.id
LEFT JOIN pagos  ON cuenta.id = pagos.cuenta_id AND pagos.estado_pago_id = 2
LEFT JOIN clientes  ON cuenta.cliente_id = clientes.id
WHERE tipo_tarjetas.activo = TRUE
GROUP BY tipo_tarjetas.id, tipo_tarjetas.codigo, tipo_tarjetas.nombre, tipo_tarjetas.descripcion;

