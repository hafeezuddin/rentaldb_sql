/* List top three films in each film category in year 2005 */
/* Approach 1 */
WITH base_film_cte AS (SELECT f.film_id,
                              f.title,
                              COUNT(DISTINCT r.rental_id) times_rented
                       --Ensures each rental is accounted once.
                       FROM film f
                                JOIN inventory i ON f.film_id = i.film_id
                                JOIN rental r ON i.inventory_id = r.inventory_id
                       WHERE r.rental_date BETWEEN '2005-01-01' AND '2005-12-31'
                       --Date in ISO Format for filtering 2005 rentals
                       GROUP BY f.film_id, f.title),
--Categories CTE to map films to film categories
--Approach concatenates film categories if the film belongs to two categories.
--Check alternate approach below after main query that categorizes film into each category it belongs to as a distinct row.
     categories AS (SELECT bfc.film_id,
                           bfc.title,
                           bfc.times_rented,
                           STRING_AGG(cat.name, ', ')                                                                 AS categories,
                           row_number()
                           over (PARTITION BY STRING_AGG(cat.name, ', ') ORDER BY bfc.times_rented DESC)              AS position
                           --This window function considers multiple categories if any for film as a single window and ranks
                    FROM base_film_cte bfc
                             JOIN film_category fc ON bfc.film_id = fc.film_id
                             JOIN category cat ON fc.category_id = cat.category_id
                    GROUP BY bfc.film_id, bfc.title, bfc.times_rented)
SELECT *
FROM categories
WHERE position <= 3;


/* Approach 2*/
/* This approach list films and its category (multiple if any) as distinct rows */
WITH film_data AS (SELECT c.name,
                          f.film_id,
                          f.title,
                          COUNT(DISTINCT r.rental_id)                                                                           AS total_rentals,
                          ROW_NUMBER()
                          OVER (PARTITION BY c.name ORDER BY COUNT(DISTINCT r.rental_id) DESC, f.release_year ASC, f.title ASC) as rank
                   FROM film f
                            INNER JOIN film_category fc ON f.film_id = fc.film_id
                            INNER JOIN category c ON fc.category_id = c.category_id
                            INNER JOIN inventory i ON f.film_id = i.film_id
                            INNER JOIN rental r ON i.inventory_id = r.inventory_id --Considering both paid and unpaid rentals
                   WHERE r.rental_date >= '2005-01-01'
                     AND r.rental_date <= '2005-12-31' --Considering 2005 rentals and Date in ISO format for consistency
                   GROUP BY 1, 2, 3)
SELECT fd.film_id, fd.title, fd.name, fd.total_rentals, fd.rank
FROM film_data fd
WHERE rank <= 3;