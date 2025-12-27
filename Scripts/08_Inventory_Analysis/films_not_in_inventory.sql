/* Films not in inventory */
SELECT 
  f.film_id,
  f.title
FROM film f
  LEFT JOIN inventory i ON f.film_id = i.film_id
WHERE i.inventory_id IS NULL;

--Count of films not in inventory
SELECT
    Count(*) AS total_films_not_in_inventory
FROM film f
LEFT JOIN inventory i ON f.film_id = i.film_id
WHERE i.film_id IS NULL;
