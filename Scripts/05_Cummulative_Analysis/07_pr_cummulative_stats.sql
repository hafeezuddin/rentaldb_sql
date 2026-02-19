/* Find the cumulative monthly revenue growth over time.
For each month, show: Year-Month, Number of rentals, Monthly revenue
Cumulative revenue up to that month
Percentage growth compared to the previous month */

-- CTE to calculate monthly revenue and rental counts
WITH revenue
         AS (SELECT TO_CHAR(DATE_TRUNC('MONTH', r.rental_date), 'YYYY-MM') AS Month_Year, -- Format rental_date as Year-Month
                    SUM(p.amount)                                          AS revenue,    -- Total revenue for the month
                    COUNT(r.rental_id)                                     AS rentals     -- Number of rentals for the month
             FROM rental r
                      INNER JOIN payment p ON r.rental_id = p.rental_id
             WHERE r.return_date IS NOT NULL
               AND (r.rental_date >= '2005-01-01' AND r.rental_date <= '2005-12-31')
             --Create a separate param cte to further modularize the code and to explicitly filter dates in a maintainable fashion.
             --This query is designed for adhoc analysis
             GROUP BY 1),
--CTE to calculate growth
     growth_metric AS (SELECT r.Month_year,
                              r.revenue,
                              CASE
                                  WHEN LAG(r.revenue) OVER (ORDER BY r.Month_year) IS NULL THEN 0
                                  ELSE ROUND((COALESCE((r.revenue - LAG(r.revenue) OVER (ORDER BY r.Month_year)), 0) /
                                              NULLIF(LAG(r.revenue) OVER (ORDER BY r.Month_year), 0)) * 100, 2)
                                  END AS rev_growth,
                              r.rentals,
                              SUM(r.revenue) OVER (ORDER BY r.Month_Year) AS cummulative_revenue
                       FROM revenue r)
SELECT *
FROM growth_metric;