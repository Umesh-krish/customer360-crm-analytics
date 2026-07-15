-- 03_analysis_queries.sql
-- Core CRM models. Work through these top to bottom — each builds on the last.
-- These use JOINs and GROUP BY heavily: this file IS your interview practice.

-- ------------------------------------------------------------
-- 1. Revenue per order (JOIN warm-up)
-- ------------------------------------------------------------
SELECT o.order_id,
       o.customer_id,
       o.order_purchase_timestamp,
       SUM(oi.price) AS order_revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY o.order_id, o.customer_id, o.order_purchase_timestamp;

-- ------------------------------------------------------------
-- 2. Customer-level summary (the base table for everything)
--    Links each order to the real person (customer_unique_id)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS customer_summary AS
SELECT c.customer_unique_id,
       COUNT(DISTINCT o.order_id)              AS total_orders,
       SUM(oi.price)                           AS total_revenue,
       MIN(o.order_purchase_timestamp)         AS first_order,
       MAX(o.order_purchase_timestamp)         AS last_order
FROM customers c
JOIN orders o        ON c.customer_id = o.customer_id
JOIN order_items oi  ON o.order_id = oi.order_id
GROUP BY c.customer_unique_id;

-- ------------------------------------------------------------
-- 3. RFM segmentation
--    Recency = days since last order (vs dataset max date)
--    Frequency = total orders, Monetary = total revenue
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS rfm AS
WITH maxdate AS (
    SELECT MAX(order_purchase_timestamp) AS d FROM orders
),
base AS (
    SELECT cs.customer_unique_id,
           CAST(julianday((SELECT d FROM maxdate)) - julianday(cs.last_order) AS INT) AS recency_days,
           cs.total_orders   AS frequency,
           cs.total_revenue  AS monetary
    FROM customer_summary cs
),
scored AS (
    SELECT *,
           NTILE(4) OVER (ORDER BY recency_days ASC)  AS r_score,  -- recent = high
           NTILE(4) OVER (ORDER BY frequency DESC)    AS f_raw,
           NTILE(4) OVER (ORDER BY monetary DESC)     AS m_raw
    FROM base
)
SELECT customer_unique_id, recency_days, frequency, monetary,
       (5 - r_score) AS r,          -- flip so 4 = best
       (5 - f_raw)  AS f,
       (5 - m_raw)  AS m,
       CASE
         WHEN (5 - r_score) >= 3 AND (5 - m_raw) >= 3 THEN 'Champions'
         WHEN (5 - r_score) >= 3                      THEN 'Recent / Growing'
         WHEN (5 - m_raw)  >= 3                       THEN 'At Risk - High Value'
         ELSE 'Hibernating'
       END AS segment
FROM scored;

-- ------------------------------------------------------------
-- 4. Churn flag (no purchase in 180+ days)
-- ------------------------------------------------------------
SELECT segment,
       COUNT(*) AS customers,
       SUM(CASE WHEN recency_days > 180 THEN 1 ELSE 0 END) AS churned,
       ROUND(100.0 * SUM(CASE WHEN recency_days > 180 THEN 1 ELSE 0 END) / COUNT(*), 1) AS churn_pct
FROM rfm
GROUP BY segment
ORDER BY churn_pct DESC;

-- ------------------------------------------------------------
-- 5. Simple CLV (historic): revenue per customer, ranked
-- ------------------------------------------------------------
SELECT customer_unique_id,
       monetary AS lifetime_value,
       frequency,
       ROUND(monetary / frequency, 2) AS avg_order_value
FROM rfm
ORDER BY lifetime_value DESC
LIMIT 100;

-- ------------------------------------------------------------
-- 6. Monthly cohort retention (advanced — window functions)
--    % of each signup-month cohort that ordered again later
-- ------------------------------------------------------------
WITH firsts AS (
    SELECT customer_unique_id,
           strftime('%Y-%m', first_order) AS cohort_month
    FROM customer_summary
),
repeats AS (
    SELECT cs.customer_unique_id,
           CASE WHEN cs.total_orders > 1 THEN 1 ELSE 0 END AS repeated
    FROM customer_summary cs
)
SELECT f.cohort_month,
       COUNT(*)                          AS cohort_size,
       SUM(r.repeated)                   AS repeat_buyers,
       ROUND(100.0 * SUM(r.repeated) / COUNT(*), 1) AS repeat_rate_pct
FROM firsts f
JOIN repeats r ON f.customer_unique_id = r.customer_unique_id
GROUP BY f.cohort_month
ORDER BY f.cohort_month;
