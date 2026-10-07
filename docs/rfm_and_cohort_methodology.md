# Advanced Analytical Methodologies: RFM & Cohort Analysis

## 1. RFM Customer Segmentation Methodology

### Concept & Rationale
RFM (Recency, Frequency, Monetary) is a data-driven customer segmentation technique used to categorize buyers based on historical purchasing behavior:
* **Recency ($R$)**: How recently did the customer purchase? (Fewer days ago = higher value).
* **Frequency ($F$)**: How often do they purchase? (More orders = higher engagement).
* **Monetary Value ($M$)**: How much money do they spend? (Higher spend = higher business impact).

---

### Scoring Mechanics (PostgreSQL NTILE quintiles)
We use `NTILE(5)` window functions to rank customers into 5 equal quintile buckets (scores 1 through 5):

$$\text{R\_Score} = \text{NTILE}(5) \text{ OVER (ORDER BY Recency\_Days DESC)}$$
$$\text{F\_Score} = \text{NTILE}(5) \text{ OVER (ORDER BY Frequency ASC)}$$
$$\text{M\_Score} = \text{NTILE}(5) \text{ OVER (ORDER BY Monetary\_Value ASC)}$$

---

### Strategic Segment Definitions & Marketing Playbooks

| Segment Name | RFM Criteria | Business Description | Recommended Action |
| :--- | :--- | :--- | :--- |
| **Champions** | R ≥ 4, F ≥ 4, M ≥ 4 | Bought recently, purchase often, spend most. | VIP early access, loyalty rewards, brand advocates. |
| **Loyal Customers** | R ≥ 3, F ≥ 3, M ≥ 3 | Responsive buyers with steady frequency. | Cross-sell higher value items, request reviews. |
| **Can't Lose Them** | R ≤ 2, F ≥ 4, M ≥ 4 | High value, frequent buyers who stopped buying. | Personal outreach, win-back discounts. |
| **At Risk** | R ≤ 2, F ≥ 3, M ≥ 3 | Spent big money in the past, but inactive. | Re-engagement email series, limited-time offers. |
| **New Customers** | R ≥ 4, F ≤ 2 | Recent buyers with low overall count. | Welcome onboarding series, product tutorials. |
| **Hibernating / Lost** | R ≤ 2, F ≤ 2, M ≤ 2 | Lowest scores across all metrics. | Ignore or minimal automated win-back campaign. |

---

## 2. Cohort Retention Matrix Methodology

### Concept & Rationale
Cohort analysis groups customers based on a shared initial characteristic—in this case, the **month of their first purchase**—and tracks their activity over time.

This isolates customer retention from new customer acquisition growth, answering: *Are we leaking existing customers over time?*

---

### Step-by-Step SQL Calculation Logic

1. **Cohort Assignment**: Find `MIN(order_date)` for each customer and truncate to `YYYY-MM`.
2. **Activity Tracing**: Extract all subsequent completed order dates for the customer.
3. **Month Offset Calculation**: 

$$\Delta \text{Months} = (\text{Year}_{\text{activity}} - \text{Year}_{\text{cohort}}) \times 12 + (\text{Month}_{\text{activity}} - \text{Month}_{\text{cohort}})$$

4. **Retention Rate Calculation**:

$$\text{Retention Rate}_{m} = \frac{\text{Active Customers in Month } m}{\text{Initial Cohort Size (Month 0)}} \times 100\%$$
