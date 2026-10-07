-- ==============================================================================
-- PROJECT: Sales & Customer Analytics Warehouse
-- FILE: 06_cohort_analysis.sql
-- DESCRIPTION: Monthly Cohort-Based Customer Retention Matrix
-- AUTHOR: Student (Placement Portfolio Project)
-- ==============================================================================

-- ==============================================================================
-- STEP 1: DEFINE CUSTOMER FIRST PURCHASE MONTH (COHORT MONTH)
-- ==============================================================================
WITH customer_first_purchase AS (
    SELECT 
        customer_id,
        DATE_TRUNC('month', MIN(order_date))::date AS cohort_month
    FROM orders
    WHERE order_status = 'Completed'
    GROUP BY customer_id
),

-- ==============================================================================
-- STEP 2: TRACK ALL SUBSEQUENT PURCHASES & CALCULATE MONTH DIFFERENCE
-- ==============================================================================
customer_activity AS (
    SELECT 
        o.customer_id,
        cfp.cohort_month,
        DATE_TRUNC('month', o.order_date)::date AS activity_month,
        (EXTRACT(YEAR FROM o.order_date) - EXTRACT(YEAR FROM cfp.cohort_month)) * 12 +
        (EXTRACT(MONTH FROM o.order_date) - EXTRACT(MONTH FROM cfp.cohort_month)) AS month_number
    FROM orders o
    JOIN customer_first_purchase cfp ON o.customer_id = cfp.customer_id
    WHERE o.order_status = 'Completed'
),

-- ==============================================================================
-- STEP 3: AGGREGATE UNIQUE ACTIVE CUSTOMERS PER COHORT PER MONTH NUMBER
-- ==============================================================================
cohort_counts AS (
    SELECT 
        cohort_month,
        month_number,
        COUNT(DISTINCT customer_id) AS active_customers
    FROM customer_activity
    GROUP BY cohort_month, month_number
),

-- ==============================================================================
-- STEP 4: GET INITIAL COHORT SIZE (MONTH 0 ACTIVE CUSTOMERS)
-- ==============================================================================
cohort_sizes AS (
    SELECT 
        cohort_month,
        active_customers AS initial_cohort_size
    FROM cohort_counts
    WHERE month_number = 0
)

-- ==============================================================================
-- STEP 5: CALCULATE RETENTION PERCENTAGES & PIVOT MATRIX
-- Outputting Cohort Retention Rates across Months 0 to 6
-- ==============================================================================
SELECT 
    TO_CHAR(cc.cohort_month, 'YYYY-MM') AS cohort,
    cs.initial_cohort_size AS cohort_size,
    MAX(CASE WHEN cc.month_number = 0 THEN ROUND((cc.active_customers * 100.0 / cs.initial_cohort_size)::numeric, 1) END) AS m0,
    MAX(CASE WHEN cc.month_number = 1 THEN ROUND((cc.active_customers * 100.0 / cs.initial_cohort_size)::numeric, 1) END) AS m1,
    MAX(CASE WHEN cc.month_number = 2 THEN ROUND((cc.active_customers * 100.0 / cs.initial_cohort_size)::numeric, 1) END) AS m2,
    MAX(CASE WHEN cc.month_number = 3 THEN ROUND((cc.active_customers * 100.0 / cs.initial_cohort_size)::numeric, 1) END) AS m3,
    MAX(CASE WHEN cc.month_number = 4 THEN ROUND((cc.active_customers * 100.0 / cs.initial_cohort_size)::numeric, 1) END) AS m4,
    MAX(CASE WHEN cc.month_number = 5 THEN ROUND((cc.active_customers * 100.0 / cs.initial_cohort_size)::numeric, 1) END) AS m5,
    MAX(CASE WHEN cc.month_number = 6 THEN ROUND((cc.active_customers * 100.0 / cs.initial_cohort_size)::numeric, 1) END) AS m6,
    MAX(CASE WHEN cc.month_number = 12 THEN ROUND((cc.active_customers * 100.0 / cs.initial_cohort_size)::numeric, 1) END) AS m12
FROM cohort_counts cc
JOIN cohort_sizes cs ON cc.cohort_month = cs.cohort_month
GROUP BY cc.cohort_month, cs.initial_cohort_size
ORDER BY cc.cohort_month;
