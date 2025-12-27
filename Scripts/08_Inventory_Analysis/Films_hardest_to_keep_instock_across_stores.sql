/* Which specific films are hardest to keep in stock across our stores? 
Film titles and IDs, Store locations, Total copies per film per store, Currently rented copies, Availability percentage
Rank films by worst availability
Consider all the available data of all years*/

-- CTE to count the total number of copies of each film available in each store.
WITH film_info AS (
  SELECT f.film_id, f.title, i.store_id, Count(f.title) AS total_copies_store
  FROM film f
    INNER JOIN inventory i ON f.film_id = i.film_id
  GROUP BY 1,2,3
  ORDER BY f.film_id
),
-- CTE to count the number of currently rented copies of each film in each store.
rented_inventory AS (
  SELECT f.film_id, s2.store_id, COUNT(*) AS rented
  FROM film f
    INNER JOIN inventory i ON f.film_id = i.film_id
    INNER JOIN store s2 ON i.store_id = s2.store_id
    LEFT JOIN rental r ON i.inventory_id = r.inventory_id
  WHERE r.return_date IS NULL -- Filters for films that are currently rented out.
  GROUP BY 1,2
  ORDER BY f.film_id
),
-- CTE to calculate the available inventory for each film by combining total copies and rented copies.
stats AS (
  SELECT fi.film_id, fi.title, fi.store_id, fi.total_copies_store, ri.rented,
    -- Calculate available inventory. If no copies are rented, available is total.
    CASE
      WHEN ri.rented IS NULL THEN fi.total_copies_store
      ELSE fi.total_copies_store - ri.rented
    END available_inventory
  FROM film_info fi
    LEFT JOIN rented_inventory ri ON fi.film_id = ri.film_id
    AND fi.store_id = ri.store_id
) 
-- Main query to display film availability stats, filtering for films with low availability.
SELECT st.film_id, st.title, st.store_id, st.total_copies_store, st.rented,st.available_inventory,
  -- Calculate the percentage of available copies.
  ROUND(st.available_inventory::numeric / st.total_copies_store * 100,2) AS percentage_available,
  -- Rank films by their availability percentage to identify the least available ones.
  DENSE_RANK() OVER (ORDER BY ROUND(st.available_inventory::numeric / st.total_copies_store * 100,2) DESC) AS ranking
FROM stats st
WHERE ROUND(st.available_inventory::numeric / st.total_copies_store * 100,2) < 50 -- Filter for films with less than 50% availability.
ORDER BY ranking DESC; -- Order to show the films with the worst availability first.
