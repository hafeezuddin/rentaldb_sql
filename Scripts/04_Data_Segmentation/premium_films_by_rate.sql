/* Films with rental rate higher than average (premium films) */
--CTE To calculate average rental rate of all films
WITH avg_price AS (
  SELECT AVG(f.rental_rate) AS avg_rate FROM film f
)
--Main query to filter films which are above average price
SELECT f.film_id,
  f.title,
  f.rental_rate,
  ROUND(ap.avg_rate, 2) AS avgrate
FROM film f
  CROSS JOIN avg_price ap 
WHERE rental_rate > ap.avg_rate
ORDER BY f.film_id;


-- Alternative using subquery
SELECT f.film_id,
  f.title,
  f.rental_rate,
  ROUND((SELECT AVG(f.rental_rate) FROM film f),2) AS avg_rental_rate
FROM film f
WHERE f.rental_rate > (SELECT AVG(f.rental_rate) FROM film f)
ORDER BY film_id;
