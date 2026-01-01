/* Weekend Rental Lovers
Find the top 10 customers who rented the most movies on weekends (Saturday and Sunday).*/
--Consider both paid and unpaid rentals.
--CTE to find top 10 customers who rented most on weekends with corresponding metric (count)
WITH wknd_rental AS 
(
  SELECT
  r.customer_id, 
  c.first_name, 
  COUNT(*) AS wk_rental_count
FROM rental r
INNER JOIN customer c ON r.customer_id = c.customer_id
WHERE EXTRACT(DOW FROM rental_date) IN (0,6) --DOW: Extracting day of week from date 0:Sunday-6:Saturday
GROUP BY 1,2
ORDER BY count(*) DESC
),
--CTE to find total_rentals by the above filtered customers (Top 10 weekend renters) to calculate weekend rental%
rentals_by_customer_id AS
(
  SELECT r2.customer_id, 
  count(*) AS total_rentals
  FROM rental r2
  INNER JOIN wknd_rental ON r2.customer_id = wknd_rental.customer_id --INNER JOIN CTE wknd_rentals
  GROUP BY r2.customer_id
)
--Main query to display customer_id, weekend_rentals, total_rentals, percentage of weekend rentals out of total rentals
SELECT wknd_rental.customer_id,
wknd_rental.first_name,
wknd_rental.wk_rental_count, --bigint
rbci.total_rentals, --bigint
ROUND((wknd_rental.wk_rental_count::numeric/rbci.total_rentals::numeric)*100,2) AS percentgae_of_rentals_on_weekends
--Percentage calculation/dt conversion into numeric for percentage calculation
FROM wknd_rental
INNER JOIN rentals_by_customer_id rbci ON wknd_rental.customer_id = rbci.customer_id
ORDER BY percentgae_of_rentals_on_weekends DESC
LIMIT 10;
