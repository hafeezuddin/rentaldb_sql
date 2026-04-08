/* Customers who rented the most expensive movie */
--CTE to find price of most expensive film
WITH expensive_film AS (
    SELECT f.film_id
    FROM film f
    WHERE f.rental_rate = (SELECT MAX(f.rental_rate) FROM film f)
)
SELECT c.customer_id, CONCAT(c.first_name,' ', c.last_name) AS full_name,
       c.email,
       COUNT(ef.film_id) AS no_of_times_rented
FROM customer c
JOIN rental r ON c.customer_id = r.customer_id
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN expensive_film ef ON i.film_id = ef.film_id
GROUP BY c.customer_id
ORDER BY no_of_times_rented DESC;