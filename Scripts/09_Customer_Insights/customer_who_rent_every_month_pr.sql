/*Business Question: "Identify customers who consistently rent films every month"
Requirements:
Find customers who have rented at least once in every month of the current year (2005)

Show customer details and their monthly rental consistency */

--CTE to for parametrization.
WITH param_cte AS (
    SELECT DATE '2005-01-01' AS analysis_start_date,
        DATE '2005-12-31' AS analysis_end_date
),
--Base CTE
base_cte AS (
    SELECT DISTINCT r.customer_id, c.first_name, c.email, pc.analysis_end_date, pc.analysis_start_date,
           DATE_TRUNC('Month', r.rental_date) AS rental_dates_truncated
    FROM rental r
    JOIN payment p ON r.rental_id = p.rental_id
    JOIN customer c ON r.customer_id = c.customer_id
    CROSS JOIN param_cte pc
    WHERE r.rental_date >= pc.analysis_start_date AND r.rental_date <= pc.analysis_end_date
    ),
customers_tw_months AS (
    SELECT bc.customer_id, bc.first_name, bc.email
    FROM base_cte bc
    GROUP BY bc.customer_id, bc.first_name, bc.email
    HAVING COUNT(DISTINCT bc.rental_dates_truncated) = 12
    ),
for_consistency AS (
    SELECT bc.customer_id, COUNT(DISTINCT bc.rental_dates_truncated) AS total_rental_months,
           min(bc.rental_dates_truncated), max(bc.rental_dates_truncated),
           COUNT(DISTINCT bc.rental_dates_truncated)::numeric/
                NULLIF((EXTRACT(YEAR FROM MAX(bc.rental_dates_truncated)) - EXTRACT(YEAR FROM MIN(bc.rental_dates_truncated)) ) * 12
                +
                (EXTRACT(MONTH FROM MAX(bc.rental_dates_truncated)) - EXTRACT(MONTH FROM MIN(bc.rental_dates_truncated))) + 1,0)
    AS consistency
    FROM base_cte bc
    GROUP BY bc.customer_id,bc.analysis_end_date
    )
SELECT ctm.customer_id, ctm.first_name, ctm.email, fc.consistency
FROM customers_tw_months ctm
JOIN for_consistency fc ON ctm.customer_id = fc.customer_id;
