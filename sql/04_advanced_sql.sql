-- ==============================================================================
-- PROJECT: Sales & Customer Analytics Warehouse
-- FILE: 04_advanced_sql.sql
-- DESCRIPTION: Advanced SQL Mechanics - CTEs, Window Functions, Framing, Lead/Lag
-- AUTHOR: Student (Placement Portfolio Project)
-- ==============================================================================

-- ==============================================================================
-- 1. RANKING: TOP 3 HIGHEST REVENUE PRODUCTS PER CATEGORY
-- Demonstrates DENSE_RANK() OVER (PARTITION BY category ORDER BY revenue DESC)
-- ==============================================================================
WITH product_category_revenue AS (
    SELECT 
        c.category_name,
        p.product_name,
        p.sku,
        SUM(oi.total_price) AS total_revenue,
        DENSE_RANK() OVER (
            PARTITION BY c.category_name 
            ORDER BY SUM(oi.total_price) DESC
        ) AS rank_within_category
    FROM order_items oi
    JOIN products p ON oi.product_id = p.product_id
    JOIN categories c ON p.category_id = c.category_id
    JOIN orders o ON oi.order_id = o.order_id
    WHERE o.order_status = 'Completed'
    GROUP BY c.category_name, p.product_name, p.sku
)
SELECT 
    category_name,
    rank_within_category,
    product_name,
    sku,
    ROUND(total_revenue::numeric, 2) AS category_product_revenue
FROM product_category_revenue
WHERE rank_within_category <= 3
ORDER BY category_name, rank_within_category;


-- ==============================================================================
-- 2. CUMULATIVE & RUNNING TOTALS: RUNNING REVENUE & RUNNING CUSTOMER ACQUISITION
-- Demonstrates SUM() OVER (ORDER BY date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
-- ==============================================================================
WITH monthly_revenue AS (
    SELECT 
        DATE_TRUNC('month', order_date)::date AS sales_month,
        SUM(total_amount) AS monthly_sales
    FROM orders
    WHERE order_status = 'Completed'
    GROUP BY DATE_TRUNC('month', order_date)::date
)
SELECT 
    sales_month,
    ROUND(monthly_sales::numeric, 2) AS monthly_revenue,
    ROUND(SUM(monthly_sales) OVER (
        ORDER BY sales_month 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )::numeric, 2) AS cumulative_running_revenue
FROM monthly_revenue
ORDER BY sales_month;


-- ==============================================================================
-- 3. LAG & LEAD: CUSTOMER ORDER INTERVALS & PREVIOUS PURCHASE DATE
-- Calculates days elapsed between consecutive purchases for repeat customers
-- ==============================================================================
WITH customer_order_sequence AS (
    SELECT 
        customer_id,
        order_id,
        order_date,
        total_amount,
        LAG(order_date) OVER (
            PARTITION BY customer_id 
            ORDER BY order_date
        ) AS previous_order_date,
        LEAD(order_date) OVER (
            PARTITION BY customer_id 
            ORDER BY order_date
        ) AS next_order_date,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id 
            ORDER BY order_date
        ) AS order_sequence_num
    FROM orders
    WHERE order_status = 'Completed'
)
SELECT 
    customer_id,
    order_id,
    order_sequence_num,
    order_date::date AS current_order_date,
    previous_order_date::date AS prior_order_date,
    ROUND(EXTRACT(EPOCH FROM (order_date - previous_order_date))/86400, 1) AS days_since_previous_order
FROM customer_order_sequence
WHERE previous_order_date IS NOT NULL
ORDER BY customer_id, order_sequence_num
LIMIT 20;


-- ==============================================================================
-- 4. MOVING / ROLLING AVERAGE: 7-DAY & 30-DAY ROLLING SALES TRENDS
-- Demonstrates AVG() OVER (ORDER BY date ROWS BETWEEN 29 PRECEDING AND CURRENT ROW)
-- ==============================================================================
WITH daily_sales AS (
    SELECT 
        order_date::date AS sales_date,
        SUM(total_amount) AS daily_revenue
    FROM orders
    WHERE order_status = 'Completed'
    GROUP BY order_date::date
)
SELECT 
    sales_date,
    ROUND(daily_revenue::numeric, 2) AS daily_revenue,
    ROUND(AVG(daily_revenue) OVER (
        ORDER BY sales_date 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    )::numeric, 2) AS rolling_7day_avg_revenue,
    ROUND(AVG(daily_revenue) OVER (
        ORDER BY sales_date 
        ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
    )::numeric, 2) AS rolling_30day_avg_revenue
FROM daily_sales
ORDER BY sales_date;


-- ==============================================================================
-- 5. PERCENTILE & CONTRIBUTION: PERCENTAGE CONTRIBUTION TO TOTAL REVENUE BY CUSTOMER
-- Demonstrates SUM(total) / SUM(SUM(total)) OVER ()
-- ==============================================================================
WITH customer_spending AS (
    SELECT 
        c.customer_id,
        c.first_name || ' ' || c.last_name AS customer_name,
        r.region_name,
        SUM(o.total_amount) AS total_spent
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    JOIN regions r ON c.region_id = r.region_id
    WHERE o.order_status = 'Completed'
    GROUP BY c.customer_id, customer_name, r.region_name
)
SELECT 
    customer_id,
    customer_name,
    region_name,
    ROUND(total_spent::numeric, 2) AS total_spent,
    ROUND((total_spent * 100.0 / SUM(total_spent) OVER())::numeric, 4) AS pct_of_global_revenue,
    DENSE_RANK() OVER (ORDER BY total_spent DESC) AS global_spend_rank
FROM customer_spending
ORDER BY total_spent DESC
LIMIT 20;
