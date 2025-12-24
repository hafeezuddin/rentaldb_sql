/* Find the cumulative monthly revenue growth over time.
For each month, show: Year-Month, Number of rentals, Monthly revenue
Cumulative revenue up to that month
Percentage growth compared to the previous month */
-- CTE to calculate monthly revenue and rental counts
WITH revenue AS (
  SELECT
    TO_CHAR(DATE_TRUNC('MONTH', r.rental_date), 'YYYY-MM') AS Month_Year, -- Format rental_date as Year-Month
    SUM(p.amount) AS revenue,                                             -- Total revenue for the month
    COUNT(r.rental_id) AS rentals                                         -- Number of rentals for the month
  FROM rental r
    INNER JOIN payment p ON r.rental_id = p.rental_id
    WHERE r.return_date IS NOT NULL AND (r.rental_date >='2005-01-01' AND r.rental_date <= '2005-12-31')
  GROUP BY 1
)
SELECT sq1.Month_Year,
       sq1.revenue,
       CASE WHEN sq1.lag IS NULL
           THEN 0
        ELSE sq1.lag
        END,
        CASE WHEN sq1.diff_in_rev IS NULL
            THEN 0
        ELSE sq1.diff_in_rev
        END,
        sq1.cumm_rev,
        CASE WHEN sq1.percentage_change IS NULL
            THEN 0
        ELSE sq1.percentage_change
        END
FROM
    (SELECT
      r.Month_Year, r.revenue,
      LAG(r.revenue) OVER (ORDER BY r.Month_Year) AS lag, -- Previous month's revenue
      r.revenue - LAG(r.revenue) OVER (ORDER BY r.Month_Year) AS diff_in_rev, -- Revenue difference from previous month
      SUM(r.revenue) OVER (ORDER BY r.Month_Year) AS cumm_rev, -- Cumulative revenue up to this month
      -- Percentage growth compared to previous month
      ROUND((r.revenue - LAG(r.revenue) OVER(ORDER BY r.Month_Year)) / NULLIF(LAG(r.revenue) OVER(ORDER BY r.Month_Year), 0) * 100, 2) AS percentage_change,
      r.rentals -- Number of rentals in the month
    FROM revenue r) sq1;