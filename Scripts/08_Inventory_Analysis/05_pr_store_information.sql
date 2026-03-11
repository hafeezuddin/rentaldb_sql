/* Store information with city and country */
SELECT s.store_id,
       c.city,
       CONCAT(st.first_name, ' ', st.last_name) AS manager_name,
       co.country,
       COUNT(st.staff_id)                       AS no_of_staff
FROM store s
         JOIN address a ON s.address_id = a.address_id
         JOIN city c ON a.city_id = c.city_id
         JOIN country co ON c.country_id = co.country_id
         JOIN staff st ON s.store_id = st.store_id
GROUP BY s.store_id, c.city, st.last_name, st.first_name, co.country;
