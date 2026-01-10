/* Customers who are from city London */
SELECT CONCAT(c.first_name, ' ', c.last_name) AS customer_full_name,
       ci.city AS customer_residing_city,
       c.email AS customer_email
FROM customer c
         JOIN address a ON c.address_id = a.address_id
         JOIN city ci ON a.city_id = ci.city_id
WHERE ci.city = 'London'
ORDER BY customer_full_name ASC;
