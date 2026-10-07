-- ==============================================================================
-- PROJECT: Sales & Customer Analytics Warehouse (NexCart E-Commerce)
-- FILE: 01_schema.sql
-- DESCRIPTION: PostgreSQL Production DDL Schema Definition
-- DATABASE ENGINE: PostgreSQL 13+
-- AUTHOR: Student (Placement Portfolio Project)
-- ==============================================================================

-- Drop existing tables if re-initialising schema (in correct reverse-dependency order)
DROP TABLE IF EXISTS payments CASCADE;
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS regions CASCADE;

-- ------------------------------------------------------------------------------
-- 1. REGIONS (Geographic Hierarchy Master)
-- ------------------------------------------------------------------------------
CREATE TABLE regions (
    region_id       SERIAL PRIMARY KEY,
    region_name     VARCHAR(50) NOT NULL,
    country         VARCHAR(50) NOT NULL DEFAULT 'USA',
    city            VARCHAR(50) NOT NULL,
    state           VARCHAR(50),
    postal_code     VARCHAR(20),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ------------------------------------------------------------------------------
-- 2. CUSTOMERS (Customer Profiles & Acquisition Logs)
-- ------------------------------------------------------------------------------
CREATE TABLE customers (
    customer_id     SERIAL PRIMARY KEY,
    first_name      VARCHAR(50) NOT NULL,
    last_name       VARCHAR(50) NOT NULL,
    email           VARCHAR(100) UNIQUE NOT NULL,
    phone           VARCHAR(20),
    signup_date     TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    region_id       INT NOT NULL,
    customer_segment VARCHAR(20) DEFAULT 'Consumer' CHECK (customer_segment IN ('Consumer', 'Corporate', 'Home Office')),
    CONSTRAINT fk_customers_region FOREIGN KEY (region_id) REFERENCES regions(region_id) ON DELETE RESTRICT
);

-- ------------------------------------------------------------------------------
-- 3. CATEGORIES (Product Taxonomy & Hierarchy)
-- ------------------------------------------------------------------------------
CREATE TABLE categories (
    category_id         SERIAL PRIMARY KEY,
    category_name       VARCHAR(50) NOT NULL,
    parent_category_id  INT,
    description         TEXT,
    CONSTRAINT fk_categories_parent FOREIGN KEY (parent_category_id) REFERENCES categories(category_id) ON DELETE SET NULL
);

-- ------------------------------------------------------------------------------
-- 4. PRODUCTS (Item Master & Pricing Specs)
-- ------------------------------------------------------------------------------
CREATE TABLE products (
    product_id      SERIAL PRIMARY KEY,
    sku             VARCHAR(50) UNIQUE NOT NULL,
    product_name    VARCHAR(150) NOT NULL,
    category_id     INT NOT NULL,
    base_price      NUMERIC(10, 2) NOT NULL CHECK (base_price >= 0),
    cost_price      NUMERIC(10, 2) NOT NULL CHECK (cost_price >= 0),
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_products_category FOREIGN KEY (category_id) REFERENCES categories(category_id) ON DELETE RESTRICT
);

-- ------------------------------------------------------------------------------
-- 5. ORDERS (Sales Transaction Headers)
-- ------------------------------------------------------------------------------
CREATE TABLE orders (
    order_id        SERIAL PRIMARY KEY,
    customer_id     INT NOT NULL,
    order_date      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    order_status    VARCHAR(20) NOT NULL DEFAULT 'Completed' 
                    CHECK (order_status IN ('Completed', 'Pending', 'Processing', 'Cancelled', 'Returned')),
    shipping_fee    NUMERIC(10, 2) NOT NULL DEFAULT 0.00 CHECK (shipping_fee >= 0),
    tax_amount      NUMERIC(10, 2) NOT NULL DEFAULT 0.00 CHECK (tax_amount >= 0),
    total_amount    NUMERIC(12, 2) NOT NULL DEFAULT 0.00 CHECK (total_amount >= 0),
    shipping_region_id INT NOT NULL,
    CONSTRAINT fk_orders_customer FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE RESTRICT,
    CONSTRAINT fk_orders_shipping_region FOREIGN KEY (shipping_region_id) REFERENCES regions(region_id) ON DELETE RESTRICT
);

-- ------------------------------------------------------------------------------
-- 6. ORDER_ITEMS (Sales Transaction Line Items)
-- ------------------------------------------------------------------------------
CREATE TABLE order_items (
    order_item_id   SERIAL PRIMARY KEY,
    order_id        INT NOT NULL,
    product_id      INT NOT NULL,
    quantity        INT NOT NULL CHECK (quantity > 0),
    unit_price      NUMERIC(10, 2) NOT NULL CHECK (unit_price >= 0),
    discount_amount NUMERIC(10, 2) NOT NULL DEFAULT 0.00 CHECK (discount_amount >= 0),
    total_price     NUMERIC(12, 2) NOT NULL GENERATED ALWAYS AS ((quantity * unit_price) - discount_amount) STORED,
    CONSTRAINT fk_items_order FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
    CONSTRAINT fk_items_product FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE RESTRICT
);

-- ------------------------------------------------------------------------------
-- 7. PAYMENTS (Financial Settlement Records)
-- ------------------------------------------------------------------------------
CREATE TABLE payments (
    payment_id      SERIAL PRIMARY KEY,
    order_id        INT NOT NULL,
    payment_date    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    payment_method  VARCHAR(30) NOT NULL CHECK (payment_method IN ('Credit Card', 'Debit Card', 'PayPal', 'UPI', 'Net Banking', 'Store Credit')),
    payment_status  VARCHAR(20) NOT NULL CHECK (payment_status IN ('Success', 'Failed', 'Pending', 'Refunded')),
    amount          NUMERIC(12, 2) NOT NULL CHECK (amount >= 0),
    transaction_ref VARCHAR(100) UNIQUE,
    CONSTRAINT fk_payments_order FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE
);

-- ------------------------------------------------------------------------------
-- BASE FOREIGN KEY INDEXES (Required for foreign key JOIN optimization)
-- ------------------------------------------------------------------------------
CREATE INDEX idx_customers_region ON customers(region_id);
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_orders_customer ON orders(customer_id);
CREATE INDEX idx_orders_shipping_region ON orders(shipping_region_id);
CREATE INDEX idx_orders_date ON orders(order_date);
CREATE INDEX idx_order_items_order ON order_items(order_id);
CREATE INDEX idx_order_items_product ON order_items(product_id);
CREATE INDEX idx_payments_order ON payments(order_id);
