/* Monthly paid rental patterns for 2005 */
SELECT 
  TO_CHAR(rental_date, 'MM') AS month,
  EXTRACT(YEAR FROM rental_date) AS year,
  COUNT(DISTINCT r.rental_id) AS rental_count
FROM rental r
JOIN payment p ON r.rental_id = p.rental_id
WHERE r.return_date IS NOT NULL AND (r.rental_date >='2005-01-01' AND r.rental_date <= '2005-12-31')
GROUP BY 1,2
ORDER BY rental_count DESC;
