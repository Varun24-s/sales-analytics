# NexCart Sales & Customer Analytics Warehouse 🛒📊
> **Production-Grade SQL Analytics & Data Warehousing Project for Software / Data Analyst Placements**

[![Database](https://img.shields.io/badge/Database-PostgreSQL%2013%2B%20%7C%20SQLite%203-blue.svg)](https://www.postgresql.org/)
[![Python](https://img.shields.io/badge/Python-3.8%2B%20(Zero--Dependency)-green.svg)](https://www.python.org/)
[![SQL Engine](https://img.shields.io/badge/SQL-Advanced%20Window%20Functions%20%26%20CTEs-orange.svg)]()
[![Dataset Size](https://img.shields.io/badge/Dataset-100k%2B%20Orders%20%7C%2050k%2B%20Customers-brightgreen.svg)]()
[![Optimization](https://img.shields.io/badge/Query%20Optimization-EXPLAIN%20ANALYZE%20Tuned-purple.svg)]()

---

## 📌 Project Overview

This repository provides an end-to-end relational data warehouse and analytics platform for **NexCart**, a multi-region e-commerce enterprise operating across 10 global territories.

Designed to demonstrate production-level SQL mastery for software engineering and data analytics roles, this project covers:
* **RFM Customer Segmentation System** (`NTILE(5)` Scoring & Segment Business Playbooks).
* **Monthly Cohort Retention Analysis Matrix** (Tracking retention from Month 0 to Month 12).
* **Financial & Profitability Analytics** (Category performance, Regional AOV, Margin contributions).
* **Time-Series Growth Trends** (YoY, MoM growth rates, rolling 30-day moving averages).
* **PostgreSQL Performance Tuning & Query Optimization** (`EXPLAIN ANALYZE` benchmarks, SARGable rewrites, and Partial B-Tree Indexes).
* **Cross-Platform Compatibility**: Run locally on **Windows**, **macOS**, or **Linux** using **either PostgreSQL or standard Python 3** (zero external dependencies required!).

---

## 🏗️ Data Warehouse Architecture & ERD Diagram

The database utilizes a normalized **3rd Normal Form (3NF)** schema designed for financial accuracy, transactional data integrity, and fast analytical query processing:

```
                       ┌──────────────┐
                       │   regions    │
                       └──────┬───────┘
                              │ 1:N
                              ▼
                       ┌──────────────┐
                       │  customers   │
                       └──────┬───────┘
                              │ 1:N
                              ▼
┌──────────────┐       ┌──────────────┐       ┌──────────────┐
│  categories  │       │    orders    ├──────►│   payments   │
└──────┬───────┘       └──────┬───────┘ 1:1   └──────────────┘
       │ 1:N                  │ 1:N
       ▼                      ▼
┌──────────────┐       ┌──────────────┐
│   products   │◄──────┤ order_items  │
└──────────────┘ 1:N   └──────────────┘
```

### Table Schema Summary
1. **`regions`**: Master table for 10 geographic territories across North America, Europe, and APAC.
2. **`customers`**: Profiles for 50,000 customers, signup timestamps, and geographic mapping.
3. **`categories`**: Taxonomy with parent-child hierarchical support (15 product categories).
4. **`products`**: Catalog of 500 items with SKUs, base prices, and cost margins.
5. **`orders`**: Transaction header log (100,000 orders across 2023–2025).
6. **`order_items`**: Detail line item log with price snapshots (193,145 item records).
7. **`payments`**: Gateway settlement logs, payment methods, and transaction references.

---

## 💻 Step-by-Step Local Setup Guide for ALL Operating Systems

This project supports **two execution modes**:
1. **Mode 1: Zero-Dependency Python Mode** (Runs on Windows, macOS, Linux with **only Python installed**).
2. **Mode 2: Production PostgreSQL Mode** (For running natively with PostgreSQL server & `psql`).

---

### 🚀 Mode 1: Zero-Dependency Python Mode (Windows, macOS, Linux)
> **Use this mode if you only have Python 3 installed** and do not have PostgreSQL installed.

#### Prerequisites
- **Python 3.8+** (Pre-installed on macOS/Linux, available from [python.org](https://www.python.org/) for Windows).

#### Step 1: Clone the Repository
```bash
git clone https://github.com/your-username/sales-customer-analytics.git
cd sales-customer-analytics
```

#### Step 2: Generate the Dataset
Run the data generator to create all CSV files and seed the embedded local database:
- **Windows (Command Prompt / PowerShell)**:
  ```cmd
  python data/generate_dataset.py
  ```
- **macOS / Linux**:
  ```bash
  python3 data/generate_dataset.py
  ```

#### Step 3: Run Any SQL Analytical Script
Use the universal cross-platform SQL query runner `run_sql.py` to execute any `.sql` file:

- **Run RFM Customer Segmentation**:
  ```bash
  python run_sql.py sql/05_rfm_analysis.sql
  ```

- **Run Cohort Retention Analysis**:
  ```bash
  python run_sql.py sql/06_cohort_analysis.sql
  ```

- **Run Basic Revenue Analysis**:
  ```bash
  python run_sql.py sql/03_basic_analysis.sql
  ```

- **Interactive Mode**:
  ```bash
  python run_sql.py
  ```

---

### 🐘 Mode 2: Production PostgreSQL Mode (PostgreSQL 13+)
> **Use this mode for native PostgreSQL execution**, database administration, and `EXPLAIN ANALYZE` query optimization.

#### Prerequisites
- PostgreSQL 13+ installed on your machine.

---

#### 🪟 Windows Setup Instructions

1. **Install PostgreSQL**:
   - Download the Windows installer from [PostgreSQL Official Site](https://www.postgresql.org/download/windows/), OR run in PowerShell:
     ```powershell
     winget install PostgreSQL.PostgreSQL
     ```
2. **Open Command Prompt / PowerShell** as Administrator and navigate to the project directory:
   ```cmd
   cd C:\path\to\sales-customer-analytics
   ```
3. **Generate Dataset**:
   ```cmd
   python data/generate_dataset.py
   ```
4. **Create Database & Run SQL Scripts**:
   ```cmd
   createdb -U postgres sales_warehouse
   psql -U postgres -d sales_warehouse -f schema/01_schema.sql
   psql -U postgres -d sales_warehouse -f data/load_data.sql
   psql -U postgres -d sales_warehouse -f sql/05_rfm_analysis.sql
   ```

---

#### 🍏 macOS Setup Instructions

1. **Install PostgreSQL via Homebrew**:
   ```bash
   brew install postgresql@16
   brew services start postgresql@16
   echo 'export PATH="/opt/homebrew/opt/postgresql@16/bin:$PATH"' >> ~/.zshrc
   source ~/.zshrc
   ```
2. **Generate Dataset & Load into PostgreSQL**:
   ```bash
   python3 data/generate_dataset.py
   createdb sales_warehouse
   psql -d sales_warehouse -f schema/01_schema.sql
   psql -d sales_warehouse -f data/load_data.sql
   psql -d sales_warehouse -f sql/05_rfm_analysis.sql
   ```

---

#### 🐧 Linux (Ubuntu / Debian) Setup Instructions

1. **Install PostgreSQL**:
   ```bash
   sudo apt update
   sudo apt install -y postgresql postgresql-contrib
   sudo systemctl start postgresql
   ```
2. **Setup Database & Execute Scripts**:
   ```bash
   python3 data/generate_dataset.py
   sudo -u postgres createdb sales_warehouse
   sudo -u postgres psql -d sales_warehouse -f schema/01_schema.sql
   sudo -u postgres psql -d sales_warehouse -f data/load_data.sql
   sudo -u postgres psql -d sales_warehouse -f sql/05_rfm_analysis.sql
   ```

---

## 📁 Repository Directory Structure

```
sales-customer-analytics/
├── README.md                           # Master Project Documentation & Local Setup Guide
├── .gitignore                          # Git Exclusion Rules (Bytecode, OS, IDE, Scratch)
├── run_sql.py                          # Universal Cross-Platform SQL Query Runner
├── schema/
│   └── 01_schema.sql                   # Production DDL Table Definitions, PKs, FKs, & Indexes
├── sql/
│   ├── 02_data_quality.sql             # Data Quality Checks, Anomaly & NULL Audits
│   ├── 03_basic_analysis.sql           # Foundational KPIs, Category & Regional Revenues
│   ├── 04_advanced_sql.sql             # CTEs, Window Framing, Moving Averages, Lead/Lag
│   ├── 05_rfm_analysis.sql             # RFM NTILE Scoring & Customer Segmentation System
│   ├── 06_cohort_analysis.sql          # Monthly Cohort Retention Matrix (M0 - M12)
│   ├── 07_customer_analysis.sql        # Repeat Purchase Rates, Churn Risk & Spend Growth
│   ├── 08_product_analysis.sql         # Profit Margins, Pareto 80/20 & Co-Purchase Pairs
│   ├── 09_time_series.sql              # YoY, MoM Growth Rates & Peak Sales Patterns
│   ├── 10_query_optimization.sql       # EXPLAIN ANALYZE Benchmarks & Partial Indexing
│   └── 11_interview_questions.sql      # 20 Interview-Level SQL Questions & Solutions
├── data/
│   ├── generate_dataset.py             # Python Data Generator (100k Orders, 50k Customers)
│   ├── load_data.sql                   # PostgreSQL \copy Bulk Ingestion Script
│   └── sales_warehouse.db              # Embedded Local SQLite Database for Offline Verification
├── dashboard/
│   └── dashboard_specs.md              # BI Dashboard Layout & Visual Blueprint
└── docs/
    ├── rfm_and_cohort_methodology.md   # Mathematical Documentation for RFM & Cohort Matrix
    └── query_optimization_guide.md     # PostgreSQL Query Performance Tuning Guide
```

---

## 📊 Core Analytics & Methodologies

### 1. RFM Customer Segmentation
Using `NTILE(5)` window functions across `recency_days`, `frequency`, and `monetary_value`, customers are classified into 5 quintile ranks (1-5) and mapped into 8 strategic segments:

```sql
WITH raw_rfm AS (
    SELECT 
        c.customer_id,
        c.first_name || ' ' || c.last_name AS customer_name,
        ROUND(EXTRACT(EPOCH FROM ((SELECT MAX(order_date) FROM orders) - MAX(o.order_date)))/86400, 0) AS recency_days,
        COUNT(DISTINCT o.order_id) AS frequency,
        ROUND(SUM(o.total_amount)::numeric, 2) AS monetary_value
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.order_status = 'Completed'
    GROUP BY c.customer_id, customer_name
),
rfm_scores AS (
    SELECT 
        customer_id, customer_name, recency_days, frequency, monetary_value,
        NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
        NTILE(5) OVER (ORDER BY monetary_value ASC) AS m_score
    FROM raw_rfm
)
SELECT 
    customer_id, customer_name,
    (r_score::text || f_score::text || m_score::text) AS rfm_code,
    CASE 
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
        WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3 THEN 'Loyal Customers'
        WHEN r_score <= 2 AND f_score >= 4 AND m_score >= 4 THEN 'Can''t Lose Them'
        WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk'
        ELSE 'Hibernating / Others'
    END AS rfm_segment
FROM rfm_scores;
```

---

### 2. Monthly Cohort Retention Matrix
Computes retention percentage of customer cohorts based on first purchase month:

```sql
WITH customer_first_purchase AS (
    SELECT customer_id, DATE_TRUNC('month', MIN(order_date))::date AS cohort_month
    FROM orders WHERE order_status = 'Completed' GROUP BY customer_id
),
customer_activity AS (
    SELECT 
        o.customer_id, cfp.cohort_month,
        (EXTRACT(YEAR FROM o.order_date) - EXTRACT(YEAR FROM cfp.cohort_month)) * 12 +
        (EXTRACT(MONTH FROM o.order_date) - EXTRACT(MONTH FROM cfp.cohort_month)) AS month_number
    FROM orders o
    JOIN customer_first_purchase cfp ON o.customer_id = cfp.customer_id
    WHERE o.order_status = 'Completed'
)
SELECT 
    TO_CHAR(cohort_month, 'YYYY-MM') AS cohort,
    COUNT(DISTINCT CASE WHEN month_number = 0 THEN customer_id END) AS initial_size,
    ROUND((COUNT(DISTINCT CASE WHEN month_number = 1 THEN customer_id END) * 100.0 / 
           NULLIF(COUNT(DISTINCT CASE WHEN month_number = 0 THEN customer_id END), 0))::numeric, 1) AS m1_retention_pct,
    ROUND((COUNT(DISTINCT CASE WHEN month_number = 3 THEN customer_id END) * 100.0 / 
           NULLIF(COUNT(DISTINCT CASE WHEN month_number = 0 THEN customer_id END), 0))::numeric, 1) AS m3_retention_pct
FROM customer_activity
GROUP BY cohort_month ORDER BY cohort_month;
```

---

## ⚡ Performance Optimization Benchmarks (`EXPLAIN ANALYZE`)

| Query Strategy | Execution Plan | Execution Time | Speedup |
| :--- | :--- | :--- | :--- |
| **Unoptimized** (`TO_CHAR(order_date, 'YYYY-MM')`) | Full Sequential Scan (`Seq Scan`) | `85.4 ms` | Baseline (1x) |
| **SARGable Rewrite** (`order_date >= ... AND < ...`) | Bitmap Index Scan | `17.8 ms` | **4.8x faster** |
| **Composite Partial Index** (`WHERE order_status = 'Completed'`) | Index Only Scan | `3.2 ms` | **26.7x faster** |

---

## 📝 Placement Resume Highlights

* **Built a 3NF E-Commerce Data Warehouse** containing **100,000+ orders** and 50,000+ customer profiles for multi-region sales performance evaluation.
* **Engineered Advanced SQL Analytical Modules** using CTEs, window functions (`NTILE`, `DENSE_RANK`, `LAG`, `LEAD`), and window framing for MoM growth rates and cohort retention tracking.
* **Designed an RFM Customer Segmentation Engine** classifying 50k+ customers into 8 actionable strategic personas (*Champions, At Risk, Can't Lose Them*).
* **Optimized Analytical Queries by 26x** (reducing runtime from 85.4ms to 3.2ms) via `EXPLAIN ANALYZE` diagnostics, refactoring non-SARGable expressions, and building partial B-Tree indexes.

---

## 🎯 Technical Interview Defense Q&A

### Q1: Why store `unit_price` in `order_items` when `products` already has `base_price`?
* **Answer**: Storing `unit_price` on `order_items` preserves **historical transactional integrity**. Product catalog prices change over time; joining on `products.base_price` would retroactively alter past revenue records when product prices are updated today.

### Q2: How do partial indexes improve PostgreSQL performance?
* **Answer**: A partial index indexes only a subset of rows matching a predicate (e.g., `WHERE order_status = 'Completed'`). This reduces index storage footprint on disk, improves cache hit ratios, and eliminates index update overhead during writes on cancelled/pending orders.
# sales-analytics
