-- Active: 1750849471952@@127.0.0.1@3307@banco

SELECT user, host, plugin FROM mysql.user;

-- Administrador
-- Acceso completo al sistema, incluyendo gestión de clientes, tarjetas, pagos, descuentos, y reportes.

CREATE USER 'Administrador'@'localhost' IDENTIFIED By '@dR1Am12';

DROP USER 'Administrador'@'localhost'; -- Borra ojo 

SHOW GRANTS FOR 'Administrador'@'localhost';

FLUSH PRIVILEGES;

-- Permisos Administrador

-- Otorga SELECT sobre todas las tablas
GRANT ALL PRIVILEGES ON banco.* TO 'Administrador'@'localhost';

-- Otorga Permiso por tabla
GRANT SELECT, INSERT, UPDATE, DELETE ON banco.tipo_cuenta TO 'Administrador'@'localhost';

GRANT SELECT, INSERT, UPDATE, DELETE ON banco.descuento TO 'Administrador'@'localhost';

GRANT SELECT, INSERT, UPDATE, DELETE ON banco.intereses TO 'Administrador'@'localhost';

GRANT SELECT, INSERT, UPDATE, DELETE ON banco.tipo_tarjeta TO 'Administrador'@'localhost';

GRANT SELECT, INSERT, UPDATE, DELETE ON banco.cuenta_bancaria TO 'Administrador'@'localhost';

GRANT SELECT, INSERT, UPDATE, DELETE ON banco.tarjeta TO 'Administrador'@'localhost';

GRANT SELECT, INSERT, UPDATE, DELETE ON banco.cliente TO 'Administrador'@'localhost';

GRANT SELECT, INSERT, UPDATE, DELETE ON banco.cuota_manejo TO 'Administrador'@'localhost';

GRANT SELECT, INSERT, UPDATE, DELETE ON banco.pago TO 'Administrador'@'localhost';

GRANT SELECT, INSERT, UPDATE, DELETE ON banco.historial_pagos TO 'Administrador'@'localhost';

GRANT SELECT, INSERT, UPDATE, DELETE ON banco.historial_cuotas TO 'Administrador'@'localhost';

GRANT SELECT, INSERT, UPDATE, DELETE ON banco.alerta_pago TO 'Administrador'@'localhost';

GRANT SELECT, INSERT, UPDATE, DELETE ON banco.reporte_cuotas_manejo TO 'Administrador'@'localhost';

-- Otorga permiso para cada procedimiento
GRANT EXECUTE ON PROCEDURE banco.ps_registrar_cuota_manejo TO 'Administrador'@'localhost';
GRANT EXECUTE ON PROCEDURE banco.ps_procesar_pago TO 'Administrador'@'localhost';
GRANT EXECUTE ON PROCEDURE banco.ps_reporte_mensual_cuotas TO 'Administrador'@'localhost';
GRANT EXECUTE ON PROCEDURE banco.ps_actualizar_descuentos TO 'Administrador'@'localhost';
GRANT EXECUTE ON PROCEDURE banco.ps_registrar_cliente_completo TO 'Administrador'@'localhost';
GRANT EXECUTE ON PROCEDURE banco.ps_bloquear_tarjeta TO 'Administrador'@'localhost';
GRANT EXECUTE ON PROCEDURE banco.ps_consultar_saldo TO 'Administrador'@'localhost';
GRANT EXECUTE ON PROCEDURE banco.ps_actualizar_saldo_cuenta TO 'Administrador'@'localhost';
GRANT EXECUTE ON PROCEDURE banco.ps_historial_pagos_cliente TO 'Administrador'@'localhost';
GRANT EXECUTE ON PROCEDURE banco.ps_total_adeudado_cliente TO 'Administrador'@'localhost';
GRANT EXECUTE ON PROCEDURE banco.ps_renovar_tarjeta TO 'Administrador'@'localhost';
GRANT EXECUTE ON PROCEDURE banco.ps_tarjetas_por_vencer TO 'Administrador'@'localhost';
GRANT EXECUTE ON PROCEDURE banco.ps_cambiar_tipo_tarjeta TO 'Administrador'@'localhost';
GRANT EXECUTE ON PROCEDURE banco.ps_registrar_pago_pendiente TO 'Administrador'@'localhost';
GRANT EXECUTE ON PROCEDURE banco.ps_actualizar_cliente TO 'Administrador'@'localhost';
GRANT EXECUTE ON PROCEDURE banco.ps_cuotas_pendientes_cliente TO 'Administrador'@'localhost';
GRANT EXECUTE ON PROCEDURE banco.ps_cerrar_cuenta TO 'Administrador'@'localhost';
GRANT EXECUTE ON PROCEDURE banco.ps_reporte_clientes_activos TO 'Administrador'@'localhost';
GRANT EXECUTE ON PROCEDURE banco.ps_aplicar_interes_inversion TO 'Administrador'@'localhost';
GRANT EXECUTE ON PROCEDURE banco.ps_resumen_financiero_cliente TO 'Administrador'@'localhost';

-- Otorga permiso para cada funcion
GRANT EXECUTE ON FUNCTION banco.fn_calcular_cuota_manejo TO 'Administrador'@'localhost';
GRANT EXECUTE ON FUNCTION banco.fn_calcular_descuento_aplicado TO 'Administrador'@'localhost';
GRANT EXECUTE ON FUNCTION banco.fn_saldo_pendiente TO 'Administrador'@'localhost';
GRANT EXECUTE ON FUNCTION banco.fn_total_pagos_tipo_tarjeta TO 'Administrador'@'localhost';
GRANT EXECUTE ON FUNCTION banco.fn_total_monto_cuotas_mensual TO 'Administrador'@'localhost';
GRANT EXECUTE ON FUNCTION banco.fn_pagos_pendientes_cliente TO 'Administrador'@'localhost';
GRANT EXECUTE ON FUNCTION banco.fn_promedio_cuotas_por_cliente TO 'Administrador'@'localhost';
GRANT EXECUTE ON FUNCTION banco.fn_estado_tarjeta TO 'Administrador'@'localhost';
GRANT EXECUTE ON FUNCTION banco.fn_tipo_cuenta_tarjeta TO 'Administrador'@'localhost';
GRANT EXECUTE ON FUNCTION banco.fn_tasa_interes_cuota TO 'Administrador'@'localhost';
GRANT EXECUTE ON FUNCTION banco.fn_total_pagado_cliente TO 'Administrador'@'localhost';
GRANT EXECUTE ON FUNCTION banco.fn_direccion_por_tarjeta TO 'Administrador'@'localhost';
GRANT EXECUTE ON FUNCTION banco.fn_ultima_cuota_cliente TO 'Administrador'@'localhost';
GRANT EXECUTE ON FUNCTION banco.fn_promedio_pago_tarjeta TO 'Administrador'@'localhost';
GRANT EXECUTE ON FUNCTION banco.fn_resumen_cuotas_tarjeta TO 'Administrador'@'localhost';
GRANT EXECUTE ON FUNCTION banco.fn_nombre_descuento_cuota TO 'Administrador'@'localhost';
GRANT EXECUTE ON FUNCTION banco.fn_total_clientes_tipo_tarjeta TO 'Administrador'@'localhost';
GRANT EXECUTE ON FUNCTION banco.fn_total_pagos TO 'Administrador'@'localhost';
GRANT EXECUTE ON FUNCTION banco.fn_total_pagos_pendientes TO 'Administrador'@'localhost';
GRANT EXECUTE ON FUNCTION banco.fn_fecha_pimer_pago TO 'Administrador'@'localhost';

-- Otorga permiso para cada evento
GRANT EXECUTE ON EVENT banco.evt_alerta_pagos_pendientes TO 'Administrador'@'localhost';
GRANT EXECUTE ON EVENT banco.evt_insertar_historial_pago TO 'Administrador'@'localhost';
GRANT EXECUTE ON EVENT banco.evt_bloquear_tarjetas_por_cuenta TO 'Administrador'@'localhost';
GRANT EXECUTE ON EVENT banco.evt_limpiar_historial_pagos TO 'Administrador'@'localhost';
GRANT EXECUTE ON EVENT banco.evt_limpiar_historial_cuotas TO 'Administrador'@'localhost';
GRANT EXECUTE ON EVENT banco.evt_aplicar_descuento_cuotas TO 'Administrador'@'localhost';
GRANT EXECUTE ON EVENT banco.evt_aplicar_interes_cuotas TO 'Administrador'@'localhost';
GRANT EXECUTE ON EVENT banco.evt_actualizar_pagos_pendientes_antiguos TO 'Administrador'@'localhost';
GRANT EXECUTE ON EVENT banco.evt_desactivar_tarjetas_por_cuenta TO 'Administrador'@'localhost';
GRANT EXECUTE ON EVENT banco.evt_cerrar_tarjetas_por_cuenta TO 'Administrador'@'localhost';
GRANT EXECUTE ON EVENT banco.evt_activar_tarjetas_por_cuenta TO 'Administrador'@'localhost';
GRANT EXECUTE ON EVENT banco.evt_generar_reporte_cuotas_manejo TO 'Administrador'@'localhost';
GRANT EXECUTE ON EVENT banco.evt_eliminar_reportes_antiguos TO 'Administrador'@'localhost';
GRANT EXECUTE ON EVENT banco.evt_desactivar_tarjetas_inactivas TO 'Administrador'@'localhost';
GRANT EXECUTE ON EVENT banco.evt_activar_tarjetas_activas_recientes TO 'Administrador'@'localhost';
GRANT EXECUTE ON EVENT banco.evt_recalcular_cuotas_tasas TO 'Administrador'@'localhost';
GRANT EXECUTE ON EVENT banco.evt_cerrar_cuentas_inactivas TO 'Administrador'@'localhost';
GRANT EXECUTE ON EVENT banco.evt_ajuste_montos_negativos TO 'Administrador'@'localhost';
GRANT EXECUTE ON EVENT banco.evt_eliminar_tarjetas_expiradas TO 'Administrador'@'localhost';
GRANT EXECUTE ON EVENT banco.evt_eliminar_tarjetas_bloqueadas_antiguas TO 'Administrador'@'localhost';

-- Otorga permiso para cada trigger
GRANT EXECUTE ON TRIGGER banco.trg_eliminar_cuotas_tarjeta TO 'Administrador'@'localhost';
GRANT EXECUTE ON TRIGGER banco.trg_eliminar_tarjetas_cuenta TO 'Administrador'@'localhost';
GRANT EXECUTE ON TRIGGER banco.trg_eliminar_pagos_cliente TO 'Administrador'@'localhost';
GRANT EXECUTE ON TRIGGER banco.trg_eliminar_historial_pago TO 'Administrador'@'localhost';
GRANT EXECUTE ON TRIGGER banco.trg_eliminar_cuotas_descuento TO 'Administrador'@'localhost';
GRANT EXECUTE ON TRIGGER banco.trg_eliminar_cuotas_interes TO 'Administrador'@'localhost';
GRANT EXECUTE ON TRIGGER banco.trg_recalcular_cuota_tarjeta TO 'Administrador'@'localhost';
GRANT EXECUTE ON TRIGGER banco.trg_recalcular_descuento TO 'Administrador'@'localhost';
GRANT EXECUTE ON TRIGGER banco.trg_recalcular_interes TO 'Administrador'@'localhost';
GRANT EXECUTE ON TRIGGER banco.trg_estado_cuenta_activa_default TO 'Administrador'@'localhost';
GRANT EXECUTE ON TRIGGER banco.trg_bloquear_tarjetas_por_cuenta TO 'Administrador'@'localhost';
GRANT EXECUTE ON TRIGGER banco.trg_cerrar_tarjetas_por_cuenta TO 'Administrador'@'localhost';
GRANT EXECUTE ON TRIGGER banco.trg_desactivar_tarjetas_por_cuenta TO 'Administrador'@'localhost';
GRANT EXECUTE ON TRIGGER banco.trg_activar_tarjetas_por_cuenta TO 'Administrador'@'localhost';
GRANT EXECUTE ON TRIGGER banco.trg_registrar_historial_pago TO 'Administrador'@'localhost';
GRANT EXECUTE ON TRIGGER banco.trg_eliminar_historial_pago TO 'Administrador'@'localhost';
GRANT EXECUTE ON TRIGGER banco.trg_eliminar_cuentas_cliente TO 'Administrador'@'localhost';
GRANT EXECUTE ON TRIGGER banco.trg_validar_cuenta_activa_tarjeta TO 'Administrador'@'localhost';
GRANT EXECUTE ON TRIGGER banco.trg_rechazar_pago_cero TO 'Administrador'@'localhost';
GRANT EXECUTE ON TRIGGER banco.trg_correo_alertas TO 'Administrador'@'localhost';

-- Operador de pagos
-- Acceso limitado a la gestión de pagos y consulta del historial de pagos.

CREATE USER 'Operador_Pagos'@'localhost' IDENTIFIED By '0PeR3r6p3g0S';

DROP USER 'Operador_Pagos'@'localhost'; -- Borra ojo 

SHOW GRANTS FOR 'Operador_Pagos'@'localhost';

FLUSH PRIVILEGES;

-- Permisos Operador de pagos

-- Otorga permisos para cada tabla
GRANT SELECT, INSERT, UPDATE ON banco.pago TO 'Operador_Pagos'@'localhost';

GRANT SELECT ON banco.historial_pagos TO 'Operador_Pagos'@'localhost';

GRANT SELECT ON banco.alerta_pago TO 'Operador_Pagos'@'localhost';

-- Otorga permisos para cada procedimiento
GRANT EXECUTE ON PROCEDURE banco.ps_procesar_pago TO 'Operador_Pagos'@'localhost';
GRANT EXECUTE ON PROCEDURE banco.ps_historial_pagos_cliente TO 'Operador_Pagos'@'localhost';
GRANT EXECUTE ON PROCEDURE banco.ps_registrar_pago_pendiente TO 'Operador_Pagos'@'localhost';

-- Otorga permisos para cada funcion
GRANT EXECUTE ON FUNCTION banco.fn_pagos_pendientes_cliente TO 'Operador_Pagos'@'localhost';
GRANT EXECUTE ON FUNCTION banco.fn_promedio_pago_tarjeta TO 'Operador_Pagos'@'localhost';
GRANT EXECUTE ON FUNCTION banco.fn_total_pagos TO 'Operador_Pagos'@'localhost';
GRANT EXECUTE ON FUNCTION banco.fn_total_pagos_pendientes TO 'Operador_Pagos'@'localhost';

-- Otorga permisos para cada evento
GRANT EXECUTE ON EVENT banco.evt_alerta_pagos_pendientes TO 'Operador_Pagos'@'localhost';
GRANT EXECUTE ON EVENT banco.evt_actualizar_pagos_pendientes_antiguos TO 'Operador_Pagos'@'localhost';

-- Otorga permisos para cada trigger
GRANT EXECUTE ON TRIGGER banco.trg_registrar_historial_pago TO 'Operador_Pagos'@'localhost';

-- Gerente
-- Acceso a reportes financieros y el desempeño del sistema de tarjetas.

CREATE USER 'Gerente'@'localhost' IDENTIFIED By 'G@3R4n7X';

DROP USER 'Gerente'@'localhost'; -- Borra ojo 

SHOW GRANTS FOR 'Gerente'@'localhost';

FLUSH PRIVILEGES;

-- Permisos Gerente

-- Otorga permisos para cada tabla
GRANT SELECT ON banco.tipo_tarjeta TO 'Gerente'@'localhost';

GRANT SELECT ON banco.tarjeta TO 'Gerente'@'localhost';

GRANT SELECT ON banco.cuota_manejo TO 
'Gerente'@'localhost';

GRANT SELECT ON banco.pago TO 'Gerente'@'localhost';

GRANT SELECT ON banco.historial_pagos TO 'Gerente'@'localhost';

GRANT SELECT ON banco.historial_cuotas TO 'Gerente'@'localhost';

GRANT SELECT ON banco.alerta_pago TO 'Gerente'@'localhost';

GRANT SELECT ON banco.reporte_cuotas_manejo TO 'Gerente'@'localhost';

-- Otorga permisos para cada procedimiento
GRANT EXECUTE ON PROCEDURE banco.ps_reporte_mensual_cuotas TO 'Gerente'@'localhost';
GRANT EXECUTE ON PROCEDURE banco.ps_consultar_saldo TO 'Gerente'@'localhost';
GRANT EXECUTE ON PROCEDURE banco.ps_reporte_clientes_activos TO 'Gerente'@'localhost';
GRANT EXECUTE ON PROCEDURE banco.ps_resumen_financiero_cliente TO 'Gerente'@'localhost';

-- Otorga permisos para cada funcion
GRANT EXECUTE ON FUNCTION banco.fn_total_pagos_tipo_tarjeta TO 'Gerente'@'localhost';
GRANT EXECUTE ON FUNCTION banco.fn_promedio_pago_tarjeta TO 'Gerente'@'localhost';

-- Otorga permisos para cada evento
GRANT EXECUTE ON EVENT banco.evt_bloquear_tarjetas_por_cuenta TO 'Gerente'@'localhost';
GRANT EXECUTE ON EVENT banco.evt_desactivar_tarjetas_por_cuenta TO 'Gerente'@'localhost';
GRANT EXECUTE ON EVENT banco.evt_cerrar_tarjetas_por_cuenta TO 'Gerente'@'localhost';
GRANT EXECUTE ON EVENT banco.evt_activar_tarjetas_por_cuenta TO 'Gerente'@'localhost';
GRANT EXECUTE ON EVENT banco.evt_desactivar_tarjetas_inactivas TO 'Gerente'@'localhost';
GRANT EXECUTE ON EVENT banco.evt_activar_tarjetas_activas_recientes TO 'Gerente'@'localhost';
GRANT EXECUTE ON EVENT banco.evt_eliminar_tarjetas_expiradas TO 'Gerente'@'localhost';
GRANT EXECUTE ON EVENT banco.evt_eliminar_tarjetas_bloqueadas_antiguas TO 'Gerente'@'localhost';

-- Otorga permisos para cada trigger
GRANT EXECUTE ON TRIGGER banco.trg_bloquear_tarjetas_por_cuenta TO 'Administrador'@'localhost';
GRANT EXECUTE ON TRIGGER banco.trg_cerrar_tarjetas_por_cuenta TO 'Administrador'@'localhost';
GRANT EXECUTE ON TRIGGER banco.trg_desactivar_tarjetas_por_cuenta TO 'Administrador'@'localhost';
GRANT EXECUTE ON TRIGGER banco.trg_activar_tarjetas_por_cuenta TO 'Administrador'@'localhost';

-- Consultor de tarjetas
-- Acceso solo para consultar información sobre las tarjetas y cuotas de manejo, sin permisos de modificación.

CREATE USER 'Consultor_Tarjetas'@'localhost' IDENTIFIED By 'C@nSU14OrT8v21';

DROP USER 'Consultor_Tarjetas'@'localhost'; -- Borra ojo 

SHOW GRANTS FOR 'Consultor_Tarjetas'@'localhost';

FLUSH PRIVILEGES;

-- Permisos Consultor Tarjetas

-- Otorga permisos para cada tabla
GRANT SELECT ON banco.tipo_tarjeta TO 'Consultor_Tarjetas'@'localhost';

GRANT SELECT ON banco.tarjeta TO 'Consultor_Tarjetas'@'localhost';

GRANT SELECT ON banco.cuota_manejo TO 'Consultor_Tarjetas'@'localhost';

GRANT SELECT ON banco.historial_cuotas TO 'Consultor_Tarjetas'@'localhost';

-- Otorga permisos para cada procedimiento
GRANT EXECUTE ON PROCEDURE banco.ps_tarjetas_por_vencer TO 'Consultor_Tarjetas'@'localhost';

-- Otorga permisos para cada funcion
GRANT EXECUTE ON FUNCTION banco.fn_calcular_cuota_manejo TO 'Consultor_Tarjetas'@'localhost';
GRANT EXECUTE ON FUNCTION banco.fn_total_pagos_tipo_tarjeta TO 'Consultor_Tarjetas'@'localhost';
GRANT EXECUTE ON FUNCTION banco.fn_promedio_cuotas_por_cliente TO 'Consultor_Tarjetas'@'localhost';
GRANT EXECUTE ON FUNCTION banco.fn_estado_tarjeta TO 'Consultor_Tarjetas'@'localhost';
GRANT EXECUTE ON FUNCTION banco.fn_tipo_cuenta_tarjeta TO 'Consultor_Tarjetas'@'localhost';
GRANT EXECUTE ON FUNCTION banco.fn_ultima_cuota_cliente TO 'Consultor_Tarjetas'@'localhost';
GRANT EXECUTE ON FUNCTION banco.fn_resumen_cuotas_tarjeta TO 'Consultor_Tarjetas'@'localhost';
GRANT EXECUTE ON FUNCTION banco.fn_nombre_descuento_cuota TO 'Consultor_Tarjetas'@'localhost';
GRANT EXECUTE ON FUNCTION banco.fn_total_clientes_tipo_tarjeta TO 'Consultor_Tarjetas'@'localhost';

-- Otorga permisos para cada evento
GRANT EXECUTE ON EVENT banco.evt_generar_reporte_cuotas_manejo TO 'Consultor_Tarjetas'@'localhost';

-- Otorga permisos para cada trigger
GRANT EXECUTE ON TRIGGER banco.trg_validar_cuenta_activa_tarjeta TO 'Consultor_Tarjetas'@'localhost';

-- Auditor
-- Acceso solo a los reportes generados y sin permisos de modificación en las tablas del sistema.

CREATE USER 'Auditor'@'localhost' IDENTIFIED By '@Ud1T0rS1o';

DROP USER 'Auditor'@'localhost'; -- Borrar, ojo 

SHOW GRANTS FOR 'Auditor'@'localhost';

FLUSH PRIVILEGES;

-- Permisos Auditor

-- Otorga permisos para cada tabla
GRANT SELECT ON banco.alerta_pago TO 'Auditor'@'localhost';

GRANT SELECT ON banco.reporte_cuotas_manejo TO 'Auditor'@'localhost';

-- Otorga permisos para cada procedimiento
GRANT EXECUTE ON PROCEDURE banco.ps_reporte_mensual_cuotas TO 'Auditor'@'localhost';
GRANT EXECUTE ON PROCEDURE banco.ps_reporte_clientes_activos TO 'Auditor'@'localhost';

-- Otorga permisos para cada funcion
GRANT EXECUTE ON FUNCTION banco.fn_resumen_cuotas_tarjeta TO 'Auditor'@'localhost';

-- Otorga permios para cada evento
GRANT EXECUTE ON EVENT banco.evt_alerta_pagos_pendientes TO 'Auditor'@'localhost';
GRANT EXECUTE ON EVENT banco.evt_generar_reporte_cuotas_manejo TO 'Auditor'@'localhost';