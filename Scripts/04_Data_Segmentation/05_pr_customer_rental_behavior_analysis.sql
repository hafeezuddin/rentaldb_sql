/* Business Requirement: ®
 Objective: Analyze Overall customer rental patterns to identify different behavioral segments

 Specific Requirements:
 Find each customer's total rentals and total spending
 Calculate their average days between rentals (engagement frequency)
 Flag if they've rented in the last 30 days (active status)
 Identify their most rented film category
 Segment customers into:
     Customers who rent frequently AND spend a lot (top 25% in both metrics)
     Customers who rent frequently but don't spend much (top 25% rentals, but lower spending)
     Customers who don't rent often but spend a lot when they do (lower rentals, but top 25% spending)
     Everyone else: Customers who rent infrequently AND don't spend much*/

--Base rental data
WITH base_rental AS (SELECT r.customer_id, r.rental_date::date, r.inventory_id, r.rental_id, p.amount
                     FROM rental r
                              LEFT JOIN payment p ON r.rental_id = p.rental_id
    --Keeps both paid and unpaid rentals
    --Replace with INNER JOIN to consider paid rentals
    --Categories cannot be joined here to avoid inflated totals in cases where film fits into two categories
),
--Sales metrics
     sales_metrics AS (SELECT br.customer_id,
                              MAX(br.rental_date::date)                                             AS latest_rental_date,
                              COUNT(DISTINCT br.rental_id)                                          AS total_rentals,
                              COALESCE(SUM(br.amount), 0)                                           AS total_spent,
                              ROUND(percent_rank() OVER (ORDER BY SUM(br.amount) DESC)::numeric, 2) AS spent_rank,
                              CASE
                                  WHEN current_date - MAX(br.rental_date) <= 30 THEN 'Active'
                                  ELSE 'Inactive'
                                  END                                                               AS active_inactive_status
                       --Distinct Accounts when customer splits the rental into two transactions.
                       FROM base_rental br
                       GROUP BY br.customer_id),
     average_days_between_rentals AS (SELECT t1.customer_id,
                                             ROUND(AVG(t1.rental_date_diff), 2) AS average_diff_between_rentals,
                                             ROUND(percent_rank()
                                                   OVER (order by ROUND(AVG(t1.rental_date_diff), 2) ASC)::numeric,
                                                   2)                           AS freq_rank
                                      FROM (SELECT br.customer_id,
                                                   CASE
                                                       WHEN LAG(br.rental_date)
                                                            OVER (partition by br.customer_id ORDER BY br.rental_date) IS NULL
                                                           THEN 0
                                                       ELSE br.rental_date -
                                                            LAG(br.rental_date)
                                                            OVER (partition by br.customer_id ORDER BY br.rental_date)
                                                       END as rental_date_diff
                                            FROM base_rental br) t1
                                      GROUP BY t1.customer_id),
--Customers most rented category based on rental volume from that category
--Caution: Didn't retrieve fav category in base rental to avoid inflated rental count and amounts.
--This Cte creates two or more records and counts totals if film is belong to two or more categories.
-- Alternative approach is to assign primary category to each film using.
/**Primary category preprocessing: (SELECT r.customer_id, r.rental_id, MIN(fc.category_id) AS primary_category
                    FROM rental r
                    JOIN inventory i ON r.inventory_id = i.inventory_id
                    JOIN film_category fc ON i.film_id = fc.film_id
                    GROUP BY r.customer_id, r.rental_id)   **/
     most_rented_cat AS (SELECT t2.customer_id, t2.name
                         FROM (SELECT br.customer_id,
                                      cat.name,
                                      COUNT(*),
                                      row_number()
                                      over (PARTITION BY br.customer_id ORDER BY COUNT(*) DESC, cat.name) AS cat_ranking
                               FROM base_rental br
                                        JOIN inventory i ON br.inventory_id = i.inventory_id
                                        JOIN film f ON i.film_id = f.film_id
                                        JOIN film_category fc ON i.film_id = fc.film_id
                                        JOIN category cat ON fc.category_id = cat.category_id
                               GROUP BY br.customer_id, cat.name) t2
                         WHERE t2.cat_ranking = 1)
--Main query to aggregate all metrics and categorize customers.
SELECT sm.customer_id,
       sm.total_rentals,
       mrc.name AS top_rented_category,
       sm.active_inactive_status,
       adbr.average_diff_between_rentals,
       adbr.freq_rank,
       sm.spent_rank,
       CASE
           WHEN adbr.freq_rank <= 0.25 AND sm.spent_rank >= 0.75
               THEN 'High spenders and renters'

           WHEN adbr.freq_rank <= 0.25 AND sm.spent_rank <= 0.74
               THEN 'High renters and low spenders'

           WHEN adbr.freq_rank >= 0.74 AND sm.spent_rank >= 0.75
               THEN 'High spenders and low renters'
           ELSE
               'Low spenders and low renters'
           END  AS customer_segment

FROM sales_metrics sm
         JOIN average_days_between_rentals adbr ON sm.customer_id = adbr.customer_id
         JOIN most_rented_cat mrc ON adbr.customer_id = mrc.customer_id;

-- [
--   {
--     "QUERY PLAN": "Planning Time: 1.959 ms"
--   },
--   {
--     "QUERY PLAN": "Execution Time: 136.393 ms"
--   }
-- ]