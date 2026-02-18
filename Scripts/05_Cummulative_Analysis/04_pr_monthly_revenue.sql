/* Yearly and Year/Month revenue 2005*/

WITH monthly_revenue AS (SELECT date_trunc('month', r.rental_date) AS month,
                                SUM(p.amount)                      AS revenue,
                                COUNT(DISTINCT r.rental_id) AS total_rentals
                         FROM rental r
                                  JOIN payment p
                                       ON r.rental_id = p.rental_id
                                  --Payment date may be different from rental date.
                                  --Rental/Transaction date is considered as sale date or revenue date not the payment processing date.
                         WHERE r.rental_date >= '2005-01-01'
                           AND r.rental_date <= '2005-12-31'
                         GROUP BY date_trunc('month', r.rental_date))

SELECT to_char(month, 'YYYY-MM')          AS year_month,
       revenue                            AS monthly_revenue,
       total_rentals,

       -- Month-over-month growth %
       CASE
           WHEN LAG(revenue) OVER (ORDER BY month) IS NULL THEN 0
           ELSE
               ROUND(
                       ((revenue - LAG(revenue) OVER (ORDER BY month))
                           / NULLIF(LAG(revenue) OVER (ORDER BY month), 0)) * 100,
                       2
               )
           END                            AS month_over_month_growth_percent,

       -- Cumulative revenue
       SUM(revenue) OVER (ORDER BY month) AS cumulative_revenue

FROM monthly_revenue
ORDER BY month;
