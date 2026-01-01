/* Unreturned films against the customer who rented them. Include no of days since film was rented.*/
SELECT 
  CONCAT(c.first_name, ' ', c.last_name) AS customer_name, --concatinating firstname and lastname into customer_name
  c.email,
  r.rental_date, f.title,
EXTRACT(DAYS FROM (CURRENT_DATE - r.rental_date)) AS days_rented --No.of days since film was rented out
FROM customer c
  JOIN rental r ON c.customer_id = r.customer_id
  JOIN inventory i ON r.inventory_id = i.inventory_id
  JOIN film f ON i.film_id = f.film_id
WHERE r.return_date IS NULL;
--Filtering customers whose returned date is Null - Unreturned films.