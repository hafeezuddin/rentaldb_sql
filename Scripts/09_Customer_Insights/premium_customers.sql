/* Customers who have spent more than the average total rental amount across all customers (Premium Customers)*/
--CTE to calculate total amount spent by each customer. Data retrieved from Payments table consider only paid rentals.
WITH total_spend AS (
  SELECT p.customer_id,
    SUM(p.amount) AS totspend --ignores rows which has null values
  FROM payment p
  GROUP BY 1
  ORDER BY p.customer_id
),

--CTE to calculate Average amount spent by each customer. Calculated from totspend metric from total_spend_cte 
avg_spend AS (
  SELECT AVG(totspend) AS avg_spend
  FROM total_spend
) --Main Query with cross join to compare, and filter the required data to display customers who spent more than average

SELECT ts.customer_id,
  CONCAT(c.first_name, ' ', c.last_name) AS full_name,
  ts.totspend,
  ROUND(avgspendamnt.avg_spend, 2) AS per_customer_avg
FROM total_spend ts
  CROSS JOIN avg_spend AS avgspendamnt --Ideal when one value is being compared against all rows.
  INNER JOIN customer c ON ts.customer_id = c.customer_id
WHERE ts.totspend > avgspendamnt.avg_spend
ORDER BY ts.totspend DESC;