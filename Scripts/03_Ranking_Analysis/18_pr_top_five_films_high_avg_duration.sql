/* Top 5 films that meet rental-count and average duration criteria */
--Base rental cte
WITH base_info AS (SELECT f.film_id,
                          f.title,
                          --Below function calculates film average rental duration
                          ROUND(AVG(EXTRACT(EPOCH FROM (r.return_date - r.rental_date) / 86400.0)),
                                2)                    AS film_rental_avg_duration,
                          COUNT(DISTINCT r.rental_id) AS total_rentals
                   FROM film f
                            JOIN inventory i on f.film_id = i.film_id
                            JOIN rental r ON i.inventory_id = r.inventory_id
                   WHERE r.return_date IS NOT NULL
                   GROUP BY f.film_id, f.film_id, f.title),

--Metrics Building CTE to filter films
metrics_cte AS (SELECT ROUND(avg(bi.film_rental_avg_duration), 2) AS overall_average_rental_duration,
                            ROUND(avg(total_rentals), 2)               AS average_no_of_rentals
                     FROM base_info bi)
--Main query to filter with above average rental counts, and above average rental duration
SELECT bi.film_id, bi.title
FROM base_info bi
         CROSS JOIN metrics_cte mc
WHERE (bi.film_rental_avg_duration > mc.overall_average_rental_duration)
  AND (bi.total_rentals > mc.average_no_of_rentals)
ORDER BY bi.total_rentals DESC, bi.film_rental_avg_duration DESC;
