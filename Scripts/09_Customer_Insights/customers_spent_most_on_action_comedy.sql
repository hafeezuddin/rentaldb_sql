/*Find the customers who spent the most on rentals from only “Action” and “Comedy” categories.
Requirements:
Show customer_id, first_name, last_name, category_name, and total_spent.
Only include customers whose total spending in that category is above the average spending in that category (across all customers).
Order by category_name and then total_spent DESC.
Limit to the top 10 results overall.*/

--CTE to find customers who rented from action or comedy or both along with their total spent in each cat
WITH customer_info AS (
    SELECT c.customer_id, c.first_name, c.last_name, ct.name, SUM(p.amount) AS total_spent FROM customer c
    INNER JOIN rental r ON c.customer_id = r.customer_id
    INNER JOIN inventory i ON r.inventory_id = i.inventory_id
    INNER JOIN film_category fc ON i.film_id = fc.film_id
    INNER JOIN category ct ON fc.category_id = ct.category_id
    INNER JOIN payment p on r.rental_id = p.rental_id
    WHERE ct.name IN ('Comedy','Action')
    GROUP BY 1,2,3,4
    ORDER BY c.customer_id
),
cat_avg AS (
  SELECT ci.name, AVG(ci.total_spent) AS avg_category
  FROM customer_info ci
  GROUP BY 1
)
SELECT ci.customer_id, ci.first_name, ci.last_name, ci.name, ci.total_spent
FROM customer_info ci
JOIN cat_avg ca ON ci.name = ca.name
WHERE ci.total_spent > ca.avg_category
ORDER BY ci.name, ci.total_spent DESC
LIMIT 10;