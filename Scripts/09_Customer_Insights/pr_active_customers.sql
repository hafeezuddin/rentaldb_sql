/* Active customers who rented at least once in year 2005. Consider only paid rentals*/
--Parametrization CTE
WITH param_cte AS (SELECT DATE '2005-01-01' AS analysis_start_date, --DATE IN ISO FORMAT
                          DATE '2005-12-31' AS analysis_end_date -- DATE IN ISO FORMAT
),
--Base CTE to retrieve rental information of each customer
base_cte AS (SELECT DISTINCT r.customer_id,
                             TO_CHAR(DATE_TRUNC('MONTH', r.rental_date), 'YYYY-MM') AS ym
                  FROM rental r
                           JOIN payment p
                                ON r.rental_id = p.rental_id --To consider paid rentals/rentals where revenue was generated
                           CROSS JOIN param_cte pc
                  WHERE r.rental_date >= pc.analysis_start_date
                    AND r.rental_date <= pc.analysis_end_date)
--Main query to filter customers who rented at least one film each month in 2005
SELECT bc.customer_id
FROM base_cte bc
GROUP BY bc.customer_id
HAVING COUNT(DISTINCT bc.ym) = 12
ORDER BY customer_id;