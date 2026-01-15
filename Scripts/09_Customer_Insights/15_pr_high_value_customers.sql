/* As we plan our next fiscal year's inventory budget,
   I need to identify which segments of our film library are delivering the best return on investment, and which customer relationships we should prioritize.

Your task is to analyze the intersection of our premium film inventory and customer behavior.

Specifically, I need you to identify customers who meet the following criteria:

    They consistently rent from our premium collection (films with a replacement cost of $20 or more).
    They have rented the same premium film multiple times (at least 2 rentals per film).
    The total revenue from a customer for a specific film must be greater than 50% of that film's replacement cost.

Key Questions this analysis should answer:
    Which customers are the most frequent renters of our highest-value assets?
    For these customer-film pairs, what is the average revenue we earn each time the film is rented?
    How does the total revenue from a customer for a specific film compare to our initial investment in that film?
Please prepare this analysis. The final deliverable should allow us to easily see the top-performing customer and film combinations based on rental efficiency and overall return.
 */


WITH premium_films AS (
    SELECT f.film_id
    FROM film f
    WHERE f.replacement_cost > 20
),
premium_customers AS (
    SELECT c.customer_id,
           CONCAT(c.first_name, ' ', c.last_name) AS full_name,
           c.email,
           f.film_id,
           f.title,
           f.rental_rate,
           f.replacement_cost,
           COUNT(*) AS times_rented
    FROM customer c
    INNER JOIN rental r ON c.customer_id = r.customer_id
    INNER JOIN payment p ON r.rental_id = p.rental_id
    INNER JOIN inventory i ON r.inventory_id = i.inventory_id
    INNER JOIN film f ON i.film_id = f.film_id
    WHERE f.film_id IN (SELECT film_id FROM premium_films)
    GROUP BY c.customer_id, c.first_name, c.last_name, c.email, f.film_id, f.title, f.rental_rate, f.replacement_cost
    HAVING COUNT(*) >= 2
),
revenue_calculation AS (
    SELECT pc.customer_id,
           pc.full_name,
           pc.email,
           pc.film_id,
           pc.title,
           pc.times_rented,
           pc.rental_rate,
           pc.times_rented * pc.rental_rate AS total_revenue_generated,
           pc.replacement_cost,
           ROUND((pc.times_rented * pc.rental_rate / pc.replacement_cost) * 100, 2) AS roi_ach
    FROM premium_customers pc
)
SELECT customer_id,
       full_name,
       email,
       film_id,
       title,
       times_rented,
       rental_rate,
       total_revenue_generated,
       replacement_cost,
       roi_ach
FROM revenue_calculation
WHERE roi_ach > 50
ORDER BY customer_id, roi_ach DESC;

