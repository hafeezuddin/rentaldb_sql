/* Top revenue generating cities for rentals in 2005 */
--BASE CTE to retrieve rental information
WITH rental_info AS (SELECT r.customer_id, ci.city, r.rental_id, p.amount
                     FROM rental r
                              JOIN payment p ON r.rental_id = p.rental_id
                              --INNER JOIN to consider paid rentals for analysis
                              --LEFT JOIN cannot be used for financial analysis as it retains unpaid rentals
                              JOIN customer c ON r.customer_id = c.customer_id
                              JOIN address a ON c.address_id = a.address_id
                              JOIN city ci ON a.city_id = ci.city_id
                     WHERE r.rental_date BETWEEN '2005-01-01' AND '2005-12-31')
                     --Filtering rentals dataset to 2005 rentals as required by business case

--Main query to list top cities and their revenue share.
SELECT ri.city, SUM(ri.amount) AS city_revenue,
       ROUND((COALESCE(SUM(ri.amount),0)::NUMERIC/NULLIF((SUM(SUM(ri.amount)) OVER ()),0))*100,2) AS revenue_share
FROM rental_info ri
GROUP BY ri.city
ORDER BY city_revenue desc
LIMIT 10;
