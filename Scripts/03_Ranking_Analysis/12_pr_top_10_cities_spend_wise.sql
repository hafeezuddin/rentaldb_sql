/*Find the top 10 cities where customers have spent the highest total amount on rentals (2005).
For each city, also show:
  Total number of rentals made, Total amount spent, Average spend per rental
  Only include cities where at least 20 rentals were made.
  Compare each city’s total spend against the overall average city spend (and only keep those above average)*/

--Base CTE to get rental transactions of each customer
WITH base_rental_information AS (
    SELECT ci.city, r.rental_id, p.amount
    FROM rental r
    JOIN payment p ON r.rental_id = p.rental_id
    --INNER JOIN considers only paid rentals.
    -- Replace with LEFT JOIN to account for Unpaid rentals as well.
    -- Since, business case as financial metrics INNER JOIN has been used.
    JOIN customer c ON r.customer_id = c.customer_id
    JOIN address ad ON c.address_id = ad.address_id
    JOIN city ci ON ad.city_id = ci.city_id
    WHERE r.rental_date BETWEEN '2005-01-01' AND '2005-12-31'
    --Date in ISO FORMAT
),
--Core metrics calculation
aggregate_metrics AS (
    SELECT bri.city,
           COALESCE(COUNT(DISTINCT bri.rental_id),0) AS total_rentals,
           --To account for duplicated rental_id's in edge cases where customer may split the payment in two transactions
           COALESCE(SUM(bri.amount),0) AS total_city_revenue
    FROM base_rental_information bri
    GROUP BY bri.city
),
--CTE to calculate overall average revenue of all cities
Overall_revenue_average AS (
    SELECT ROUND(AVG(am.total_city_revenue),2) AS overall_average FROM aggregate_metrics am
)
--Main query to list top 10 cities revenue wise and with filter conditions (At least 20 rentals & total revenue > average revenue) Applied.
SELECT am.city,
       am.total_rentals,
       am.total_city_revenue,
       ROUND(am.total_city_revenue/am.total_rentals,2) AS average_revenue_per_rental
FROM aggregate_metrics am
CROSS JOIN Overall_revenue_average ora
WHERE am.total_rentals > 20 AND (am.total_city_revenue > ora.overall_average)
ORDER BY am.total_city_revenue DESC
LIMIT 10;