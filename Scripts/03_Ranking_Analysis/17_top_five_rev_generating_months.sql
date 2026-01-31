/*Find the top 5 months (across all years) with the highest rental activity.
For each of these months, show:
    Year and Month (e.g., 2021-05),
    Total number of rentals,
    Total revenue collected (from payment.amount)
The percentage share of revenue compared to the overall revenue.*/

--Base CTE for rental with date transformation for main query
WITH base_rental_data AS (SELECT date_trunc('Month', r.rental_date) AS truncated_date,
                                 SUM(p.amount)                      AS total_revenue,
                                 COUNT(DISTINCT r.rental_id)        AS total_rentals,
                                 SUM(SUM(p.amount)) OVER ()         AS total_revenue_overall
                          FROM rental r
                                   JOIN payment p ON r.rental_id = p.rental_id
                          GROUP BY 1)
--Main query to list top five revenue generating months.
SELECT to_char(brd.truncated_date, 'YYYY-MON')                                               AS year_month_head,
       brd.total_revenue,
       brd.total_rentals,
       ROUND(coalesce(brd.total_revenue, 0) / NULLIF(brd.total_revenue_overall, 0) * 100, 2) AS revenue_share
FROM base_rental_data brd
ORDER BY revenue_share DESC
LIMIT 5;