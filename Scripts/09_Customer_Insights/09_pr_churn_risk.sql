/* A “churn risk” customer is one who hasn’t rented in the last 60 days but had rented at least 5 films before that.*
For each such customer, show: Customer ID & Name, Last rental date, Total amount spent
Total rentals of customer.
Consider both paid and unpaid rentals */

--Param_cte is efficient for modularity and when this script is required to be executed periodically with changing parameters (dates, cutoff criteria)
WITH param_cte AS (SELECT 60                AS last_rentals_cutoff_duration,
                          5                 AS prior_films,
                          DATE '2006-01-01' AS analysis_date),
--For adhoc request this CTE can be replaced and criteria can be directly hard coded in where clause.

--Base CTE for customer and their rental data
     rental_info AS (SELECT r.customer_id,
                            CONCAT(c.first_name, ' ', c.last_name) AS customer_full_name,
                            r.rental_id,
                            r.rental_date,
                            p.amount                               AS rental_amount,
                            pc.analysis_date,
                            pc.last_rentals_cutoff_duration
                     FROM rental r
                              JOIN customer c ON r.customer_id = c.customer_id
                              LEFT JOIN payment p ON r.rental_id = p.rental_id
                         -- LEFT JOI retains all unpaid rentals as well as required by business case.
                         --Both paid and unpaid rentals are included.
                              CROSS JOIN param_cte pc),
--Core aggregated metrics calculation CTE for applying filters.
     metrics_for_main_query AS (SELECT ri.customer_id,
                                       ri.customer_full_name,
                                       ri.analysis_date,
                                       ri.last_rentals_cutoff_duration,
                                       MAX(ri.rental_date)          latest_rental_date,
                                       COALESCE(SUM(ri.rental_amount),0)      total_spent,
                                       COUNT(DISTINCT ri.rental_id) AS total_rentals
                                FROM rental_info ri
                                GROUP BY ri.customer_id, ri.analysis_date, ri.customer_full_name,
                                         ri.last_rentals_cutoff_duration)
--Main query with applied required filters to determine customers who at highest risk of churning.
SELECT mfmq.customer_id, mfmq.customer_full_name, mfmq.latest_rental_date, mfmq.total_spent, mfmq.total_rentals
FROM metrics_for_main_query mfmq
WHERE (mfmq.analysis_date - latest_rental_date::date) >= last_rentals_cutoff_duration
  AND mfmq.total_rentals >= 5;