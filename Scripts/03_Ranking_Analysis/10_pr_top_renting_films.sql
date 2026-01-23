/* How many times each film is rented out / Top renting films in the year 2005.
   Consider rentals where revenue generated details are accurate*/
SELECT f.film_id,
       f.title AS film_name,
       COUNT(distinct r.rental_id) AS total_rentals
       --To handle edge case of avoiding overcounting after joining payment table
       -- and customer splits his transaction into two.
FROM film f
JOIN inventory i ON f.film_id = i.film_id
JOIN rental r ON i.inventory_id = r.inventory_id
JOIN payment p ON r.rental_id = p.rental_id
--To consider paid rentals.
-- Using distinct in select clause count unique rentals
WHERE r.rental_date BETWEEN '2005-01-01' AND '2005-12-31'
--Filters 2005 rentals
GROUP BY f.film_id,f.title
ORDER BY total_rentals DESC
LIMIT 10;
