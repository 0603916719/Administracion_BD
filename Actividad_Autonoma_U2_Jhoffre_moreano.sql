-- 1. CREAR BASE DE DATOS
CREATE DATABASE UCEM_LogsTransacciones;
GO

USE UCEM_LogsTransacciones;
GO

-- Configuro modo FULL para trabajar con logs de transacciones
ALTER DATABASE UCEM_LogsTransacciones SET RECOVERY FULL;
GO

--CREAO TABLAS
   

CREATE TABLE Plantas (
    id_planta INT IDENTITY(1,1) PRIMARY KEY,
    nombre_planta VARCHAR(100) NOT NULL,
    ciudad VARCHAR(80) NOT NULL
);

CREATE TABLE Productos (
    id_producto INT IDENTITY(1,1) PRIMARY KEY,
    nombre_producto VARCHAR(100) NOT NULL,
    tipo_producto VARCHAR(80) NOT NULL,
    stock INT NOT NULL CHECK (stock >= 0),
    precio DECIMAL(10,2) NOT NULL
);

CREATE TABLE MovimientosInventario (
    id_movimiento INT IDENTITY(1,1) PRIMARY KEY,
    id_producto INT NOT NULL,
    id_planta INT NOT NULL,
    tipo_movimiento VARCHAR(20) CHECK (tipo_movimiento IN ('INGRESO','SALIDA')),
    cantidad INT NOT NULL CHECK (cantidad > 0),
    fecha_movimiento DATETIME DEFAULT GETDATE(),
    observacion VARCHAR(200),
    FOREIGN KEY (id_producto) REFERENCES Productos(id_producto),
    FOREIGN KEY (id_planta) REFERENCES Plantas(id_planta)
);
GO

--INSERTAR DATOS INICIALES
 

BEGIN TRANSACTION;

INSERT INTO Plantas (nombre_planta, ciudad)
VALUES 
('Planta UCEM Chimborazo', 'Riobamba'),
('Planta UCEM Guapán', 'Azogues');

INSERT INTO Productos (nombre_producto, tipo_producto, stock, precio)
VALUES
('Cemento Portland Tipo IP', 'Cemento', 500, 8.50),
('Clinker', 'Materia prima', 300, 12.75),
('Caliza procesada', 'Materia prima', 1000, 3.25);

COMMIT TRANSACTION;
GO

--OPERACIÓN DE INSERCIÓN REGISTRADA EN EL LOG
   

BEGIN TRANSACTION;

INSERT INTO MovimientosInventario 
(id_producto, id_planta, tipo_movimiento, cantidad, observacion)
VALUES
(1, 1, 'INGRESO', 100, 'Ingreso de cemento producido en planta Chimborazo');

UPDATE Productos
SET stock = stock + 100
WHERE id_producto = 1;

COMMIT TRANSACTION;
GO


-- OPERACIÓN DE ACTUALIZACIÓN REGISTRADA EN EL LOG


BEGIN TRANSACTION;

UPDATE Productos
SET precio = 9.00
WHERE id_producto = 1;

COMMIT TRANSACTION;
GO

--OPERACIÓN DE ELIMINACIÓN REGISTRADA EN EL LOG
  

BEGIN TRANSACTION;

DELETE FROM MovimientosInventario
WHERE id_movimiento = 1;

COMMIT TRANSACTION;
GO


--SIMULAR ERROR Y APLICAR UNDO CON ROLLBACK


BEGIN TRANSACTION;

UPDATE Productos
SET stock = stock - 900
WHERE id_producto = 1;

-- Verificamos el stock
SELECT * FROM Productos WHERE id_producto = 1;

-- Como el stock queda incorrecto para la empresa, se deshace la operación
ROLLBACK TRANSACTION;
GO

-- Verificar que el dato volvió al estado anterior
SELECT * FROM Productos;
GO

--SIMULAR REDO CON BACKUP Y RESTAURACIÓN DE LOG
IF @@TRANCOUNT > 0 COMMIT;
GO

BACKUP DATABASE UCEM_LogsTransacciones
TO DISK='C:\Backups\UCEM_Full.bak'
WITH INIT;
GO

BEGIN TRANSACTION;
INSERT INTO MovimientosInventario
(id_producto,id_planta,tipo_movimiento,cantidad,observacion)
VALUES
(2,2,'SALIDA',50,'Salida de clinker');
UPDATE Productos
SET stock=stock-50
WHERE id_producto=2;
COMMIT;
GO

BACKUP LOG UCEM_LogsTransacciones
TO DISK='C:\Backups\UCEM_Log.trn'
WITH INIT;
GO

--SERVIDOR PRINCIPAL
ALTER DATABASE UCEM_LogsTransacciones
SET RECOVERY FULL;
GO

BACKUP DATABASE UCEM_LogsTransacciones
TO DISK='C:\Backups\UCEM_Full.bak';
GO

BACKUP LOG UCEM_LogsTransacciones
TO DISK='C:\Backups\UCEM_Log.trn';
GO


--SEFVIDOR SECUNDARIO
USE master;
GO

ALTER DATABASE UCEM_LogsTransacciones
SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO

RESTORE DATABASE UCEM_LogsTransacciones
FROM DISK='C:\Backups\UCEM_Full.bak'
WITH REPLACE, NORECOVERY;
GO

RESTORE LOG UCEM_LogsTransacciones
FROM DISK='C:\Backups\UCEM_Log.trn'
WITH RECOVERY;
GO


--
USE master;
GO

RESTORE DATABASE UCEM_LogsTransacciones WITH RECOVERY;
GO

ALTER DATABASE UCEM_LogsTransacciones SET MULTI_USER;
GO

BACKUP DATABASE UCEM_LogsTransacciones
TO DISK='C:\Backups\UCEM_Full_Nuevo.bak'
WITH INIT;
GO

USE UCEM_LogsTransacciones;
GO

DELETE FROM MovimientosInventario
WHERE fecha_movimiento='2026-05-24';
GO

USE master;
GO

BACKUP LOG UCEM_LogsTransacciones
TO DISK='C:\Backups\UCEM_Log_Nuevo.trn'
WITH INIT;
GO

-- RECUPERACION PITR


USE master;
GO

ALTER DATABASE UCEM_LogsTransacciones SET RECOVERY FULL;
GO

BACKUP DATABASE UCEM_LogsTransacciones
TO DISK='C:\Backups\UCEM_Full.bak'
WITH INIT;
GO

USE UCEM_LogsTransacciones;
GO

DELETE FROM MovimientosInventario
WHERE fecha_movimiento='2026-05-24';
GO

USE master;
GO

BACKUP LOG UCEM_LogsTransacciones
TO DISK='C:\Backups\UCEM_Log.trn'
WITH INIT;
GO

ALTER DATABASE UCEM_LogsTransacciones
SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO

RESTORE DATABASE UCEM_LogsTransacciones
FROM DISK='C:\Backups\UCEM_Full.bak'
WITH REPLACE, NORECOVERY;
GO

RESTORE LOG UCEM_LogsTransacciones
FROM DISK='C:\Backups\UCEM_Log.trn'
WITH STOPAT='2026-05-24T10:29:00', RECOVERY;
GO

ALTER DATABASE UCEM_LogsTransacciones SET MULTI_USER;
GO