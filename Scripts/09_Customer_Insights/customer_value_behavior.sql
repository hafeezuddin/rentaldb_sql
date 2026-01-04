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

--CTE for customer demographic and total metrics
WITH customer_insights AS (SELECT c.customer_id,
                                  EXTRACT(MONTH FROM age(MAX(r.rental_date), MIN(r.rental_date))) + 1             AS active_months,
                                  SUM(p.amount)                                                                   AS life_time_payments,
                                  percent_rank() OVER (ORDER BY SUM(p.amount) DESC)                               AS life_time_value_percent_rank,
                                  to_char(DATE_TRUNC('day', MAX(r.rental_date)), 'YYYY-MM-DD')                    AS last_rental_date,
                                  EXTRACT(DAYS FROM '01-01-2006' - MAX(r.rental_date))                            AS days_since_last_rental,
                                  COUNT(distinct r.rental_id)                                                     AS total_rentals, --Paid rentals
                                  ROUND(COUNT(distinct r.rental_id)::numeric /
                                        (EXTRACT(MONTH FROM age(MAX(r.rental_date), MIN(r.rental_date))) + 1),
                                        2)                                                                        AS rental_frequency,
                                  CASE
                                      WHEN '2006-01-01' - MAX(r.rental_date::date) < 150
                                          THEN 'active'
                                      ELSE
                                          'Inactive'
                                      END                                                                         AS active_status,
                                  CASE
                                      WHEN '2006-01-01' - MAX(r.rental_date::date) < 150
                                          THEN 'Not at Risk'
                                      ELSE
                                          'At Risk'
                                      END AS                                                                      risk_status
                           FROM customer c
                                    INNER JOIN rental r ON c.customer_id = r.customer_id
                                    INNER JOIN payment p ON r.rental_id = p.rental_id
                           WHERE r.rental_date >= '2005-01-01'
                             AND r.rental_date <= '2005-12-31'
                           GROUP BY c.customer_id
                           ),
--CTE for each customers fav category
fav_cat AS (SELECT t1.customer_id, t1.name
            FROM (SELECT ci.customer_id,
                         ct.name,
                         COUNT(DISTINCT r.rental_id),
                         row_number() OVER (PARTITION BY ci.customer_id ORDER BY count(distinct r.rental_id) DESC, ct.name ASC) AS ctrank
                  FROM customer_insights ci
                           INNER JOIN rental r ON ci.customer_id = r.customer_id
                           INNER JOIN payment p ON r.rental_id = p.rental_id    --Consider paid rentals
                           INNER JOIN inventory i ON r.inventory_id = i.inventory_id
                           INNER JOIN film_category fc ON i.film_id = fc.film_id
                           INNER JOIN category ct ON fc.category_id = ct.category_id
                  WHERE r.rental_date >= '2005-01-01' AND r.rental_date <= '2005-12-31' --Considering 2005 rentals data
                  group by ci.customer_id, ct.name) t1
            WHERE t1.ctrank =1),
--CTE for primary store customer uses.
primary_store AS (
   SELECT t2.customer_id, t2.staff_id, t2.store_id
   FROM (SELECT ci.customer_id,
                st.staff_id,
                st.store_id,
                COUNT(distinct r.rental_id),
                row_number() OVER (PARTITION BY ci.customer_id order by COUNT(DISTINCT r.rental_id) DESC, st.store_id ASC) favrank
         FROM customer_insights ci
                  INNER JOIN rental r ON ci.customer_id = r.customer_id
                  INNER JOIN staff st ON r.staff_id = st.staff_id
         GROUP BY ci.customer_id, st.staff_id, st.store_id) t2
   WHERE t2.favrank = 1
)
SELECT ci.customer_id, concat(C.first_name, ' ', c.last_name), c.email, ci.active_status, ci.risk_status, ci.last_rental_date, ci.days_since_last_rental, ci.life_time_payments,
       life_time_value_percent_rank*100 AS spent_rank, ci.rental_frequency,
       ci.total_rentals, fc.name, ps.staff_id, ps.store_id
FROM customer_insights ci
JOIN customer c ON ci.customer_id = c.customer_id
JOIN fav_cat fc ON ci.customer_id = fc.customer_id
JOIN primary_store ps ON ci.customer_id = ps.customer_id
ORDER BY spent_rank ASC;
