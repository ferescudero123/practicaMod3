-- SISTEMA RESTAURANTE - POSTGRESQL
-- PASO 0. ELIMINAR OBJETOS
DROP TRIGGER IF EXISTS before_insert_detalle_trigger ON detalle_pedido;
DROP TRIGGER IF EXISTS after_insert_detalle_trigger ON detalle_pedido;
DROP FUNCTION IF EXISTS before_insert_detalle();
DROP FUNCTION IF EXISTS after_insert_detalle();
DROP PROCEDURE IF EXISTS hacer_pedido(INT, INT, INT);
DROP PROCEDURE IF EXISTS cerrar_pedido(INT);
DROP TABLE IF EXISTS detalle_pedido;
DROP TABLE IF EXISTS pedido;
DROP TABLE IF EXISTS auditoria;
DROP TABLE IF EXISTS producto;
-- PASO 1. CREAR TABLAS
CREATE TABLE producto(
    id_producto SERIAL PRIMARY KEY,
    nombre VARCHAR(100),
    precio NUMERIC(10,2),
    stock INT DEFAULT 100
);

CREATE TABLE pedido(
    id_pedido SERIAL PRIMARY KEY,
    mesa INT,
    total NUMERIC(10,2) DEFAULT 0,
    estado VARCHAR(20) DEFAULT 'pendiente',
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE detalle_pedido(
    id SERIAL PRIMARY KEY,
    id_pedido INT,
    id_producto INT,
    cantidad INT,
    subtotal NUMERIC(10,2),
    CONSTRAINT fk_pedido
        FOREIGN KEY(id_pedido)
        REFERENCES pedido(id_pedido),
    CONSTRAINT fk_producto
        FOREIGN KEY(id_producto)
        REFERENCES producto(id_producto)
);

CREATE TABLE auditoria(
    id SERIAL PRIMARY KEY,
    mensaje VARCHAR(255),
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);