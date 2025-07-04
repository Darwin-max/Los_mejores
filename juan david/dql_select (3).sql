-- 1. Total de pagos por estado
SELECT 
    estado,
    COUNT(*) AS cantidad_pagos,
    SUM(total) AS monto_total
FROM pago
GROUP BY estado;

-- 2. Cuotas de manejo por tipo de tarjeta
SELECT 
    ta.tipo_tarjeta_id AS tipo_tarjeta,
    SUM(cu.total_monto) AS total_cuotas_manejo
FROM tarjeta AS ta
JOIN cuota_manejo AS cu ON ta.id = cu.tarjeta_id
WHERE cu.fecha BETWEEN '2023-06-22' AND '2025-12-31'
GROUP BY ta.tipo_tarjeta_id;

-- 3. Clientes sin pagos registrados
SELECT 
    cl.id,
    cl.nombre,
    cl.telefono,
    cl.correo
FROM cliente cl
LEFT JOIN pago p ON cl.id = p.cliente_id
WHERE p.id IS NULL;

-- 4. Pagos realizados en fin de semana
SELECT 
    p.id,
    p.total,
    p.fecha,
    cl.nombre AS cliente,
    DAYNAME(p.fecha) AS dia_semana
FROM pago p
JOIN cliente cl ON p.cliente_id = cl.id
WHERE DAYOFWEEK(p.fecha) IN (1, 7);

-- 5. Promedio de montos en cuotas por cliente
SELECT 
    cl.nombre,
    AVG(cm.total_monto) AS promedio_cuotas
FROM cliente cl
JOIN cuota_manejo cm ON cl.id = cm.cliente_id
GROUP BY cl.id;

-- 6. Ingresos por tipo de tarjeta
SELECT 
    tt.nombre AS tipo_tarjeta,
    SUM(cm.total_monto) AS ingresos_cuotas
FROM tipo_tarjeta tt
JOIN tarjeta t ON tt.id = t.tipo_tarjeta_id
JOIN cuota_manejo cm ON t.id = cm.tarjeta_id
GROUP BY tt.id;

-- 7. Top 10 clientes más rentables
SELECT 
    cl.nombre,
    SUM(cm.total_monto) AS total_cuotas_pagadas
FROM cliente cl
JOIN cuota_manejo cm ON cl.id = cm.cliente_id
GROUP BY cl.id
ORDER BY total_cuotas_pagadas DESC
LIMIT 10;

-- 8. Historial de pagos por trimestre
SELECT 
    YEAR(hp.fecha_pago) AS año,
    QUARTER(hp.fecha_pago) AS trimestre,
    COUNT(*) AS pagos_realizados
FROM historial_pagos hp
GROUP BY YEAR(hp.fecha_pago), QUARTER(hp.fecha_pago);

-- 9. Cuotas de manejo sin intereses
SELECT 
    cm.id,
    cm.total_monto,
    cl.nombre AS cliente
FROM cuota_manejo cm
JOIN cliente cl ON cm.cliente_id = cl.id
LEFT JOIN intereses i ON cm.interes_id = i.id
WHERE i.id IS NULL;

-- 10. Clientes con pagos pendientes últimos 3 meses
SELECT 
    cl.nombre AS cliente,
    pa.total
FROM cliente cl
JOIN pago pa ON cl.id = pa.cliente_id
WHERE pa.fecha >= DATE_SUB(CURDATE(), INTERVAL 3 MONTH)
  AND pa.estado = 'Pendiente';

-- 11. ROI por cliente
SELECT 
    cl.nombre,
    SUM(cm.total_monto) AS ingresos_generados,
    COUNT(p.id) AS transacciones,
    ROUND(SUM(cm.total_monto) / COUNT(p.id), 2) AS roi
FROM cliente cl
JOIN cuota_manejo cm ON cl.id = cm.cliente_id
LEFT JOIN pago p ON cl.id = p.cliente_id
GROUP BY cl.id
HAVING COUNT(p.id) > 0;

-- 12. Cuotas por mes
SELECT 
    YEAR(fecha) AS año,
    MONTH(fecha) AS mes,
    SUM(total_monto) AS ingresos_cuotas
FROM cuota_manejo
GROUP BY año, mes;

-- 13. Clientes más recientes
SELECT 
    c.id, c.nombre
FROM cliente c
JOIN tarjeta t ON c.tarjeta_id = t.id
ORDER BY t.fecha_activacion DESC
LIMIT 3;

-- 14. Tarjetas próximas a vencer (30 días)
SELECT 
    t.numero, t.fecha_expiracion, cl.nombre
FROM tarjeta t
JOIN cliente cl ON t.id = cl.tarjeta_id
WHERE t.fecha_expiracion BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 30 DAY);

-- 15. Ingresos proyectados y realizados
SELECT 
    MONTH(p.fecha) AS mes,
    SUM(CASE WHEN p.estado = 'Pendiente' THEN p.total ELSE 0 END) AS ingresos_proyectados,
    SUM(CASE WHEN p.estado = 'Pagado' THEN p.total ELSE 0 END) AS ingresos_realizados
FROM pago p
WHERE p.fecha >= CURDATE()
GROUP BY mes;

-- 16. Cuentas sin tarjetas
SELECT 
    cb.numero_cuenta
FROM cuenta_bancaria cb
LEFT JOIN tarjeta t ON cb.id = t.cuenta_bancaria_id
WHERE t.id IS NULL;

-- 17. KPI del mes actual
SELECT 
    'Ingresos Cuotas' AS kpi,
    SUM(cm.total_monto) AS valor
FROM cuota_manejo cm
WHERE MONTH(cm.fecha) = MONTH(CURDATE());

-- 18. Validación de tasas
SELECT 
    id, tasa_interes
FROM intereses
WHERE tasa_interes <= 0 OR tasa_interes > 100;

-- 19. Descuentos aplicados
SELECT 
    d.nombre,
    SUM(cm.total_monto) AS ingresos,
    SUM(cm.total_monto * d.tasa_descuento / 100) AS descuentos
FROM descuento d
JOIN cuota_manejo cm ON d.id = cm.descuento_id
GROUP BY d.id;

-- 20. Total alertas por cliente
SELECT 
    cl.nombre,
    COUNT(ap.id) AS total_alertas
FROM cliente cl
JOIN alerta_pago ap ON cl.id = ap.cliente_id
GROUP BY cl.id;

-- 21. Clientes inactivos (90 días)
SELECT 
    COUNT(*) AS clientes_inactivos
FROM (
    SELECT cl.id, MAX(p.fecha) AS ultima_actividad
    FROM cliente cl
    LEFT JOIN pago p ON cl.id = p.cliente_id
    GROUP BY cl.id
    HAVING ultima_actividad < DATE_SUB(CURDATE(), INTERVAL 90 DAY)
) inactivos;

-- 22. Morosidad por tipo de tarjeta
SELECT 
    tt.nombre,
    COUNT(CASE WHEN p.estado = 'Vencido' THEN 1 END) AS vencidos,
    ROUND(COUNT(CASE WHEN p.estado = 'Vencido' THEN 1 END) * 100.0 / COUNT(p.id), 2) AS porcentaje_morosidad
FROM tipo_tarjeta tt
JOIN tarjeta t ON tt.id = t.tipo_tarjeta_id
JOIN pago p ON t.id = p.tarjeta_id
GROUP BY tt.id;

-- 23. Top clientes por volumen de pagos
SELECT 
    cl.nombre,
    SUM(p.total) AS total_pagado
FROM cliente cl
JOIN pago p ON cl.id = p.cliente_id
GROUP BY cl.id
ORDER BY total_pagado DESC
LIMIT 10;

-- 24. Benchmark de rentabilidad por producto
SELECT 
    tt.nombre,
    AVG(cm.total_monto) AS cuota_promedio,
    COUNT(t.id) AS cantidad_activas
FROM tipo_tarjeta tt
JOIN tarjeta t ON tt.id = t.tipo_tarjeta_id
JOIN cuota_manejo cm ON t.id = cm.tarjeta_id
WHERE t.estado = 'Activa'
GROUP BY tt.id;

-- 25. Tarjetas expiradas pero activas
SELECT 
    t.numero,
    t.fecha_expiracion,
    t.estado
FROM tarjeta t
WHERE t.fecha_expiracion < CURDATE() AND t.estado = 'Activa';