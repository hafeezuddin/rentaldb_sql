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

Required Output:
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

Required Output:
store_id
total_customers (count of unique customers)
avg_customer_value (average spending per customer at that store)
total_revenue (sum of all payments from that store's customers)

Final Integration: Create a summary that shows for each store:
The distribution of customer engagement tiers (High/Medium/Low)
The average customer value
The total revenue
*/

--CTE to label customers with engagement tier
WITH engagement_metric AS (
    SELECT sq1.customer_id, sq1.store_id,
        sq1.first_rental_date::date, 
        sq1.last_rental_date::date, 
        EXTRACT(DAY FROM sq1.tenure_days) AS tenure,
        CASE 
            WHEN EXTRACT(DAY FROM sq1.tenure_days) > 300 
                THEN 'High'
            WHEN EXTRACT(DAY FROM sq1.tenure_days) BETWEEN 150 AND 300
                THEN 'Medium'
            WHEN EXTRACT(DAY FROM sq1.tenure_days) < 150
                THEN 'Low'
        END AS engagement_tier
    FROM (
        SELECT c.customer_id, c.store_id,
        MIN(r.rental_date) AS first_rental_date,
        MAX(r.rental_date) AS last_rental_date,
        (MAX(r.rental_date) - MIN(r.rental_date)) AS tenure_days --Activity period
        FROM customer c
        INNER JOIN rental r ON c.customer_id = r.customer_id
        INNER JOIN payment p ON r.rental_id = p.rental_id   --Considering only paid rentals
        WHERE r.return_date IS NOT NULL
            AND (r.rental_date >= '2005-01-01' AND r.rental_date <= '2005-12-31')
        GROUP BY 1,2) sq1
),
store_performance AS (
    SELECT sq2.store_id, 
        sq2.total_customers,
        sq2.total_spent,
        SUM(sq2.total_customers) OVER () AS total_customers_across_all_stores,
        ROUND((sq2.total_spent/sq2.total_customers),2) AS avg_spending_per_customer
    FROM (
        SELECT c.store_id, 
            COUNT(DISTINCT c.customer_id) AS total_customers, 
            SUM(p.amount) AS total_spent
        FROM customer c
        INNER JOIN rental r ON c.customer_id  = r.customer_id
        INNER JOIN payment p ON r.rental_id = p.rental_id --Considering only paid rentals
        WHERE r.return_date IS NOT NULL
            AND (r.rental_date >= '2005-01-01' AND r.rental_date <= '2005-12-31')
        GROUP BY 1
        ORDER BY 1
        ) sq2
),
--Aggregation of metrics
aggregation AS (
SELECT 
    em.store_id, 
        em.engagement_tier,
        sp.total_customers,
        sp.total_spent,
        sp.avg_spending_per_customer,
        sp.total_customers_across_all_stores,
        COUNT(*) AS tier_customers
    FROM engagement_metric em
    INNER JOIN store_performance sp ON em.store_id = sp.store_id
    GROUP BY 1,2,3,4,5,6
)
--Main query with an additional metric of distribution
SELECT *, 
    ROUND(a.tier_customers::numeric/a.total_customers_across_all_stores,2)*100 AS share
FROM aggregation a;
