/* Find the top 5 customers in each country by total rental amount for year 2005.
For each customer, show: Country name, Customer ID and name
Total amount spent
Their rank within the country,
Their percentage share of that country’s rental revenue */

--Base rental CTE with customers and rental information.
WITH base_rental AS (SELECT r.customer_id,
                            co.country,
                            c.first_name,
                            c.last_name,
                            SUM(p.amount)                                                           AS total_spent,
                            row_number() over (partition by co.country ORDER BY sum(p.amount) DESC) AS position
                     FROM rental r
                              JOIN payment p ON r.rental_id = p.rental_id
                              JOIN customer c ON r.customer_id = c.customer_id
                              JOIN address ad ON c.address_id = ad.address_id
                              JOIN city ci ON ad.city_id = ci.city_id
                              JOIN country co ON ci.country_id = co.country_id
                     WHERE r.rental_date BETWEEN '2005-01-01' AND '2005-12-31'
                     GROUP BY r.customer_id, co.country, c.first_name, c.last_name),
--Country totals metric calculation
     country_totals AS (SELECT br.country, SUM(br.total_spent) AS total_country_revenue
                        FROM base_rental br
                        GROUP BY br.country)
--Main query to filter top 5 customers in each country and their contribution in total revenue
SELECT br.customer_id,
       CONCAT(br.first_name, ' ', br.last_name)                                            AS full_name,
       br.country,
       br.position                                                                         AS position_in_country,
       br.total_spent,
       ROUND((COALESCE(br.total_spent, 0) / NULLIF(ct.total_country_revenue, 0)) * 100, 2) AS revenue_contribution
FROM base_rental br
         JOIN country_totals ct ON br.country = ct.country
WHERE position <= 5
ORDER BY br.country;
