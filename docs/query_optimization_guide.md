# PostgreSQL Query Optimization & Performance Tuning Guide

## 1. Fundamentals of Execution Plans (`EXPLAIN ANALYZE`)

When PostgreSQL executes a query, the Query Planner generates an execution plan consisting of tree nodes. Using `EXPLAIN ANALYZE` executes the query and reports actual runtime statistics vs planner estimates.

### Key Metrics to Monitor
* **Cost Range (`cost=start..total`)**: Arbitrary units estimating I/O and CPU work.
* **Actual Time (`actual time=start..total ms`)**: Execution time in milliseconds.
* **Rows examined vs returned**: High discrepancy indicates poor filtering or missing indexes.

---

## 2. Scan Operations Explained

| Scan Type | How it Works | When Used | Performance Impact |
| :--- | :--- | :--- | :--- |
| **Sequential Scan (`Seq Scan`)** | Reads every single block of the table sequentially from disk. | Small tables or unindexed filtered columns. | **Slow on large tables** ($O(N)$ overhead). |
| **Index Scan (`Index Scan`)** | Reads index B-Tree, fetches matching tuple IDs, then fetches table heap rows. | High selectivity queries returning small subset. | **Fast** ($O(\log N)$ B-Tree lookup). |
| **Bitmap Index Scan** | Scans index, builds bitmap of matching pages, then reads heap pages in physical order. | Medium selectivity queries returning multiple matching rows. | **Optimized for disk I/O**. |
| **Index Only Scan** | Fetches required data directly from index without touching table heap. | Covering indexes containing all queried columns. | **Fastest possible I/O**. |

---

## 3. Optimization Anti-Patterns & Refactoring Strategies

### Anti-Pattern 1: Non-SARGable Function Wrappers
* **Bad Practice**: `WHERE TO_CHAR(order_date, 'YYYY-MM') = '2024-11'`
* **Why it Fails**: Functions mask column values; PostgreSQL cannot use a standard B-Tree index on `order_date`.
* **Fix (SARGable)**: `WHERE order_date >= '2024-11-01' AND order_date < '2024-12-01'`

### Anti-Pattern 2: Unindexed Foreign Keys in `JOIN` Operations
* **Bad Practice**: Joining `orders` to `order_items` without index on `order_items.order_id`.
* **Fix**: Create B-Tree index `CREATE INDEX idx_order_items_order ON order_items(order_id);`

### Anti-Pattern 3: Index Over-Saturation
* **Tradeoff**: Adding indexes improves `SELECT` read speed but slows down `INSERT`, `UPDATE`, and `DELETE` writes because indexes must be updated on every write.
* **Fix**: Use **Partial Indexes** (e.g., `WHERE order_status = 'Completed'`) to index only active transactional rows.
