/* Daily Key Business Metrics Dashboard Query
   Returns: report_date, today_total_rentals, today_revenue, today_rented_films,
   new_customers_this_month, late_returns_this_month

   Optimization: Single pass with CTEs instead of correlated subqueries to improve performance
*/

WITH param_cte AS (
    -- Single source of truth for date filtering
    SELECT CURRENT_DATE AS report_date,
           DATE_TRUNC('month', CURRENT_DATE)::date AS month_start
),

todays_rentals AS (
    -- All rentals initiated today
    SELECT DISTINCT r.rental_id, r.customer_id, i.film_id
    FROM rental r
    INNER JOIN inventory i ON r.inventory_id = i.inventory_id
    CROSS JOIN param_cte p
    WHERE DATE(r.rental_date) = p.report_date
),

todays_payments AS (
    -- Payments for today's rentals
    SELECT SUM(p.amount) AS daily_revenue
    FROM payment p
    INNER JOIN todays_rentals tr ON p.rental_id = tr.rental_id
),

new_customers_month AS (
    -- Customers whose FIRST rental occurred this month
    SELECT COUNT(DISTINCT sq.customer_id) AS new_customers
    FROM (
        SELECT r.customer_id,
               ROW_NUMBER() OVER (PARTITION BY r.customer_id ORDER BY r.rental_date ASC) AS rn
        FROM rental r
        CROSS JOIN param_cte p
        WHERE DATE_TRUNC('month', r.rental_date::date) = p.month_start
    ) sq
    WHERE sq.rn = 1
),

late_returns_month AS (
    -- Rentals returned late in the current month (by return_date)
    SELECT COUNT(DISTINCT r.rental_id) AS late_return_count
    FROM rental r
    INNER JOIN inventory i ON r.inventory_id = i.inventory_id
    INNER JOIN film f ON i.film_id = f.film_id
    CROSS JOIN param_cte p
    WHERE r.return_date IS NOT NULL
      AND DATE_TRUNC('month', r.return_date::date) = p.month_start
      AND (r.return_date::date - r.rental_date::date) > f.rental_duration
)

SELECT
    p.report_date AS todays_date,
    (SELECT COUNT(*) FROM todays_rentals) AS todays_total_rentals,
    COALESCE((SELECT daily_revenue FROM todays_payments), 0) AS todays_revenue,
    (SELECT COUNT(DISTINCT film_id) FROM todays_rentals) AS todays_rented_films,
    (SELECT new_customers FROM new_customers_month) AS new_customers_this_month,
    (SELECT late_return_count FROM late_returns_month) AS late_returns_this_month
FROM param_cte p;