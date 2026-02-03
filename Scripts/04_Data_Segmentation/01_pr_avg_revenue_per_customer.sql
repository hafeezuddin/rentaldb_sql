/* Average revenue per customer (subquery + CTE versions) */
-- Subquery Version
SELECT CONCAT('$', ROUND(AVG(t1.total_revenue), 2)) AS avg_revenue_per_customer
FROM (SELECT customer_id,
             SUM(amount) AS total_revenue
      FROM payment
      GROUP BY customer_id) t1;

-- CTE Version
WITH customer_revenue AS (SELECT customer_id,
                                 SUM(amount) AS total_revenue
                          FROM payment
                          GROUP BY customer_id)
SELECT CONCAT('$', ROUND(AVG(total_revenue), 2)) AS avg_revenue_per_customer
FROM customer_revenue;
