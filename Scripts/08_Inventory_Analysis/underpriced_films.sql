
/* Task: "Identify Underpriced Films"
 Find films where:
 High Rental Demand: Above-average rental frequency
 Low Rental Rate: Priced below the average rental rate for their category
 Available to Rent: Currently in stock. All available rental data from all years. */

--CTE to find films with above average rental frequency
WITH abv_avg_rental_f AS (
  SELECT f.film_id, f.title, f.rental_rate, COUNT(r.rental_id)
  FROM film f
    INNER JOIN inventory i ON f.film_id = i.film_id
    INNER JOIN rental r ON i.inventory_id = r.inventory_id
  GROUP BY f.film_id
  HAVING COUNT(r.rental_id) > (
      SELECT AVG(for_avg_rental_freq)
      FROM (
          SELECT f2.film_id,
            COUNT(r2.rental_id) AS for_avg_rental_freq
          FROM film f2
            INNER JOIN inventory i2 ON f2.film_id = i2.film_id
            INNER JOIN rental r2 ON i2.inventory_id = r2.inventory_id
          GROUP BY f2.film_id
        ) t
    )
  ORDER BY f.film_id
),
--CTE to get films which are priced below average
low_priced_films AS (
  SELECT f.film_id, f.rental_rate
  FROM film f
  WHERE f.rental_rate < (
      SELECT AVG(f.rental_rate)
      FROM film f
    )
  ORDER BY f.film_id
),
--CTE to retrieve available inventory
available_in_inventory AS (
  SELECT DISTINCT f.film_id
  FROM film f
    INNER JOIN inventory i ON f.film_id = i.film_id
    LEFT JOIN rental r ON i.inventory_id = r.inventory_id AND r.return_date IS NULL --Conditional Left Join
  WHERE r.rental_id IS NULL

) -- Main query to display underpriced films
SELECT aarf.film_id, aarf.title, aarf.rental_rate
FROM abv_avg_rental_f aarf
  INNER JOIN low_priced_films lpf ON aarf.film_id = lpf.film_id
  INNER JOIN available_in_inventory aii ON lpf.film_id = aii.film_id
ORDER BY aarf.film_id;