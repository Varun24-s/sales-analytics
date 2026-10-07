-- ==============================================================================
-- PROJECT: Sales & Customer Analytics Warehouse
-- FILE: 05_rfm_analysis.sql
-- DESCRIPTION: RFM (Recency, Frequency, Monetary) Customer Segmentation Framework
-- AUTHOR: Student (Placement Portfolio Project)
-- ==============================================================================

-- ==============================================================================
-- STEP 1: CALCULATE RAW RFM METRICS PER CUSTOMER
-- Recency  = Days since last purchase (relative to max dataset date)
-- Frequency = Total count of completed orders
-- Monetary  = Total sum of spend across completed orders
-- ==============================================================================

WITH max_date_cte AS (
    SELECT MAX(order_date) AS max_order_date FROM orders
),
raw_rfm AS (
    SELECT 
        c.customer_id,
        c.first_name || ' ' || c.last_name AS customer_name,
        c.email,
        r.region_name,
        ROUND(EXTRACT(EPOCH FROM ((SELECT max_order_date FROM max_date_cte) - MAX(o.order_date)))/86400, 0) AS recency_days,
        COUNT(DISTINCT o.order_id) AS frequency,
        ROUND(SUM(o.total_amount)::numeric, 2) AS monetary_value
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN regions r ON c.region_id = r.region_id
    WHERE o.order_status = 'Completed'
    GROUP BY c.customer_id, customer_name, c.email, r.region_name
),

-- ==============================================================================
-- STEP 2: ASSIGN RFM SCORES (1 to 5) USING NTILE() WINDOW FUNCTION
-- Note: Recency is inverted (lower days = higher score 5)
-- ==============================================================================
rfm_scores AS (
    SELECT 
        customer_id,
        customer_name,
        email,
        region_name,
        recency_days,
        frequency,
        monetary_value,
        NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score, -- inverted: newest order gets 5
        NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
        NTILE(5) OVER (ORDER BY monetary_value ASC) AS m_score
    FROM raw_rfm
),

-- ==============================================================================
-- STEP 3: CONCATENATE RFM SCORE AND MAP TO STRATEGIC BUSINESS SEGMENTS
-- ==============================================================================
rfm_segmented AS (
    SELECT 
        customer_id,
        customer_name,
        email,
        region_name,
        recency_days,
        frequency,
        monetary_value,
        r_score,
        f_score,
        m_score,
        (r_score::text || f_score::text || m_score::text) AS rfm_combined_code,
        CASE 
            WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
            WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3 THEN 'Loyal Customers'
            WHEN r_score >= 4 AND f_score <= 2 THEN 'New / Recent Customers'
            WHEN r_score >= 3 AND f_score >= 1 AND m_score >= 4 THEN 'Promising / High Spenders'
            WHEN r_score = 3 AND f_score <= 2 THEN 'Potential Loyalists'
            WHEN r_score <= 2 AND f_score >= 4 AND m_score >= 4 THEN 'Can''t Lose Them'
            WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk'
            WHEN r_score <= 2 AND f_score <= 2 AND m_score <= 2 THEN 'Hibernating / Lost'
            ELSE 'Others / Needs Attention'
        END AS rfm_segment
    FROM rfm_scores
)

-- Save result view / Select for analysis
SELECT 
    customer_id,
    customer_name,
    email,
    region_name,
    recency_days,
    frequency,
    monetary_value,
    r_score,
    f_score,
    m_score,
    rfm_combined_code,
    rfm_segment
FROM rfm_segmented
ORDER BY monetary_value DESC
LIMIT 50;


-- ==============================================================================
-- EXECUTIVE SUMMARY: RFM SEGMENT AGGREGATION & ACTIONABLE STRATEGY
-- ==============================================================================
WITH max_date_cte AS (
    SELECT MAX(order_date) AS max_order_date FROM orders
),
raw_rfm AS (
    SELECT 
        c.customer_id,
        ROUND(EXTRACT(EPOCH FROM ((SELECT max_order_date FROM max_date_cte) - MAX(o.order_date)))/86400, 0) AS recency_days,
        COUNT(DISTINCT o.order_id) AS frequency,
        ROUND(SUM(o.total_amount)::numeric, 2) AS monetary_value
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.order_status = 'Completed'
    GROUP BY c.customer_id
),
rfm_scores AS (
    SELECT 
        customer_id,
        recency_days,
        frequency,
        monetary_value,
        NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
        NTILE(5) OVER (ORDER BY monetary_value ASC) AS m_score
    FROM raw_rfm
),
rfm_segmented AS (
    SELECT 
        customer_id,
        recency_days,
        frequency,
        monetary_value,
        CASE 
            WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
            WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3 THEN 'Loyal Customers'
            WHEN r_score >= 4 AND f_score <= 2 THEN 'New / Recent Customers'
            WHEN r_score >= 3 AND f_score >= 1 AND m_score >= 4 THEN 'Promising / High Spenders'
            WHEN r_score = 3 AND f_score <= 2 THEN 'Potential Loyalists'
            WHEN r_score <= 2 AND f_score >= 4 AND m_score >= 4 THEN 'Can''t Lose Them'
            WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk'
            WHEN r_score <= 2 AND f_score <= 2 AND m_score <= 2 THEN 'Hibernating / Lost'
            ELSE 'Others / Needs Attention'
        END AS rfm_segment
    FROM rfm_scores
)
SELECT 
    rfm_segment,
    COUNT(*) AS total_customers,
    ROUND((COUNT(*) * 100.0 / SUM(COUNT(*)) OVER())::numeric, 2) AS customer_share_pct,
    ROUND(AVG(recency_days)::numeric, 1) AS avg_recency_days,
    ROUND(AVG(frequency)::numeric, 1) AS avg_frequency_orders,
    ROUND(AVG(monetary_value)::numeric, 2) AS avg_monetary_spend,
    ROUND(SUM(monetary_value)::numeric, 2) AS total_segment_revenue,
    ROUND((SUM(monetary_value) * 100.0 / SUM(SUM(monetary_value)) OVER())::numeric, 2) AS revenue_share_pct
FROM rfm_segmented
GROUP BY rfm_segment
ORDER BY total_segment_revenue DESC;
