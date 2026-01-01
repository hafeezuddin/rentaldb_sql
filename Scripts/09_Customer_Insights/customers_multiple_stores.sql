/* Customers renting from multiple stores */
SELECT 
  c.customer_id,
  c.first_name,
  c.last_name
FROM customer c
  INNER JOIN rental r ON c.customer_id = r.customer_id
  INNER JOIN staff s ON r.staff_id = s.staff_id
WHERE s.store_id IN (1, 2) --Typically not required as customers are spread across two stores and are being filtered in having clause
GROUP BY 1,2,3
HAVING COUNT(DISTINCT s.store_id) = 2;
