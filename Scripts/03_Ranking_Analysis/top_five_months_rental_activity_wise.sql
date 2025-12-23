
/*Find the top 5 months (across all years) with the highest rental activity.
For each of these months, show: Year and Month (e.g., 2021-05), Total number of rentals, Total revenue collected (from payment.amount)
The percentage share of revenue compared to the overall revenue.*/

-- CTE to calculate total rentals and revenue per month
WITH revenue_cal AS (
  SELECT
    DATE_TRUNC('Month', r.rental_date) AS rental_month,             -- Truncate rental_date to month
    COUNT(DISTINCT r.rental_id) AS no_of_rentals,                   -- Number of rentals in the month
    SUM(p.amount) AS total_revenue                                  -- Total revenue in the month
  FROM rental r
    INNER JOIN payment p ON r.rental_id = p.rental_id
  GROUP BY 1
),
-- CTE to calculate overall total revenue
total_rev_cal AS (
  SELECT SUM(p.amount) AS tot_rev
  FROM payment p
)
-- Main query: Top 5 months by revenue, with percentage of total revenue
SELECT 
  TO_CHAR(rc.rental_month, 'YYYY-MM') AS YEAR_Month,         -- Year-Month format
  TO_CHAR(rc.rental_month, 'MON-YYYY') AS Mon_Desc,          -- Month-Year description
  rc.no_of_rentals,                                          -- Number of rentals in the month
  rc.total_revenue,
  rvc.tot_rev,                                                -- Total overall revenue
  ROUND((rc.total_revenue/rvc.tot_rev)*100,2) AS percentage  -- Percentage of total revenue
FROM revenue_cal rc
  CROSS JOIN total_rev_cal rvc
ORDER BY rc.total_revenue DESC
LIMIT 5;


--Window_function_version
WITH revenue_cal AS (
  SELECT DATE_TRUNC('Month', r.rental_date) AS year_month, --Truncate rental_date to month
  COUNT(DISTINCT r.rental_id) AS no_of_rentals,            --Counting no.of.rentals in a given month
  SUM(p.amount) AS revenue,                                --Counting revenue in each given month
  SUM(SUM(p.amount)) OVER() AS total_revenue               --Counting total global revenue generated till date (May not work in all db's) using window function. (Non-cummulative)
  FROM rental r
  INNER JOIN payment p ON r.rental_id = p.rental_id
  GROUP BY 1
)
SELECT 
TO_CHAR(rc.year_month, 'YYYY-MM') AS ym,                    --Year Month format
TO_CHAR(rc.year_month, 'MON-YYYY') my_des,
rc.no_of_rentals, rc.revenue, rc.total_revenue,             --Month Year format description
ROUND((rc.revenue/rc.total_revenue)*100,2) AS percentage    --Percentage/Share in total revenue
FROM revenue_cal rc
ORDER BY rc.revenue DESC
LIMIT 5;

