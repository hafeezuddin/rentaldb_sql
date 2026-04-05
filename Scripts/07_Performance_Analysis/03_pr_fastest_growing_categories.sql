/*Identify which film categories (like Action, Comedy, etc.)
  are growing the fastest month-over-month based on total rental revenue.*/

/* checks if each film belongs to exactly one category to avoid cartesian product */
-- SELECT fc.film_id, COUNT(fc.film_id)
-- FROM film_category fc
-- GROUP BY fc.film_id
-- HAVING COUNT(fc.film_id) > 1

--Aggregate payments (To handle cases where payment was split in two or more transactions)
WITH payment_agg AS (SELECT p.rental_id, SUM(p.amount) total_amount
FROM payment p
GROUP BY p.rental_id
),
--Base rental CTE
base_rental AS (
    SELECT r.rental_id, to_char(date_trunc('MONTH', r.rental_date),'YYYY-MM') trans_month,
           f.film_id, cat.name, pa.total_amount
    FROM rental r
    JOIN inventory i ON r.inventory_id = i.inventory_id
    JOIN film f ON i.film_id = f.film_id
    JOIN film_category fc ON f.film_id = fc.film_id
    JOIN category cat ON fc.category_id = cat.category_id
    JOIN payment_agg pa ON r.rental_id  = pa.rental_id
),
cat_aggregates AS (
    SELECT br.name, br.trans_month,
           SUM(total_amount) total_monthly_revenue,
           LAG(SUM(total_amount)) OVER (partition by br.name ORDER BY br.trans_month) prev_month_revenue
    FROM base_rental br
    GROUP BY br.name, br.trans_month
),
mom_calculation AS (SELECT ca.name,
                           ca.trans_month,
                           ca.total_monthly_revenue,
                           COALESCE(ca.prev_month_revenue, 0)                              prev_month_revenue,
                           ROUND((COALESCE(ca.total_monthly_revenue - COALESCE(ca.prev_month_revenue, 0), 0) / NULLIF(COALESCE(ca.prev_month_revenue, 0), 0)) * 100, 2) MoM_growth,
                        row_number() over (PARTITION BY ca.trans_month ORDER BY ROUND((COALESCE(ca.total_monthly_revenue - COALESCE(ca.prev_month_revenue, 0), 0) /
                                  NULLIF(COALESCE(ca.prev_month_revenue, 0), 0)) * 100, 2) DESC) monthly_top_cat_rank
                    FROM cat_aggregates ca)
SELECT mc.name, mc.trans_month, mc.total_monthly_revenue, mc.prev_month_revenue, mc.MoM_growth, mc.monthly_top_cat_rank
FROM mom_calculation mc
WHERE prev_month_revenue !=0 AND mc.monthly_top_cat_rank = 1
--To avoid over inflated MoM growth values where there are no records of prev month revenues;

-- Planning Time: 1.837 ms
-- Execution Time: 60.621 ms

