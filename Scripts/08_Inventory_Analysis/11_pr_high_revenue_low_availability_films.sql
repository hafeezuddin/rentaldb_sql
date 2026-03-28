/*Identify Films with High Revenue but Low Availability.
 (Find films that generate strong revenue per rental but have limited inventory copies,
 potentially indicating missed business opportunities)*/

--To avoid cartesian product payments are aggregated for same rental_id (Edge case of split payments)
WITH aggregating_payments AS (SELECT r.rental_id, SUM(p.amount) AS total_rental_amount
                              FROM rental r
                                       JOIN payment p ON r.rental_id = p.rental_id
                              GROUP BY r.rental_id),
    --Base film cte to calculate metrics
     base_film_cte AS (SELECT i.film_id,
                              COUNT(DISTINCT i.inventory_id)           AS total_inventory_copies,
                              SUM(COALESCE(ap.total_rental_amount, 0)) AS total_revenue,
                              COUNT(DISTINCT r.rental_id)              AS total_rentals,
                              ROUND(
                                      SUM(COALESCE(ap.total_rental_amount, 0))
                                          / NULLIF(COUNT(DISTINCT r.rental_id), 0),
                                      2)                               AS avg_rev_per_rental
                       FROM inventory i
                                LEFT JOIN rental r ON i.inventory_id = r.inventory_id
                                LEFT JOIN aggregating_payments ap ON r.rental_id = ap.rental_id
                       GROUP BY i.film_id),
    --CTE to calculate averages
    final_cte AS (SELECT *,
                          ROUND(AVG(total_inventory_copies) OVER (), 2) AS avg_inventory_copies,
                          ROUND(AVG(avg_rev_per_rental) OVER (), 2)     AS over_all_avg
               FROM base_film_cte)
--Main query to filter films that meet business criteria.
SELECT film_id
FROM final_cte
WHERE total_inventory_copies < avg_inventory_copies
  AND avg_rev_per_rental > over_all_avg;

