/* Customers who return rented films late (MB). */
--CTE to retrieve total_rentals of each customer
--For this business use case do not account the rentals which are not returned yet.
-- Use only the rentals which have return date and were retuned late.
WITH total_rentals AS
    (SELECT r.customer_id, COUNT(DISTINCT r.rental_id) AS total_rentals
    FROM rental r
    GROUP BY 1),

--CTE to retrieve late-returns of each customer
--Doesn't count rentals which are not returned yet.
late_returns AS (
    SELECT
    r.customer_id,COUNT(*) AS late_returns
    FROM rental r
    JOIN inventory i ON r.inventory_id = i.inventory_id
    JOIN film f ON i.film_id = f.film_id
    WHERE r.return_date IS NOT NULL
    AND (r.return_date::date - r.rental_date::date) > f.rental_duration
    GROUP BY 1
    )

--Main query to integrate total rentals and late rentals cte and calculate percentage of late rentals,
--sorted by top 10 late returning customers
SELECT tr.customer_id, CONCAT(c.first_name,' ',c.last_name) AS full_name,
       c.store_id,c.email,
       tr.total_rentals,
       COALESCE(lr.late_returns, 0) AS late_returns,
       ROUND((coalesce(lr.late_returns::numeric,0)/tr.total_rentals)*100,2) AS percentage_of_late_returns
FROM total_rentals tr
INNER JOIN late_returns lr ON tr.customer_id = lr.customer_id
INNER JOIN customer c ON tr.customer_id = c.customer_id
ORDER BY percentage_of_late_returns DESC
LIMIT 10;

