/* Top rented films per category in year 2005 (using CTEs) */
--CTE to retrieve film rentals and their rental counts.
WITH film_rentals AS (
  SELECT f.film_id,
    f.title,
    c.name AS category,
    COUNT(*) AS rental_count
  FROM film f
    JOIN film_category fc ON f.film_id = fc.film_id
    JOIN category c ON fc.category_id = c.category_id
    JOIN inventory i ON f.film_id = i.film_id
    JOIN rental r ON i.inventory_id = r.inventory_id
    JOIN payment p ON r.rental_id = p.rental_id
  WHERE r.return_date IS NOT NULL AND (r.rental_date >= '2005-01-01' AND r.rental_date <= '2005-12-31') --To consider only paid rentals
  GROUP BY f.film_id, f.title, c.name
),

--CTE to category maximums from film_rentals cte.
category_max AS (
  SELECT category,
    MAX(rental_count) AS max_rentals
  FROM film_rentals
  GROUP BY category
)
SELECT fr.film_id,
  fr.title,
  fr.category,
  fr.rental_count
FROM film_rentals fr
  JOIN category_max cm ON fr.category = cm.category
  AND fr.rental_count = cm.max_rentals 
ORDER BY fr.category;



/* Option:2 */
/* Top rented films per category in year 2005 (using CTEs) */

SELECT sq2.film_id, sq2.title, sq2.category, sq2.rental_count
FROM (SELECT f.film_id,
             f.title,
             c.name AS category,
             COUNT(*)  AS rental_count,
             ROW_NUMBER() OVER (PARTITION BY c.name ORDER BY count(*) DESC) AS position
      FROM film f
               JOIN film_category fc ON f.film_id = fc.film_id
               JOIN category c ON fc.category_id = c.category_ids
               JOIN inventory i ON f.film_id = i.film_id
               JOIN rental r ON i.inventory_id = r.inventory_id
               JOIN payment p ON r.rental_id = p.rental_id          --To consider only paid rentals
      WHERE r.return_date IS NOT NULL
        AND (r.rental_date >= '2005-01-01' AND r.rental_date <= '2005-12-31')
      GROUP BY f.film_id, f.title, c.name) sq2
WHERE sq2.position = 1;