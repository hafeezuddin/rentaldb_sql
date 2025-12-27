/*Find the top 3 most-rented films in each category.
For each film, show: Category name,Film title, Number of times it was rented, Its rank within the category */
WITH films_data AS (
    SELECT f.film_id, f.title, c.name, COUNT(f.film_id) AS times_rented, SUM(f.rental_rate), f.release_year,
    ROW_NUMBER() OVER (PARTITION BY c.name ORDER BY COUNT(f.film_id) DESC, SUM(f.rental_rate) DESC, f.title ASC) AS ranks
    FROM film f
    INNER JOIN inventory i ON f.film_id = i.film_id
    INNER JOIN rental r ON i.inventory_id = r.inventory_id
    INNER JOIN payment p ON r.rental_id = p.rental_id
    INNER JOIN film_category fc ON f.film_id = fc.film_id
    INNER JOIN category c ON fc.category_id = c.category_id
    WHERE r.return_date IS NOT NULL AND (r.rental_date >= '2005-01-01' AND r.rental_date <= '2005-12-31')
    GROUP BY f.film_id, f.title, c.name, f.release_year
)
SELECT fd.film_id, fd.title, fd.name, fd.times_rented, fd.ranks
FROM films_data fd
WHERE ranks <=3;