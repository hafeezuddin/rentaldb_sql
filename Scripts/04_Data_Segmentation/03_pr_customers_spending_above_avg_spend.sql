/* Customers spending more than average */
--CTE to find each customer total_spending in the year 2005.
-- Considering only paid rentals.

WITH customer_rental_data AS (SELECT r.customer_id,
                                     SUM(p.amount) total_spent
                              FROM rental r
                                       JOIN payment p ON r.rental_id = p.rental_id
                              WHERE r.return_date IS NOT NULL
                                AND (r.rental_date BETWEEN '2005-01-01' AND '2005-12-31')
                              GROUP BY r.customer_id)
SELECT crd.customer_id, crd.total_spent
FROM customer_rental_data crd
WHERE crd.total_spent > (SELECT AVG(total_spent) FROM customer_rental_data)
--Avg can also be calculated in a separate CTE AND cross joined to filter customers
ORDER BY crd.total_spent DESC;