/* Busiest hours by rental count.
   Consider only paid rentals and 2005 data */
SELECT EXTRACT(HOUR FROM r.rental_date) AS hour_of_day,
       COUNT(DISTINCT r.rental_id)      AS rental_count
FROM rental r
         INNER JOIN payment p ON r.rental_id = p.rental_id
         --To filter out unpaid rentals.
         -- Eliminate INNER JOIN on payments to consider all rentals in specified period.
WHERE r.return_date IS NOT NULL
  AND (r.rental_date > '2005-01-01' AND r.rental_date <= '2005-12-31')
GROUP BY hour_of_day
ORDER BY rental_count DESC
LIMIT 10;