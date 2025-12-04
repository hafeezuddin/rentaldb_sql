
/*Find the 3 months where revenue grew the fastest compared to the previous month.
For each month, you need: Total revenue in that month, Cumulative revenue (running total up to that month).
Growth % compared to the previous month.
Then pick only the top 3 growth months. */

--CTE to find monthly total_revenue
WITH mon_rev AS (
SELECT DATE_TRUNC('Month', r.rental_date) AS datemonth, --Truncates Date upto monthlevel for aggregation task
SUM(p.amount) AS total_revenue                          -- Calculate total revenue generated and aggregated with date
FROM rental r
INNER JOIN payment p ON r.rental_id = p.rental_id --NOT USING LEFT (Exluding rentals that do not have payment id)
GROUP BY 1
ORDER BY datemonth
),
--CTE to calculate cummulative revenue, lag for percentage change in revenue calculations
cumm_rev AS (
  SELECT m.datemonth AS datemonth2,
  LAG(total_revenue) OVER (ORDER BY m.datemonth) AS pmr,        --LAG() window function for calculating percentage change in revenue
  SUM(total_revenue) OVER (ORDER BY m.datemonth) AS cummu_rev   --Cummulative revenue month-over-month
  FROM mon_rev m
)
SELECT
  m.datemonth, 
  m.total_revenue, 
  cr.pmr, 
  cr.cummu_rev,
CASE                                                   --CASE statement to handle null values.
  WHEN cr.pmr IS NULL THEN 0
ELSE 
  ROUND((m.total_revenue - cr.pmr)/NULLIF(cr.pmr,0)*100,2)     --Change in percentage calculation. total_revenue - previous_month_revenue/previous_month revenue
END AS percentage_change

FROM mon_rev m
INNER JOIN cumm_rev cr ON m.datemonth = cr.datemonth2
ORDER BY percentage_change DESC
LIMIT 4;