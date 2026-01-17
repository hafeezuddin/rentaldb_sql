/* Weekend Rental Lovers
Find the top 10 customers who rented the most movies on weekends (Saturday and Sunday).
Conditions: Consider both paid and unpaid rentals.*/

--Base CTE for Customers and their rental information
WITH rental_info AS (SELECT r.customer_id,  --Both paid and unpaid rentals are included in the analysis.
                            r.rental_date::date, EXTRACT(DOW FROM r.rental_date) AS rental_day_of_week
                     FROM rental r), --ADD:payment table using inner on customer_id to filter and consider paid rentals only (Future use case).

--CTE To filter weekend rentals
     rental_flag AS (SELECT ri.customer_id,
                            ri.rental_day_of_week,
                            CASE
                                WHEN ri.rental_day_of_week = 0 OR ri.rental_day_of_week = 6 THEN 'Weekend rental'
                                ELSE 'Weekday rental'
                                End AS dow_flag
                     FROM rental_info ri),
--CTE to calculate weekend and weekday rentals for a customers
     consolidated_customer_rental_metrics AS (SELECT rf.customer_id,
                                                     SUM(CASE WHEN rf.dow_flag = 'Weekend rental' THEN 1 ELSE 0 END) AS weekend_rentals,
                                                     SUM(CASE WHEN rf.dow_flag = 'Weekday rental' THEN 1 ELSE 0 END) AS weekday_rentals
                                              FROM rental_flag rf
                                              GROUP BY rf.customer_id)

--Main query to calculate weekend rentals share for a customer and limiting to top 10 weekend renters.
SELECT ccrm.customer_id,
       ccrm.weekend_rentals,
       ccrm.weekday_rentals,
       ROUND((COALESCE(ccrm.weekend_rentals, 0)::numeric / NULLIF((ccrm.weekend_rentals + ccrm.weekday_rentals), 0)) *
             100, 2) AS weekend_rentals_percentage
FROM consolidated_customer_rental_metrics ccrm
ORDER BY  ccrm.weekend_rentals DESC
LIMIT 10;
