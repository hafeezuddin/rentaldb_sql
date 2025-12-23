/* Top spending customers for the year 2005*/
SELECT c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    SUM(p.amount) AS total_spend
FROM customer c
JOIN payment p ON c.customer_id = p.customer_id
JOIN rental r ON p.rental_id = r.rental_id              --Joined to filter 2005 rental data
WHERE r.return_date IS NOT NULL AND (r.rental_date >= '2005-01-01' AND r.rental_date <= '2005-12-31')
GROUP BY c.customer_id        --Grouping by Primary key is sufficient
ORDER BY total_spend DESC
LIMIT 5;
