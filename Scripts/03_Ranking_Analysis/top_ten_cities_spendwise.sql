
/*Find the top 10 cities where customers have spent the highest total amount on rentals.
For each city, also show: Total number of rentals made, Total amount spent, Average spend per rental 
Only include cities where at least 20 rentals were made.
Compare each city’s total spend against the overall average city spend.
Compare each city’s total spend against the overall average city spend (and only keep those above average)*/
SELECT c.city,
  a.city_id,
  SUM(p.amount) AS city_total,
  COUNT(DISTINCT r.rental_id) AS total_rentals,
  ROUND(SUM(p.amount)/COUNT(DISTINCT r.rental_id),2) AS avg_spent_per_rental
  FROM city c
INNER JOIN address a ON c.city_id = a.city_id
INNER JOIN customer cus ON a.address_id = cus.address_id
INNER JOIN rental r ON cus.customer_id = r.customer_id
INNER JOIN payment p ON r.rental_id = p.rental_id                                               --Considering only paid rentals
WHERE r.return_date IS NOT NULL AND (r.rental_date >= '2005-01-01' AND r.rental_date <= '2005-12-31')   --Filtering 2005 rentals
GROUP BY 1,2
HAVING COUNT(DISTINCT r.rental_id) > 20 AND
  SUM(p.amount) > (SELECT AVG(city_sum) AS city_average
                   FROM
                    (SELECT SUM(p2.amount) AS city_sum
                    FROM city c2
                    INNER JOIN address a2 ON c2.city_id = a2.city_id
                    INNER JOIN customer cus2 ON a2.address_id = cus2.address_id
                    INNER JOIN rental r2 ON cus2.customer_id = r2.customer_id
                    INNER JOIN payment p2 ON r2.rental_id = p2.rental_id                                            --Considering only paid rentals
                    WHERE r2.return_date IS NOT NULL AND (r2.rental_date >= '2005-01-01' AND r2.rental_date <= '2005-12-31') --Filtering 2005 rentals
                    GROUP BY c2.city_id
  ) t
)
ORDER BY city_total DESC
LIMIT 10;


--CTE Version
--CTE to calculate city_wise data
WITH city_wise_rental AS (
SELECT c.city, 
  a.city_id, 
  SUM(p.amount) AS city_total, 
  COUNT(r.rental_id) AS total_rentals, 
  ROUND(SUM(p.amount)/COUNT(r.rental_id),2) AS avg_spent_per_rental
  FROM city c
INNER JOIN address a ON c.city_id = a.city_id
INNER JOIN customer cus ON a.address_id = cus.address_id
INNER JOIN rental r ON cus.customer_id = r.customer_id
INNER JOIN payment p ON r.rental_id = p.rental_id                                             --Considering only paid rentals
WHERE r.return_date IS NOT NULL AND (r.rental_date >= '2005-01-01' AND r.rental_date <= '2005-12-31') --Filtering 2005 rentals
GROUP BY 1,2
),
--CTE to calculate city average by implementing sub-query
avg_income_per_city AS (
SELECT AVG(city_avg) AS city_average FROM 
                    (SELECT SUM(p2.amount) AS city_avg
                    FROM city c2
                    INNER JOIN address a2 ON c2.city_id = a2.city_id
                    INNER JOIN customer cus2 ON a2.address_id = cus2.address_id
                    INNER JOIN rental r2 ON cus2.customer_id = r2.customer_id
                    INNER JOIN payment p2 ON r2.rental_id = p2.rental_id                                               --Considering only paid rentals
                    WHERE r2.return_date IS NOT NULL AND (r2.rental_date >= '2005-01-01' AND r2.rental_date <= '2005-12-31')  --Filtering 2005 rentals
                    GROUP BY c2.city_id
                    )t
)
--Main query to display cities whose total rentals are greater than 20 
--And city total revenue is greater than average city revenue using cross join

SELECT cwr.city, cwr.city_id, cwr.city_total, ROUND(aipc.city_average,2) overall_city_avg_rev, cwr.total_rentals, cwr.avg_spent_per_rental
FROM city_wise_rental cwr
CROSS JOIN avg_income_per_city aipc   --Average income of city (Overall)
WHERE cwr.total_rentals > 20 AND cwr.city_total > aipc.city_average
ORDER BY cwr.city_total DESC
LIMIT 10;                                        

