/*Find the top 5 customers who:
Have spent the most total rental fees (based on payment.amount).
Also have rented films from at least 5 different categories.
Display for each customer: customer_id,first_name & last_name,total_spent, number_of_categories_rented
Order the result by total_spent (highest first). */

--Base CTE with customer and corresponding rental data for building metrics
WITH rental_info AS (SELECT r.customer_id,
                            concat(c.first_name, ' ', c.last_name) AS customer_full_name,
                            p.amount                               AS rental_amount,
                            ct.name
                     FROM rental r
                              JOIN customer c ON r.customer_id = c.customer_id
                              LEFT JOIN payment p ON r.rental_id = p.rental_id
                              JOIN inventory i ON r.inventory_id = i.inventory_id
                              JOIN film f ON i.film_id = f.film_id
                              JOIN film_category fc ON f.film_id = fc.film_id
                              JOIN category ct ON fc.category_id = ct.category_id
    --LEFT JOIN retains both paid and unpaid rentals.
    --Replace LEFT JOIN with INNER JOIN ton consider only paid rentals and exclude unpaid rentals from total rentals calculation.
),
     metrics AS (SELECT ri.customer_id,
                        ri.customer_full_name,
                        COUNT(DISTINCT ri.name) AS         categories_rented,
                        COALESCE(SUM(ri.rental_amount), 0) amount_spent
                 --Handles edge case where customers all rentals are unpaid rentals.
                 FROM rental_info ri
                 GROUP BY ri.customer_id, ri.customer_full_name)
SELECT m.customer_id, m.customer_full_name, m.categories_rented AS unique_categories_rented, m.amount_spent
FROM metrics m
WHERE m.categories_rented >= 5
ORDER BY m.amount_spent DESC
LIMIT 5;
