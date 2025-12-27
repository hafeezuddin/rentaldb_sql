/* Top Rented films in each category and Number of times they were rented. (Consider only paid rentals for analysis)*/
--CTE to find No.of.Times each film is rented/to calculate rental counts per film.

WITH filmcount AS (
  SELECT f.film_id, c.name, f.title,
    COUNT(*) AS total_rents
  FROM film f
    INNER JOIN inventory i ON f.film_id = i.film_id
    INNER JOIN rental r ON i.inventory_id = r.inventory_id
    INNER JOIN payment p ON r.rental_id = p.rental_id
    INNER JOIN film_category fc ON f.film_id = fc.film_id
    INNER JOIN category c ON fc.category_id = c.category_id
  GROUP BY 1,2,3
),
-- CTE to find the maximum rental count for each category
Catmax AS (
  SELECT name, MAX(total_rents) AS max_rent
  FROM filmcount
  GROUP BY name

) --Main query to JOIN the results and display most rented films in each category.
SELECT cm.name AS category,
  flc.film_id,
  flc.title AS film_name,
  flc.total_rents AS no_of_times_rented
FROM filmcount flc
  INNER JOIN catmax cm ON flc.name = cm.name
WHERE flc.total_rents = cm.max_rent
ORDER BY cm.name;

--Using window function
WITH film_count AS (
SELECT f.film_id,
    c.name,
    f.title,
    COUNT(*) AS total_rents,
    DENSE_RANK() OVER (PARTITION BY c.name ORDER BY COUNT(*) DESC) AS ranking
  FROM film f
    INNER JOIN inventory i ON f.film_id = i.film_id
    INNER JOIN rental r ON i.inventory_id = r.inventory_id
    INNER JOIN payment p ON r.rental_id = p.rental_id
    INNER JOIN film_category fc ON f.film_id = fc.film_id
    INNER JOIN category c ON fc.category_id = c.category_id
  GROUP BY 1,2,3
)
SELECT fc.film_id, fc.name, fc.title, fc.total_rents,fc.ranking
FROM film_count fc
WHERE ranking =1;