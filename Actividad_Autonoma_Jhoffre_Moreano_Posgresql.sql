SELECT datname FROM pg_database;


-- 1. CREAR BASE DE DATOS
CREATE DATABASE "UCEM_LogsTransacciones";

-- Luego conéctese a la base de datos UCEM_LogsTransacciones
-- En pgAdmin: clic derecho sobre la BD → Query Tool

/* ============================================================
   2. CREAR TABLAS
   ============================================================ */

CREATE TABLE Plantas (
    id_planta SERIAL PRIMARY KEY,
    nombre_planta VARCHAR(100) NOT NULL,
    ciudad VARCHAR(80) NOT NULL
);

CREATE TABLE Productos (
    id_producto SERIAL PRIMARY KEY,
    nombre_producto VARCHAR(100) NOT NULL,
    tipo_producto VARCHAR(80) NOT NULL,
    stock INT NOT NULL CHECK (stock >= 0),
    precio NUMERIC(10,2) NOT NULL
);

CREATE TABLE MovimientosInventario (
    id_movimiento SERIAL PRIMARY KEY,
    id_producto INT NOT NULL,
    id_planta INT NOT NULL,
    tipo_movimiento VARCHAR(20) CHECK (tipo_movimiento IN ('INGRESO','SALIDA')),
    cantidad INT NOT NULL CHECK (cantidad > 0),
    fecha_movimiento TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    observacion VARCHAR(200),
    FOREIGN KEY (id_producto) REFERENCES Productos(id_producto),
    FOREIGN KEY (id_planta) REFERENCES Plantas(id_planta)
);

/* ============================================================
   3. INSERTAR DATOS INICIALES
   ============================================================ */

BEGIN;

INSERT INTO Plantas (nombre_planta, ciudad)
VALUES 
('Planta UCEM Chimborazo', 'Riobamba'),
('Planta UCEM Guapán', 'Azogues');

INSERT INTO Productos (nombre_producto, tipo_producto, stock, precio)
VALUES
('Cemento Portland Tipo IP', 'Cemento', 500, 8.50),
('Clinker', 'Materia prima', 300, 12.75),
('Caliza procesada', 'Materia prima', 1000, 3.25);

COMMIT;

/* ============================================================
   4. OPERACIÓN DE INSERCIÓN REGISTRADA EN EL LOG
   ============================================================ */

BEGIN;

INSERT INTO MovimientosInventario 
(id_producto, id_planta, tipo_movimiento, cantidad, observacion)
VALUES
(1, 1, 'INGRESO', 100, 'Ingreso de cemento producido en planta Chimborazo');

UPDATE Productos
SET stock = stock + 100
WHERE id_producto = 1;

COMMIT;

/* ============================================================
   5. OPERACIÓN DE ACTUALIZACIÓN REGISTRADA EN EL LOG
   ============================================================ */

BEGIN;

UPDATE Productos
SET precio = 9.00
WHERE id_producto = 1;

COMMIT;

/* ============================================================
   6. OPERACIÓN DE ELIMINACIÓN REGISTRADA EN EL LOG
   ============================================================ */

BEGIN;

DELETE FROM MovimientosInventario
WHERE id_movimiento = 1;

COMMIT;

/* ============================================================
   7. SIMULAR ERROR Y APLICAR UNDO CON ROLLBACK
   ============================================================ */

ROLLBACK;
BEGIN;

UPDATE Productos
SET stock = stock - 100
WHERE id_producto = 1;

SELECT * FROM Productos WHERE id_producto = 1;

ROLLBACK;

SELECT * FROM Productos;

