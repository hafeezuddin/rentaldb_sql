/* Analyze film performance across rental metrics and inventory efficiency to identify optimization opportunities.

Specific Requirements:
For each film, calculate: Total rentals and total revenue generated
Average rental duration vs. actual rental period
Rental frequency (rentals per day available)
Inventory utilization rate (% of inventory copies rented at least once in last 90 days)

Categorize films into:
"Blockbusters": Top 20% by revenue AND rental frequency
"Underperformers": Bottom 30% by revenue AND rental frequency
"Efficient Classics": High utilization rate (>80%) AND above average rental duration

"Slow Movers": Low utilization rate (<30%) AND below average rentals
"Balanced Performers": All other films

Include store-level analysis:
Compare performance between store locations
Identify films that perform well in one store but poorly in another


Desired Output Business requirement:
film_id, title, category_name, total_rentals, total_revenue, avg_rental_duration, rental_frequency, inventory_utilization_rate
performance_category, store_1_rentals, store_2_rentals, performance_disparity */


--Checks for cardinality and to avoid cartesian products in cases where film has two categories.
-- SELECT f.film_id, COUNT(f.film_id)
-- FROM film f
-- JOIN film_category fc ON f.film_id = fc.film_id
-- GROUP BY f.film_id
-- HAVING count(f.film_id) > 1
--Zero results indicating each film has exactly one category.

WITH payment_agg AS (SELECT p.rental_id, SUM(p.amount) tot_amount
                     FROM payment p
                     GROUP BY p.rental_id),

     base_film_info AS (SELECT f.film_id,
                               f.title,
                               i.inventory_id,
                               i.store_id,
                               ct.name,
                               f.rental_duration   allowed_rental_duration,
                               r.rental_id,
                               r.rental_date::date rn_date,
                               r.return_date::date rt_date,
                               pa.tot_amount
                        FROM film f
                                 JOIN film_category fc ON f.film_id = fc.film_id
                                 JOIN category ct ON fc.category_id = ct.category_id
                                 LEFT JOIN inventory i ON f.film_id = i.film_id
                                 LEFT JOIN rental r ON i.inventory_id = r.inventory_id
                                 LEFT JOIN payment_agg pa ON r.rental_id = pa.rental_id),

     last_ninety_days AS (SELECT bfi.film_id,
                                 COUNT(DISTINCT bfi.inventory_id) rentals_90
                          FROM base_film_info bfi
                          WHERE bfi.rn_date >= DATE '2006-01-01' - INTERVAL '90 days'
                            AND bfi.rn_date < DATE '2006-01-01'
                          GROUP BY bfi.film_id),

     total_inventory AS (SELECT bfi.film_id,
                                COUNT(DISTINCT bfi.inventory_id) film_tot_inventory
                         FROM base_film_info bfi
                         GROUP BY bfi.film_id),

     store_level_metrics AS (SELECT bfi.film_id,
                                    COUNT(CASE WHEN bfi.store_id = 1 THEN 1 END) AS store_1_rentals,
                                    COUNT(CASE WHEN bfi.store_id = 2 THEN 1 END) AS store_2_rentals
                             FROM base_film_info bfi
                             WHERE bfi.tot_amount IS NOT NULL
                               AND rt_date IS NOT NULL
                             GROUP BY bfi.film_id),

     core_metrics AS (SELECT bfi.film_id,
                             bfi.name,
                             sm.store_1_rentals,
                             sm.store_2_rentals,
                             bfi.title,
                             bfi.allowed_rental_duration,

                             COALESCE(lnd.rentals_90, 0)                                  last_90_days_rentals,
                             ti.film_tot_inventory,

                             ROUND(
                                     (COALESCE(lnd.rentals_90, 0)::numeric / NULLIF(ti.film_tot_inventory, 0)) * 100,
                                     2
                             ) AS                                                         utilization_rate_90_days,

                             COUNT(DISTINCT bfi.rental_id)                                total_rentals,
                             SUM(bfi.tot_amount)                                          total_revenue,

                             percent_rank() OVER (ORDER BY SUM(bfi.tot_amount))           revenue_rank,

                             ROUND(AVG(bfi.rt_date - bfi.rn_date), 2)                     avg_rental_duration,

                             ROUND(COUNT(DISTINCT bfi.rental_id)::numeric / 365, 2)       rental_frequency,

                             percent_rank() OVER (ORDER BY COUNT(DISTINCT bfi.rental_id)) freq_rank

                      FROM base_film_info bfi
                               LEFT JOIN last_ninety_days lnd ON bfi.film_id = lnd.film_id
                               LEFT JOIN total_inventory ti ON bfi.film_id = ti.film_id
                               LEFT JOIN store_level_metrics sm ON bfi.film_id = sm.film_id
                      WHERE bfi.tot_amount IS NOT NULL
                        AND rt_date IS NOT NULL
                      GROUP BY bfi.film_id, bfi.title, bfi.name,
                               sm.store_1_rentals, sm.store_2_rentals,
                               bfi.allowed_rental_duration,
                               lnd.rentals_90, ti.film_tot_inventory),

--Compute averages ONCE
     avg_metrics AS (SELECT AVG(avg_rental_duration) AS avg_duration,
                            AVG(total_rentals)       AS avg_rentals
                     FROM core_metrics)

SELECT cm.film_id,
       cm.title,
       cm.name,
       cm.total_rentals,
       cm.total_revenue,
       cm.avg_rental_duration,
       cm.rental_frequency,
       cm.utilization_rate_90_days,
       cm.store_1_rentals,
       cm.store_2_rentals,
       cm.store_1_rentals - cm.store_2_rentals AS performance_disparity,

       CASE
           WHEN cm.revenue_rank >= 0.8 AND cm.freq_rank >= 0.8 THEN 'Block Buster'

           WHEN cm.revenue_rank <= 0.3 AND cm.freq_rank <= 0.3 THEN 'Under Performers'

           WHEN cm.utilization_rate_90_days > 80
               AND cm.avg_rental_duration > am.avg_duration THEN 'Efficient Classics'

           WHEN cm.utilization_rate_90_days < 30
               AND cm.total_rentals < am.avg_rentals THEN 'Slow Movers'

           ELSE 'Balanced'
           END                                 AS film_category

FROM core_metrics cm
         CROSS JOIN avg_metrics am;