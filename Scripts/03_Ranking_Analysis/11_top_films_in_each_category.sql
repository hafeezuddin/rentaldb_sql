/* Top film in each category in the year 2005. Consider paid rentals */
WITH base_rentals_table AS (SELECT f.film_id,
                                   f.title,
                                   cat.name,
                                   r.rental_id
                            FROM film f
                                     JOIN film_category fc ON f.film_id = fc.film_id
                                     JOIN category cat ON fc.category_id = cat.category_id
                                --If film is listed in two categories.
                                -- This join creates two distinct rows for same film with distinct category
                                     JOIN inventory i ON f.film_id = i.film_id
                                     JOIN rental r ON i.inventory_id = r.inventory_id
                                     JOIN payment p ON r.rental_id = p.rental_id
                            WHERE r.rental_date BETWEEN '2005-01-01' AND '2005-12-12'),
--CTE to rank films in their category
     film_ranking AS (SELECT brt.film_id,
                             brt.title,
                             brt.name,
                             COUNT(distinct brt.rental_id)                                                         AS total_rentals,
                             --Handles edge case where film fits into two categories and avoids inflating the count
                             row_number()
                             over (PARTITION BY brt.name ORDER BY COUNT(distinct brt.rental_id) DESC)              AS position
                      FROM base_rentals_table brt
                      GROUP BY brt.film_id, brt.title, brt.name)
SELECt fr.film_id, fr.title, fr.name, fr.total_rentals
FROM film_ranking fr
WHERE fr.position = 1
ORDER BY fr.name;