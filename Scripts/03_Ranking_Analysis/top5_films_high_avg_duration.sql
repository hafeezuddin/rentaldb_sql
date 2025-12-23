/* Top 5 films that meet rental-count and average duration criteria */
SELECT f.film_id,
    f.title,
    c.name,
    COUNT(DISTINCT r.rental_id) AS no_of_times_rented,
    --Exact average rental duration calculation using epoch function
    AVG(EXTRACT(EPOCH FROM (r.return_date -r.rental_date))/86400.0) AS average_rental_duration_days
FROM film f
    INNER JOIN film_category fc ON f.film_id = fc.film_id           -- To retrieve film category name
    INNER JOIN category c ON fc.category_id = c.category_id         -- To retrieve film category name
    INNER JOIN inventory i ON f.film_id = i.film_id                 --To map film to inventory
    INNER JOIN rental r ON i.inventory_id = r.inventory_id          --Mapping inventory to rentals
    INNER JOIN payment p ON r.rental_id = p.rental_id               --Considering only paid rentals
WHERE r.return_date IS NOT NULL
GROUP BY 1,2,3
HAVING count(distinct r.rental_id) >= 10
ORDER BY average_rental_duration_days DESC
LIMIT 5;