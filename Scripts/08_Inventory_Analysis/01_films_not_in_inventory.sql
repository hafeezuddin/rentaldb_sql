/* Business case: Films not in inventory (Currently Rented out - Unreturned films) */
SELECT f.film_id, i.inventory_id, f.title
FROM film f
JOIN inventory i ON f.film_id = i.film_id
LEFT JOIN rental r ON i.inventory_id = r.inventory_id AND r.return_date IS NULL
--Joins only unreturned rentals.
WHERE r.rental_id IS NOT NULL
--Filters films which were not returned
ORDER BY f.film_id;

/* Business Case: Films with No recorded inventory copies/stock */
SELECT f.film_id, f.title
FROM film f
LEFT JOIN inventory i ON f.film_id = i.film_id
WHERE i.inventory_id IS NULL

/* Total count of films with no inventory stock record */
SELECT COUNT(*) films_count_with_zero_inventory
FROM film f
LEFT JOIN inventory i ON f.film_id = i.film_id
WHERE i.inventory_id IS NULL