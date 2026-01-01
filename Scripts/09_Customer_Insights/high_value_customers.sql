/* As we plan our next fiscal year's inventory budget, I need to identify which segments of our film library are delivering the best return on investment, and which customer relationships we should prioritize.

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

--CTE for premium films (replacement cost > 20)
WITH premium_films AS (
    SELECT f.film_id FROM film f
    WHERE f.replacement_cost > 20
),
premium_customers AS (
    SELECT c.customer_id, f.film_id, COUNT(*) AS times_rented
    FROM customer c
    INNER JOIN rental r ON c.customer_id = r.customer_id
    INNER JOIN payment p ON r.rental_id = p.rental_id --To filter paid rentals for analysis
    INNER JOIN inventory i ON r.inventory_id = i.inventory_id
    INNER JOIN film f ON i.film_id = f.film_id
    WHERE i.film_id IN (SELECT f.film_id FROM film f
                            WHERE f.replacement_cost > 20)
    GROUP BY 1,2
    HAVING COUNT(*) >= 2
),
revenue_calculation AS (
    SELECT pm.customer_id, 
        pm.film_id, 
        pm.times_rented,
        f.rental_rate,
        pm.times_rented * f.rental_rate AS total_revenue_generated,
        f.replacement_cost
    FROM premium_customers pm
    INNER JOIN film f ON pm.film_id = f.film_id
),
ROI AS (
    SELECT rc.customer_id, CONCAT(c.first_name,' ', c.last_name) AS full_name,
        rc.film_id, f.title,
        rc.times_rented,
        rc.rental_rate,
        rc.total_revenue_generated,
        rc.replacement_cost,
        ROUND((rc.total_revenue_generated/rc.replacement_cost)*100,2) AS roi_ach
     FROM revenue_calculation rc
     INNER JOIN customer c ON rc.customer_id = c.customer_id
     INNER JOIN film f ON rc.film_id = f.film_id
     WHERE ROUND((rc.total_revenue_generated/rc.replacement_cost)*100,2) > 50
)
SELECT * FROM ROI;
