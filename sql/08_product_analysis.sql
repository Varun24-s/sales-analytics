-- ==============================================================================
-- PROJECT: Sales & Customer Analytics Warehouse
-- FILE: 08_product_analysis.sql
-- DESCRIPTION: Product Performance, Profit Margins, Volume vs Revenue Matrix
-- AUTHOR: Student (Placement Portfolio Project)
-- ==============================================================================

-- ==============================================================================
-- 1. PRODUCT MARGIN & PROFITABILITY LEADERBOARD
-- Evaluates gross profit margins per product SKU (Revenue - Cost)
-- ==============================================================================
SELECT 
    p.product_id,
    p.sku,
    p.product_name,
    c.category_name,
    SUM(oi.quantity) AS total_units_sold,
    ROUND(SUM(oi.total_price)::numeric, 2) AS total_revenue,
    ROUND(SUM(oi.quantity * p.cost_price)::numeric, 2) AS total_cost,
    ROUND(SUM(oi.total_price - (oi.quantity * p.cost_price))::numeric, 2) AS gross_profit,
    ROUND(((SUM(oi.total_price - (oi.quantity * p.cost_price)) * 100.0) / NULLIF(SUM(oi.total_price), 0))::numeric, 2) AS gross_profit_margin_pct
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN categories c ON p.category_id = c.category_id
JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_status = 'Completed'
GROUP BY p.product_id, p.sku, p.product_name, c.category_name
ORDER BY gross_profit DESC
LIMIT 20;


-- ==============================================================================
-- 2. HIGH VOLUME VS HIGH REVENUE QUADRANT ANALYSIS
-- Identifies products with high quantity sold but low revenue (and vice-versa)
-- ==============================================================================
WITH product_stats AS (
    SELECT 
        p.product_id,
        p.product_name,
        c.category_name,
        SUM(oi.quantity) AS total_units,
        SUM(oi.total_price) AS total_revenue,
        AVG(oi.unit_price) AS avg_unit_price
    FROM order_items oi
    JOIN products p ON oi.product_id = p.product_id
    JOIN categories c ON p.category_id = c.category_id
    JOIN orders o ON oi.order_id = o.order_id
    WHERE o.order_status = 'Completed'
    GROUP BY p.product_id, p.product_name, c.category_name
),
benchmarks AS (
    SELECT 
        AVG(total_units) AS avg_units_benchmark,
        AVG(total_revenue) AS avg_revenue_benchmark
    FROM product_stats
)
SELECT 
    ps.product_id,
    ps.product_name,
    ps.category_name,
    ps.total_units,
    ROUND(ps.total_revenue::numeric, 2) AS total_revenue,
    ROUND(ps.avg_unit_price::numeric, 2) AS avg_unit_price,
    CASE 
        WHEN ps.total_units >= b.avg_units_benchmark AND ps.total_revenue >= b.avg_revenue_benchmark THEN 'Star (High Volume, High Revenue)'
        WHEN ps.total_units >= b.avg_units_benchmark AND ps.total_revenue < b.avg_revenue_benchmark THEN 'Workhorse (High Volume, Low Revenue)'
        WHEN ps.total_units < b.avg_units_benchmark AND ps.total_revenue >= b.avg_revenue_benchmark THEN 'Niche / Premium (Low Volume, High Revenue)'
        ELSE 'Underperformer (Low Volume, Low Revenue)'
    END AS product_classification
FROM product_stats ps, benchmarks b
ORDER BY ps.total_revenue DESC
LIMIT 30;


-- ==============================================================================
-- 3. PARETO 80/20 REVENUE ANALYSIS FOR PRODUCTS
-- Finds top products that drive 80% of total company revenue
-- ==============================================================================
WITH product_revenue AS (
    SELECT 
        p.product_id,
        p.product_name,
        c.category_name,
        SUM(oi.total_price) AS product_revenue
    FROM order_items oi
    JOIN products p ON oi.product_id = p.product_id
    JOIN categories c ON p.category_id = c.category_id
    JOIN orders o ON oi.order_id = o.order_id
    WHERE o.order_status = 'Completed'
    GROUP BY p.product_id, p.product_name, c.category_name
),
cumulative_revenue AS (
    SELECT 
        product_id,
        product_name,
        category_name,
        product_revenue,
        SUM(product_revenue) OVER (ORDER BY product_revenue DESC) AS cumulative_rev,
        SUM(product_revenue) OVER () AS total_company_rev
    FROM product_revenue
)
SELECT 
    product_id,
    product_name,
    category_name,
    ROUND(product_revenue::numeric, 2) AS product_revenue,
    ROUND((cumulative_rev * 100.0 / total_company_rev)::numeric, 2) AS cumulative_revenue_share_pct
FROM cumulative_revenue
WHERE (cumulative_rev * 100.0 / total_company_rev) <= 80.0
ORDER BY product_revenue DESC;


-- ==============================================================================
-- 4. CROSS-SELLING & AFFINITY ANALYSIS (Frequently Co-Purchased Product Pairs)
-- Finds products purchased together in the same order
-- ==============================================================================
SELECT 
    p1.product_name AS product_A,
    p2.product_name AS product_B,
    COUNT(*) AS times_bought_together
FROM order_items oi1
JOIN order_items oi2 ON oi1.order_id = oi2.order_id AND oi1.product_id < oi2.product_id
JOIN products p1 ON oi1.product_id = p1.product_id
JOIN products p2 ON oi2.product_id = p2.product_id
JOIN orders o ON oi1.order_id = o.order_id
WHERE o.order_status = 'Completed'
GROUP BY p1.product_name, p2.product_name
ORDER BY times_bought_together DESC
LIMIT 15;
