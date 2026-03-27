/* Task: Identify Films at Risk of Being Overlooked */
/* Objective:
 Find films that meet all of these criteria:
    High Quality: Above-average rental rate
    Low Engagement: Below-average rental frequency
    Available Inventory: Currently in stock (at least 1 copy) */

--Checks: Payment table joining is not required.
--Possibility of cartesian product can be completely avoided in cases like multiple payments under one rental_id without preprocessing
--CTE to filter films with high rental rate than average
WITH above_average_film_rentals AS (SELECT f.film_id
                                    FROM film f
                                    WHERE f.rental_rate > (SELECT AVG(f.rental_rate) FROM film f)),
--Base metrics calculation
     metrics AS (SELECT f.film_id,
                        COUNT(r.rental_id)             rental_frequency,
                        COUNT(DISTINCT i.inventory_id) accounted_inventory
                 FROM film f
                          JOIN inventory i ON f.film_id = i.film_id
                          LEFT JOIN rental r ON i.inventory_id = r.inventory_id
                 --LEFT Ensures films with zero rentals are included.
                 GROUP BY f.film_id),
--CTE to account for currently rented inventory, required to check current available inventory
     rented_inventory AS (SELECT i.film_id, COUNT(i.inventory_id) rented_inventory
                          FROM inventory i
                                   JOIN rental r ON i.inventory_id = r.inventory_id AND r.return_date IS NULL
                          GROUP BY i.film_id)
--Main query to filter films based on required aggregated metrics
SELECT aafr.film_id,
       m.rental_frequency,
       m.accounted_inventory,
       m.accounted_inventory - COALESCE(ri.rented_inventory, 0) available_inventory
FROM above_average_film_rentals aafr
         JOIN metrics m ON aafr.film_id = m.film_id
         LEFT JOIN rented_inventory ri ON aafr.film_id = ri.film_id
WHERE (m.rental_frequency < (SELECT AVG(m.rental_frequency) FROM metrics m))
  AND (m.accounted_inventory - COALESCE(ri.rented_inventory, 0) > 0)

-- Planning Time: 0.814 ms
-- Execution Time: 24.054 ms

