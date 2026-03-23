/*Identify which film categories (like Action, Comedy, etc.)
  are growing the fastest month-over-month based on total rental revenue.*/

--Integrity check if film has exactly one category
-- SELECT fc.film_id, COUNT(fc.category_id)
-- FROM film_category fc
-- GROUP by fc.film_id
-- HAVING COUNT(fc.category_id) > 1
--Result Set: 0
--Confirms each film has exactly one primary film category and no risk of Cartesian product

--Base rental cte
WITH rental_case AS (
    SELECT f.film_id, p.amount,
           ct.name,
           to_char(date_trunc('Month', r.rental_date::date), 'YYYY-MM') rental_month
    FROM film f
    JOIN inventory i ON f.film_id = i.film_id
    JOIN rental r ON i.inventory_id = r.inventory_id
    JOIN payment p ON r.rental_id = p.rental_id
    JOIN film_category fc ON f.film_id = fc.film_id
    --No possible Cartesian product. Refer the check above. Safe to Join
    JOIN category ct ON fc.category_id = ct.category_id
    WHERE (r.rental_date BETWEEN '2005-01-01' AND '2005-12-31') AND r.return_date IS NOT NULL
    --Restricting the analysis to 2005. Expand the period when applicable and necessary. Unreturned films are excluded from analysis
),
--CTE to build base metrics
metrics_calculation AS (
    SELECT rc.name, rc.rental_month,
           COUNT(rc.name) rentals,
           SUM(rc.amount) cat_revenue,
           LAG(SUM(rc.amount)) OVER (PARTITION BY rc.name ORDER BY rental_month ASC) pmr
    FROM rental_case rc
    GROUP BY rc.name, rc.rental_month
),
--Cte to calculate MoM Growth
growth_cte AS (
    SELECT mc.name, mc.rental_month, mc.rentals, mc.cat_revenue, mc.pmr,
    CASE WHEN mc.pmr IS NULL THEN 0
         WHEN mc.pmr IS NOT NULL
            THEN ROUND((coalesce(mc.cat_revenue - mc.pmr,0)/NULLIF(mc.pmr,0))*100,2)
    END AS growth,
    rank() OVER (PARTITION BY mc.rental_month ORDER BY ROUND((coalesce(mc.cat_revenue - mc.pmr,0)/NULLIF(mc.pmr,0))*100,2) DESC) cat_rank
    FROM metrics_calculation mc
)
--Main query
SELECT * from growth_cte gc
WHERE gc.growth !=0 AND gc.cat_rank =1;

-- Planning Time: 1.432 ms
-- Execution Time: 37.421 ms

