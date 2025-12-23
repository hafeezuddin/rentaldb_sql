

/* Find the top 5 customers (by total spend) in each film category.
For each category, show:
Category name, Customer name (first and last)
Total amount they’ve spent on rentals in that category
Number of rentals they made in that category
Only include customers who have rented more than 3 films in that category.
Order the results by category name, then total spent (descending). */

--CTE to Display each customer total_spend in each category
WITH total_cat_spend AS (
  Select c.first_name, 
  c.last_name, 
  cat.name, 
  SUM(p.amount) AS total_spent,
  COUNT(DISTINCT r.rental_id) AS no_of_rentals
  FROM customer c
  INNER JOIN rental r ON c.customer_id = r.customer_id
  INNER JOIN payment p ON r.rental_id = p.rental_id --Considering paid rentals only
  INNER JOIN inventory i ON r.inventory_id = i.inventory_id
  INNER JOIN film_category fc ON i.film_id = fc.film_id
  INNER JOIN category cat ON fc.category_id = cat.category_id
  WHERE r.return_date IS NOT NULL AND (r.rental_date >= '2005-01-01' AND r.rental_date <= '2005-12-31')
  GROUP BY 1,2,3
  HAVING COUNT(DISTINCT r.rental_id) > 3 --Filtering customers who rented less than/Equals to 3 films.
),

--CTE to rank customers using window function. Partitioning by category and ranking by total_spend in descending order.
ranked_customers AS (
    SELECT tcs.first_name,
    tcs.last_name,
    tcs.name,
    tcs.total_spent,
    tcs.no_of_rentals,
    DENSE_RANK() OVER (PARTITION BY tcs.name ORDER BY tcs.total_spent DESC) AS spend_rank
    FROM total_cat_spend tcs
)

--Main query to display top 5 customers in each category.
SELECT rc.first_name, 
rc.last_name, 
rc.name, 
rc.total_spent, 
rc.no_of_rentals,
rc.spend_rank
FROM ranked_customers rc
WHERE spend_rank <= 5
ORDER BY rc.name, rc.total_spent DESC;

