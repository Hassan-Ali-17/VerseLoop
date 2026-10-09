-- ====================================================================
-- LoopServe 3.0 — Advanced Restaurant Operations Database Schema
-- Supabase / PostgreSQL Initial Schema & Atomic Business Logic
-- ====================================================================

-- 1. Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. Drop existing tables if re-running
DROP TABLE IF EXISTS idempotency_records CASCADE;
DROP TABLE IF EXISTS order_status_logs CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS inventory CASCADE;
DROP TABLE IF EXISTS dishes CASCADE;

-- ====================================================================
-- TABLE: dishes
-- Restaurant menu items, 3D dish assets, and customization schemas
-- ====================================================================
CREATE TABLE dishes (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    category TEXT NOT NULL,
    description TEXT NOT NULL,
    base_price_cents INT NOT NULL CHECK (base_price_cents >= 0),
    image_url TEXT NOT NULL,
    model_3d_id TEXT NOT NULL,
    is_available BOOLEAN NOT NULL DEFAULT true,
    stock_count INT NOT NULL DEFAULT 0 CHECK (stock_count >= 0),
    is_featured BOOLEAN NOT NULL DEFAULT false,
    ingredients JSONB NOT NULL DEFAULT '[]'::jsonb,
    customization_groups JSONB NOT NULL DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_dishes_category ON dishes(category);
CREATE INDEX idx_dishes_available ON dishes(is_available);

-- ====================================================================
-- TABLE: inventory
-- Real-time dish portion availability and stock counts
-- ====================================================================
CREATE TABLE inventory (
    dish_id TEXT PRIMARY KEY REFERENCES dishes(id) ON DELETE CASCADE,
    dish_name TEXT NOT NULL,
    category TEXT NOT NULL,
    available_portions INT NOT NULL CHECK (available_portions >= 0),
    is_available BOOLEAN NOT NULL DEFAULT true,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_inventory_available ON inventory(is_available);

-- ====================================================================
-- TABLE: orders
-- Customer and staff kitchen order tickets
-- ====================================================================
CREATE TABLE orders (
    id TEXT PRIMARY KEY,
    idempotency_key TEXT UNIQUE NOT NULL,
    order_number TEXT UNIQUE NOT NULL,
    customer_name TEXT NOT NULL,
    customer_notes TEXT,
    items JSONB NOT NULL DEFAULT '[]'::jsonb,
    subtotal_cents INT NOT NULL CHECK (subtotal_cents >= 0),
    fee_cents INT NOT NULL DEFAULT 250 CHECK (fee_cents >= 0),
    total_cents INT NOT NULL CHECK (total_cents >= 0),
    status TEXT NOT NULL CHECK (status IN ('pending', 'accepted', 'preparing', 'ready', 'handedOver', 'cancelled')),
    estimated_prep_minutes INT NOT NULL DEFAULT 20,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_created_at ON orders(created_at DESC);
CREATE INDEX idx_orders_idempotency ON orders(idempotency_key);

-- ====================================================================
-- TABLE: order_status_logs
-- Audit log of order state transitions
-- ====================================================================
CREATE TABLE order_status_logs (
    id BIGSERIAL PRIMARY KEY,
    order_id TEXT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    status TEXT NOT NULL,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    note TEXT
);

CREATE INDEX idx_order_logs_order_id ON order_status_logs(order_id);

-- ====================================================================
-- TABLE: idempotency_records
-- Guaranteed deduplication for order placement requests
-- ====================================================================
CREATE TABLE idempotency_records (
    idempotency_key TEXT PRIMARY KEY,
    order_id TEXT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    response_payload JSONB NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ====================================================================
-- STORED PROCEDURE: place_order_atomic
-- Enforces:
-- 1. Idempotency (replays prior result if key exists)
-- 2. Concurrency-safe inventory reservation (SELECT ... FOR UPDATE)
-- 3. Atomic inventory decrement (never negative, sold-out auto-toggle)
-- 4. Order creation & status history
-- ====================================================================
CREATE OR REPLACE FUNCTION place_order_atomic(
    p_idempotency_key TEXT,
    p_order_id TEXT,
    p_order_number TEXT,
    p_customer_name TEXT,
    p_customer_notes TEXT,
    p_items JSONB,
    p_subtotal_cents INT,
    p_fee_cents INT,
    p_total_cents INT,
    p_estimated_prep_minutes INT DEFAULT 20
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_existing_order JSONB;
    v_item JSONB;
    v_dish_id TEXT;
    v_qty INT;
    v_current_portions INT;
    v_created_order JSONB;
BEGIN
    -- 1. Check idempotency record
    SELECT response_payload INTO v_existing_order
    FROM idempotency_records
    WHERE idempotency_key = p_idempotency_key;

    IF v_existing_order IS NOT NULL THEN
        RETURN v_existing_order;
    END IF;

    -- 2. Lock & Validate inventory for each item
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        v_dish_id := v_item->>'dishId';
        v_qty := COALESCE((v_item->>'quantity')::INT, 1);

        -- Row-level lock on inventory
        SELECT available_portions INTO v_current_portions
        FROM inventory
        WHERE dish_id = v_dish_id
        FOR UPDATE;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'ITEM_NOT_FOUND: Dish % not found in inventory', v_dish_id;
        END IF;

        IF v_current_portions < v_qty THEN
            RAISE EXCEPTION 'INSUFFICIENT_STOCK: Dish % has only % portions available, requested %', v_dish_id, v_current_portions, v_qty;
        END IF;
    END LOOP;

    -- 3. Atomically decrement inventory & dish stock
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        v_dish_id := v_item->>'dishId';
        v_qty := COALESCE((v_item->>'quantity')::INT, 1);

        UPDATE inventory
        SET 
            available_portions = available_portions - v_qty,
            is_available = CASE WHEN available_portions - v_qty > 0 THEN true ELSE false END,
            updated_at = NOW()
        WHERE dish_id = v_dish_id;

        UPDATE dishes
        SET
            stock_count = stock_count - v_qty,
            is_available = CASE WHEN stock_count - v_qty > 0 THEN true ELSE false END,
            updated_at = NOW()
        WHERE id = v_dish_id;
    END LOOP;

    -- 4. Insert Order
    INSERT INTO orders (
        id,
        idempotency_key,
        order_number,
        customer_name,
        customer_notes,
        items,
        subtotal_cents,
        fee_cents,
        total_cents,
        status,
        estimated_prep_minutes,
        created_at,
        updated_at
    ) VALUES (
        p_order_id,
        p_idempotency_key,
        p_order_number,
        p_customer_name,
        p_customer_notes,
        p_items,
        p_subtotal_cents,
        p_fee_cents,
        p_total_cents,
        'pending',
        p_estimated_prep_minutes,
        NOW(),
        NOW()
    );

    -- 5. Insert initial status log
    INSERT INTO order_status_logs (order_id, status, timestamp, note)
    VALUES (p_order_id, 'pending', NOW(), 'Order submitted by customer');

    -- 6. Construct JSON response matching Flutter OrderModel
    SELECT json_build_object(
        'id', id,
        'idempotencyKey', idempotency_key,
        'orderNumber', order_number,
        'customerName', customer_name,
        'customerNotes', customer_notes,
        'items', items,
        'subtotalCents', subtotal_cents,
        'feeCents', fee_cents,
        'totalCents', total_cents,
        'status', status,
        'estimatedPrepMinutes', estimated_prep_minutes,
        'createdAt', to_char(created_at AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"'),
        'updatedAt', to_char(updated_at AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"'),
        'history', json_build_array(
            json_build_object(
                'status', 'pending',
                'timestamp', to_char(NOW() AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"'),
                'note', 'Order submitted by customer'
            )
        )
    )::jsonb INTO v_created_order
    FROM orders
    WHERE id = p_order_id;

    -- 7. Persist Idempotency Record
    INSERT INTO idempotency_records (idempotency_key, order_id, response_payload, created_at)
    VALUES (p_idempotency_key, p_order_id, v_created_order, NOW());

    RETURN v_created_order;
END;
$$;

-- ====================================================================
-- STORED PROCEDURE: update_order_status_atomic
-- Enforces valid state machine transitions & concurrency conflict handling
-- ====================================================================
CREATE OR REPLACE FUNCTION update_order_status_atomic(
    p_order_id TEXT,
    p_new_status TEXT,
    p_note TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_order orders%ROWTYPE;
    v_item JSONB;
    v_dish_id TEXT;
    v_qty INT;
    v_history JSONB;
    v_updated_order JSONB;
BEGIN
    SELECT * INTO v_order
    FROM orders
    WHERE id = p_order_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'ORDER_NOT_FOUND: Order % does not exist', p_order_id;
    END IF;

    -- Check valid state transitions
    IF v_order.status = 'handedOver' OR v_order.status = 'cancelled' THEN
        RAISE EXCEPTION 'INVALID_TRANSITION: Cannot change status of % order', v_order.status;
    END IF;

    -- Concurrency rule: If customer cancels after staff started preparing
    IF p_new_status = 'cancelled' AND v_order.status IN ('preparing', 'ready') THEN
        -- Staff already prepared or preparing; cancellation conflict
        RAISE EXCEPTION 'CANCEL_CONFLICT: Order is already in % state and cannot be cancelled', v_order.status;
    END IF;

    -- If successfully cancelled from pending/accepted, restore inventory portions
    IF p_new_status = 'cancelled' THEN
        FOR v_item IN SELECT * FROM jsonb_array_elements(v_order.items)
        LOOP
            v_dish_id := v_item->>'dishId';
            v_qty := COALESCE((v_item->>'quantity')::INT, 1);

            UPDATE inventory
            SET available_portions = available_portions + v_qty,
                is_available = true,
                updated_at = NOW()
            WHERE dish_id = v_dish_id;

            UPDATE dishes
            SET stock_count = stock_count + v_qty,
                is_available = true,
                updated_at = NOW()
            WHERE id = v_dish_id;
        END LOOP;
    END IF;

    -- Update status
    UPDATE orders
    SET status = p_new_status,
        updated_at = NOW()
    WHERE id = p_order_id;

    -- Insert log
    INSERT INTO order_status_logs (order_id, status, timestamp, note)
    VALUES (p_order_id, p_new_status, NOW(), p_note);

    -- Build full history
    SELECT json_agg(
        json_build_object(
            'status', status,
            'timestamp', to_char(timestamp AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"'),
            'note', note
        ) ORDER BY timestamp ASC
    )::jsonb INTO v_history
    FROM order_status_logs
    WHERE order_id = p_order_id;

    -- Return updated order object
    SELECT json_build_object(
        'id', id,
        'idempotencyKey', idempotency_key,
        'orderNumber', order_number,
        'customerName', customer_name,
        'customerNotes', customer_notes,
        'items', items,
        'subtotalCents', subtotal_cents,
        'feeCents', fee_cents,
        'totalCents', total_cents,
        'status', status,
        'estimatedPrepMinutes', estimated_prep_minutes,
        'createdAt', to_char(created_at AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"'),
        'updatedAt', to_char(updated_at AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"'),
        'history', v_history
    )::jsonb INTO v_updated_order
    FROM orders
    WHERE id = p_order_id;

    RETURN v_updated_order;
END;
$$;

-- ====================================================================
-- SEED DATA: 5 Signature Dishes, Initial Inventory & Fixture Orders
-- Note: Dish 'd5' starts with stock_count = 1 for the concurrency test!
-- ====================================================================

INSERT INTO dishes (id, name, category, description, base_price_cents, image_url, model_3d_id, is_available, stock_count, is_featured, ingredients, customization_groups)
VALUES 
(
    'd1',
    'Ember Signature Wagyu Burger',
    'Main Course',
    'Aged A5 Japanese Wagyu patty, caramelized onion jam, melted artisan cheddar, and secret truffle ember glaze on toasted brioche.',
    2450,
    'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=600&auto=format&fit=crop',
    'd1',
    true,
    8,
    true,
    '["A5 Wagyu Beef", "Caramelized Onion", "Aged Cheddar", "Brioche Bun", "Truffle Ember Glaze"]'::jsonb,
    '[
        {
            "id": "g_portion",
            "name": "Portion Size",
            "isRequired": true,
            "options": [
                {"id": "opt_p1", "name": "Classic Single", "priceDeltaCents": 0},
                {"id": "opt_p2", "name": "Double Patty", "priceDeltaCents": 850},
                {"id": "opt_p3", "name": "Junior Portion", "priceDeltaCents": -400}
            ]
        },
        {
            "id": "g_sauce",
            "name": "Signature Sauce",
            "isRequired": true,
            "options": [
                {"id": "opt_s1", "name": "Secret Ember Sauce", "priceDeltaCents": 0},
                {"id": "opt_s2", "name": "Truffle Mayo", "priceDeltaCents": 250},
                {"id": "opt_s3", "name": "Smoky BBQ", "priceDeltaCents": 150},
                {"id": "opt_s4", "name": "Spicy Sriracha", "priceDeltaCents": 150}
            ]
        },
        {
            "id": "g_cheese",
            "name": "Artisan Cheese",
            "isRequired": false,
            "options": [
                {"id": "opt_c1", "name": "Melted Cheddar", "priceDeltaCents": 0},
                {"id": "opt_c2", "name": "Melted Cheddar Extra", "priceDeltaCents": 300},
                {"id": "opt_c3", "name": "Smoked Gouda", "priceDeltaCents": 350},
                {"id": "opt_c4", "name": "None", "priceDeltaCents": 0}
            ]
        },
        {
            "id": "g_toppings",
            "name": "Extra Toppings",
            "isRequired": false,
            "options": [
                {"id": "opt_t1", "name": "Crispy Bacon", "priceDeltaCents": 350},
                {"id": "opt_t2", "name": "Sautéed Mushrooms", "priceDeltaCents": 250},
                {"id": "opt_t3", "name": "Fried Egg", "priceDeltaCents": 200}
            ]
        }
    ]'::jsonb
),
(
    'd2',
    'Artisan Truffle & Wild Mushroom Pizza',
    'Wood-Fired Pizza',
    'Slow-fermented sourdough, black truffle cream, wild forest mushrooms, fior di latte mozzarella, and fresh thyme.',
    2800,
    'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=600&auto=format&fit=crop',
    'd2',
    true,
    12,
    true,
    '["Sourdough", "Black Truffle Cream", "Wild Mushrooms", "Fior di Latte", "Fresh Thyme"]'::jsonb,
    '[
        {
            "id": "g_pizza_size",
            "name": "Size",
            "isRequired": true,
            "options": [
                {"id": "opt_pz1", "name": "Medium 11\"", "priceDeltaCents": 0},
                {"id": "opt_pz2", "name": "Large 14\"", "priceDeltaCents": 600}
            ]
        },
        {
            "id": "g_pizza_base",
            "name": "Base Sauce",
            "isRequired": true,
            "options": [
                {"id": "opt_pb1", "name": "Black Truffle Cream", "priceDeltaCents": 0},
                {"id": "opt_pb2", "name": "Classic Tomato", "priceDeltaCents": 0},
                {"id": "opt_pb3", "name": "Pesto Base", "priceDeltaCents": 200}
            ]
        }
    ]'::jsonb
),
(
    'd3',
    'Wood-Grilled Wagyu Ribeye Steak',
    'Grill & Steaks',
    'Prime 300g Wagyu ribeye grilled over white oak charcoal, served with marrow butter and charred rosemary.',
    4500,
    'https://images.unsplash.com/photo-1558030006-450675393462?w=600&auto=format&fit=crop',
    'd3',
    true,
    5,
    true,
    '["Wagyu Ribeye 300g", "Bone Marrow Butter", "Charred Rosemary", "Sea Salt"]'::jsonb,
    '[
        {
            "id": "g_steak_cut",
            "name": "Cut Size",
            "isRequired": true,
            "options": [
                {"id": "opt_st1", "name": "300g Standard", "priceDeltaCents": 0},
                {"id": "opt_st2", "name": "500g Feast", "priceDeltaCents": 2200}
            ]
        },
        {
            "id": "g_steak_butter",
            "name": "Finish Butter",
            "isRequired": true,
            "options": [
                {"id": "opt_sb1", "name": "Herb Garlic Butter", "priceDeltaCents": 0},
                {"id": "opt_sb2", "name": "Truffle Butter", "priceDeltaCents": 400}
            ]
        },
        {
            "id": "g_steak_side",
            "name": "Included Side",
            "isRequired": true,
            "options": [
                {"id": "opt_side1", "name": "Truffle Fries", "priceDeltaCents": 0},
                {"id": "opt_side2", "name": "Charred Asparagus", "priceDeltaCents": 200}
            ]
        }
    ]'::jsonb
),
(
    'd4',
    'Smoky Tonkotsu Ramen Supreme',
    'Soups & Bowls',
    '24-hour simmered pork bone broth, hand-crafted wheat noodles, slow-braised chashu pork belly, ajitsuke tamago egg.',
    2150,
    'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=600&auto=format&fit=crop',
    'd4',
    true,
    15,
    false,
    '["Tonkotsu Broth", "Wheat Noodles", "Chashu Pork Belly", "Ajitsuke Egg", "Black Garlic Oil"]'::jsonb,
    '[
        {
            "id": "g_ramen_broth",
            "name": "Broth Style",
            "isRequired": true,
            "options": [
                {"id": "opt_rb1", "name": "Classic Rich Tonkotsu", "priceDeltaCents": 0},
                {"id": "opt_rb2", "name": "Spicy Miso", "priceDeltaCents": 150},
                {"id": "opt_rb3", "name": "Black Garlic Oil", "priceDeltaCents": 200}
            ]
        }
    ]'::jsonb
),
(
    'd5',
    'Ember Dark Chocolate Molten Lava Cake',
    'Desserts',
    'Valrhona 70% dark chocolate cake with a molten truffle center, accompanied by Madagascar vanilla bean ice cream.',
    1400,
    'https://images.unsplash.com/photo-1606313564200-e75d5e30476c?w=600&auto=format&fit=crop',
    'd5',
    true,
    1, -- Exactly 1 portion available to test race conditions!
    true,
    '["70% Valrhona Chocolate", "Madagascar Vanilla Bean", "Gold Leaf", "Raspberry Coulis"]'::jsonb,
    '[
        {
            "id": "g_dessert_portion",
            "name": "Serving Option",
            "isRequired": true,
            "options": [
                {"id": "opt_des1", "name": "Solo Cake", "priceDeltaCents": 0},
                {"id": "opt_des2", "name": "Vanilla Bean Ice Cream", "priceDeltaCents": 350}
            ]
        }
    ]'::jsonb
);

-- Populate inventory from dishes
INSERT INTO inventory (dish_id, dish_name, category, available_portions, is_available, updated_at)
SELECT id, name, category, stock_count, is_available, NOW()
FROM dishes;

-- Seed Sample Orders
INSERT INTO orders (id, idempotency_key, order_number, customer_name, customer_notes, items, subtotal_cents, fee_cents, total_cents, status, estimated_prep_minutes, created_at, updated_at)
VALUES 
(
    'ord-101',
    'idemp-seed-101',
    '8042',
    'Alexander Wright',
    'Please extra crispy bacon if possible',
    '[
        {
            "id": "c1",
            "dish": {
                "id": "d1",
                "name": "Ember Signature Wagyu Burger",
                "category": "Main Course",
                "description": "Aged A5 Japanese Wagyu patty",
                "basePriceCents": 2450,
                "imageUrl": "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=600&auto=format&fit=crop",
                "model3dId": "d1",
                "isAvailable": true,
                "stockCount": 8,
                "isFeatured": true,
                "ingredients": ["A5 Wagyu Beef", "Caramelized Onion"],
                "customizationGroups": []
            },
            "selectedOptions": {"g_portion": "opt_p1", "g_sauce": "opt_s1", "g_cheese": "opt_c1"},
            "selectedOptionNames": {"g_portion": "Classic Single", "g_sauce": "Secret Ember Sauce", "g_cheese": "Melted Cheddar"},
            "extraPriceCents": 0,
            "quantity": 1
        }
    ]'::jsonb,
    2450,
    250,
    2700,
    'preparing',
    15,
    NOW() - INTERVAL '12 minutes',
    NOW() - INTERVAL '5 minutes'
),
(
    'ord-102',
    'idemp-seed-102',
    '8043',
    'Sophia Chen',
    'No garlic oil',
    '[
        {
            "id": "c2",
            "dish": {
                "id": "d2",
                "name": "Artisan Truffle & Wild Mushroom Pizza",
                "category": "Wood-Fired Pizza",
                "description": "Slow-fermented sourdough",
                "basePriceCents": 2800,
                "imageUrl": "https://images.unsplash.com/photo-1513104890138-7c749659a591?w=600&auto=format&fit=crop",
                "model3dId": "d2",
                "isAvailable": true,
                "stockCount": 12,
                "isFeatured": true,
                "ingredients": ["Sourdough", "Black Truffle Cream"],
                "customizationGroups": []
            },
            "selectedOptions": {"g_pizza_size": "opt_pz2", "g_pizza_base": "opt_pb1"},
            "selectedOptionNames": {"g_pizza_size": "Large 14\"", "g_pizza_base": "Black Truffle Cream"},
            "extraPriceCents": 600,
            "quantity": 1
        }
    ]'::jsonb,
    3400,
    250,
    3650,
    'pending',
    20,
    NOW() - INTERVAL '3 minutes',
    NOW() - INTERVAL '3 minutes'
);

-- Seed status logs
INSERT INTO order_status_logs (order_id, status, timestamp, note) VALUES
('ord-101', 'pending', NOW() - INTERVAL '12 minutes', 'Order submitted by customer'),
('ord-101', 'accepted', NOW() - INTERVAL '10 minutes', 'Kitchen accepted ticket'),
('ord-101', 'preparing', NOW() - INTERVAL '5 minutes', 'Chef started grilling'),
('ord-102', 'pending', NOW() - INTERVAL '3 minutes', 'Order submitted by customer');

-- ====================================================================
-- REALTIME PUBLICATION SETUP
-- Broadcasts changes on orders and inventory to connected clients
-- ====================================================================
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE orders;
        ALTER PUBLICATION supabase_realtime ADD TABLE inventory;
        ALTER PUBLICATION supabase_realtime ADD TABLE dishes;
    END IF;
EXCEPTION WHEN OTHERS THEN
    -- If already added, ignore
    NULL;
END;
$$;
