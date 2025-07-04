
-- 1. Historial de pagos de un cliente
SELECT cl.id AS cliente_id, p.fecha_pago, p.total_pago, p.metodo_pago, hp.fecha_cambio, hp.nuevo_estado AS estado
FROM Clientes cl
INNER JOIN Cuentas cu ON cl.id = cu.cliente_id
INNER JOIN Tarjetas t ON cu.id = t.cuenta_id
INNER JOIN Cuotas_de_manejo cm ON t.id = cm.tarjeta_id
INNER JOIN Pagos p ON cm.id = p.cuota_id
INNER JOIN Historial_de_pagos hp ON p.id = hp.pago_id
WHERE cl.id = 3;

-- 2. Total cuotas pagadas en julio 2025
SELECT SUM(monto_total) AS total_pagado
FROM Cuotas_de_manejo
WHERE MONTH(vencimiento_cuota) = 7 AND YEAR(vencimiento_cuota) = 2025 AND estado = 'Pago';

-- 3. Cuotas con descuento aplicado
SELECT cl.id AS cliente_id, cl.nombre, tt.descuento, cm.monto_base, cm.monto_total
FROM Clientes cl
INNER JOIN Cuentas cu ON cl.id = cu.cliente_id
INNER JOIN Tarjetas t ON cu.id = t.cuenta_id
INNER JOIN Tipo_tarjetas tt ON t.tipo_tarjeta_id = tt.id
INNER JOIN Cuotas_de_manejo cm ON t.id = cm.tarjeta_id;

-- 4. Reporte mensual por tarjeta
SELECT t.id AS tarjeta_id, cm.vencimiento_cuota AS mes, SUM(cm.monto_total) AS total_cuotas
FROM Cuotas_de_manejo cm
INNER JOIN Tarjetas t ON cm.tarjeta_id = t.id
GROUP BY t.id, cm.vencimiento_cuota;

-- 5. Cuotas pendientes últimos 3 meses
SELECT cl.id AS cliente_id, cl.nombre, cm.vencimiento_cuota, cm.monto_total
FROM Clientes cl
INNER JOIN Cuentas cu ON cl.id = cu.cliente_id
INNER JOIN Tarjetas t ON cu.id = t.cuenta_id
INNER JOIN Cuotas_de_manejo cm ON t.id = cm.tarjeta_id
WHERE cm.estado = 'Pendiente' AND cm.vencimiento_cuota >= DATE_SUB(CURDATE(), INTERVAL 3 MONTH) AND cm.vencimiento_cuota < CURDATE();

-- 6. Cuotas por tipo de tarjeta
SELECT tt.id, tt.nombre, MAX(cm.monto_base) AS monto_base, MAX(cm.monto_total) AS monto_descuento
FROM Cuotas_de_manejo cm
INNER JOIN Tarjetas t ON cm.tarjeta_id = t.id
INNER JOIN Tipo_tarjetas tt ON t.tipo_tarjeta_id = tt.id
GROUP BY tt.id, tt.nombre;

-- 7. Descuentos aplicados por tipo de tarjeta
SELECT tt.nombre AS tipo_tarjeta, COUNT(cm.id) AS Total_cuotas, SUM(cm.monto_base - cm.monto_total) AS Total_descuento
FROM Cuotas_de_manejo cm
INNER JOIN Tarjetas t ON cm.tarjeta_id = t.id
INNER JOIN Tipo_tarjetas tt ON t.tipo_tarjeta_id = tt.id
WHERE YEAR(cm.vencimiento_cuota) = 2025 AND cm.estado = 'Pago'
GROUP BY tt.nombre;

-- 8. Total de pagos por tipo de tarjeta
SELECT tt.id, tt.nombre AS Tipo_tarjeta, COUNT(p.id) AS Total_transacciones, SUM(p.total_pago) AS Total_pagado
FROM Tipo_tarjetas tt
INNER JOIN Tarjetas t ON tt.id = t.tipo_tarjeta_id
INNER JOIN Cuotas_de_manejo cm ON t.id = cm.tarjeta_id
INNER JOIN Pagos p ON cm.id = p.cuota_id
WHERE p.estado = 'Completado'
GROUP BY tt.id, tt.nombre;

-- 9. Tarjetas activas con saldo
SELECT t.id, tt.nombre AS tipo_tarjeta, t.numero_tarjeta, t.saldo, t.estado
FROM Tarjetas t
INNER JOIN Tipo_tarjetas tt ON t.tipo_tarjeta_id = tt.id
WHERE estado = 'Activa';

-- 10. Total de tarjetas por cliente
SELECT c.id AS cliente_id, c.nombre, COUNT(t.id) AS total_tarjetas
FROM Clientes c
JOIN Cuentas cu ON cu.cliente_id = c.id
JOIN Tarjetas t ON t.cuenta_id = cu.id
GROUP BY c.id, c.nombre;

-- 11. Cuotas vencidas pendientes
SELECT id, vencimiento_cuota, monto_total, estado
FROM Cuotas_de_manejo
WHERE vencimiento_cuota < CURDATE() AND estado = 'Pendiente';

-- 12. Pagos por método
SELECT metodo_pago, SUM(total_pago) AS Total
FROM Pagos
WHERE estado = 'Completado'
GROUP BY metodo_pago;

-- 13. Clientes con más pagos rechazados
SELECT cl.id, cl.nombre, COUNT(*) AS pagos_rechazados
FROM Clientes cl
JOIN Cuentas cu ON cl.id = cu.cliente_id
JOIN Tarjetas t ON cu.id = t.cuenta_id
JOIN Cuotas_de_manejo cm ON t.id = cm.tarjeta_id
JOIN Pagos p ON cm.id = p.cuota_id
WHERE p.estado = 'Rechazado'
GROUP BY cl.id, cl.nombre
ORDER BY pagos_rechazados DESC
LIMIT 3;

-- 14. Total de intereses por cliente
SELECT cl.id AS cliente_id, cl.nombre, SUM(it.monto_interes) AS total_intereses
FROM Clientes cl
JOIN Cuentas cu ON cl.id = cu.cliente_id
JOIN Tarjetas t ON cu.id = t.cuenta_id
JOIN Intereses_tarjetas it ON t.id = it.tarjeta_id
WHERE YEAR(it.fecha_generacion) = YEAR(CURDATE())
GROUP BY cl.id, cl.nombre;

-- 15. Ranking de clientes por pagos
SELECT cl.id AS cliente_id, cl.nombre, SUM(p.total_pago) AS total_pagado
FROM Clientes cl
JOIN Cuentas cu ON cl.id = cu.cliente_id
JOIN Tarjetas t ON cu.id = t.cuenta_id
JOIN Cuotas_de_manejo cm ON t.id = cm.tarjeta_id
JOIN Pagos p ON cm.id = p.cuota_id
WHERE p.estado = 'Completado'
GROUP BY cl.id
ORDER BY total_pagado DESC;

-- 16. Clientes sin tarjetas
SELECT cl.id, cl.nombre
FROM Clientes cl
LEFT JOIN Cuentas cu ON cl.id = cu.cliente_id
LEFT JOIN Tarjetas t ON cu.id = t.cuenta_id
WHERE t.id IS NULL;

-- 17. Promedio de intereses por tipo de tarjeta
SELECT tt.nombre, AVG(it.monto_interes) AS promedio_interes
FROM Intereses_tarjetas it
JOIN Tarjetas t ON it.tarjeta_id = t.id
JOIN Tipo_tarjetas tt ON t.tipo_tarjeta_id = tt.id
GROUP BY tt.nombre;

-- 18. Cuotas sin pagos y vencidas
SELECT t.id, t.numero_tarjeta
FROM Tarjetas t
JOIN Cuotas_de_manejo cm ON t.id = cm.tarjeta_id
LEFT JOIN Pagos p ON cm.id = p.cuota_id
WHERE cm.estado = 'Pendiente' AND cm.vencimiento_cuota < CURDATE() AND p.id IS NULL;

-- 19. Total pagos por cliente por trimestre
SELECT cl.id AS cliente_id, cl.nombre, QUARTER(p.fecha_pago) AS trimestre, SUM(p.total_pago) AS total_pagado
FROM Clientes cl
JOIN Cuentas cu ON cl.id = cu.cliente_id
JOIN Tarjetas t ON cu.id = t.cuenta_id
JOIN Cuotas_de_manejo cm ON t.id = cm.tarjeta_id
JOIN Pagos p ON cm.id = p.cuota_id
WHERE YEAR(p.fecha_pago) = 2025
GROUP BY cl.id, cl.nombre, trimestre;

-- 20. Total intereses por tipo de tarjeta por mes en 2025
SELECT tt.nombre, MONTH(it.fecha_generacion) AS mes, SUM(it.monto_interes) AS total_intereses
FROM Intereses_tarjetas it
JOIN Tarjetas t ON it.tarjeta_id = t.id
JOIN Tipo_tarjetas tt ON t.tipo_tarjeta_id = tt.id
WHERE YEAR(it.fecha_generacion) = 2025
GROUP BY tt.nombre, mes
ORDER BY tt.nombre, mes;

-- 21. Evolución del estado de cada pago
SELECT p.id AS pago_id, p.total_pago, hp.estado_anterior, hp.nuevo_estado, hp.fecha_cambio
FROM Pagos p
JOIN Historial_de_pagos hp ON p.id = hp.pago_id
ORDER BY p.id, hp.fecha_cambio;

-- 22. Total pagos por año y mes
SELECT YEAR(fecha_pago) AS anio, MONTH(fecha_pago) AS mes, SUM(total_pago) AS total
FROM Pagos
WHERE estado = 'Completado'
GROUP BY anio, mes
ORDER BY anio, mes;

-- 23. Cuotas por tarjeta (ordenado)
SELECT tarjeta_id, COUNT(id) AS total_cuotas
FROM Cuotas_de_manejo
GROUP BY tarjeta_id
ORDER BY total_cuotas DESC;

-- 24. Detalle de pagos por método y estado
SELECT metodo_pago, estado, COUNT(*) AS cantidad, SUM(total_pago) AS total
FROM Pagos
GROUP BY metodo_pago, estado
ORDER BY metodo_pago, estado;

-- 25. Promedio de pago por tipo de tarjeta
SELECT tt.nombre AS tipo_tarjeta, ROUND(AVG(p.total_pago), 2) AS promedio_pago
FROM Tipo_tarjetas tt
JOIN Tarjetas t ON tt.id = t.tipo_tarjeta_id
JOIN Cuotas_de_manejo cm ON t.id = cm.tarjeta_id
JOIN Pagos p ON cm.id = p.cuota_id
WHERE p.estado = 'Completado'
GROUP BY tt.nombre;