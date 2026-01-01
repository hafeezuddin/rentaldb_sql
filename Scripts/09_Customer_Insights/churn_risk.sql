
/* A “churn risk” customer is one who hasn’t rented in the last 60 days but had rented at least 5 films before that.*
For each such customer, show: Customer ID & Name, Last rental date, Total amount spent
Total rentals before their last rental.
Consider both paid and unpaid rentals */

--CTE to calculate last rental date
WITH last_rental_date AS (
SELECT c.customer_id, MAX(r.rental_date) AS last_rental_date
FROM customer c
INNER JOIN rental r ON c.customer_id = r.customer_id
GROUP BY 1
),
--CTE to filter inactive customers
inactive_customers AS (
  SELECT lrd.customer_id,
  CURRENT_DATE -last_rental_date::date AS days_since_last_rented
  FROM last_rental_date lrd
  WHERE CURRENT_DATE -last_rental_date::date >60
),
--CTE to find customer_Activity
customer_activity AS (
SELECT 
    r.customer_id,
    COUNT(r.rental_id) AS total_rentals,
    SUM(p.amount) AS total_spent
  FROM rental r
  INNER JOIN payment p ON r.rental_id = p.rental_id
  GROUP BY r.customer_id
)
SELECT lrd.customer_id, c.first_name, c.last_name, lrd.last_rental_date, ca.total_rentals, ca.total_spent
FROM last_rental_date lrd
INNER JOIN inactive_customers ic ON lrd.customer_id = ic.customer_id
INNER JOIN customer_activity ca ON ic.customer_id = ca.customer_id
INNER JOIN customer c ON lrd.customer_id = c.customer_id
WHERE ca.total_rentals > 5;