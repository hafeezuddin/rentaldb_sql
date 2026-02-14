/* Total revenue generated & total rentals in 2005  */
/* Adhoc request */
SELECT SUM(p.amount)               total_revenue_generated,
       COUNT(DISTINCT r.rental_id) total_rental,
       --Includes unpaid rentals as well (Due to left Join).
       --Replace left join with inner join to consider paid rentals.
       -- r.rental_id is primary key in rental table.
       '2005'                      financial_year
FROM rental r
         LEFT JOIN payment p ON r.rental_id = p.rental_id
WHERE r.rental_date BETWEEN '2005-01-01' AND '2005-12-31'

