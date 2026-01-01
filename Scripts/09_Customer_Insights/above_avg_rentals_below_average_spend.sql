
/*- Find customers who have rented films more than the average number of times but whose 
total spend is below the average total spend across all customers. */
--CTE to find customers who rented more than average number of times
--Consider both paid and unpaid rentals

WITH above_avg_rentals AS (
SELECT c.customer_id,
    c.first_name,
    COUNT(*) AS abv_avg_rentals_count
FROM customer c
    INNER JOIN rental r ON c.customer_id = r.customer_id
GROUP BY 1,2
HAVING COUNT(*) > (
        SELECT AVG(count2)
        FROM (
                SELECT r2.customer_id,
                    COUNT(*) AS count2
                FROM rental r2
                GROUP BY r2.customer_id
            ) as cic2
    )
ORDER BY abv_avg_rentals_count DESC
),
--CTE to calculate average spend and Filter customers whose spend is below average
below_avg_payment AS (
    SELECT c.customer_id,
        c.first_name,
        SUM(p.amount) AS total_spent
    FROM customer c
        INNER JOIN payment p ON c.customer_id = p.customer_id
    GROUP BY c.customer_id
    HAVING SUM(p.amount) < (
            SELECT AVG(total_spent2)
            FROM (
                    SELECT p2.customer_id,
                        SUM(p2.amount) AS total_spent2
                    FROM payment p2
                    GROUP BY p2.customer_id
                ) as s
        )
)
--Main query to filter customers who rent above average times but spent below average.
--Picky spenders
SELECT aar.customer_id, aar.first_name
FROM above_avg_rentals AS aar
INNER JOIN below_avg_payment bap ON aar.customer_id = bap.customer_id
ORDER BY 1;
