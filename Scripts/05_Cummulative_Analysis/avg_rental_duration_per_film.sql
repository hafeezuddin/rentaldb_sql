/* Average rental duration per film */
SELECT f.film_id, f.title,
  EXTRACT(DAY FROM AVG(r.return_date - r.rental_date)) AS avg_rental_days
FROM film f
  JOIN inventory i ON f.film_id = i.film_id
  JOIN rental r ON i.inventory_id = r.inventory_id
  JOIN payment p ON r.rental_id = p.rental_id
WHERE r.return_date IS NOT NULL AND (r.rental_date >= '2005-01-01' AND r.rental_date <= '2005-12-31')
GROUP BY f.film_id,
  f.title
ORDER BY avg_rental_days DESC;
