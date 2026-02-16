/* Rental trends by location (City, Country), Year and Month for year 2005.
   Paid rentals only */

SELECT TO_CHAR(date_trunc('Month', r.rental_date::date), 'YYYY-MM') YYYY_MM,
       ci.city, co.country, COUNT(DISTINCT r.rental_id) total_rentals
FROM rental r
JOIN payment p ON r.rental_id = p.rental_id
JOIN customer c ON r.customer_id = c.customer_id
JOIN address a ON c.address_id = a.address_id
JOIN city ci ON a.city_id = ci.city_id
JOIN country co ON ci.country_id = co.country_id
WHERE r.rental_date BETWEEN '2005-01-01' AND '2005-12-31'
group by TO_CHAR(date_trunc('Month', r.rental_date::date), 'YYYY-MM'),
       ci.city, co.country