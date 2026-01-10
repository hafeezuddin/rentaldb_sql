/*- Find customers who have rented films more than the average number of times but whose
total spend is below the average total spend across all customers.
--CTE to find customers who rented more than average number of times
--Consider both paid and unpaid rentals */

--Base CTE for customer rental data
WITH rentals_info AS (SELECT DISTINCT r.customer_id, p.amount, r.rental_id
                      FROM rental r
                               LEFT JOIN payment p ON r.rental_id = p.rental_id
    --Considers both paid and unpaid rentals as required by business case
    --Replace Left with INNER JOIN to consider only paid rentals.
),
--CTE to calculated customer wise total_spent and rentals.
     consolidated_customer_rental_data AS (SELECT ri.customer_id,
                                                  SUM(ri.amount)               AS customer_total_spent, --Caution: Considers all rentals but ignores rows which have null values
                                                  COUNT(distinct ri.rental_id) AS total_no_of_rentals   --Considers both paid and unpaid rentals
                                           FROM rentals_info ri
                                           GROUP BY ri.customer_id),
--CTE to calculate average metrics based upon customer rentals_info CTE data
     average_metrics AS (SELECT ROUND(AVG(ccrd.customer_total_spent), 2) AS overall_spent_average,
                                ROUND(AVG(total_no_of_rentals), 2)       AS avg_rentals_per_customer
                         FROM consolidated_customer_rental_data ccrd)
--Data-Quality checks
-- SELECT * FROM
--     (SELECT count(ri.rental_id) FROM rentals_info ri),
--     (SELECT count(ri.rental_id) FROM rentals_info ri WHERE ri.amount is NULL),
--     (SELECT count(ri.rental_id) FROM rentals_info ri WHERE ri.amount is NOT NULL);

--Main query to filter customers who rent more than average but spend less than average.
SELECT DISTINCT ri.customer_id
FROM rentals_info ri
         JOIN consolidated_customer_rental_data ccrd ON ri.customer_id = ccrd.customer_id
         CROSS JOIN average_metrics am
WHERE ccrd.customer_total_spent < am.overall_spent_average
  AND ccrd.total_no_of_rentals > am.avg_rentals_per_customer;