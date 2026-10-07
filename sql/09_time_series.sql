-- ==============================================================================
-- PROJECT: Sales & Customer Analytics Warehouse
-- FILE: 09_time_series.sql
-- DESCRIPTION: Time-Series Dynamics - Month-over-Month (MoM), Year-over-Year (YoY) Growth
-- AUTHOR: Student (Placement Portfolio Project)
-- ==============================================================================

-- ==============================================================================
-- 1. MONTH-OVER-MONTH (MoM) REVENUE & ORDER GROWTH RATE
-- Uses LAG() OVER (ORDER BY month) to compute percentage change
-- ==============================================================================
WITH monthly_metrics AS (
    SELECT 
        DATE_TRUNC('month', order_date)::date AS sales_month,
        COUNT(order_id) AS total_orders,
        SUM(total_amount) AS monthly_revenue
    FROM orders
    WHERE order_status = 'Completed'
    GROUP BY DATE_TRUNC('month', order_date)::date
)
SELECT 
    TO_CHAR(sales_month, 'YYYY-MM') AS month_label,
    total_orders,
    ROUND(monthly_revenue::numeric, 2) AS monthly_revenue,
    ROUND(LAG(monthly_revenue, 1) OVER (ORDER BY sales_month)::numeric, 2) AS prior_month_revenue,
    ROUND(
        ((monthly_revenue - LAG(monthly_revenue, 1) OVER (ORDER BY sales_month)) * 100.0 / 
        NULLIF(LAG(monthly_revenue, 1) OVER (ORDER BY sales_month), 0))::numeric, 
        2
    ) AS mom_revenue_growth_pct
FROM monthly_metrics
ORDER BY sales_month;


-- ==============================================================================
-- 2. YEAR-OVER-YEAR (YoY) REVENUE COMPARISON BY MONTH
-- Compares same month performance across different calendar years (e.g. Jan 2024 vs Jan 2023)
-- ==============================================================================
WITH monthly_sales AS (
    SELECT 
        EXTRACT(YEAR FROM order_date) AS sales_year,
        EXTRACT(MONTH FROM order_date) AS sales_month_num,
        TO_CHAR(order_date, 'Month') AS sales_month_name,
        SUM(total_amount) AS monthly_revenue
    FROM orders
    WHERE order_status = 'Completed'
    GROUP BY EXTRACT(YEAR FROM order_date), EXTRACT(MONTH FROM order_date), TO_CHAR(order_date, 'Month')
)
SELECT 
    sales_month_num,
    TRIM(sales_month_name) AS month_name,
    ROUND(MAX(CASE WHEN sales_year = 2023 THEN monthly_revenue END)::numeric, 2) AS rev_2023,
    ROUND(MAX(CASE WHEN sales_year = 2024 THEN monthly_revenue END)::numeric, 2) AS rev_2024,
    ROUND(MAX(CASE WHEN sales_year = 2025 THEN monthly_revenue END)::numeric, 2) AS rev_2025,
    ROUND(
        ((MAX(CASE WHEN sales_year = 2024 THEN monthly_revenue END) - MAX(CASE WHEN sales_year = 2023 THEN monthly_revenue END)) * 100.0 /
        NULLIF(MAX(CASE WHEN sales_year = 2023 THEN monthly_revenue END), 0))::numeric, 
        2
    ) AS yoy_growth_2023_to_2024_pct
FROM monthly_sales
GROUP BY sales_month_num, sales_month_name
ORDER BY sales_month_num;


-- ==============================================================================
-- 3. DAY-OF-WEEK & HOUR-OF-DAY SALES PEAK PATTERNS
-- Helps marketing & logistics schedule promotions & inventory staffing
-- ==============================================================================
SELECT 
    TO_CHAR(order_date, 'Day') AS day_of_week,
    EXTRACT(ISODOW FROM order_date) AS day_num,
    COUNT(order_id) AS order_volume,
    ROUND(SUM(total_amount)::numeric, 2) AS total_revenue,
    ROUND(AVG(total_amount)::numeric, 2) AS avg_order_value
FROM orders
WHERE order_status = 'Completed'
GROUP BY TO_CHAR(order_date, 'Day'), EXTRACT(ISODOW FROM order_date)
ORDER BY day_num;


-- ==============================================================================
-- 4. CUMULATIVE REVENUE TARGET PROGRESSION & PACING
-- Target tracking across 2025 financial quarters
-- ==============================================================================
WITH quarterly_revenue AS (
    SELECT 
        EXTRACT(YEAR FROM order_date) AS sales_year,
        EXTRACT(QUARTER FROM order_date) AS sales_quarter,
        SUM(total_amount) AS quarter_revenue
    FROM orders
    WHERE order_status = 'Completed'
    GROUP BY EXTRACT(YEAR FROM order_date), EXTRACT(QUARTER FROM order_date)
)
SELECT 
    sales_year,
    sales_quarter,
    ROUND(quarter_revenue::numeric, 2) AS quarter_revenue,
    ROUND(SUM(quarter_revenue) OVER (
        PARTITION BY sales_year 
        ORDER BY sales_quarter
    )::numeric, 2) AS ytd_cumulative_revenue
FROM quarterly_revenue
ORDER BY sales_year, sales_quarter;
