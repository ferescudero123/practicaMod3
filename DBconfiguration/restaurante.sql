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
-- =========================================
-- PASO 3. TRIGGER BEFORE
-- CALCULAR SUBTOTAL
-- =========================================
CREATE OR REPLACE FUNCTION before_insert_detalle()
RETURNS TRIGGER AS
$$
DECLARE
    v_precio NUMERIC(10,2);
BEGIN
    SELECT precio
    INTO v_precio
    FROM producto
    WHERE id_producto = NEW.id_producto;
    NEW.subtotal := v_precio * NEW.cantidad;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER before_insert_detalle_trigger
BEFORE INSERT ON detalle_pedido
FOR EACH ROW
EXECUTE FUNCTION before_insert_detalle();
-- =========================================
-- PASO 4. TRIGGER AFTER
-- ACTUALIZAR STOCK Y TOTAL
-- =========================================
CREATE OR REPLACE FUNCTION after_insert_detalle()
RETURNS TRIGGER AS
$$
DECLARE
    v_stock_actual INT;
BEGIN
    -- Verificar stock
    SELECT stock
    INTO v_stock_actual
    FROM producto
    WHERE id_producto = NEW.id_producto;
    IF v_stock_actual < NEW.cantidad THEN
        RAISE EXCEPTION 'Stock insuficiente';
    END IF;
    -- Actualizar stock
    UPDATE producto
    SET stock = stock - NEW.cantidad
    WHERE id_producto = NEW.id_producto;
    -- Actualizar total
    UPDATE pedido
    SET total = (
        SELECT SUM(subtotal)
        FROM detalle_pedido
        WHERE id_pedido = NEW.id_pedido
    )
    WHERE id_pedido = NEW.id_pedido;
    -- Auditoría
    INSERT INTO auditoria(mensaje)
    VALUES(
        CONCAT(
            'Se vendió ',
            NEW.cantidad,
            ' unidad(es) del producto ID ',
            NEW.id_producto,
            ' en pedido #',
            NEW.id_pedido
        )
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER after_insert_detalle_trigger
AFTER INSERT ON detalle_pedido
FOR EACH ROW
EXECUTE FUNCTION after_insert_detalle();
-- =========================================
-- PASO 5. PROCEDURE HACER PEDIDO
-- =========================================
CREATE OR REPLACE PROCEDURE hacer_pedido(
    p_mesa INT,
    p_id_producto INT,
    p_cantidad INT
)
LANGUAGE plpgsql
AS
$$
DECLARE
    v_id_pedido INT;
BEGIN
    -- Buscar pedido pendiente
    SELECT id_pedido
    INTO v_id_pedido
    FROM pedido
    WHERE mesa = p_mesa
    AND estado = 'pendiente'
    LIMIT 1;
    -- Crear pedido si no existe
    IF v_id_pedido IS NULL THEN
        INSERT INTO pedido(mesa)
        VALUES(p_mesa)
        RETURNING id_pedido INTO v_id_pedido;
    END IF;
    -- Insertar detalle
    INSERT INTO detalle_pedido(
        id_pedido,
        id_producto,
        cantidad
    )
    VALUES(
        v_id_pedido,
        p_id_producto,
        p_cantidad
    );
    RAISE NOTICE 'Producto agregado al pedido %', v_id_pedido;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error en el pedido';
END;
$$;
-- =========================================
-- PASO 6. PROCEDURE CERRAR PEDIDO
-- =========================================
CREATE OR REPLACE PROCEDURE cerrar_pedido(
    p_mesa INT
)
LANGUAGE plpgsql
AS
$$
DECLARE
    v_id_pedido INT;
    v_total NUMERIC(10,2);
BEGIN
    SELECT id_pedido, total
    INTO v_id_pedido, v_total
    FROM pedido
    WHERE mesa = p_mesa
    AND estado = 'pendiente'
    LIMIT 1;
    IF v_id_pedido IS NOT NULL THEN
        UPDATE pedido
        SET estado = 'pagado'
        WHERE id_pedido = v_id_pedido;
        INSERT INTO auditoria(mensaje)
        VALUES(
            CONCAT(
                'Pedido #',
                v_id_pedido,
                ' cerrado'
            )
        );
        RAISE NOTICE 'Pedido % pagado. Total: %',
            v_id_pedido,
            v_total;
    ELSE
        RAISE NOTICE 'No existe pedido pendiente';
    END IF;
END;
$$;