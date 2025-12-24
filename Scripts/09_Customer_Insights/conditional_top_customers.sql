/*Find the top 5 customers who:
Have spent the most total rental fees (based on payment.amount).
Also have rented films from at least 5 different categories.
Display for each customer: customer_id,first_name & last_name,total_spent, number_of_categories_rented
Order the result by total_spent (highest first). */
--Main Query to retrieve customer details, total spend, no.of unique categories they rented from
SELECT 
    c.customer_id,
    c.first_name, 
    c.last_name,
    count(DISTINCT ct.name) AS number_of_categories_rented,
    SUM(p.amount) AS total_spent
FROM customer c
    INNER JOIN rental r ON c.customer_id = r.customer_id
    INNER JOIN inventory i ON r.inventory_id = i.inventory_id
    INNER JOIN film_category fc ON i.film_id = fc.film_id
    INNER JOIN category ct ON fc.category_id = ct.category_id
    INNER JOIN payment p ON r.rental_id = p.rental_id
GROUP BY 1,2,3
HAVING COUNT(DISTINCT ct.name) >= 5
ORDER BY SUM(p.amount) DESC
LIMIT 5;


--By Applying CTE
--CTE to calculate no.of.times each customer rented from categories
WITH customer_data AS (
  SELECT c.customer_id,
    c.first_name,c.last_name,
    count(DISTINCT ct.name) AS number_of_categories_rented
FROM customer c
    INNER JOIN rental r ON c.customer_id = r.customer_id
    INNER JOIN inventory i ON r.inventory_id = i.inventory_id
    INNER JOIN film_category fc ON i.film_id = fc.film_id
    INNER JOIN category ct ON fc.category_id = ct.category_id
    INNER JOIN payment p ON r.rental_id = p.rental_id
GROUP BY 1,2,3
HAVING count(DISTINCT ct.NAME) >=5
),
spend_criteria AS (
  SELECT c.customer_id, SUM(p.amount) AS total_spent
  FROM customer c
  INNER JOIN rental r ON c.customer_id = r.customer_id --In case customer has 2 rentals and 1 payment (x Joined using c.customer_id).
  INNER JOIN payment p ON r.rental_id = p.rental_id
  GROUP BY 1
)
SELECT cs.first_name, cs.last_name, cs.number_of_categories_rented, sc.total_spent
FROM customer_data cs
INNER JOIN spend_criteria sc ON cs.customer_id = sc.customer_id
ORDER BY sc.total_spent DESC
LIMIT 5;