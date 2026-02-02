/* Find the top 5 customers (by total spend) in each film category.
For each category, show:
    Category name, Customer name (first and last)
    Total amount they’ve spent on rentals in that category
    Number of rentals they made in that category
    Only include customers who have rented more than 3 films in that category.
    Order the results by category name, then total spent (descending). */

--Approach: Assign one primary category to film
-- To avoid cartesian product and inflated numbers.
-- Though not required for sakila db, coding standards maintained to handle edge cases]
--BASE CTE for rental information and also to assign primary category to each film.
WITH base_cte AS (SELECT r.customer_id, r.rental_id, MIN(fc.category_id) AS primary_category
                  FROM rental r
                           JOIN inventory i ON r.inventory_id = i.inventory_id
                           JOIN film_category fc ON i.film_id = fc.film_id
                  GROUP BY r.customer_id, r.rental_id),
--Amount spent per rental calculation cte without joining categories table to avoid inflated totals
     spent_per_rental AS (SELECT bc.customer_id,
                                 bc.rental_id,
                                 bc.primary_category,
                                 SUM(p.amount) AS spent_per_rental
                          FROM base_cte bc
                                   JOIN payment p ON bc.rental_id = p.rental_id
                          GROUP BY bc.customer_id, bc.rental_id, bc.primary_category)
--Main query to aggregate metrics and rank customers in each category based on amount they spent
SELECT t1.name           AS category_name,
       c.first_name,
       c.last_name,
       t1.category_spent AS amount_spent,
       t1.distinct_rentals_in_category,
       t1.category_rank
--Can be converted into CTE for better readability
FROM (SELECT spr.customer_id,
             cat.name,
             spr.primary_category,
             SUM(spent_per_rental)                                                               AS category_spent,
             COUNT(DISTINCT spr.rental_id)                                                       AS distinct_rentals_in_category,
             RANK() OVER (PARTITION BY spr.primary_category ORDER BY SUM(spent_per_rental) DESC) AS category_rank
      FROM spent_per_rental spr
               JOIN category cat ON spr.primary_category = cat.category_id
      GROUP BY spr.customer_id, spr.primary_category, cat.name
      HAVING COUNT(DISTINCT spr.rental_id) > 3) t1
         --Joining customers table here to avoid unnecessary processing over head in base query.
         JOIN customer c ON t1.customer_id = c.customer_id
WHERE t1.category_rank <= 5
ORDER BY t1.name, category_rank;
