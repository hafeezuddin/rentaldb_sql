/* Customers who never rented a film (sample) */
SELECT 
  c.customer_id
FROM customer c
  LEFT JOIN rental r ON c.customer_id = r.customer_id
WHERE r.customer_id IS NULL
ORDER BY c.customer_id ASC;
