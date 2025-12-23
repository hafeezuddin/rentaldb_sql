/* Find the top 3 highest revenue-generating days in each month in the year 2005.
For each month, show: Year-Month, Day (date), Daily revenue, Rank of the day within that month by revenue */
SELECT * FROM (
    SELECT TO_CHAR(DATE_TRUNC('DAY', r.rental_date), 'YYYY-MM-DD') AS date_of_month,
    TO_CHAR(DATE_TRUNC('MONTH', r.rental_date), 'YYYY-MM') AS mon_year,
    --Also considers payment made in 2006 for 2005 rentals along with 2005 payments
    SUM(p.amount) AS total_rev_by_date,
    RANK() OVER (PARTITION BY TO_CHAR(DATE_TRUNC('MONTH', r.rental_date), 'YYYY-MM') ORDER BY sum(p.amount) DESC) AS rank_within_month
    FROM rental r
    --Considering paid rentals
    INNER JOIN payment p ON r.rental_id = p.rental_id
    --Filtering data for 2005 rentals only
    WHERE r.return_date IS NOT NULL AND (r.rental_date >= '2005-01-01' AND r.rental_date <= '2005-12-31')
    GROUP BY date_of_month, mon_year
) r
WHERE rank_within_month <=3;