-- ================================================================================= --
-- GESTOR DE PERMISOS BASADO EN ROLES Y TABLAS
-- ================================================================================= --

-- Crear roles según la imagen
CREATE ROLE `Administrador`;
CREATE ROLE `OperadorPagos`;
CREATE ROLE `Gerente`;
CREATE ROLE `ConsultorTarjetas`;
CREATE ROLE `Auditor`;

-- Asignar permisos a cada rol
-- Administrador: Acceso completo
GRANT ALL PRIVILEGES ON ProyectoSQL.* TO `Administrador`;

-- Operador de Pagos: Acceso limitado a pagos e historial de pagos
GRANT SELECT, INSERT, UPDATE ON ProyectoSQL.Pago TO `OperadorPagos`;
GRANT SELECT ON ProyectoSQL.Historial_Pagos TO `OperadorPagos`;

-- Gerente: Acceso a reportes financieros y desempeño del sistema de tarjetas
GRANT SELECT ON ProyectoSQL.Reportes TO `Gerente`;
GRANT SELECT ON ProyectoSQL.Tarjeta TO `Gerente`;

-- Consultor de Tarjetas: Acceso solo para consultar información sobre tarjetas y cuotas de manejo
GRANT SELECT ON ProyectoSQL.Tarjeta TO `ConsultorTarjetas`;
GRANT SELECT ON ProyectoSQL.Cuota_Manejo TO `ConsultorTarjetas`;

-- Auditor: Acceso solo a las tablas de auditoría
GRANT SELECT ON ProyectoSQL.Auditoria_Sistema TO `Auditor`;
GRANT SELECT ON ProyectoSQL.Historial_Pagos TO `Auditor`;

-- Asignar roles a usuarios específicos
GRANT `Administrador` TO 'admin01'@'localhost';
GRANT `OperadorPagos` TO 'operador01'@'localhost';
GRANT `Gerente` TO 'gerente01'@'localhost';
GRANT `ConsultorTarjetas` TO 'consultor01'@'localhost';
GRANT `Auditor` TO 'auditor01'@'localhost';

-- Limitar recursos por usuario (ejemplo)
ALTER USER 'auditor01'@'localhost' WITH MAX_QUERIES_PER_HOUR 100;
ALTER USER 'operador01'@'localhost' WITH MAX_QUERIES_PER_HOUR 200;

-- Verificar privilegios asignados
SHOW GRANTS FOR 'admin01'@'localhost';
SHOW GRANTS FOR 'operador01'@'localhost';
SHOW GRANTS FOR 'gerente01'@'localhost';
SHOW GRANTS FOR 'consultor01'@'localhost';
SHOW GRANTS FOR 'auditor01'@'localhost';