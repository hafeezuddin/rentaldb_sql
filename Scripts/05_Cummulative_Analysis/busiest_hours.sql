/* Busiest hours by rental count. Consider only paid rentals and 2005 data */
SELECT EXTRACT(HOUR FROM rental_date) AS hour_of_day,
  COUNT(*) AS rental_count
FROM rental
INNER JOIN payment p ON rental.rental_id = p.rental_id
WHERE rental.return_date IS NOT NULL
  AND (rental.rental_date > '2005-01-01' AND rental.rental_date <= '2005-12-31')
GROUP BY hour_of_day
ORDER BY rental_count DESC
LIMIT 10;