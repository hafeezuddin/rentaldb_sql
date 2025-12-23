/* Top revenue generating cities */
SELECT
    c.city,
    co.country,
    EXTRACT(YEAR FROM p.payment_date) AS year,
    SUM(p.amount) AS total_revenue
FROM city c
  JOIN address a ON c.city_id = a.city_id
  JOIN customer ct ON a.address_id = ct.address_id
  JOIN payment p ON ct.customer_id = p.customer_id -- Considering paid rentals only
  INNER JOIN country co ON c.country_id = co.country_id
GROUP BY c.city,year, co.country
ORDER BY total_revenue DESC
LIMIT 10;
