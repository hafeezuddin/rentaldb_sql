/**Customer Value & Behavior Analysis"

Write a single comprehensive query that returns:
Analysis date: 01-01-2006
Customer details (ID, name, email, active status - Rented in last 150 Days)
Rental frequency (rentals per month)

Favorite category (most rented)
Their lifetime value (total payments)
Days since last rental
Last_rental date
active_status
Store they primarily use
Staff member who usually helps them

Requirements:
Use CTEs or subqueries
Handle ties for favorite category
Include both active and inactive customers
Rank customers by lifetime value percentile
Flag customers who haven't rented in > 150 days as "at-risk" **/

--CTE for params
WITH param_cte AS (SELECT DATE '01-01-2006' AS analysis_date,
                          DATE '01-01-2005' AS analysis_start_date,
                          DATE '12-31-2005' AS analysis_end_date,
                          150 AS activity_cut_off
                   ),
rental_metrics AS (
    SELECT r.customer_id,
        r.rental_id,
        cat.name,
        r.rental_date,
        p.amount,
        st.first_name,
        st.store_id,
        pc.analysis_date,
        pc.analysis_start_date,
        pc.analysis_end_date
    FROM rental r
    INNER JOIN payment p ON r.rental_id = p.rental_id
    INNER JOIN inventory i ON r.inventory_id = i.inventory_id
    INNER JOIN film_category fc ON i.film_id = fc.film_id
    INNER JOIN category cat ON fc.category_id = cat.category_id
    INNER JOIN staff st on r.staff_id = st.staff_id

    CROSS JOIN param_cte pc
    WHERE r.rental_date >= pc.analysis_start_date AND r.rental_date <= pc.analysis_end_date
    ),
customer_fav_cat AS (
    SELECT t1.customer_id, t1.name
    FROM (SELECT rm.customer_id, rm.name, COUNT(DISTINCT rm.rental_id), row_number() over (PARTITION BY rm.customer_id ORDER BY COUNT(DISTINCT rm.rental_id) DESC, rm.name ASC) catrank
    FROM rental_metrics rm
    GROUP BY 1, 2) t1
    WHERE t1.catrank = 1
    ),
customer_life_time_value AS (
    SELECT rm.customer_id,
           SUM(rm.amount) AS life_time_spent FROM rental_metrics rm
    GROUP BY rm.customer_id
),
rental_info AS (SELECT rm.customer_id, MAX(rm.rental_date) AS latest_rental_date, COUNT(distinct rm.rental_id) AS total_rentals,
                                  EXTRACT(EPOCH FROM (rm.analysis_date - MAX(rm.rental_date))) /
                                  86400.0 AS days_since_last_rental,
                           CASE
                              WHEN EXTRACT(EPOCH FROM (rm.analysis_date - MAX(rm.rental_date))) /
                                  86400.0 < 150
                              THEN 'Active'
                              ELSE
                                    'In-active'
                            END AS status
                           FROM rental_metrics rm
                           GROUP BY rm.customer_id, rm.analysis_date
                           ),
primary_store AS (
                  SELECT t3.customer_id, t3.store_id
                  FROM (SELECT rm.customer_id, rm.store_id, COUNT(DISTINCT rm.rental_id),
                        ROW_NUMBER() OVER (PARTITION BY rm.customer_id ORDER BY COUNT(DISTINCT rm.rental_id) DESC) AS fav_store_rank
                        FROM rental_metrics rm
                        GROUP BY rm.customer_id, rm.store_id
                  ) t3
                  WHERE t3.fav_store_rank = 1
),
most_serving_staff_member AS (
    SELECT t3.customer_id, t3.first_name
                  FROM (SELECT rm.customer_id, rm.first_name, COUNT(DISTINCT rm.rental_id),
                        ROW_NUMBER() OVER (PARTITION BY rm.customer_id ORDER BY COUNT(DISTINCT rm.rental_id) DESC) AS top_staff_rank
                        FROM rental_metrics rm
                        GROUP BY rm.customer_id, rm.first_name
                  ) t3
                  WHERE t3.top_staff_rank = 1
    ),
rental_frequency AS (
    SELECT rm.customer_id,
    COUNT(DISTINCT rm.rental_id)/(EXTRACT(MONTH FROM age(max(rm.rental_date), min(rm.rental_date))) + 1) AS rental_frequency
    FROM rental_metrics rm
    GROUP BY rm.customer_id
    )

SELECT c.customer_id AS customer_id, CONCAT(c.first_name,' ', c.last_name) AS customer_full_name,
       c.email AS customer_email, cfc.name AS fav_category, cftv.life_time_spent AS period_total_spent_amount, ri.total_rentals AS total_period_rentals,
       ri.days_since_last_rental AS days_since_last_rented, ri.status AS status_of_customer,
       ps.store_id AS fav_store, mstm.first_name AS staff_who_served_most, ROUND(rf.rental_frequency,2) AS rental_frequency
FROM customer c
JOIN customer_fav_cat cfc ON c.customer_id = cfc.customer_id
JOIN customer_life_time_value cftv ON c.customer_id = cftv.customer_id
JOIN rental_info ri ON c.customer_id = ri.customer_id
JOIN primary_store ps ON c.customer_id = ps.customer_id
JOIN most_serving_staff_member mstm ON c.customer_id = mstm.customer_id
JOIN rental_frequency rf ON c.customer_id = rf.customer_id;


