/* Top 10 customers with >=20 rentals and above-average spend in 2005 */
SELECT c.customer_id,
    c.first_name,
    c.last_name,
    COUNT(DISTINCT r.rental_id) AS total_rentals,
    SUM(p.amount) AS total_spent,
    ROUND(SUM(p.amount)/COUNT(DISTINCT r.rental_id), 2) AS avg_spent_per_rental
FROM customer c
INNER JOIN rental r ON c.customer_id = r.customer_id
INNER JOIN payment p ON r.rental_id = p.rental_id
WHERE r.return_date IS NOT NULL
  AND r.rental_date >= '2005-01-01'
  AND r.rental_date <= '2005-12-31'
GROUP BY c.customer_id, c.first_name, c.last_name
HAVING COUNT(DISTINCT r.rental_id) >= 20
  AND SUM(p.amount) > (
    SELECT AVG(t.total)
    FROM (
      SELECT p2.customer_id, SUM(p2.amount) AS total
      FROM payment p2
      INNER JOIN rental r2 ON p2.rental_id = r2.rental_id  -- Changed to r2
      WHERE r2.return_date IS NOT NULL   --Rental activity for year 2005 regardless of when paid
        AND r2.rental_date >= '2005-01-01'
        AND r2.rental_date <= '2005-12-31'
      GROUP BY p2.customer_id
    ) t
  )
ORDER BY total_spent DESC
LIMIT 10;