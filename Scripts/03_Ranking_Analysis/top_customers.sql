/* Customers who rented the most (top 5) */
--Considering only paid rentals for 2005 period
SELECT 
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    COUNT(DISTINCT r.rental_id) AS total_rentals,
    row_number() over (ORDER BY COUNT(DISTINCT r.rental_id) desc, c.customer_id ASC) AS customer_rank
FROM customer c
    JOIN rental r ON c.customer_id = r.customer_id
    JOIN payment p ON r.rental_id = p.rental_id   --To consider only rentals that have payment information available on file.
WHERE r.return_date IS NOT NULL AND (r.rental_date BETWEEN '2005-01-01' AND '2005-12-31')
GROUP BY c.customer_id,
  CONCAT(c.first_name, ' ', c.last_name)
ORDER BY customer_rank ASC
LIMIT 5;


--Considering all rentals both paid and unpaid rentals for 2005 period
SELECT
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    COUNT(DISTINCT r.rental_id) AS total_rentals,
    row_number() over (ORDER BY COUNT(DISTINCT r.rental_id) desc, c.customer_id ASC) AS customer_rankS
FROM customer c
    JOIN rental r ON c.customer_id = r.customer_id
WHERE r.return_date IS NOT NULL AND (r.rental_date BETWEEN '2005-01-01' AND '2005-12-31')
GROUP BY c.customer_id,
  CONCAT(c.first_name, ' ', c.last_name)
ORDER BY customer_rank ASC
LIMIT 5;