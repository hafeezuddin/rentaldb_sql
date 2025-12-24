/* Total revenue generated till date */
SELECT 
  CONCAT('$', SUM(p.amount)) AS total_revenue
FROM payment p;
