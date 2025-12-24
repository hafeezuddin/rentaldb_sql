/* Number of films rented out by each staff member */
SELECT 
  r.staff_id,
  s.email,
  COUNT(*) AS rental_count
FROM rental r
  JOIN staff s ON r.staff_id = s.staff_id
GROUP BY r.staff_id, s.email
ORDER BY rental_count DESC;
