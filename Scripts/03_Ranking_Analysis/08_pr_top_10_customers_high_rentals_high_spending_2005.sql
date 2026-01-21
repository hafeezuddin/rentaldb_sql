/* Top 10 customers with >=20 rentals and above-average spend in 2005 */

--CTE defines the parameters used in analysis and to maintain code modularity
WITH param_cte AS (
    SELECT DATE '2005-01-01' analysis_start_date,   --Date is in ISO format
           DATE '2005-12-31' analysis_end_date
),
--Rental information CTE
-- (Also handles edge case when customer splits the transaction into two payments - same rental_id, two payment_id's)
rental_information_cte AS (
    SELECT          r.customer_id,
                    COUNT(DISTINCT r.rental_id) AS total_distinct_rentals_2005,
                    COUNT(DISTINCT p.payment_id) AS total_distinct_payments_2005,
                    --To account/track for split payments if any
                    SUM(p.amount) AS total_spent
    FROM rental r
    JOIN payment p ON r.rental_id = p.rental_id
    --Considers paid rental's using INNER JOIN
    --Using LEFT JOIN would also consider rentals for which there is not payment information leading to discrepancies in calculating totals and averages
    CROSS JOIN param_cte pc
    WHERE r.rental_date BETWEEN pc.analysis_start_date AND pc.analysis_end_date
    GROUP BY r.customer_id
),
--CTE to calculate average spend of customers
average_spend AS (
    SELECT AVG(ri.total_spent) AS avg_spend FROM rental_information_cte ri
)
--Main query to aggregate metrics and filter customers.
SELECT ri.customer_id,
       CONCAT(c.first_name, ' ' , c.last_name) AS full_name,
       ri.total_spent, ri.total_distinct_rentals_2005, ri.total_distinct_payments_2005,
       ROUND(ri.total_spent::numeric/(NULLIF(ri.total_distinct_rentals_2005,0)),2) AS average_spent_per_rental
FROM rental_information_cte ri
JOIN customer c ON ri.customer_id = c.customer_id
CROSS JOIN average_spend
WHERE ri.total_distinct_rentals_2005 > 20 AND ri.total_spent >= average_spend.avg_spend
ORDER BY ri.total_spent DESC
LIMIT 10;