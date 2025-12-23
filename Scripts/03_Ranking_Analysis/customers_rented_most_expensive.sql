/* Customers who rented the most expensive movie */
WITH expensive_movie AS (
  SELECT MAX(f.rental_rate) AS max_rate FROM film f --Extract price of most expensive film
)
SELECT 
  c.customer_id, 
  COUNT(c.customer_id) AS no_of_high_value_rentals,
  CONCAT(c.first_name,' ',c.last_name) AS full_name,
  c.email
FROM customer c
  INNER JOIN rental r ON c.customer_id = r.customer_id
  INNER JOIN inventory i ON r.inventory_id = i.inventory_id
  INNER JOIN film f ON i.film_id = f.film_id
  INNER JOIN expensive_movie em ON f.rental_rate = em.max_rate  --Joining CTE to filter only the most expensive movies
GROUP BY c.customer_id, c.email, CONCAT(c.first_name,' ',c.last_name)
ORDER BY c.customer_id;
