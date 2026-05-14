-- SISTEMA RESTAURANTE - POSTGRESQL FINAL
-- PASO 0. ELIMINAR OBJETOS
DROP TRIGGER IF EXISTS before_insert_detalle_trigger ON detalle_pedido;
DROP TRIGGER IF EXISTS after_insert_detalle_trigger ON detalle_pedido;
DROP FUNCTION IF EXISTS before_insert_detalle() CASCADE;
DROP FUNCTION IF EXISTS after_insert_detalle() CASCADE;
DROP PROCEDURE IF EXISTS hacer_pedido(INT, INT, INT);
DROP PROCEDURE IF EXISTS cerrar_pedido(INT);
DROP TABLE IF EXISTS detalle_pedido CASCADE;
DROP TABLE IF EXISTS pedido CASCADE;
DROP TABLE IF EXISTS auditoria CASCADE;
DROP TABLE IF EXISTS producto CASCADE;

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
    id_pedido INT REFERENCES pedido(id_pedido),
    id_producto INT REFERENCES producto(id_producto),
    cantidad INT,
    subtotal NUMERIC(10,2)
);

CREATE TABLE auditoria(
    id SERIAL PRIMARY KEY,
    mensaje VARCHAR(255),
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- PASO 3. TRIGGER BEFORE (CALCULAR SUBTOTAL)
CREATE OR REPLACE FUNCTION before_insert_detalle()
RETURNS TRIGGER AS $$
DECLARE
    v_precio NUMERIC(10,2);
BEGIN
    SELECT precio INTO v_precio FROM producto WHERE id_producto = NEW.id_producto;
    IF v_precio IS NULL THEN
        RAISE EXCEPTION 'El producto con ID % no existe', NEW.id_producto;
    END IF;
    NEW.subtotal := v_precio * NEW.cantidad;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER before_insert_detalle_trigger
BEFORE INSERT ON detalle_pedido
FOR EACH ROW EXECUTE FUNCTION before_insert_detalle();

-- PASO 4. TRIGGER AFTER (ACTUALIZAR STOCK Y TOTAL)
CREATE OR REPLACE FUNCTION after_insert_detalle()
RETURNS TRIGGER AS $$
BEGIN
    -- 1. Actualizar stock
    UPDATE producto SET stock = stock - NEW.cantidad WHERE id_producto = NEW.id_producto;
    
    -- 2. Actualizar total del pedido
    UPDATE pedido 
    SET total = (SELECT COALESCE(SUM(subtotal), 0) FROM detalle_pedido WHERE id_pedido = NEW.id_pedido)
    WHERE id_pedido = NEW.id_pedido;

    -- 3. Auditoría
    INSERT INTO auditoria(mensaje)
    VALUES (CONCAT('Venta: ', NEW.cantidad, ' pz del prod ', NEW.id_producto, ' en pedido #', NEW.id_pedido));
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER after_insert_detalle_trigger
AFTER INSERT ON detalle_pedido
FOR EACH ROW EXECUTE FUNCTION after_insert_detalle();

-- PASO 5. PROCEDURE HACER PEDIDO (CORREGIDO)
CREATE OR REPLACE PROCEDURE hacer_pedido(
    p_mesa INT,
    p_id_producto INT,
    p_cantidad INT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_id_pedido INT;
    v_stock_actual INT;
BEGIN
    -- Verificar stock antes de empezar
    SELECT stock INTO v_stock_actual FROM producto WHERE id_producto = p_id_producto;
    IF v_stock_actual < p_cantidad THEN
        RAISE EXCEPTION 'No hay stock suficiente. Disponible: %', v_stock_actual;
    END IF;

    -- Buscar o crear pedido
    SELECT id_pedido INTO v_id_pedido FROM pedido WHERE mesa = p_mesa AND estado = 'pendiente' LIMIT 1;
    
    IF v_id_pedido IS NULL THEN
        INSERT INTO pedido(mesa) VALUES(p_mesa) RETURNING id_pedido INTO v_id_pedido;
    END IF;

    -- Insertar detalle
    INSERT INTO detalle_pedido(id_pedido, id_producto, cantidad)
    VALUES(v_id_pedido, p_id_producto, p_cantidad);

    RAISE NOTICE 'Producto agregado al pedido %', v_id_pedido;
END;
$$;