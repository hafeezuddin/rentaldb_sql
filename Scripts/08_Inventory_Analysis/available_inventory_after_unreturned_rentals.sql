--QUERY RETURNS AVAILABLE COPIES OF FILMS (AFTER ACCOUNTING FOR UNRETURNED FILMS)
SELECT f.film_id, COUNT(*)
FROM film f
INNER JOIN inventory i ON f.film_id = i.film_id
WHERE i.inventory_id NOT IN 
    (SELECT r.inventory_id 
        FROM rental r 
        WHERE r.return_date IS NULL)
GROUP BY 1
ORDER BY 1 ASC;

--Using left Join
SELECT f.film_id, COUNT(*)
FROM film f
INNER JOIN inventory i ON f.film_id = i.film_id
--Conditional left joins (Joins only rentals that are out)
LEFT JOIN rental r ON i.inventory_id = r.inventory_id AND r.return_date IS NULL
WHERE r.rental_id IS NULL --Filters currently out inventory based on conditional left join
GROUP BY f.film_id
ORDER BY f.film_id ASC;