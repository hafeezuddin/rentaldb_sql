/* Customers renting premium films (most expensive) */
WITH premium_films AS (
  SELECT film_id
  FROM film
  WHERE rental_rate = (
      SELECT MAX(rental_rate)
      FROM film
    )
)
SELECT DISTINCT 
  c.customer_id, 
  CONCAT(c.first_name,' ',c.last_name) AS full_name,
  c.email
FROM customer c
  JOIN rental r ON c.customer_id = r.customer_id
  JOIN payment p ON r.rental_id = p.rental_id
  JOIN inventory i ON r.inventory_id = i.inventory_id
  JOIN premium_films pf ON i.film_id = pf.film_id
WHERE r.return_date IS NOT NULL AND (r.rental_date >= '2005-01-01' AND r.rental_date <= '2005-12-31')
ORDER BY c.customer_id;
