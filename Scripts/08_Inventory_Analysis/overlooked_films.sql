
/* Task: Identify Films at Risk of Being Overlooked */
/* Objective:
 Find films that meet all of these criteria:
 High Quality: Above-average rental rate
 Low Engagement: Below-average rental frequency
 Available Inventory: Currently in stock (at least 1 copy) */

-- CTE to Display films whose price is above the avg.rental rate of all films.
WITH ab_avg_rental_rate AS (
  SELECT f.film_id, f.title, f.rental_rate
  FROM film f
  WHERE rental_rate > (
      SELECT AVG(rental_price)
      FROM (
          SELECT f.film_id, f.rental_rate AS rental_price
          FROM film f
        ) t1
    )
  ORDER BY f.film_id
),
--CTE to display films with below average rental frequency
rental_frequency AS (
  SELECT f.film_id, COUNT(f.film_id) AS no_of_times_film_rented
  FROM film f
    INNER JOIN inventory i ON f.film_id = i.film_id
    INNER JOIN rental r ON i.inventory_id = r.inventory_id  --Considering all rentals from all years including unpaid rentals.
  GROUP BY f.film_id
  HAVING COUNT(f.film_id) < (
      SELECT AVG(rental_count)
      FROM (
          SELECT f2.film_id,
            COUNT(f2.film_id) AS rental_count
          FROM film f2
            INNER JOIN inventory i2 ON f2.film_id = i2.film_id
            INNER JOIN rental r2 ON i2.inventory_id = r2.inventory_id
          GROUP BY f2.film_id
        ) t2
    )
),
--CTE to get available inventory
available_inventory AS (
  SELECT DISTINCT f.film_id
  FROM film f --Replace with * for detailed idea
    INNER JOIN inventory i ON f.film_id = i.film_id
    LEFT JOIN rental r ON i.inventory_id = r.inventory_id
    AND return_date IS NULL
    /* --We join to the rental table only if the inventory item is currently rented and NOT returned (return_date IS NULL).
     Because it’s a LEFT JOIN, even if there’s no active rental, the row will still appear — but with r.rental_id as NULL. Conditional left join*/
  WHERE r.rental_id IS NULL
  ORDER BY f.film_id
) 
--Main Query
SELECT avrr.film_id,
  avrr.title
FROM ab_avg_rental_rate AS avrr
  INNER JOIN rental_frequency rf ON avrr.film_id = rf.film_id
  INNER JOIN available_inventory ai ON rf.film_id = ai.film_id
ORDER BY avrr.film_id;