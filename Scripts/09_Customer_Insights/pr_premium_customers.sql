/* Customers who have spent more than the average total rental amount across all customers (Premium Customers).
   Consider paid rentals only, Consider rental transactions of 2005 (payment can be in next year)*/

--Parameters CTE to maintain modularity in analysis
WITH param_cte AS (SELECT DATE '2005-01-01' AS analysis_period_start,
                          DATE '2005-12-31' AS analysis_period_end),
--BASE CTE to retrieve customer rental data, its payment and filter 2005 data for metrics
     rentals_info AS (SELECT r.customer_id, concat(C.first_name, ' ', c.last_name) AS customer_full_name, SUM(p.amount) AS total_spent
                      FROM rental r
                               JOIN payment p ON r.rental_id = p.rental_id
                               JOIN customer c ON r.customer_id = c.customer_id
                               CROSS JOIN param_cte pc
                      WHERE r.rental_date >= analysis_period_start
                        AND r.rental_date <= analysis_period_end
                      GROUP BY r.customer_id, c.first_name, c.last_name)
--Main query to filter customer who spent more than average overall spent amount.
SELECT ri.customer_id, ri.customer_full_name, ri.total_spent
FROM rentals_info ri
WHERE ri.total_spent > (SELECT AVG(ri.total_spent) FROM rentals_info ri)
ORDER BY total_spent DESC;