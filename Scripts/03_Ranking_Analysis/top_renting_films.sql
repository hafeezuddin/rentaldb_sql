/* How many times each film is rented out / Top renting films in the year 2005.
   Consider rentals where revenue generated details are accurate*/

SELECT f.film_id, f.title, COUNT(f.film_id) AS total_rentals
FROM film f
INNER JOIN inventory i ON f.film_id = i.film_id
INNER JOIN rental r ON i.inventory_id = r.inventory_id
INNER JOIN payment p ON r.rental_id = p.rental_id --Considering only paid rentals
WHERE r.return_date IS NOT NULL AND (r.rental_date >= '2005-01-01' AND r.rental_date <= '2005-12-31')
GROUP BY f.film_id,f.title
ORDER BY total_rentals DESC;