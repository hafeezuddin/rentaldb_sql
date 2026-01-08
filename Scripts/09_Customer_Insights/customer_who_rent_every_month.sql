/*Business Question: "Identify customers who consistently rent films every month"
Requirements:
Find customers who have rented at least once in every month of the current year (2005)
Show customer details and their monthly rental consistency */
--CTE to select customers who ordered in 2005 (Assuming we are in dec 2005)

WITH this_year_rentals AS (
SELECT c.customer_id, c.first_name, c.last_name, r.rental_date,
EXTRACT('month' FROM r.rental_date) AS month
FROM customer c
INNER JOIN rental r ON c.customer_id = r.customer_id --Consider both paid and unpaid rentals
WHERE r.rental_date BETWEEN '2005-01-01' AND '2005-12-31' --Analysis for year 2005
),
--CTE to count customers ordering
every_month AS (
  SELECT tyr.customer_id, COUNT(DISTINCT tyr.month) AS distinct_months_rented
  FROM this_year_rentals tyr
  GROUP BY 1
  HAVING COUNT(DISTINCT tyr.month) =12
)
SELECT em.customer_id, CONCAT(c.first_name,'',c.last_name) AS full_name,
TO_CHAR(DATE_TRUNC('month', r.rental_date::date), 'YYYY-MM') AS ym,
COUNT(*) AS rental_counts FROM every_month em 
INNER JOIN rental r ON em.customer_id = r.customer_id
INNER JOIN customer c ON r.customer_id = c.customer_id
GROUP BY 1,2,3
ORDER BY em.customer_id;