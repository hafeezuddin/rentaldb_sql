
/* Create a Single SQL Query that Shows Today's Key Business Metrics - 
Todays rentals, report date, todays revenue, films_rented, late_returns (this month), new_customers (this month) */
-- Single-row scalar query: Today's Key Business Metrics
-- Returns: todays_date, todays_total_rentals, todays_revenue,
-- todays_rented_films, new_customers_today, late_returns_current_month
SELECT 
  -- Current date for the report
  (SELECT CURRENT_DATE) AS todays_date,

  -- Total rentals that started today (based on rental_date)
  (SELECT COUNT(r.rental_id) FROM rental r
    WHERE DATE(r.rental_date) = CURRENT_DATE) AS todays_total_rentals,

  -- Total revenue collected today (payments linked to rentals that started today)
  (SELECT COALESCE(SUM(p.amount), 0) FROM payment p
    INNER JOIN rental r ON p.rental_id = r.rental_id --connect payments to paid rentals
    WHERE DATE(r.rental_date) = CURRENT_DATE) AS todays_revenue,
  
  -- Number of distinct films that were rented today
  (SELECT COUNT(DISTINCT f.film_id) FROM film f
    INNER JOIN inventory i ON f.film_id = i.film_id
    INNER JOIN rental r ON i.inventory_id = r.inventory_id
    WHERE DATE(r.rental_date) = CURRENT_DATE) AS todays_rented_films,
  
  -- New customers this month: count of customers whose first rental occurred in the current month
  (SELECT COUNT(sq.cus) FROM 
    (SELECT r.customer_id AS cus
      FROM rental r
      GROUP BY 1
      HAVING DATE_TRUNC('month', MIN(r.rental_date::date)) = DATE_TRUNC('month', CURRENT_DATE)
    ) sq) AS new_customers_today,

  -- Late returns recorded in the current month:
  -- customers with return_date later than allowed rental_duration, filtered to current month by return_date
  (SELECT COUNT(sq2.customer_id) AS late_returns_current_month FROM 
    (
      SELECT c.customer_id
      FROM customer c
      INNER JOIN rental r ON c.customer_id = r.customer_id
      INNER JOIN inventory i ON r.inventory_id = i.inventory_id
      INNER JOIN film f ON i.film_id = f.film_id
      WHERE (r.return_date::date - r.rental_date::date) > f.rental_duration
        AND r.return_date IS NOT NULL
        AND DATE_TRUNC('year', r.return_date::date) = DATE_TRUNC('year', CURRENT_DATE) --Filtering to currect year
        AND DATE_TRUNC('month', r.return_date::date) = DATE_TRUNC('month', CURRENT_DATE) --Filtering to current months
    ) sq2
  ) AS late_returns_current_month;
-- End of Query