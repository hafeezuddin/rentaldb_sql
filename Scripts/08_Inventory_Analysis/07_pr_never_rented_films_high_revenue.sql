/* Task: Identify Never-Rented Films with High Revenue Potential.
 Find films that meet all of these criteria:

 Zero Rentals: Never been rented
 High Value: Rental rate above the average for their category
 In Stock: Currently available in inventory. */

WITH category_average AS (SELECT fc.category_id, ROUND(AVG(f.rental_rate), 2) category_average
                          FROM film f
                                   JOIN film_category fc ON f.film_id = fc.film_id
                          GROUP BY fc.category_id),
     unrented_films AS (SELECT f.film_id, f.rental_rate, f.title, COUNT(f.film_id) available_inventory
                        FROM film f
                                 JOIN inventory i ON f.film_id = i.film_id
                        WHERE f.film_id NOT IN (SELECT DISTINCT f.film_id
                                                FROM (SELECT i.film_id
                                                      FROM rental r
                                                               JOIN inventory i ON r.inventory_id = i.inventory_id) t)
                        GROUP BY f.film_id)
SELECT uf.film_id, uf.title
FROM unrented_films uf
         JOIN film_category fc ON uf.film_id = fc.film_id
         JOIN category_average ca ON fc.category_id = ca.category_id
WHERE uf.rental_rate > ca.category_average

-- Planning Time: 0.857 ms
-- Execution Time: 4.782 ms



