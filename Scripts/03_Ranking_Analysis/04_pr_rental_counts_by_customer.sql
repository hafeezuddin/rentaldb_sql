/* Rental counts by customer */
-- This query retrieves the number of rentals made by each customer including unpaid rentals,
SELECT r.customer_id,
       c.first_name,
       c.last_name,
       COUNT(DISTINCT r.rental_id) AS rental_count
FROM rental r
--Considers both paid and unpaid rentals
         JOIN customer c ON r.customer_id = c.customer_id
GROUP BY r.customer_id, c.first_name, c.last_name
ORDER BY rental_count DESC;


--This query retrieves the number of rentals made by each customer ONLY including paid rentals
SELECT r.customer_id,
       c.first_name,
       c.last_name,
       COUNT(DISTINCT r.rental_id) AS rental_count
FROM rental r
--Considers only paid rentals/where transaction exists in payment table for rental table records
         JOIN customer c ON r.customer_id = c.customer_id
         JOIN payment p ON r.rental_id = p.rental_id --To consider only paid rentals
GROUP BY r.customer_id, c.first_name, c.last_name
ORDER BY rental_count DESC;