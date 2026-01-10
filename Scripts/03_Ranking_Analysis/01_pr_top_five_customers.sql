/* Customers who rented the most (top 5) */
--Considering both paid and unpaid rentals in the year 2005

--Param CTE for constants to maintain modularity.
WITH param_cte AS (SELECT DATE '2005-01-01' AS analysis_start_date, --DATE IS IN ISO FORMAT YYYY-MM-DD
                          DATE '2005-12-31' AS analysis_end_date),
--BASE CTE to retrieve customer and their rentals.
     rental_info AS (SELECT r.customer_id, r.rental_id, CONCAT(c.first_name, ' ', c.last_name) AS customer_full_name
                     FROM rental r
                              LEFT JOIN payment p ON r.rental_id = p.rental_id
                              JOIN customer c ON r.customer_id = c.customer_id
                              CROSS JOIN param_cte pc
                     --Left Join accounts for both paid and unpaid rentals. Join is not mandatory in case where both paid and unpaid data is considered.
                     --Left Join is to be replaced with INNER JOIN in business cases where only paid rental data is to be considered.
                     WHERE r.rental_date BETWEEN pc.analysis_start_date AND pc.analysis_end_date)
--Main query to filter customers based on no.of.films they rented in descending order.
--DISTINCT ri.rental_id handles cases where customer paid/split the rental amount in two transactions.
SELECT ri.customer_id, ri.customer_full_name, COUNT(DISTINCT ri.rental_id) AS total_rentals
FROM rental_info ri
GROUP BY ri.customer_id, ri.customer_full_name
ORDER BY total_rentals DESC
LIMIT 5;



--Non_Modular approach/Preferable for ad-hoc analysis
SELECT c.customer_id,
       CONCAT(c.first_name, ' ', c.last_name)                                           AS customer_name,
       COUNT(DISTINCT r.rental_id)                                                      AS total_rentals,
       row_number() over (ORDER BY COUNT(DISTINCT r.rental_id) desc, c.customer_id ASC) AS customer_rank
FROM customer c
         JOIN rental r ON c.customer_id = r.customer_id
         LEFT JOIN payment p ON r.rental_id = p.rental_id
WHERE r.rental_date BETWEEN '2005-01-01' AND '2005-12-31'
GROUP BY c.customer_id,
         CONCAT(c.first_name, ' ', c.last_name)
ORDER BY customer_rank ASC
LIMIT 5;