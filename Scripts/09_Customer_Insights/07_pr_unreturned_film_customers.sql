/* Unreturned films against the customer who rented them.
   Include no of days since film was rented.
   Analyze 2005 data. Include both paid and unpaid data*/

--Parameters CTE to maintain modularity in analysis
WITH param_cte AS (SELECT DATE '2005-01-01' AS analysis_period_start,
                          DATE '2005-12-31' AS analysis_period_end,
                          DATE '2006-01-01' AS analysis_date),

--Base CTE with rental records (Both paid and unpaid) of each customer during the period of 2005
     rentals_info AS (SELECT r.customer_id,
                             CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
                             c.email,
                             f.title,
                             r.rental_date,
                             r.return_date,
                             r.rental_id,
                             pc.analysis_date,
                             pc.analysis_date - r.rental_date::date AS days_since_last_rented
                      FROM rental r
                               JOIN customer c ON r.customer_id = c.customer_id
                               JOIN inventory i ON r.inventory_id = i.inventory_id
                               JOIN film f ON i.film_id = f.film_id
                               CROSS JOIN param_cte pc
                      WHERE (r.rental_date >= pc.analysis_period_start
                          AND r.rental_date <= pc.analysis_period_end)
                        AND (r.return_date IS NULL))
--Main query to extrapolate customer details against the film they haven't returned and the days since it was rented out.
--List is ordered by customers having highest unreturned duration
SELECT ri.customer_id,
       ri.title                  AS film_title,
       ri.customer_name          AS customer_full_name,
       ri.email,
       ri.days_since_last_rented AS days_since_last_rental
FROM rentals_info ri
ORDER BY days_since_last_rental DESC;

