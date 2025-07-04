-- 1. Historial de pagos de un cliente especifico
SELECT cl.id AS cliente_id, p.fecha_pago, p.total_pago, p.metodo_pago, hp.fecha_cambio, hp.nuevo_estado AS estado
FROM Clientes cl
INNER JOIN Cuentas cu ON cl.id = cu.cliente_id
INNER JOIN Tarjetas t ON cu.id = t.cuenta_id
INNER JOIN Cuotas_de_manejo cm ON t.id = cm.tarjeta_id
INNER JOIN Historial_pagos hp ON cm.id = hp.cuota_id
INNER JOIN Pagos p ON hp.pago_id = p.id
WHERE cl.id = 1;

-- 2. Total de cuotas de manejo pagadas durante un mes determinado
SELECT COUNT(*) AS total_pagadas
FROM Cuotas_de_manejo
WHERE estado = 'Pagado' AND MONTH(fecha_generacion) = 6;

-- 3. Total de usuarios registrados en el sistema
SELECT COUNT(*) AS total_usuarios FROM Clientes;

-- 4. Clientes con más de una tarjeta
SELECT c.nombre, COUNT(t.id_tarjeta) AS total_tarjetas
FROM clientes c
JOIN cliente_tarjeta ct ON c.id_cliente = ct.id_cliente
JOIN tarjetas t ON t.id_tarjeta = ct.id_tarjeta
GROUP BY c.nombre
HAVING total_tarjetas > 1;

-- 5. Cuotas de manejo con estado "Pagado"
SELECT * FROM cuotas_manejo WHERE estado = 'Pagado';

-- 6. Tarjetas con cuotas de manejo vencidas
SELECT DISTINCT t.*
FROM tarjetas t
JOIN cliente_tarjeta ct ON t.id_tarjeta = ct.id_tarjeta
JOIN cuotas_manejo cm ON cm.id_cliente_tarjeta = ct.id_cliente_tarjeta
WHERE cm.estado = 'Vencido';

-- 7. Clientes sin tarjetas asociadas
SELECT * FROM clientes
WHERE id_cliente NOT IN (
    SELECT DISTINCT id_cliente FROM cliente_tarjeta
);

-- 8. Total de descuentos aplicados por cliente
SELECT c.nombre, SUM(d.valor_descuento) AS total_descuentos
FROM clientes c
JOIN cliente_tarjeta ct ON ct.id_cliente = c.id_cliente
JOIN cuotas_manejo cm ON cm.id_cliente_tarjeta = ct.id_cliente_tarjeta
JOIN descuentos d ON d.id_cuota = cm.id_cuota
GROUP BY c.nombre;

-- 9. Tarjetas emitidas en un rango de fechas
SELECT * FROM tarjetas
WHERE fecha_emision BETWEEN '2024-01-01' AND '2024-12-31';

-- 10. Pagos por método de pago específico
SELECT metodo_pago, COUNT(*) AS total_pagos
FROM historial_pagos
GROUP BY metodo_pago;

-- 11. Cuotas generadas por mes
SELECT MONTH(fecha_generacion) AS mes, COUNT(*) AS total
FROM cuotas_manejo
GROUP BY mes;

-- 12. Clientes con tarjetas de crédito y débito
SELECT c.nombre
FROM clientes c
JOIN cliente_tarjeta ct ON c.id_cliente = ct.id_cliente
JOIN tarjetas t ON ct.id_tarjeta = t.id_tarjeta
GROUP BY c.nombre
HAVING SUM(t.tipo_tarjeta = 'Credito') > 0 AND SUM(t.tipo_tarjeta = 'Debito') > 0;

-- 13. Tarjetas con mayor monto de apertura
SELECT * FROM tarjetas
ORDER BY monto_apertura DESC
LIMIT 5;

-- 14. Total de pagos por cliente
SELECT c.nombre, SUM(p.monto_pagado) AS total_pagado
FROM clientes c
JOIN cliente_tarjeta ct ON ct.id_cliente = c.id_cliente
JOIN cuotas_manejo cm ON cm.id_cliente_tarjeta = ct.id_cliente_tarjeta
JOIN historial_pagos p ON p.id_cuota = cm.id_cuota
GROUP BY c.nombre;

-- 15. Pagos por tipo de tarjeta y total de cuotas de manejo
SELECT t.tipo_tarjeta, COUNT(cm.id_cuota) AS total_cuotas
FROM tarjetas t
JOIN cliente_tarjeta ct ON ct.id_tarjeta = t.id_tarjeta
JOIN cuotas_manejo cm ON cm.id_cliente_tarjeta = ct.id_cliente_tarjeta
GROUP BY t.tipo_tarjeta;

-- 16. Clientes con cuotas vencidas en el último mes
SELECT DISTINCT c.nombre
FROM clientes c
JOIN cliente_tarjeta ct ON c.id_cliente = ct.id_cliente
JOIN cuotas_manejo cm ON cm.id_cliente_tarjeta = ct.id_cliente_tarjeta
WHERE cm.estado = 'Vencido' AND cm.fecha_vencimiento >= CURDATE() - INTERVAL 1 MONTH;

-- 17. Cuotas de manejo generadas por tipo de tarjeta
SELECT t.tipo_tarjeta, COUNT(cm.id_cuota) AS total_cuotas
FROM tarjetas t
JOIN cliente_tarjeta ct ON ct.id_tarjeta = t.id_tarjeta
JOIN cuotas_manejo cm ON cm.id_cliente_tarjeta = ct.id_cliente_tarjeta
GROUP BY t.tipo_tarjeta;

-- 18. Total de pagos por cliente y método de pago
SELECT c.nombre, p.metodo_pago, SUM(p.monto_pagado) AS total
FROM clientes c
JOIN cliente_tarjeta ct ON ct.id_cliente = c.id_cliente
JOIN cuotas_manejo cm ON cm.id_cliente_tarjeta = ct.id_cliente_tarjeta
JOIN historial_pagos p ON p.id_cuota = cm.id_cuota
GROUP BY c.nombre, p.metodo_pago;

-- 19. Clientes con tarjetas bloqueadas
SELECT DISTINCT c.nombre
FROM clientes c
JOIN cliente_tarjeta ct ON ct.id_cliente = c.id_cliente
JOIN tarjetas t ON t.id_tarjeta = ct.id_tarjeta
WHERE t.estado = 'Bloqueada';

-- 20. Total de descuentos aplicados por tipo de tarjeta
SELECT t.tipo_tarjeta, SUM(d.valor_descuento) AS total_descuento
FROM tarjetas t
JOIN cliente_tarjeta ct ON ct.id_tarjeta = t.id_tarjeta
JOIN cuotas_manejo cm ON cm.id_cliente_tarjeta = ct.id_cliente_tarjeta
JOIN descuentos d ON d.id_cuota = cm.id_cuota
GROUP BY t.tipo_tarjeta;

-- 21. Tarjetas con mayor número de cuotas generadas
SELECT t.id_tarjeta, COUNT(cm.id_cuota) AS total_cuotas
FROM tarjetas t
JOIN cliente_tarjeta ct ON ct.id_tarjeta = t.id_tarjeta
JOIN cuotas_manejo cm ON cm.id_cliente_tarjeta = ct.id_cliente_tarjeta
GROUP BY t.id_tarjeta
ORDER BY total_cuotas DESC;

-- 22. Total de pagos por tipo de moneda
SELECT t.moneda, SUM(p.monto_pagado) AS total_pagado
FROM tarjetas t
JOIN cliente_tarjeta ct ON ct.id_tarjeta = t.id_tarjeta
JOIN cuotas_manejo cm ON cm.id_cliente_tarjeta = ct.id_cliente_tarjeta
JOIN historial_pagos p ON p.id_cuota = cm.id_cuota
GROUP BY t.moneda;

-- 23. Total de pagos por sucursal
SELECT s.nombre_sucursal, SUM(p.monto_pagado) AS total
FROM sucursales s
JOIN tarjetas t ON t.id_sucursal = s.id_sucursal
JOIN cliente_tarjeta ct ON ct.id_tarjeta = t.id_tarjeta
JOIN cuotas_manejo cm ON cm.id_cliente_tarjeta = ct.id_cliente_tarjeta
JOIN historial_pagos p ON p.id_cuota = cm.id_cuota
GROUP BY s.nombre_sucursal;

-- 24. Cuotas vencidas por sucursal
SELECT s.nombre_sucursal, COUNT(*) AS total_vencidas
FROM sucursales s
JOIN tarjetas t ON t.id_sucursal = s.id_sucursal
JOIN cliente_tarjeta ct ON ct.id_tarjeta = t.id_tarjeta
JOIN cuotas_manejo cm ON cm.id_cliente_tarjeta = ct.id_cliente_tarjeta
WHERE cm.estado = 'Vencido'
GROUP BY s.nombre_sucursal;

-- 25. Clientes con el mayor número de tarjetas activas
SELECT c.nombre, COUNT(*) AS total_activas
FROM clientes c
JOIN cliente_tarjeta ct ON c.id_cliente = ct.id_cliente
JOIN tarjetas t ON ct.id_tarjeta = t.id_tarjeta
WHERE t.estado = 'Activa'
GROUP BY c.nombre
ORDER BY total_activas DESC
LIMIT 5;
