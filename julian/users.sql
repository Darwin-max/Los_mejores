
-- 1. ADMINISTRADOR
-- Con todos los privilegios sobre la base de datos
CREATE ROLE 'admin_banco'@'%';

GRANT ALL PRIVILEGES ON Banco_CL.* TO 'admin_banco'@'%';
GRANT EXECUTE ON Banco_CL.* TO 'admin_banco'@'%';
GRANT CREATE USER ON *.* TO 'admin_banco'@'%';
GRANT RELOAD ON *.* TO 'admin_banco'@'%';

-- 2. OPERADOR DE PAGOS
-- Permisos para consultar, insertar y actualizar con pagos, cuotas de manejo y prestamos 
-- tambien puede consultar datos de clientes, cuentas, tarjetas y de pago
-- PERO NO tiene permisos para eliminar ni modificar otras areas del sistema
CREATE ROLE 'operador_pagos'@'%';
GRANT SELECT, INSERT, UPDATE ON Banco_CL.pagos TO 'operador_pagos'@'%';
GRANT SELECT, INSERT, UPDATE ON Banco_CL.pago_cuota_manejo TO 'operador_pagos'@'%';
GRANT SELECT, INSERT, UPDATE ON Banco_CL.pagos_prestamo TO 'operador_pagos'@'%';
GRANT SELECT, INSERT ON Banco_CL.historial_de_pagos TO 'operador_pagos'@'%';

GRANT SELECT ON Banco_CL.clientes TO 'operador_pagos'@'%';
GRANT SELECT ON Banco_CL.cuenta TO 'operador_pagos'@'%';
GRANT SELECT ON Banco_CL.tarjetas_bancarias TO 'operador_pagos'@'%';
GRANT SELECT ON Banco_CL.cuotas_manejo TO 'operador_pagos'@'%';
GRANT SELECT ON Banco_CL.registro_cuota TO 'operador_pagos'@'%';
GRANT SELECT ON Banco_CL.prestamos TO 'operador_pagos'@'%';
GRANT SELECT ON Banco_CL.cuotas_prestamo TO 'operador_pagos'@'%';

GRANT SELECT ON Banco_CL.estados_pago TO 'operador_pagos'@'%';
GRANT SELECT ON Banco_CL.tipos_pago TO 'operador_pagos'@'%';
GRANT SELECT ON Banco_CL.metodos_de_pago TO 'operador_pagos'@'%';
GRANT SELECT ON Banco_CL.metodos_transaccion TO 'operador_pagos'@'%';


-- 3. GERENTE
-- Para ver toda la base de datos,con privilegios para insertar y actualizar descuentos
-- y actualizar tipos de cuota de manejo e intereses
CREATE ROLE 'gerente_banco'@'%';

GRANT SELECT ON Banco_CL.* TO 'gerente_banco'@'%';

GRANT INSERT, UPDATE ON Banco_CL.descuento TO 'gerente_banco'@'%';
GRANT UPDATE ON Banco_CL.tipo_cuota_de_manejo TO 'gerente_banco'@'%';
GRANT UPDATE ON Banco_CL.interes TO 'gerente_banco'@'%';


-- 4. CONSULTOR DE TARJETAS
-- Puede consultar todas las tablas relacionadas con tarjetas, clientes, cuotas y descuentos 
-- sin permisos de modificacion
CREATE ROLE 'consultor_tarjetas'@'%';
GRANT SELECT ON Banco_CL.tarjetas_bancarias TO 'consultor_tarjetas'@'%';
GRANT SELECT ON Banco_CL.cuotas_manejo TO 'consultor_tarjetas'@'%';
GRANT SELECT ON Banco_CL.registro_cuota TO 'consultor_tarjetas'@'%';
GRANT SELECT ON Banco_CL.descuentos_aplicados TO 'consultor_tarjetas'@'%';
GRANT SELECT ON Banco_CL.historial_tarjetas TO 'consultor_tarjetas'@'%';
GRANT SELECT ON Banco_CL.clientes TO 'consultor_tarjetas'@'%';
GRANT SELECT ON Banco_CL.cuenta TO 'consultor_tarjetas'@'%';
GRANT SELECT ON Banco_CL.cuenta_tarjeta TO 'consultor_tarjetas'@'%';
GRANT SELECT ON Banco_CL.tipo_tarjetas TO 'consultor_tarjetas'@'%';
GRANT SELECT ON Banco_CL.marca_tarjeta TO 'consultor_tarjetas'@'%';
GRANT SELECT ON Banco_CL.nivel_tarjeta TO 'consultor_tarjetas'@'%';
GRANT SELECT ON Banco_CL.tipo_cuota_de_manejo TO 'consultor_tarjetas'@'%';
GRANT SELECT ON Banco_CL.eventos_tarjeta TO 'consultor_tarjetas'@'%';
GRANT SELECT ON Banco_CL.estados_cuota TO 'consultor_tarjetas'@'%';
GRANT SELECT ON Banco_CL.descuento TO 'consultor_tarjetas'@'%';

-- 5. AUDITOR
-- Con permisos de solo lectura sobre todas las tablas 
-- consultar cualquier informacion sin modificar nada
CREATE ROLE 'auditor_banco'@'%';
GRANT SELECT ON Banco_CL.* TO 'auditor_banco'@'%';