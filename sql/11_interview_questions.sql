-- ==============================================================================
-- PROJECT: Sales & Customer Analytics Warehouse
-- FILE: 11_interview_questions.sql
-- DESCRIPTION: 20 Interview-Level SQL Questions with Step-by-Step PostgreSQL Solutions
-- AUTHOR: Student (Placement Portfolio Project)
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- Q1: Find the top 10 customers by lifetime completed revenue.
-- ------------------------------------------------------------------------------
SELECT 
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    c.email,
    ROUND(SUM(o.total_amount)::numeric, 2) AS lifetime_revenue
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_status = 'Completed'
GROUP BY c.customer_id, customer_name, c.email
ORDER BY lifetime_revenue DESC
LIMIT 10;


-- ------------------------------------------------------------------------------
-- Q2: Find the 2nd highest spending customer in every geographic region.
-- ------------------------------------------------------------------------------
WITH customer_regional_spend AS (
    SELECT 
        r.region_name,
        c.customer_id,
        c.first_name || ' ' || c.last_name AS customer_name,
        SUM(o.total_amount) AS total_spend,
        DENSE_RANK() OVER (
            PARTITION BY r.region_name 
            ORDER BY SUM(o.total_amount) DESC
        ) AS spend_rank
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN regions r ON c.region_id = r.region_id
    WHERE o.order_status = 'Completed'
    GROUP BY r.region_name, c.customer_id, customer_name
)
SELECT 
    region_name,
    customer_id,
    customer_name,
    ROUND(total_spend::numeric, 2) AS total_spend
FROM customer_regional_spend
WHERE spend_rank = 2
ORDER BY region_name;


-- ------------------------------------------------------------------------------
-- Q3: Find customers whose latest order value is higher than their historical average order value.
-- ------------------------------------------------------------------------------
WITH customer_order_analysis AS (
    SELECT 
        customer_id,
        order_id,
        order_date,
        total_amount,
        AVG(total_amount) OVER (PARTITION BY customer_id) AS avg_historical_aov,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date DESC) AS recency_rank
    FROM orders
    WHERE order_status = 'Completed'
)
SELECT 
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    coa.order_id AS latest_order_id,
    ROUND(coa.total_amount::numeric, 2) AS latest_order_amount,
    ROUND(coa.avg_historical_aov::numeric, 2) AS customer_avg_aov,
    ROUND((coa.total_amount - coa.avg_historical_aov)::numeric, 2) AS delta_above_avg
FROM customer_order_analysis coa
JOIN customers c ON coa.customer_id = c.customer_id
WHERE coa.recency_rank = 1 
  AND coa.total_amount > coa.avg_historical_aov
ORDER BY delta_above_avg DESC
LIMIT 20;


-- ------------------------------------------------------------------------------
-- Q4: Find customers who placed orders in 3 consecutive calendar months.
-- ------------------------------------------------------------------------------
WITH monthly_orders AS (
    SELECT DISTINCT
        customer_id,
        DATE_TRUNC('month', order_date)::date AS order_month
    FROM orders
    WHERE order_status = 'Completed'
),
consecutive_analysis AS (
    SELECT 
        customer_id,
        order_month,
        LAG(order_month, 1) OVER (PARTITION BY customer_id ORDER BY order_month) AS prev_month_1,
        LAG(order_month, 2) OVER (PARTITION BY customer_id ORDER BY order_month) AS prev_month_2
    FROM monthly_orders
)
SELECT DISTINCT
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    c.email
FROM consecutive_analysis ca
JOIN customers c ON ca.customer_id = c.customer_id
WHERE ca.prev_month_1 = ca.order_month - INTERVAL '1 month'
  AND ca.prev_month_2 = ca.order_month - INTERVAL '2 months'
ORDER BY c.customer_id;


-- ------------------------------------------------------------------------------
-- Q5: Find the longest gap (in days) between any two consecutive purchases for each customer.
-- ------------------------------------------------------------------------------
WITH customer_order_gaps AS (
    SELECT 
        customer_id,
        order_date,
        LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS prev_order_date,
        EXTRACT(EPOCH FROM (order_date - LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date)))/86400 AS gap_days
    FROM orders
    WHERE order_status = 'Completed'
)
SELECT 
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    ROUND(MAX(gap_days)::numeric, 1) AS longest_gap_days
FROM customer_order_gaps cog
JOIN customers c ON cog.customer_id = c.customer_id
WHERE gap_days IS NOT NULL
GROUP BY c.customer_id, customer_name
ORDER BY longest_gap_days DESC
LIMIT 20;


-- ------------------------------------------------------------------------------
-- Q6: Find customers who have NEVER purchased items from the 'Electronics' category.
-- ------------------------------------------------------------------------------
SELECT 
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    c.email
FROM customers c
WHERE c.customer_id NOT IN (
    SELECT DISTINCT o.customer_id
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    JOIN categories cat ON p.category_id = cat.category_id
    WHERE cat.category_name LIKE '%Electronics%' OR cat.category_name LIKE '%Smartphones%'
)
LIMIT 20;


-- ------------------------------------------------------------------------------
-- Q7: Find products that account for the top 80% of total company sales revenue (Pareto Analysis).
-- ------------------------------------------------------------------------------
WITH product_rev AS (
    SELECT 
        p.product_id,
        p.product_name,
        SUM(oi.total_price) AS rev
    FROM order_items oi
    JOIN products p ON oi.product_id = p.product_id
    JOIN orders o ON oi.order_id = o.order_id
    WHERE o.order_status = 'Completed'
    GROUP BY p.product_id, p.product_name
),
cumulative_rev AS (
    SELECT 
        product_id,
        product_name,
        rev,
        SUM(rev) OVER (ORDER BY rev DESC) AS cum_rev,
        SUM(rev) OVER () AS total_rev
    FROM product_rev
)
SELECT 
    product_id,
    product_name,
    ROUND(rev::numeric, 2) AS product_revenue,
    ROUND((cum_rev * 100.0 / total_rev)::numeric, 2) AS cum_rev_pct
FROM cumulative_rev
WHERE (cum_rev * 100.0 / total_rev) <= 80.0
ORDER BY rev DESC;


-- ------------------------------------------------------------------------------
-- Q8: Find each customer's first purchase date and latest purchase date side by side.
-- ------------------------------------------------------------------------------
SELECT 
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    MIN(o.order_date)::date AS first_purchase_date,
    MAX(o.order_date)::date AS latest_purchase_date,
    COUNT(o.order_id) AS total_orders
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_status = 'Completed'
GROUP BY c.customer_id, customer_name
ORDER BY total_orders DESC
LIMIT 20;


-- ------------------------------------------------------------------------------
-- Q9: Find customers whose spending increased for 3 consecutive completed orders.
-- ------------------------------------------------------------------------------
WITH order_sequence AS (
    SELECT 
        customer_id,
        order_id,
        order_date,
        total_amount,
        LAG(total_amount, 1) OVER (PARTITION BY customer_id ORDER BY order_date) AS prev_1,
        LAG(total_amount, 2) OVER (PARTITION BY customer_id ORDER BY order_date) AS prev_2
    FROM orders
    WHERE order_status = 'Completed'
)
SELECT DISTINCT
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    c.email
FROM order_sequence os
JOIN customers c ON os.customer_id = c.customer_id
WHERE os.prev_2 IS NOT NULL 
  AND os.prev_1 > os.prev_2 
  AND os.total_amount > os.prev_1;


-- ------------------------------------------------------------------------------
-- Q10: Find the #1 best-selling product in each category for every calendar year.
-- ------------------------------------------------------------------------------
WITH category_yearly_products AS (
    SELECT 
        EXTRACT(YEAR FROM o.order_date) AS sales_year,
        c.category_name,
        p.product_name,
        SUM(oi.total_price) AS product_sales,
        DENSE_RANK() OVER (
            PARTITION BY EXTRACT(YEAR FROM o.order_date), c.category_name 
            ORDER BY SUM(oi.total_price) DESC
        ) AS rank_in_cat
    FROM order_items oi
    JOIN products p ON oi.product_id = p.product_id
    JOIN categories c ON p.category_id = c.category_id
    JOIN orders o ON oi.order_id = o.order_id
    WHERE o.order_status = 'Completed'
    GROUP BY EXTRACT(YEAR FROM o.order_date), c.category_name, p.product_name
)
SELECT 
    sales_year,
    category_name,
    product_name,
    ROUND(product_sales::numeric, 2) AS total_sales
FROM category_yearly_products
WHERE rank_in_cat = 1
ORDER BY sales_year, category_name;


-- ------------------------------------------------------------------------------
-- Q11: Calculate the average order value (AOV) growth rate month-over-month.
-- ------------------------------------------------------------------------------
WITH monthly_aov AS (
    SELECT 
        DATE_TRUNC('month', order_date)::date AS sales_month,
        AVG(total_amount) AS current_aov
    FROM orders
    WHERE order_status = 'Completed'
    GROUP BY DATE_TRUNC('month', order_date)::date
)
SELECT 
    TO_CHAR(sales_month, 'YYYY-MM') AS month_label,
    ROUND(current_aov::numeric, 2) AS current_aov,
    ROUND(LAG(current_aov) OVER (ORDER BY sales_month)::numeric, 2) AS prev_month_aov,
    ROUND(
        ((current_aov - LAG(current_aov) OVER (ORDER BY sales_month)) * 100.0 / 
        NULLIF(LAG(current_aov) OVER (ORDER BY sales_month), 0))::numeric, 
        2
    ) AS aov_mom_growth_pct
FROM monthly_aov;


-- ------------------------------------------------------------------------------
-- Q12: Find orders containing products from more than 3 distinct product categories.
-- ------------------------------------------------------------------------------
SELECT 
    o.order_id,
    o.customer_id,
    o.order_date::date,
    COUNT(DISTINCT p.category_id) AS distinct_category_count,
    ROUND(o.total_amount::numeric, 2) AS order_total
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
GROUP BY o.order_id, o.customer_id, o.order_date, o.total_amount
HAVING COUNT(DISTINCT p.category_id) >= 3
ORDER BY distinct_category_count DESC
LIMIT 20;


-- ------------------------------------------------------------------------------
-- Q13: Calculate the customer retention rate for customers acquired in 2023.
-- ------------------------------------------------------------------------------
WITH cohort_2023 AS (
    SELECT customer_id
    FROM customers
    WHERE signup_date >= '2023-01-01' AND signup_date < '2024-01-01'
),
retained_2024 AS (
    SELECT DISTINCT customer_id
    FROM orders
    WHERE customer_id IN (SELECT customer_id FROM cohort_2023)
      AND order_date >= '2024-01-01' AND order_date < '2025-01-01'
      AND order_status = 'Completed'
)
SELECT 
    (SELECT COUNT(*) FROM cohort_2023) AS total_acquired_2023,
    (SELECT COUNT(*) FROM retained_2024) AS active_in_2024,
    ROUND(((SELECT COUNT(*) FROM retained_2024) * 100.0 / (SELECT COUNT(*) FROM cohort_2023))::numeric, 2) AS retention_rate_pct;


-- ------------------------------------------------------------------------------
-- Q14: Find products that have NEVER had a return or cancellation.
-- ------------------------------------------------------------------------------
SELECT 
    p.product_id,
    p.sku,
    p.product_name,
    COUNT(oi.order_item_id) AS total_successful_sales
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
JOIN orders o ON oi.order_id = o.order_id
WHERE p.product_id NOT IN (
    SELECT DISTINCT oi_sub.product_id
    FROM order_items oi_sub
    JOIN orders o_sub ON oi_sub.order_id = o_sub.order_id
    WHERE o_sub.order_status IN ('Returned', 'Cancelled')
)
GROUP BY p.product_id, p.sku, p.product_name
HAVING COUNT(oi.order_item_id) > 10
ORDER BY total_successful_sales DESC
LIMIT 20;


-- ------------------------------------------------------------------------------
-- Q15: Find the median order value across all completed transactions.
-- ------------------------------------------------------------------------------
SELECT 
    ROUND(PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY total_amount)::numeric, 2) AS median_order_value,
    ROUND(AVG(total_amount)::numeric, 2) AS mean_order_value
FROM orders
WHERE order_status = 'Completed';


-- ------------------------------------------------------------------------------
-- Q16: Find customers whose total discounts received exceed $100.
-- ------------------------------------------------------------------------------
SELECT 
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    c.email,
    ROUND(SUM(oi.discount_amount)::numeric, 2) AS total_discount_received
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'Completed'
GROUP BY c.customer_id, customer_name, c.email
HAVING SUM(oi.discount_amount) > 100
ORDER BY total_discount_received DESC
LIMIT 20;


-- ------------------------------------------------------------------------------
-- Q17: Find geographic regions with a return rate higher than 10%.
-- ------------------------------------------------------------------------------
SELECT 
    r.region_name,
    COUNT(o.order_id) AS total_orders,
    COUNT(CASE WHEN o.order_status = 'Returned' THEN 1 END) AS returned_orders,
    ROUND((COUNT(CASE WHEN o.order_status = 'Returned' THEN 1 END) * 100.0 / COUNT(o.order_id))::numeric, 2) AS return_rate_pct
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN regions r ON c.region_id = r.region_id
GROUP BY r.region_name
HAVING (COUNT(CASE WHEN o.order_status = 'Returned' THEN 1 END) * 100.0 / COUNT(o.order_id)) > 10.0
ORDER BY return_rate_pct DESC;


-- ------------------------------------------------------------------------------
-- Q18: Calculate the 3-month moving average of monthly customer signups.
-- ------------------------------------------------------------------------------
WITH monthly_signups AS (
    SELECT 
        DATE_TRUNC('month', signup_date)::date AS signup_month,
        COUNT(customer_id) AS new_signups
    FROM customers
    GROUP BY DATE_TRUNC('month', signup_date)::date
)
SELECT 
    TO_CHAR(signup_month, 'YYYY-MM') AS month_label,
    new_signups,
    ROUND(AVG(new_signups) OVER (
        ORDER BY signup_month 
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    )::numeric, 1) AS rolling_3month_avg_signups
FROM monthly_signups;


-- ------------------------------------------------------------------------------
-- Q19: Find the most popular payment method per customer segment.
-- ------------------------------------------------------------------------------
WITH segment_payments AS (
    SELECT 
        c.customer_segment,
        p.payment_method,
        COUNT(p.payment_id) AS tx_count,
        DENSE_RANK() OVER (
            PARTITION BY c.customer_segment 
            ORDER BY COUNT(p.payment_id) DESC
        ) AS rank_in_segment
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN payments p ON o.order_id = p.order_id
    GROUP BY c.customer_segment, p.payment_method
)
SELECT 
    customer_segment,
    payment_method AS preferred_payment_method,
    tx_count AS total_transactions
FROM segment_payments
WHERE rank_in_segment = 1;


-- ------------------------------------------------------------------------------
-- Q20: Find products that generated revenue in 2023 but ZERO revenue in 2025 (Lapsed Products).
-- ------------------------------------------------------------------------------
WITH prod_2023 AS (
    SELECT DISTINCT oi.product_id
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.order_id
    WHERE o.order_date >= '2023-01-01' AND o.order_date < '2024-01-01'
      AND o.order_status = 'Completed'
),
prod_2025 AS (
    SELECT DISTINCT oi.product_id
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.order_id
    WHERE o.order_date >= '2025-01-01' AND o.order_date < '2026-01-01'
      AND o.order_status = 'Completed'
)
SELECT 
    p.product_id,
    p.sku,
    p.product_name,
    c.category_name
FROM prod_2023 p23
JOIN products p ON p23.product_id = p.product_id
JOIN categories c ON p.category_id = c.category_id
LEFT JOIN prod_2025 p25 ON p23.product_id = p25.product_id
WHERE p25.product_id IS NULL
ORDER BY p.product_id;
