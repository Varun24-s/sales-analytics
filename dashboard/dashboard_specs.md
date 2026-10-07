# Dashboard Architecture & BI Specifications

## 1. Overview & Purpose
This document provides the blueprint for building an interactive **Sales & Customer Analytics Dashboard** in Power BI, Tableau, or Metabase, backed by the PostgreSQL data warehouse.

---

## 2. Dashboard Layout & Page Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                       NEXCART ANALYTICS PORTAL                              │
├─────────────────────────────────────────────────────────────────────────────┤
│ [PAGE 1] Executive Overview  [PAGE 2] Customer Segmentation & RFM            │
│ [PAGE 3] Cohort Retention    [PAGE 4] Product & Category Performance        │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Page 1: Executive Sales Overview

### Top KPI Summary Cards
* **Total Revenue**: Total monetary value of completed transactions (`$SUM(total_amount)`).
* **Total Orders**: Total count of completed order IDs.
* **Active Customers**: Count of distinct purchasing customers.
* **Average Order Value (AOV)**: Revenue / Orders.
* **Repeat Customer Rate (%)**: `% of customers with > 1 completed purchase`.

### Visual Components
1. **Monthly Revenue & MoM Growth (Combo Chart)**:
   - *Line*: MoM Revenue Growth %
   - *Bar*: Monthly Gross Revenue ($)
2. **Regional Sales Distribution (Choropleth Map / Donut Chart)**:
   - Breakdown of revenue and order volume by Geographic Region.
3. **Order Fulfillment & Status Split (Funnel Chart)**:
   - Completed vs Returned vs Cancelled vs Pending orders.

---

## Page 2: RFM Customer Segmentation Matrix

### Visual Components
1. **RFM Segment Breakdown (TreeMap / Stacked Bar)**:
   - Size by customer count, color by revenue share (Champions, Loyal, At Risk, Hibernating).
2. **Customer Recency vs Monetary Value (Scatter Plot)**:
   - *X-Axis*: Days since last order (Recency)
   - *Y-Axis*: Total Spend ($) (Monetary)
   - *Bubble Size*: Order Frequency
3. **Actionable Segment Table**:
   - Lists top customers in "Can't Lose Them" and "At Risk" with contact email and days inactive for targeted re-engagement campaigns.

---

## Page 3: Cohort Retention Analysis Matrix

### Visual Components
1. **Monthly Cohort Heatmap**:
   - *Rows*: Acquisition Month (Cohort Year-Month)
   - *Columns*: Months elapsed since acquisition (M0, M1, M2, M3, M6, M12)
   - *Values*: Retention Percentage (%) with color gradient scale from dark blue (100%) to light blue (0%).
2. **Cohort Decay Curve (Line Chart)**:
   - Compares retention curves across different acquisition quarters.

---

## Page 4: Product & Category Analytics

### Visual Components
1. **Pareto 80/20 Revenue Chart (Dual Axis Bar & Line)**:
   - *Bar*: Individual Product Revenue ($)
   - *Line*: Cumulative Revenue Share (%)
2. **Product Margin vs Volume Quadrant Matrix**:
   - *X-Axis*: Units Sold
   - *Y-Axis*: Gross Profit Margin %
3. **Top 3 Products per Category (Matrix Grid)**.
