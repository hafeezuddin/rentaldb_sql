/* Customers renting premium films (most expensive) */
--Sub-Query Version (Planning time: 0.943 ms, Execution Time: 16.910 ms)
SELECT DISTINCT r.customer_id, c.first_name, c.last_name, c.email
FROM rental r
         JOIN inventory i ON r.inventory_id = i.inventory_id
         JOIN customer c ON r.customer_id = c.customer_id
WHERE i.film_id IN (SELECT f.film_id
                    FROM film f
                    WHERE f.rental_rate = (SELECT MAX(f.rental_rate) FROM film f)
                    )
AND (r.rental_date BETWEEN '2005-01-01' AND '2005-12-31') AND r.return_date IS NOT NULL;


--CTE + Sub query version
--(Planning time: 0.917 ms, Execution Time: 17.007 ms)
WITH premium_films AS (SELECT f.film_id
                       FROM film f
                       WHERE f.rental_rate = (SELECT MAX(f.rental_rate) FROM film f))
SELECT DISTINCT c.customer_id, c.first_name, c.last_name, c.email
FROM rental r
         JOIN customer c ON r.customer_id = c.customer_id
         JOIN inventory i on r.inventory_id = i.inventory_id
         JOIN premium_films pf ON i.film_id = pf.film_id
WHERE (r.rental_date BETWEEN '2005-01-01' AND '2005-12-31')
  AND r.return_date IS NOT NULL;