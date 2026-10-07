-- ==============================================================================
-- PROJECT: Sales & Customer Analytics Warehouse
-- FILE: 03_basic_analysis.sql
-- DESCRIPTION: Foundational Business Metrics & Aggregations
-- AUTHOR: Student (Placement Portfolio Project)
-- ==============================================================================

-- ==============================================================================
-- 1. EXECUTIVE KPI SUMMARY
-- Measures top-line financial performance across completed orders
-- ==============================================================================
SELECT 
    COUNT(DISTINCT order_id) AS total_orders,
    COUNT(DISTINCT customer_id) AS active_customers,
    ROUND(SUM(total_amount)::numeric, 2) AS gross_revenue,
    ROUND(AVG(total_amount)::numeric, 2) AS average_order_value,
    ROUND((SUM(total_amount) / COUNT(DISTINCT customer_id))::numeric, 2) AS revenue_per_customer
FROM orders
WHERE order_status = 'Completed';


-- ==============================================================================
-- 2. REVENUE BY YEAR & QUARTER
-- Tracks high-level macro economic sales growth
-- ==============================================================================
SELECT 
    EXTRACT(YEAR FROM order_date) AS sales_year,
    EXTRACT(QUARTER FROM order_date) AS sales_quarter,
    COUNT(order_id) AS total_orders,
    ROUND(SUM(total_amount)::numeric, 2) AS quarterly_revenue,
    ROUND(AVG(total_amount)::numeric, 2) AS quarterly_aov
FROM orders
WHERE order_status = 'Completed'
GROUP BY 
    EXTRACT(YEAR FROM order_date),
    EXTRACT(QUARTER FROM order_date)
ORDER BY sales_year, sales_quarter;


-- ==============================================================================
-- 3. REVENUE BY MONTHLY TREND (Granular Seasonal Breakdown)
-- ==============================================================================
SELECT 
    TO_CHAR(order_date, 'YYYY-MM') AS year_month,
    COUNT(order_id) AS order_volume,
    ROUND(SUM(total_amount)::numeric, 2) AS total_revenue,
    ROUND(AVG(total_amount)::numeric, 2) AS avg_order_value
FROM orders
WHERE order_status = 'Completed'
GROUP BY TO_CHAR(order_date, 'YYYY-MM')
ORDER BY year_month;


-- ==============================================================================
-- 4. REVENUE BY PRODUCT CATEGORY
-- Identifies top-performing product categories & revenue contribution
-- ==============================================================================
SELECT 
    c.category_name,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    SUM(oi.quantity) AS units_sold,
    ROUND(SUM(oi.total_price)::numeric, 2) AS category_revenue,
    ROUND((SUM(oi.total_price) * 100.0 / SUM(SUM(oi.total_price)) OVER())::numeric, 2) AS revenue_percentage
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN categories c ON p.category_id = c.category_id
JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_status = 'Completed'
GROUP BY c.category_name
ORDER BY category_revenue DESC;


-- ==============================================================================
-- 5. REVENUE & CUSTOMER CONCENTRATION BY GEOGRAPHIC REGION
-- Identifies geographical strongholds and expansion opportunities
-- ==============================================================================
SELECT 
    r.region_name,
    r.country,
    COUNT(DISTINCT c.customer_id) AS total_customers,
    COUNT(o.order_id) AS total_orders,
    ROUND(SUM(o.total_amount)::numeric, 2) AS regional_revenue,
    ROUND(AVG(o.total_amount)::numeric, 2) AS regional_aov
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN regions r ON c.region_id = r.region_id
WHERE o.order_status = 'Completed'
GROUP BY r.region_name, r.country
ORDER BY regional_revenue DESC;


-- ==============================================================================
-- 6. ORDER STATUS DISTRIBUTION & CANCELLATION RATE
-- Operational metrics evaluating order fulfillment efficiency
-- ==============================================================================
SELECT 
    order_status,
    COUNT(*) AS order_count,
    ROUND((COUNT(*) * 100.0 / (SELECT COUNT(*) FROM orders))::numeric, 2) AS status_percentage,
    ROUND(SUM(total_amount)::numeric, 2) AS total_monetary_value
FROM orders
GROUP BY order_status
ORDER BY order_count DESC;


-- ==============================================================================
-- 7. TOP 10 REVENUE-GENERATING PRODUCTS
-- Best-selling individual SKUs
-- ==============================================================================
SELECT 
    p.product_id,
    p.sku,
    p.product_name,
    c.category_name,
    SUM(oi.quantity) AS total_units_sold,
    ROUND(SUM(oi.total_price)::numeric, 2) AS gross_product_revenue
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN categories c ON p.category_id = c.category_id
JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_status = 'Completed'
GROUP BY p.product_id, p.sku, p.product_name, c.category_name
ORDER BY gross_product_revenue DESC
LIMIT 10;
