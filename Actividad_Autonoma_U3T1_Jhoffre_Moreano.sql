CREATE DATABASE DistribuidaFundamentos;
GO

USE DistribuidaFundamentos;
GO

CREATE TABLE EMPLEADOS (
    ID_Empleado INT IDENTITY(1,1) PRIMARY KEY,
    Nombre NVARCHAR(100) NOT NULL,
    Cargo NVARCHAR(100) NOT NULL,
    País NVARCHAR(100) NOT NULL,
    Salario DECIMAL(12,2) NOT NULL
);
GO

USE DistribuidaFundamentos;
GO
-- Verificar registros ingresados
SELECT * FROM EMPLEADOS;
GO
ALTER TABLE EMPLEADOS
ADD Dirección NVARCHAR(150);
GO

INSERT INTO EMPLEADOS (Nombre, Cargo, País, Salario, Dirección)
VALUES
('Jhoffre Moreano', 'Analista de Datos', 'Ecuador', 1200.00, 'Quito'),
('María Gomes', 'Desarrollador', 'México', 1500.00, 'Ciudad de México'),
('Carlos Jara', 'Administrador BD', 'España', 1800.00, 'Madrid'),
('Ana Torres', 'Ingeniera de Software', 'Ecuador', 1700.00, 'Guayaquil'),
('Luis Ramírez', 'Soporte Técnico', 'México', 1100.00, 'Monterrey'),
('Sofía Martínez', 'Gerente de Proyectos', 'España', 2500.00, 'Barcelona');
GO

-- Verificar registros ingresados
SELECT * FROM EMPLEADOS;
GO
ALTER TABLE EMPLEADOS
ADD Dirección NVARCHAR(150);
GO

-- Fragmentación horizontal: Ecuador
SELECT *
INTO EMPLEADOS_Ecuador
FROM EMPLEADOS
WHERE País = 'Ecuador';
GO

-- Fragmentación horizontal: México
SELECT *
INTO EMPLEADOS_Mexico
FROM EMPLEADOS
WHERE País = 'México';
GO

-- Fragmentación horizontal: España
SELECT *
INTO EMPLEADOS_Espana
FROM EMPLEADOS
WHERE País = 'España';
GO
SELECT * FROM EMPLEADOS_Ecuador;
SELECT * FROM EMPLEADOS_Mexico;
SELECT * FROM EMPLEADOS_Espana;
-- Fragmentación vertical
SELECT ID_Empleado, Nombre, Dirección 
INTO EMPLEADOS_Fragmento1
FROM EMPLEADOS;
GO

SELECT ID_Empleado, Cargo, Salario
INTO EMPLEADOS_Fragmento2
FROM EMPLEADOS;
GO

SELECT
    F1.ID_Empleado,
    F1.Nombre,
    F1.Dirección,
    F2.Cargo,
    F2.Salario
FROM EMPLEADOS_Fragmento1 F1
INNER JOIN EMPLEADOS_Fragmento2 F2
ON F1.ID_Empleado = F2.ID_Empleado;
GO

USE DistribuidaFundamentos;
GO

-- Replicación total en dos nodos simulados
SELECT * INTO EMPLEADOS_Nodo1
FROM EMPLEADOS;

SELECT * INTO EMPLEADOS_Nodo2
FROM EMPLEADOS;

-- Replicación parcial: empleados con salario mayor a 1500
SELECT * INTO EMPLEADOS_ReplicaParcial
FROM EMPLEADOS
WHERE Salario > 1500;

-- Verificar replicación total
SELECT * FROM EMPLEADOS_Nodo1;
SELECT * FROM EMPLEADOS_Nodo2;

-- Verificar replicación parcial
SELECT * FROM EMPLEADOS_ReplicaParcial;

-- Vista que oculta la ubicación física de los datos
CREATE VIEW VW_EMPLEADOS AS
SELECT * FROM EMPLEADOS_Nodo1;
GO

-- Consulta realizada por el usuario
SELECT * FROM VW_EMPLEADOS;

-- Vista que integra los fragmentos horizontales

DROP VIEW IF EXISTS VW_EMPLEADOS_COMPLETO;
GO

SELECT TOP 1 * FROM EMPLEADOS_Ecuador;
SELECT TOP 1 * FROM EMPLEADOS_Mexico;
SELECT TOP 1 * FROM EMPLEADOS_Espana;


DROP VIEW IF EXISTS VW_EMPLEADOS_COMPLETO;
GO

CREATE VIEW VW_EMPLEADOS_COMPLETO AS
SELECT ID_Empleado, Nombre, Cargo, País, Salario, Dirección
FROM EMPLEADOS_Ecuador
UNION ALL
SELECT ID_Empleado, Nombre, Cargo, País, Salario, Dirección
FROM EMPLEADOS_Mexico
UNION ALL
SELECT ID_Empleado, Nombre, Cargo, País, Salario, Dirección
FROM EMPLEADOS_Espana;
GO

SELECT * FROM VW_EMPLEADOS_COMPLETO;

----
-- 5. Transacciones distribuidas y protocolo 2PC

-- Crear tablas que simulan dos nodos
CREATE TABLE Cuenta_Quito (
    ID_Cuenta INT PRIMARY KEY,
    Cliente NVARCHAR(100),
    Saldo DECIMAL(10,2)
);

CREATE TABLE Cuenta_Guayaquil (
    ID_Cuenta INT PRIMARY KEY,
    Cliente NVARCHAR(100),
    Saldo DECIMAL(10,2)
);

-- Insertar saldos iniciales
INSERT INTO Cuenta_Quito VALUES (1, 'Cuenta Quito', 1500.00);
INSERT INTO Cuenta_Guayaquil VALUES (1, 'Cuenta Guayaquil', 500.00);

-- Verificar saldos iniciales
SELECT * FROM Cuenta_Quito;
SELECT * FROM Cuenta_Guayaquil;

-- CASO 1: COMMIT GLOBAL

BEGIN TRANSACTION;

BEGIN TRY
    -- Fase de preparación
    IF (SELECT Saldo FROM Cuenta_Quito WHERE ID_Cuenta = 1) >= 300
    BEGIN
        -- Fase de confirmación
        UPDATE Cuenta_Quito
        SET Saldo = Saldo - 300
        WHERE ID_Cuenta = 1;

        UPDATE Cuenta_Guayaquil
        SET Saldo = Saldo + 300
        WHERE ID_Cuenta = 1;

        COMMIT TRANSACTION;
        PRINT 'COMMIT GLOBAL: transferencia realizada correctamente.';
    END
    ELSE
    BEGIN
        ROLLBACK TRANSACTION;
        PRINT 'ROLLBACK GLOBAL: saldo insuficiente.';
    END
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    PRINT 'ROLLBACK GLOBAL: ocurrió un error en la transacción.';
END CATCH;

SELECT * FROM Cuenta_Quito;
SELECT * FROM Cuenta_Guayaquil;

----
-- CASO 2: ROLLBACK GLOBAL

BEGIN TRANSACTION;

BEGIN TRY
    -- Fase de preparación
    IF (SELECT Saldo FROM Cuenta_Quito WHERE ID_Cuenta = 1) >= 2000
    BEGIN
        UPDATE Cuenta_Quito
        SET Saldo = Saldo - 2000
        WHERE ID_Cuenta = 1;

        UPDATE Cuenta_Guayaquil
        SET Saldo = Saldo + 2000
        WHERE ID_Cuenta = 1;

        COMMIT TRANSACTION;
        PRINT 'COMMIT GLOBAL: transferencia realizada correctamente.';
    END
    ELSE
    BEGIN
        ROLLBACK TRANSACTION;
        PRINT 'ROLLBACK GLOBAL: saldo insuficiente, no se realizó la transferencia.';
    END
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    PRINT 'ROLLBACK GLOBAL: ocurrió un error en la transacción.';
END CATCH;

SELECT * FROM Cuenta_Quito;
SELECT * FROM Cuenta_Guayaquil;

-- Verificar consistencia después de la transacción
SELECT 'Quito' AS Nodo, Saldo FROM Cuenta_Quito
UNION ALL
SELECT 'Guayaquil' AS Nodo, Saldo FROM Cuenta_Guayaquil;

-- Verificar saldo total del sistema
SELECT 
    (SELECT Saldo FROM Cuenta_Quito WHERE ID_Cuenta = 1) +
    (SELECT Saldo FROM Cuenta_Guayaquil WHERE ID_Cuenta = 1) AS Saldo_Total;