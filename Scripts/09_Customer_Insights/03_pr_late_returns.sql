/* Customers who return rented films late (MB). */
--Constraints: Do not consider rentals that are not returned.
-- Use only the rentals which have return date and were retuned late.

--Base CTE to retrieve rental data
WITH rentals_info AS (SELECT r.customer_id, r.rental_date, r.return_date, f.rental_duration
                      FROM rental r
                               JOIN inventory i ON r.inventory_id = i.inventory_id
                               JOIN film f ON i.film_id = f.film_id
                      WHERE r.return_date IS NOT NULL),
--CTE to count total rentals for each customer.
     total_rentals_cte AS (SELECT ri.customer_id, COUNT(*) AS total_rentals
                           FROM rentals_info ri
                           GROUP BY ri.customer_id),
--To calculate no.of late returns from total rentals
     late_rentals_cte AS (SELECT ri.customer_id, COUNT(*) AS late_returns
                          FROM rentals_info ri
                          WHERE (ri.return_date::date - ri.rental_date::date) > ri.rental_duration
                          GROUP BY ri.customer_id)
--Main query to calculate percentage of late rentals
SELECT lrc.customer_id,
       lrc.late_returns,
       trc.total_rentals,
       ROUND((COALESCE(lrc.late_returns, 0)::numeric / NULLIF(trc.total_rentals, 0)) * 100,
             2) AS late_returns_percentage
FROM late_rentals_cte lrc
         JOIN total_rentals_cte trc ON lrc.customer_id = trc.customer_id;

