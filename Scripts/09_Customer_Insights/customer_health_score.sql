/* Task: Customer Health Score & Churn Risk Analysis (2005 Data Only)
Background: Using only 2005 data, we need to identify which customers are at risk of not returning in 2006. The business needs to run a year-end retention campaign.

Key Constraint: All date calculations must work within January 1 - December 31, 2005.

Metric 1: Customer Health Score (2005 Only)
Objective: Build a composite score (0-100 points) based on 2005 behavior only:
    Recency (30 points): How recently did they last rent in 2005?
        Last rental in Q4 2005 (Oct-Dec): 30 points
        Last rental in Q3 2005 (Jul-Sep): 15 points
        Last rental in H1 2005 (Jan-Jun): 5 points
    Frequency (40 points): How often did they rent in 2005?
        12 rentals in 2005: 40 points
        6-12 rentals in 2005: 25 points
        < 6 rentals in 2005: 10 points
    Monetary (30 points): How much did they spend in 2005?
        Top 25% of 2005 spenders: 30 points
        Middle 50%: 15 points
        Bottom 25%: 5 points
Health Score = Recency + Frequency + Monetary


Metric 2: 2005 Churn Risk Flag
Objective: Flag customers who showed signs of disengaging during 2005.
Business Rule: Flag a customer as 'High Risk' if:

    Their health score is below 40 AND Their last 2005 rental was before October 1, 2005 (no activity in Q4)

Final Deliverable:
A customer-level report showing 2005 performance:
    customer_id, name, email, first_2005_rental, last_2005_rental, total_2005_rentals, total_2005_spend, recency_score, frequency_score, monetary_score, health_score (0-100)
    churn_risk_flag (High Risk / Low Risk)
Sort by: health_score ASC, last_2005_rental ASC */

--CTE for recency metric
WITH recency_cte AS (
    SELECT sq1.customer_id, 
        sq1.last_2005_rental_month AS last_2005_rental_month,
        sq1.first_2005_rental_month AS first_2005_rental_month,
        sq1.total_rentals,
        sq1.total_spent,
    CASE
        WHEN sq1.last_2005_rental_month BETWEEN 10 AND 12
            THEN 'Q4'
         WHEN sq1.last_2005_rental_month BETWEEN 07 AND 09
            THEN 'Q3'
        ELSE
            'H1'
        END AS quarter_classification,
    CASE
        WHEN sq1.last_2005_rental_month BETWEEN 10 AND 12
            THEN 30
        WHEN sq1.last_2005_rental_month BETWEEN 07 AND 09
            THEN 15
        ELSE 5
        END AS recency_Score
    FROM (
        SELECT c.customer_id,
        EXTRACT(MONTH FROM MAX(r.rental_date)) AS last_2005_rental_month,
        EXTRACT(MONTH FROM MIN(r.rental_date)) AS first_2005_rental_month,
        COUNT(Distinct r.rental_id) AS total_rentals,
        SUM(p.amount) AS total_spent
        FROM customer c
        INNER JOIN rental r ON c.customer_id = r.customer_id
        INNER JOIN payment p ON r.rental_id = p.rental_id
        WHERE r.return_date IS NOT NULL AND (r.rental_date BETWEEN '2005-01-01' AND '2005-12-31')
        GROUP BY 1
    ) sq1
),
--CTE for frequency_metric
frequency_cte AS (
    SELECT sq2.customer_id, 
        sq2.total_rentals,
        CASE 
            WHEN sq2.total_rentals >= 12 
                THEN 40
            WHEN sq2.total_rentals BETWEEN 6 AND 11
                THEN 25
        ELSE
            10
        END frequency_score
    FROM (
        SELECT 
            rc.customer_id, 
            COUNT(DISTINCT r2.rental_id) AS total_rentals
        FROM recency_cte rc
        INNER JOIN rental r2 ON rc.customer_id = r2.customer_id
        INNER JOIN payment p2 ON r2.rental_id = p2.rental_id
        WHERE r2.return_date IS NOT NULL AND (r2.rental_date BETWEEN '2005-01-01' AND '2005-12-31')
        GROUP BY 1
    ) sq2
),
--CTE to rank spends
spend_ranking AS (
    SELECT *,
        CASE
            WHEN sq3.spend_rank > 0.75
                THEN 30
            WHEN sq3.spend_rank BETWEEN 0.25 AND 0.75
                THEN 15
            ELSE
                5
            END spendranking
    FROM (
    SELECT rc.customer_id,
        SUM(p3.amount) total_spent,
        PERCENT_RANK() OVER (ORDER BY SUM(p3.amount)) AS spend_rank
    FROM recency_cte rc
   INNER JOIN rental r3 ON rc.customer_id = r3.customer_id
   INNER JOIN payment p3 ON r3.rental_id = p3.rental_id
   WHERE r3.return_date IS NOT NULL AND (r3.rental_date BETWEEN '2005-01-01' AND '2005-12-31')
   GROUP BY 1
    ) sq3
)
--Aggregator Query
SELECT rc.customer_id, 
        CONCAT(cu.first_name, ' ', cu.last_name) AS customer_name, cu.email,
        rc.last_2005_rental_month,
        rc.first_2005_rental_month,
        rc.total_spent,
        rc.recency_score,
        fc.frequency_score,
        sr.spendranking,
        rc.recency_score + fc.frequency_score + sr.spendranking AS health_score,
        CASE
            WHEN rc.last_2005_rental_month < 10 AND rc.recency_score + fc.frequency_score + sr.spendranking < 40
                THEN 'High Risk'
            ELSE
                'Low Risk'
            END AS churn_risk
FROM recency_cte rc
INNER JOIN frequency_cte fc ON rc.customer_id = fc.customer_id
INNER JOIN spend_ranking sr ON fc.customer_id = sr.customer_id
INNER JOIN customer cu ON sr.customer_id = cu.customer_id
ORDER BY health_score ASC, last_2005_rental_month ASC;