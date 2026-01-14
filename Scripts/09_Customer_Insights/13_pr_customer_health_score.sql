/* Task: Customer Health Score & Churn Risk Analysis (2005 Data Only)
Background: Using only 2005 data, we need to identify which customers are at risk of not returning in 2006. The business needs to run a year-end retention campaign.

Key Constraint: All date calculations must work within January 1 - December 31, 2005.

Metric 1: Customer Health Score (2005 Only)
Objective: Build a composite score (0-100 points) based on 2005 behavior only:
    Recency (30 points): How recently did they last rent in 2005?
        Last rental in Q4 2005 (Oct-Dec): 30 points
        Last rental in Q3 2005 (Jul-Sep): 15 points
        Last rental in H1 2005 (Jan-Jun): 5 points
    Rental volume (40 points): Volume rent in 2005?
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

--Parameters cte to maintain modularity
WITH param_cte AS (SELECT DATE '2005-01-01' AS analysis_start_date, --Date is in Standard-ISO Format
                          DATE '2005-12-31' AS analysis_end_date),  --Date is in Standard-ISO Format
--CTE for to build customers and their rental data set
rental_info AS (SELECT r.customer_id,
                            MAX(r.rental_date)::date                     AS latest_rental_date_2005,
                            MIN(r.rental_date)::date                     AS first_rental_date_2005,
                            SUM(p.amount)                                AS total_2005_spent,
                            COUNT(DISTINCT r.rental_id)                  AS total_2005_rentals,
                            percent_rank() OVER (ORDER BY sum(p.amount)) AS spent_rank
                     FROM rental r
                              LEFT JOIN payment p ON r.rental_id = p.rental_id
                              --LEFT JOIN retains both paid and unpaid rentals
                              --Replace LEFT Join with INNER JOIN to consider only paid rentals for analysis based on business requirement
                              CROSS JOIN param_cte
                     WHERE r.rental_date BETWEEN param_cte.analysis_start_date AND param_cte.analysis_end_date
                     --Where clause filtering and retaining only 2005 data by cross joining param_cte
                     --This base dataset has only 2005 Data (Both paid and unpaid)
                     GROUP BY r.customer_id),

--CTE to calculate metric #1 components: recency_score, rental_volume, spending_Score
customer_health_score AS (SELECT ri.customer_id,
                                      CASE
                                          WHEN EXTRACT(MONTH FROM ri.latest_rental_date_2005) BETWEEN 10 AND 12
                                              THEN 30
                                          WHEN EXTRACT(MONTH FROM ri.latest_rental_date_2005) BETWEEN 6 AND 9
                                              THEN 15
                                          ELSE
                                              5
                                          END AS recency_score,
                                      CASE
                                          WHEN ri.total_2005_rentals >= 12
                                              THEN 40
                                          WHEN ri.total_2005_rentals BETWEEN 6 AND 12
                                              THEN 25
                                          ELSE
                                              10
                                          END AS rental_volume,
                                      CASE
                                          WHEN ri.spent_rank >= 0.75
                                              THEN 30
                                          WHEN ri.spent_rank BETWEEN 0.25 AND 0.74
                                              THEN 15
                                          ELSE
                                              5
                                          END AS spending_score
                               FROM rental_info ri),

--Flagging customers who didn't rent in Q4 of 2005.
--Flag(Inactive/active) is used in churn risk calculation in main query
active_status AS (SELECT chs.customer_id,
                              CASE
                                  WHEN EXTRACT(MONTH FROM MAX(ri.latest_rental_date_2005)) < 10
                                      THEN 'Inactive'
                                  ELSE 'Active'
                                  END AS last_rental_flag
                       FROM customer_health_score chs
                                JOIN rental_info ri ON chs.customer_id = ri.customer_id
                       GROUP BY chs.customer_id)

--Main query to aggregate metrics and categorize the customer churn risk.
SELECT ri.customer_id,
       ri.latest_rental_date_2005,
       ri.first_rental_date_2005,
       ri.total_2005_rentals,
       ri.total_2005_spent,
       CONCAT(c.first_name, ' ', c.last_name) AS full_name,
       c.email,
       chs.spending_score AS monetary_score,
       chs.recency_score,
       chs.rental_volume AS frequency_score,
       COALESCE(chs.spending_score + chs.recency_score + chs.rental_volume,0) AS health_score,
       ac.last_rental_flag,
       CASE
           WHEN chs.spending_score + chs.recency_score + chs.rental_volume < 40 AND last_rental_flag = 'Inactive'
               THEN 'High Risk'
           ELSE
               'Low Risk'
           END                                as churn_risk_flag
FROM rental_info ri
         JOIN customer c ON ri.customer_id = c.customer_id
         JOIN customer_health_score chs ON ri.customer_id = chs.customer_id
         JOIN active_status ac ON ri.customer_id = ac.customer_id
ORDER BY health_score ASC, ri.latest_rental_date_2005 ASC;



