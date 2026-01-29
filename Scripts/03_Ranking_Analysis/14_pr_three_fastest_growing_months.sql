
/*Find the 3 month's where revenue grew the fastest compared to the previous month.
For each month, you need: Total revenue in that month, Cumulative revenue (running total up to that month).
Growth % compared to the previous month.
Then pick only the top 3 growth months. */

WITH base_rental_data AS (
    SELECT date_trunc('Month', r.rental_date) AS rev_month, p.amount AS trans_amount
    FROM rental r
    INNER JOIN payment p ON r.rental_id = p.rental_id
    --To filter rentals with payment information on file and to consider paid rentals only.
),
--CTE to calculate base aggregating metrics
agg_metrics AS (
    SELECT brd.rev_month, SUM(brd.trans_amount) AS total_rev_per_month,
       LAG(SUM(brd.trans_amount)) OVER (ORDER BY brd.rev_month ASC) AS previous_month_revenue
FROM base_rental_data brd
GROUP BY brd.rev_month
)
--Main query to aggregate metrics and calculate Month-over-Month change in revenue percentage and ordering months with Highest change in Descending order
SELECT agg.rev_month,
       agg.total_rev_per_month,
       agg.previous_month_revenue,
       SUM(agg.total_rev_per_month) OVER (ORDER BY agg.rev_month) AS running_total,
       CASE WHEN agg.previous_month_revenue IS NULL THEN 0
            ELSE (coalesce((agg.total_rev_per_month -agg.previous_month_revenue),0)/NULLIF(agg.previous_month_revenue,0))*100
           END AS percentage_change
FROM agg_metrics agg
WHERE previous_month_revenue IS NOT NULL
--To handle edge case where previous month rental is not available for analysis for the very 1st Month.
ORDER BY percentage_change DESC;