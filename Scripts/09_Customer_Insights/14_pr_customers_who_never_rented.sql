/* Customers who never rented a film (sample) */
SELECT c.customer_id,
       CONCAT(c.first_name, ' ', c.last_name) AS customer_full_name,
       c.email
FROM customer c
         LEFT JOIN rental r ON c.customer_id = r.customer_id
--LEFT JOIN retains all customers including customers who haven't rented
WHERE r.rental_id IS NULL
--Filters
ORDER BY c.customer_id;