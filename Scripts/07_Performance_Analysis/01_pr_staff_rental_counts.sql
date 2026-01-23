/* Number of films rented out by each staff member */
SELECT r.staff_id,
       s.email AS staff_email,
       s.store_id,
       s.first_name AS staff_first_name,
       COUNT(r.staff_id) AS rented_out_times
FROM rental r
JOIN staff s ON r.staff_id = s.staff_id
GROUP BY r.staff_id,s.email,s.first_name,s.store_id;