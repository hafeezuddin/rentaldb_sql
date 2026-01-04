/**Customer Value & Behavior Analysis"

Write a single comprehensive query that returns:
Analysis date: 01-01-2006
Customer details (ID, name, email, active status - Rented in last 150 Days)
Their lifetime value (total payments)
Rental frequency (rentals per month)
Last rental date
Days since last rental

Favorite category (most rented)
Store they primarily use
Staff member who usually helps them

Requirements:
Use CTEs or subqueries
Handle ties for favorite category
Include both active and inactive customers
Rank customers by lifetime value percentile
Flag customers who haven't rented in > 150 days as "at-risk" **/

SELECT c.customer_id, c.first_name, c.email,
       EXTRACT(MONTH FROM age(MAX(r.rental_date),MIN(r.rental_date))) + 1 AS active_months,
       SUM(p.amount) AS life_time_payments, to_char(DATE_TRUNC('day', MAX(r.rental_date)), 'YYYY-MM-DD') AS last_rental_date,
       EXTRACT(DAYS FROM '01-01-2006' - MAX(r.rental_date)) AS days_since_last_rental,
       COUNT(distinct r.rental_id) AS total_rentals, --Paid rentals
       ROUND(COUNT(distinct  r.rental_id)::numeric/(EXTRACT(MONTH FROM age(MAX(r.rental_date),MIN(r.rental_date))) + 1),2) AS rental_frequency,
       CASE
           WHEN '2006-01-01' - MAX(r.rental_date::date) < 150
                THEN 'active'
            ELSE
                'Inactive'
       END AS active_status
FROM customer c
INNER JOIN rental r ON c.customer_id = r.customer_id
INNER JOIN payment p ON r.rental_id = p.rental_id
WHERE r.rental_date >= '2005-01-01' AND r.rental_date <= '2005-12-31'
GROUP BY c.customer_id, c.first_name, c.email;