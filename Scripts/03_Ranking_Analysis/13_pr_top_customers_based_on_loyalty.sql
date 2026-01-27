/* Identify Customers with High Potential for Loyalty Programs - 2005 Data */
--1.Frequent Renters: Above-average rental frequency,
--2.High-Value: Above-average total spending
--3.Recent Activity: Rented at least once in the last 30 days)

--Base rental information cte (Single source of information/data)
WITH base_rental_cte AS (SELECT r.customer_id, r.rental_id, r.rental_date, p.amount
                         FROM rental r
                                  LEFT JOIN payment p ON r.rental_id = p.rental_id
                         --Accounts for unpaid rentals as well.
                         --Replace LEFT Join with INNER to consider paid rentals only.
                         WHERE (r.rental_date BETWEEN '2005-01-01' AND '2005-12-31')
                        --Filtering 2005 Data for analysis
),
--CTE to calculate rental frequency of each customer
--Rental frequency Def: Totals Rentals/No.of active months
customer_totals AS (SELECT brc.customer_id,
                                COALESCE(SUM(brc.amount), 0)                                   AS total_spent,
                                COUNT(DISTINCT brc.rental_id)::numeric /
                                NULLIF(COUNT(DISTINCT EXTRACT(Month FROM brc.rental_date)), 0) AS rental_frequency
                         FROM base_rental_cte brc
                         GROUP BY brc.customer_id),
--Filtering customers who rented in last 30 days
recent_activity AS (SELECT t.customer_id
                         FROM (SELECT brc.customer_id, MAX(brc.rental_date) AS latest_rental_date
                               FROM base_rental_cte brc
                               GROUP BY brc.customer_id) t
                         WHERE '2005-12-31'::date - t.latest_rental_date::date <= 30),
--Overall average metrics for filtering above average spenders and above average frequent renters
overall_average_metrics AS (SELECT ROUND(AVG(ct.total_spent), 2)      AS average_spent,
                                        ROUND(AVG(ct.rental_frequency), 2) AS average_frequency
                                 FROM customer_totals ct)
--Main query to filter customers based on business criteria.
SELECT rc.customer_id, ct.total_spent, ct.rental_frequency
FROM recent_activity rc
         JOIN customer_totals ct ON rc.customer_id = ct.customer_id
         CROSS JOIN overall_average_metrics oam
WHERE (ct.total_spent > oam.average_spent)
  AND (ct.rental_frequency > oam.average_frequency)
ORDER BY ct.total_spent DESC
LIMIT 10;


