/* Business Case: You are analyzing the DVD rental business to optimize inventory purchasing
   and identify underperforming films using 2005 rental data.

   Management wants to make data-driven decisions about which films to keep, restock,
   expand, or remove from inventory based on demand, revenue, and inventory efficiency.

   --------------------------------------------------------
   Scope and Data Rules
   --------------------------------------------------------
   - Only rentals between '2005-01-01' and '2005-12-31' are included.
   - Only completed rentals (return_date IS NOT NULL) are included.
   - Only films with at least 5 rentals in 2005 are analyzed.
   - Inventory count refers to the total number of copies owned for each film.

   --------------------------------------------------------
   Metrics to calculate for each film
   --------------------------------------------------------
   Calculate the following:

       Total number of rentals (in 2005)
       Total revenue generated (sum of all payments)
       Average rental duration (return_date − rental_date)
       Total number of copies in inventory
       Total rental days (sum of all rental durations)
       Utilization rate = (total rental days / (inventory copies × 365)) × 100
       Revenue per copy = total revenue / inventory copies
       Replacement cost (cost to replace one copy)
       ROI = (total revenue / replacement cost) × 100

   Include:
       Film category
       Replacement cost

   --------------------------------------------------------
   Film performance tiers
   --------------------------------------------------------
   Categorize each film into exactly one of the following:

       "Blockbuster":
           Films that are in the top 15% of all films by:
               - Total revenue
               AND
               - Total rental count

       "Efficient":
           Films that have:
               - Revenue per copy greater than the overall average
               AND
               - Utilization rate ≥ 60%

       "Underperforming":
           Films that are in the bottom 25% by total revenue
           AND have replacement_cost > 20

       "Standard":
           All remaining films

*/

--CTE to build core dataset for calculating metrics

WITH base_film_cte AS (SELECT f.film_id,
                              r.rental_id,
                              f.rental_rate,
                              r.return_date::date - r.rental_date::date rental_duration,
                              i.inventory_id,
                              f.replacement_cost
                       FROM film f
                                 JOIN inventory i ON f.film_id = i.film_id
                                JOIN rental r ON i.inventory_id = r.inventory_id
                       WHERE r.return_date IS NOT NULL
                         AND (r.rental_date BETWEEN '2005-01-01' AND '2005-12-31')
    --To filter analysis on 2005 data
),
    film_inventory AS (
        SELECT film_id, COUNT(*) AS total_inventory_copies
        FROM inventory
        GROUP BY film_id
    ),
     core_metrics AS (SELECT bf.film_id,
                             bf.replacement_cost,
                             COUNT(DISTINCT bf.rental_id)                                                        total_rentals,
                             SUM(bf.rental_rate)                                                                 total_revenue_generated,
                             ROUND(AVG(bf.rental_duration), 2)                                                   Avg_rental_duration,
                             fi.total_inventory_copies,
                             ROUND(COALESCE(SUM(bf.rental_duration), 2)::numeric /
                                   (NULLIF(fi.total_inventory_copies,0) * 365),2),
                                                                                                            inventory_utilisation, --Utilization ratio
                             --Formula: sum of rental duration / inventory copies * 365
                             ROUND(COALESCE(SUM(bf.rental_rate), 0) / NULLIF(fi.total_inventory_copies, 0),
                                   2)                                                                            revenue_per_copy,
                             ROUND((coalesce(SUM(bf.rental_rate), 0) / NULLIF(bf.replacement_cost, 0)) * 100, 2) ROI,
                             ROUND(percent_rank() OVER (ORDER BY sum(bf.rental_rate))::NUMERIC,
                                   2)                                                                            revenue_rank,
                             ROUND(percent_rank() OVER (ORDER BY COUNT(DISTINCT bf.rental_id))::NUMERIC,
                                   2)                                                                            total_rentals_rank
                      FROM base_film_cte bf
                      JOIN film_inventory fi ON bf.film_id = fi.film_id
                      GROUP BY bf.film_id, bf.replacement_cost, fi.total_inventory_copies
                      HAVING count(DISTINCT bf.rental_id) >= 5)
SELECT *,
       CASE
           WHEN cm.revenue_rank >= 0.85 AND cm.total_rentals_rank > 0.85 THEN 'BLOCK BUSTERS'
           WHEN (cm.revenue_per_copy > avg(cm.revenue_per_copy) OVER ()) AND cm.inventory_utilisation >= 60
               THEN 'Efficient'
           WHEN cm.revenue_rank <= 0.25 AND cm.replacement_cost > 20 THEN 'Underperforming'
           ELSE 'Standard'
           END AS categories
FROM core_metrics cm;

-- [
--   {
--     "QUERY PLAN": "Planning Time: 1.079 ms"
--   },
--   {
--     "QUERY PLAN": "Execution Time: 51.149 ms"
--   }
-- ]
