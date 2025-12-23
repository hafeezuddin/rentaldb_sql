/* Total amount spent by customer (Lifetime Value for year 2005) */
SELECT 
  p.customer_id,
  SUM(p.amount) AS lifetime_value_2005--Calculating total amount spent by each customer (Paid rentals only)
FROM payment p
INNER JOIN rental r ON p.rental_id = r.rental_id
WHERE r.rental_date >= '2005-01-01' AND r.rental_date <= '2005-12-31'
GROUP BY p.customer_id
ORDER BY lifetime_value_2005 DESC;
