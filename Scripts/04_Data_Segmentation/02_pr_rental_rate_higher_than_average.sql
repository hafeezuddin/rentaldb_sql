/* Films with rental rate higher than average (premium films) */
--CTE to calculate average rental rate
WITH average_rental_rate AS (SELECT AVG(f.rental_rate) AS overall_avg_rental_rate
                             FROM film f)
--Main query to filter films whose rental price is more than average rental price.
SELECT f.film_id, f.title, f.rental_rate
FROM film f
         CROSS JOIN average_rental_rate arr
WHERE f.rental_rate >= arr.overall_avg_rental_rate
ORDER BY f.rental_rate DESC;

--Subquery version
SELECT f.film_id, f.title, f.rental_rate
FROM film f
WHERE f.rental_rate >= (SELECT AVG(f.rental_rate) FROM film f)
--Filtering films based on subquery.
ORDER BY f.rental_rate DESC;