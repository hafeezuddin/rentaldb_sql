/* Customers spending more than average */
--CTE to find each customer total_spending in the year 2005. Considering only paid rentals.
WITH customer_spending AS (
  SELECT 
    p.customer_id,
    SUM(p.amount) AS total_spent
  FROM payment p
  INNER JOIN rental r ON p.rental_id = r.rental_id
  WHERE r.return_date IS NOT NULL AND (r.rental_date >= '2005-01-01' AND r.rental_date <= '2005-12-31')
  GROUP BY p.customer_id
),
--Cte to calculate avg customer spending.
avg_cal AS (SELECT AVG(cs.total_spent) AS avg_spending
            FROM customer_spending cs)
--Main query
SELECT
  cs.customer_id,
  cs.total_spent
FROM customer_spending cs
CROSS JOIN avg_cal ac
WHERE cs.total_spent > ac.avg_spending
ORDER BY total_spent;




--Without cross join
WITH customer_spending AS (
  SELECT
    p.customer_id,
    SUM(p.amount) AS total_spent
  FROM payment p
  INNER JOIN rental r ON p.rental_id = r.rental_id
  WHERE r.return_date IS NOT NULL AND (r.rental_date >= '2005-01-01' AND r.rental_date <= '2005-12-31')
  GROUP BY p.customer_id
)
--Main query
SELECT
  cs.customer_id,
  cs.total_spent
FROM customer_spending cs
WHERE cs.total_spent > (SELECT AVG(total_spent) FROM customer_spending)
ORDER BY total_spent;

