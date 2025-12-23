
/*Find the top 5 actors who:
Have acted in films from at least 7 different categories.
Have an average rental rate (across all their films) above the overall average rental rate of all films in the database.
Output columns: actor_id, first_name, last_name, num_categories (distinct film categories), avg_rental_rate*/

--CTE to filter actors who have acted in at-least 7 different categories
WITH actor_filter AS (
    SELECT 
        a.actor_id,
        a.first_name,
        a.last_name,
        count(DISTINCT c.name) AS num_categories
    FROM actor a
        INNER JOIN film_actor fa ON a.actor_id = fa.actor_id
        INNER JOIN film_category fc ON fa.film_id = fc.film_id
        INNER JOIN category c ON fc.category_id = c.category_id
    GROUP BY 1,2,3
    HAVING COUNT(DISTINCT c.name) >= 7
),
--CTE to calculate average rental rate of the actor and comparing to overall average rental rate of all the films.
rental_rate_cte AS (
    SELECT a.actor_id,
        AVG(f.rental_rate) AS actor_avg_rental_rate
    FROM actor a
        INNER JOIN film_actor fa ON a.actor_id = fa.actor_id
        INNER JOIN film f ON fa.film_id = f.film_id
    GROUP BY 1
    HAVING AVG(f.rental_rate) > (
            SELECT AVG(f2.rental_rate)
            FROM film f2
        )
)
SELECT af.actor_id,
    af.first_name,
    af.last_name,
    af.num_categories,
    ROUND(rrc.actor_avg_rental_rate,2)
FROM actor_filter af
    INNER JOIN rental_rate_cte rrc ON af.actor_id = rrc.actor_id
ORDER BY rrc.actor_avg_rental_rate DESC
LIMIT 5;

