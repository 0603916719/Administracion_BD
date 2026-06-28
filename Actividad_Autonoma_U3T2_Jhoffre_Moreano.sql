/* =====================================================
   TAREA: Creación de roles y privilegios
   Nombre: Jhoffre Moreano
   Base de datos: SeguridadBD
   ===================================================== */


-- 1. Crear base de datos
CREATE DATABASE SeguridadBD;
GO

USE SeguridadBD;
GO

-- 2. Crear tabla CLIENTES
CREATE TABLE CLIENTES (
    id_cliente INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    correo VARCHAR(100),
    telefono VARCHAR(20),
    ciudad VARCHAR(50)
);
GO

-- 3. Crear tabla PRODUCTOS
CREATE TABLE PRODUCTOS (
    id_producto INT IDENTITY(1,1) PRIMARY KEY,
    nombre_producto VARCHAR(100) NOT NULL,
    precio DECIMAL(10,2) NOT NULL,
    stock INT NOT NULL
);
GO

-- 4. Crear tabla VENTAS
CREATE TABLE VENTAS (
    id_venta INT IDENTITY(1,1) PRIMARY KEY,
    id_cliente INT NOT NULL,
    id_producto INT NOT NULL,
    cantidad INT NOT NULL,
    fecha_venta DATE DEFAULT GETDATE(),

    FOREIGN KEY (id_cliente) REFERENCES CLIENTES(id_cliente),
    FOREIGN KEY (id_producto) REFERENCES PRODUCTOS(id_producto)
);
GO

-- 5. Insertar datos de prueba
INSERT INTO CLIENTES (nombre, correo, telefono, ciudad)
VALUES 
('Jhoffre Pérez', 'jhoffre@correo.com', '0999999999', 'Riobamba'),
('María López', 'maria@correo.com', '0988888888', 'Quito');

INSERT INTO PRODUCTOS (nombre_producto, precio, stock)
VALUES
('Laptop Lenovo', 850.00, 10),
('Mouse Logitech', 25.00, 50);

INSERT INTO VENTAS (id_cliente, id_producto, cantidad)
VALUES
(1, 1, 1),
(2, 2, 3);
GO

-- 6. Crear roles
CREATE ROLE rol_ventas;
GO

CREATE ROLE rol_admin;
GO

-- 7. Dar permisos al rol_ventas
-- Puede consultar e insertar solo en la tabla CLIENTES
GRANT SELECT, INSERT ON CLIENTES TO rol_ventas;
GO

-- 8. Dar permisos de administración total al rol_admin
ALTER ROLE db_owner ADD MEMBER rol_admin;
GO

-- 9. Crear usuarios de ejemplo
CREATE LOGIN usuario_ventas_jhoffre WITH PASSWORD = 'Ventas123*';
GO

CREATE LOGIN usuario_admin_jhoffre WITH PASSWORD = 'Admin123*';
GO

USE SeguridadBD;
GO

CREATE USER usuario_ventas_jhoffre FOR LOGIN usuario_ventas_jhoffre;
GO

CREATE USER usuario_admin_jhoffre FOR LOGIN usuario_admin_jhoffre;
GO

-- 10. Asignar usuarios a los roles
ALTER ROLE rol_ventas ADD MEMBER usuario_ventas_jhoffre;
GO

ALTER ROLE rol_admin ADD MEMBER usuario_admin_jhoffre;
GO

-- 11. Verificación de roles creados
SELECT 
    DP1.name AS Rol,
    DP2.name AS Usuario
FROM sys.database_role_members DRM
INNER JOIN sys.database_principals DP1
    ON DRM.role_principal_id = DP1.principal_id
INNER JOIN sys.database_principals DP2
    ON DRM.member_principal_id = DP2.principal_id;
GO

-- 12. Verificar permisos sobre la tabla CLIENTES
SELECT 
    USER_NAME(grantee_principal_id) AS Usuario_o_Rol,
    OBJECT_NAME(major_id) AS Tabla,
    permission_name AS Permiso
FROM sys.database_permissions
WHERE major_id = OBJECT_ID('CLIENTES');
GO

--CONTROL DE USUARIOS
USE SeguridadBD;
GO

-- Crear usuario de ventas
CREATE LOGIN usuario_ventas WITH PASSWORD = 'Ventas123*';
CREATE USER usuario_ventas FOR LOGIN usuario_ventas;
GO

-- Crear usuario de finanzas
CREATE LOGIN usuario_finanzas WITH PASSWORD = 'Finanzas123*';
CREATE USER usuario_finanzas FOR LOGIN usuario_finanzas;
GO

-- Crear rol para finanzas
CREATE ROLE rol_finanzas;
GO

SELECT * FROM VENTAS;


-- Asignar roles
ALTER ROLE rol_ventas ADD MEMBER usuario_ventas;
ALTER ROLE rol_finanzas ADD MEMBER usuario_finanzas;
GO

-- Permisos mínimos
GRANT SELECT, INSERT ON CLIENTES TO rol_ventas;
GRANT SELECT ON PRODUCTOS TO rol_finanzas;
GRANT SELECT ON VENTAS TO rol_finanzas;
GO

-- Verificación usuario_ventas
EXECUTE AS USER = 'usuario_ventas';
SELECT * FROM CLIENTES;
INSERT INTO CLIENTES (nombre, correo, telefono, ciudad)
VALUES ('Cliente prueba', 'cliente@correo.com', '0999999999', 'Riobamba');

-- Esta actualización debe dar error
UPDATE CLIENTES SET ciudad = 'Quito' WHERE id_cliente = 1;
REVERT;
GO

-- Verificación usuario_finanzas
EXECUTE AS USER = 'usuario_finanzas';
SELECT * FROM PRODUCTOS;
SELECT * FROM VENTAS;

-- Esta actualización debe dar error
UPDATE PRODUCTOS SET precio = 100 WHERE id_producto = 1;
REVERT;
GO
--3 AUDITORIA
USE SeguridadBD;
GO

CREATE TABLE Auditoria_CLIENTES (
    id_auditoria INT IDENTITY(1,1) PRIMARY KEY,
    operacion VARCHAR(20),
    fecha DATETIME DEFAULT GETDATE(),
    usuario_bd SYSNAME DEFAULT SYSTEM_USER,
    id_cliente INT
);
GO
SELECT * FROM Auditoria_CLIENTES;

CREATE TRIGGER TR_Insert_CLIENTES
ON CLIENTES
AFTER INSERT
AS
BEGIN

--4. MATENIMIENTO PREVENTIVO

USE master;
GO

-- Respaldo completo de la base SeguridadBD
BACKUP DATABASE SeguridadBD
TO DISK = 'C:\BACKUP\SeguridadBD_Completo.bak'
WITH INIT,
NAME = 'Backup completo SeguridadBD';
GO

-- Verificar integridad de la base de datos
DBCC CHECKDB ('SeguridadBD');
GO

USE SeguridadBD;
GO

-- Revisar fragmentación de índices

USE SeguridadBD;
GO
SELECT * 
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_NAME = 'CLIENTES';
GO


--
USE SeguridadBD;
GO

-- Ver índices de CLIENTES
SELECT 
    name AS NombreIndice,
    type_desc AS TipoIndice
FROM sys.indexes
WHERE object_id = OBJECT_ID('dbo.CLIENTES');
GO

-- Reorganizar índices de CLIENTES
ALTER INDEX ALL ON dbo.CLIENTES REORGANIZE;
GO

-- Reconstruir índices de CLIENTES
ALTER INDEX ALL ON dbo.CLIENTES REBUILD;
GO
-- Reorganizar índice de la tabla CLIENTES
ALTER INDEX ALL ON CLIENTES REORGANIZE;
GO

-- Reconstruir índice de la tabla CLIENTES
ALTER INDEX ALL ON CLIENTES REBUILD;
GO


    INSERT INTO Auditoria_CLIENTES (operacion, id_cliente)
    SELECT 'INSERT', id_cliente
    FROM inserted;
END;
GO

CREATE TRIGGER TR_Update_CLIENTES
ON CLIENTES
AFTER UPDATE
AS
BEGIN
    INSERT INTO Auditoria_CLIENTES (operacion, id_cliente)
    SELECT 'UPDATE', id_cliente
    FROM inserted;
END;
GO

CREATE TRIGGER TR_Delete_CLIENTES
ON CLIENTES
AFTER DELETE
AS
BEGIN
    INSERT INTO Auditoria_CLIENTES (operacion, id_cliente)
    SELECT 'DELETE', id_cliente
    FROM deleted;
END;
GO

INSERT INTO CLIENTES(nombre, correo, telefono, ciudad)
VALUES('Cliente Auditoria','cliente@test.com','0999999999','Riobamba');
GO
UPDATE CLIENTES
SET ciudad='Quito'
WHERE id_cliente=1;
GO

DELETE FROM CLIENTES
WHERE id_cliente=2;
GO

SELECT * FROM Auditoria_CLIENTES;
GO

-- Mantenimiento correctivo
USE SeguridadBD;
GO

-- Eliminar un registro por accidente
DELETE FROM CLIENTES
WHERE id_cliente = 1;
GO

-- Eliminar la venta
DELETE FROM VENTAS
WHERE id_cliente = 1;
GO

-- Ahora eliminar el cliente
DELETE FROM CLIENTES
WHERE id_cliente = 1;
GO

USE master;
GO

--
USE master;
GO

-- Cerrar conexiones activas de SeguridadBD
ALTER DATABASE SeguridadBD 
SET SINGLE_USER 
WITH ROLLBACK IMMEDIATE;
GO

-- Restaurar la base desde el respaldo
RESTORE DATABASE SeguridadBD
FROM DISK = 'C:\BACKUP\SeguridadBD_Completo.bak'
WITH REPLACE;
GO

-- Volver a permitir múltiples usuarios
ALTER DATABASE SeguridadBD 
SET MULTI_USER;
GO

USE SeguridadBD;
GO
 
SELECT * FROM CLIENTES;
SELECT * FROM VENTAS;
GO