-- ==============================================================================
-- PROJECT: Sales & Customer Analytics Warehouse
-- FILE: 02_data_quality.sql
-- DESCRIPTION: Data Quality Auditing, Integrity Checks, and Anomaly Reporting
-- AUTHOR: Student (Placement Portfolio Project)
-- ==============================================================================

-- ==============================================================================
-- 1. NULL VALUE AUDIT IN CRITICAL COLUMNS
-- Checks for missing mandatory attributes across transactional entities
-- ==============================================================================

SELECT 
    'customers' AS table_name,
    COUNT(*) AS total_records,
    COUNT(*) - COUNT(customer_id) AS null_customer_ids,
    COUNT(*) - COUNT(email) AS null_emails,
    COUNT(*) - COUNT(region_id) AS null_regions
FROM customers
UNION ALL
SELECT 
    'orders' AS table_name,
    COUNT(*) AS total_records,
    COUNT(*) - COUNT(order_id) AS null_order_ids,
    COUNT(*) - COUNT(customer_id) AS null_customer_ids,
    COUNT(*) - COUNT(total_amount) AS null_total_amounts
FROM orders
UNION ALL
SELECT 
    'order_items' AS table_name,
    COUNT(*) AS total_records,
    COUNT(*) - COUNT(order_item_id) AS null_item_ids,
    COUNT(*) - COUNT(product_id) AS null_product_ids,
    COUNT(*) - COUNT(unit_price) AS null_unit_prices
FROM order_items;


-- ==============================================================================
-- 2. DUPLICATE RECORD IDENTIFICATION
-- Checks for duplicate customer emails or duplicate order transactions
-- ==============================================================================

-- Check duplicate customer emails
SELECT 
    email, 
    COUNT(*) AS occurrence_count
FROM customers
GROUP BY email
HAVING COUNT(*) > 1;

-- Check duplicate order items for the same product within a single order
SELECT 
    order_id, 
    product_id, 
    COUNT(*) AS duplicate_entries
FROM order_items
GROUP BY order_id, product_id
HAVING COUNT(*) > 1;


-- ==============================================================================
-- 3. REFERENTIAL INTEGRITY AUDIT (Orphan Records)
-- Identifies orders without valid customers or order_items without orders
-- ==============================================================================

-- Orphan orders (Order customer_id missing from customers table)
SELECT 
    o.order_id, 
    o.customer_id, 
    o.order_date
FROM orders o
LEFT JOIN customers c ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- Orphan order items (Item order_id missing from orders table)
SELECT 
    oi.order_item_id, 
    oi.order_id, 
    oi.product_id
FROM order_items oi
LEFT JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;


-- ==============================================================================
-- 4. DOMAIN & BOUNDARY VALIDATION (Negative / Invalid Numbers & Dates)
-- ==============================================================================

-- Check for invalid price/cost/quantity values
SELECT 
    'invalid_product_prices' AS anomaly_type,
    COUNT(*) AS anomaly_count
FROM products
WHERE base_price <= 0 OR cost_price <= 0
UNION ALL
SELECT 
    'invalid_item_quantities',
    COUNT(*)
FROM order_items
WHERE quantity <= 0 OR unit_price < 0
UNION ALL
SELECT 
    'future_order_dates',
    COUNT(*)
FROM orders
WHERE order_date > CURRENT_TIMESTAMP;


-- ==============================================================================
-- 5. TRANSACTIONAL DISCREPANCY AUDIT
-- Validates if header total_amount matches the sum of line items + tax + shipping
-- ==============================================================================

WITH line_item_sums AS (
    SELECT 
        order_id,
        SUM((quantity * unit_price) - discount_amount) AS calculated_item_total
    FROM order_items
    GROUP BY order_id
)
SELECT 
    o.order_id,
    o.total_amount AS header_total,
    ROUND((lis.calculated_item_total + o.shipping_fee + o.tax_amount)::numeric, 2) AS calculated_total,
    ABS(o.total_amount - (lis.calculated_item_total + o.shipping_fee + o.tax_amount)) AS discrepancy
FROM orders o
JOIN line_item_sums lis ON o.order_id = lis.order_id
WHERE ABS(o.total_amount - (lis.calculated_item_total + o.shipping_fee + o.tax_amount)) > 0.05
ORDER BY discrepancy DESC;


-- ==============================================================================
-- 6. DATA QUALITY SUMMARY REPORT
-- Single execution summary to verify database health before analytical runs
-- ==============================================================================

SELECT 
    (SELECT COUNT(*) FROM customers) AS total_customers,
    (SELECT COUNT(*) FROM orders) AS total_orders,
    (SELECT COUNT(*) FROM order_items) AS total_order_items,
    (SELECT COUNT(*) FROM products) AS total_products,
    (SELECT COUNT(*) FROM orders WHERE order_status = 'Completed') AS completed_orders,
    (SELECT COUNT(*) FROM orders WHERE order_status = 'Returned') AS returned_orders,
    (SELECT COUNT(*) FROM orders WHERE order_status = 'Cancelled') AS cancelled_orders;
