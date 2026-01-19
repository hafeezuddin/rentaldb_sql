/*Find the top 5 actors who:
Have acted in films from at least 7 different categories.
Have an average rental rate (across all their films) above the overall average rental rate of all films in the database.
Output columns: actor_id, first_name, last_name, num_categories (distinct film categories), avg_rental_rate*/

--BASE CTE for films and actors
WITH base_info AS (
    SELECT a.actor_id, a.first_name, a.last_name, fc.category_id
    FROM actor a
    JOIN film_actor fa ON a.actor_id = fa.actor_id
    JOIN film_category fc ON fa.film_id = fc.film_id
),
--Filtering actors who acted in at least 7 distinct categories
actors_acted_in_seven_cat AS (
    SELECT bi.actor_id, bi.first_name, bi.last_name,
           COUNT(DISTINCT bi.category_id) AS distinct_categories
    FROM base_info bi
    GROUP BY bi.actor_id, bi.first_name, bi.last_name
    HAVING count(distinct bi.category_id) >=7
),
--This CTE is created separately to avoid duplicates and inflated totals/averages when film is categorized into two categories in base cte
    --Not Joining categories in this cte for accurate calculation of actors total rentals without inflating
actor_rental_rate AS (
    SELECT aa.actor_id, aa.first_name, aa.last_name, ROUND(AVG(f.rental_rate),2) AS actor_total_rentals
    FROM actors_acted_in_seven_cat aa
    JOIN film_actor fa ON aa.actor_id = fa.actor_id
    JOIN film f ON fa.film_id = f.film_id
    GROUP BY aa.actor_id, aa.first_name, aa.last_name
    )
--Main query to list actors who's average rental rate of his/her films is greater than overall rental rate of films
SELECT ar.actor_id, ar.first_name, ar.last_name, aa.distinct_categories, ar.actor_total_rentals
FROM actor_rental_rate ar
JOIN actors_acted_in_seven_cat aa ON ar.actor_id = aa.actor_id
WHERE ar.actor_total_rentals > (SELECT AVG(f.rental_rate) FROM film f)
ORDER BY ar.actor_total_rentals DESC
LIMIT 5;
