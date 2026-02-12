/*
Task: Customer Engagement & Store Performance Analysis
Background: Management wants to understand customer loyalty and how it translates to store performance.
They are particularly interested in the relationship between how long customers stay with us and how much they spend.
Your Mission: Build two key metrics to analyze customer engagement and value.

Metric 1: Customer Tenure Analysis
Objective: Identify how long customers have been active with the business and categorize them based on their loyalty.
Calculation:
Customer Tenure = Number of days between their first rental and last rental
Engagement Tier:
'High' - Tenure > 300 days
'Medium' - Tenure between 150 and 300 days
'Low' - Tenure < 150 days

    Required Out put:
    customer_id
    first_rental_date
    last_rental_date
    tenure_days
    engagement_tier


Metric 2: Store Performance by Customer Value
Objective: Analyze which stores are retaining the most valuable customers.
Calculation:
Total Customer Value = Sum of all payments made by each customer
Average Customer Value per Store = Average of Total Customer Value for each store

Required Out put:
store_id
total_customers (count of unique customers)
avg_customer_value (average spending per customer at that store)
total_revenue (sum of all payments from that store's customers)

Final Integration: Create a summary that shows for each store:
The distribution of customer engagement tiers (High/Medium/Low)
The average customer value
The total revenue
*/
     WITH base_rental AS (SELECT r.customer_id, c.store_id, r.rental_id, r.rental_date::date, p.amount
                     FROM rental r
                              JOIN staff s ON r.staff_id = s.staff_id
                              JOIN customer c ON r.customer_id = c.customer_id
                              LEFT JOIN payment p ON r.rental_id = p.rental_id
                     WHERE r.rental_date BETWEEN '2005-01-01' AND '2005-12-31'),
     metric_01 AS (SELECT br.customer_id,
                          br.store_id,
                          MIN(br.rental_date)                       first_rental_date,
                          MAX(br.rental_date)                       latest_rental_date,
                          MAX(br.rental_date) - MIN(br.rental_date) tenure,
                          CASE
                              WHEN MAX(br.rental_date) - MIN(br.rental_date) > 300 THEN 'High'
                              WHEN MAX(br.rental_date) - MIN(br.rental_date) > 150 THEN 'Medium'
                              ELSE 'Low'
                              END AS                                engagement
                   FROM base_rental br
                   GROUP BY br.customer_id, br.store_id),
     metric_02 AS (SELECT br.store_id,
                          COUNT(distinct br.customer_id)                                       total_customers,
                          sum(br.amount)                                                       total_revenue,
                          ROUND(sum(br.amount) / NULLIF(COUNT(distinct br.customer_id), 0), 2) avg_spent_per_customer
                   FROM base_rental br
                   GROUP BY br.store_id),
     store_wise_engagement_distribution AS (SELECT m1.store_id,
                                                   SUM(CASE WHEN m1.engagement = 'High' THEN 1 ELSE 0 END)   AS high_engaged_customers,
                                                   SUM(CASE WHEN m1.engagement = 'Medium' THEN 1 ELSE 0 END) AS Medium_engaged_customers,
                                                   SUM(CASE WHEN m1.engagement = 'Low' THEN 1 ELSE 0 END)    AS Low_engaged_customers
                                            FROM metric_01 m1
                                            GROUP BY m1.store_id)
SELECT DISTINCT m2.store_id,
                m2.total_customers,
                m2.total_revenue,
                m2.avg_spent_per_customer,
                swed.high_engaged_customers,
                swed.Medium_engaged_customers,
                swed.Low_engaged_customers,
                ROUND(COALESCE(m2.total_customers, 0) / NULLIF((sum(m2.total_customers) OVER ()), 0),
                      2)                                                                             AS customer_wise_market_share,
                ROUND(COALESCE(m2.total_revenue, 0) / NULLIF((sum(m2.total_revenue) OVER ()), 0),
                      2)                                                                             AS revenue_wise_market_share
FROM metric_02 m2
         JOIN store_wise_engagement_distribution swed ON m2.store_id = swed.store_id;

-- [
--   {
--     "QUERY PLAN": "Planning Time: 1.232 ms"
--   },
--   {
--     "QUERY PLAN": "Execution Time: 66.098 ms"
--   }
-- ]