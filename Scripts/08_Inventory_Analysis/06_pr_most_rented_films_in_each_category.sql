/* Most rented films in each category */
--Test to check if each film has exactly one category
SELECT t1.film_id FROM (
SELECT f.film_id,
       row_number() over (partition by f.film_id) AS flm_dup
       FROM film_category f
) t1
WHERE t1.flm_dup > 1;

--Zero results. Each film belongs to one category
--(or)
SELECT film_id
FROM film_category
GROUP BY film_id
HAVING COUNT(*) > 1;

--Base rental cte
WITH base_rental AS (
    SELECT f.film_id,
           f.title, ct.name,
           COUNT(r.rental_id) total_rentals,
           rank() over (PARTITION BY ct.name ORDER BY COUNT(r.rental_id) DESC) rank
           --Returns to three films in each category
    FROM film f
    JOIN inventory i ON f.film_id = i.film_id
    JOIN rental r ON i.inventory_id = r.inventory_id
    JOIN film_category fc ON f.film_id = fc.film_id
    JOIN category ct ON fc.category_id = ct.category_id
    WHERE r.rental_date >= '2005-01-01' AND r.rental_date < '2006-01-01'    --Confines to year 2005 trends.
    GROUP BY F.film_id, f.title, ct.name
)
SELECT br.film_id, br.title, br.name, br.rank, br.total_rentals
FROM base_rental br
WHERE br.rank <= 3
ORDER BY br.name, br.rank;

-- Planning Time: 12.528 ms
-- Execution Time: 28.664 ms
