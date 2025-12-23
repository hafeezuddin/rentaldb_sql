
/* Identify Customers with High Potential for Loyalty Programs */
--1.Frequent Renters: Above-average rental frequency, 
--2.High-Value: Above-average total spending 
--3.Recent Activity: Rented at least once in the last 30 days)

--CTE to find customers who rent more often than average
WITH above_avg_rental_frequency AS (
  SELECT r.customer_id,
    COUNT(r.rental_id) AS no_of_times_film_rented
  FROM rental r
  INNER JOIN payment p on r.rental_id = p.rental_id --Considering only rentals which were paid for
  GROUP BY 1
  HAVING COUNT(r.rental_id) > --Filtering customers based on average frequency
    (
      SELECT AVG(sq1.times_rented) --Over all rental average
      FROM (
          SELECT r.customer_id,
            COUNT(r.rental_id) AS times_rented
          FROM rental r
          INNER JOIN payment p ON r.rental_id = p.rental_id --To consider only paid rentals from each customer
          GROUP BY 1
        ) sq1
    )
),
--CTE to find customers who spend more than the average amount
above_avg_spend AS (
  SELECT p.customer_id,
    SUM(p.amount) AS total_amount_spent
  FROM payment p
  GROUP BY 1
  HAVING SUM(p.amount) > --Filtering customers based on avg amount spent criteria
    (
      SELECT AVG(sq2.tot_spend)
      FROM (
          SELECT SUM(amount) AS tot_spend
          FROM payment
          GROUP BY customer_id
        ) sq2
    )
),

--CTE to find customers who rented out movies in last 30 days
recent_activity AS (
  SELECT DISTINCT r.customer_id
  FROM rental r
  WHERE (CURRENT_DATE - r.rental_date::date) < 100000
) 
--Main query to find customers who spend more than average, rent more than average and has recent activity.
SELECT cte1.customer_id
FROM above_avg_rental_frequency AS cte1
  INNER JOIN above_avg_spend cte2 ON cte1.customer_id = cte2.customer_id
  INNER JOIN recent_activity cte3 ON cte2.customer_id = cte3.customer_id;


--Additional Query to find count of unpaid rentals
SELECT
  (SELECT count(DISTINCT r.rental_id) FROM rental r)
  AS total_rentals,

  (SELECT count(DISTINCT p.payment_id) FROM payment p)
  AS total_payments,

  (SELECT count(DISTINCT r.rental_id) FROM rental r) - 
    (SELECT count(DISTINCT p.payment_id) FROM payment p)
  AS unpaid_rentals; --Not all rentals are paid for
