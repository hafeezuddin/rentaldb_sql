/* Top Rented films in each category and Number of times they were rented.
   (Consider only paid rentals for analysis)*/

--Preliminary checks
--Check to find if each film has exactly one primary film category to avoid cartesian product when joining tables.
SELECT f.film_id, COUNT(*)
FROM film f
         JOIN film_category fc ON f.film_id = fc.film_id
GROUP BY 1
HAVING COUNT(*) > 1;
--Each film has exactly one primary category assigned to it. Safe to Join.

--CTE to find No.of.Times each film is rented/to calculate rental counts per film.
WITH base_rental AS (SELECT f.film_id,
                            f.title,
                            ct.name                                                                                     category_name,
                            COUNT(DISTINCT r.rental_id)                                                                 times_rented_in_2005,
                            --Distinct keyword included to avoid over counting (In cases when one rental has multiple split payments)
                            row_number()
                            OVER (PARTITION BY ct.name ORDER BY COUNT(*) DESC, f.rental_rate DESC, f.release_year ASC) film_rank
                            --Additional columns to break ties.
                     FROM rental r
                              JOIN inventory i ON r.inventory_id = i.inventory_id
                              JOIN film f ON i.film_id = f.film_id
                              JOIN film_category fc ON f.film_id = fc.film_id
                              JOIN category ct ON fc.category_id = ct.category_id
                              JOIN payment p ON r.rental_id = p.rental_id
                     WHERE (r.rental_date BETWEEN '2005-01-01' AND '2005-12-31')
                       AND (r.return_date IS NOT NULL)
                     --Filtering base data set to 2005 Year & excluding records which were unreturned.
                     GROUP BY f.film_id, f.title, ct.name)
--Main query to filter top films in each category.
SELECT br.category_name, br.title top_rented_film, br.times_rented_in_2005
FROM base_rental br
WHERE br.film_rank <= 1
ORDER BY br.category_name;

-- Planning Time: 1.414 ms
-- Execution Time: 34.152 ms