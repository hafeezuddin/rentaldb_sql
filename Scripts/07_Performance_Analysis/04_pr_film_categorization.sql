/* Categorize Films by Rental Performance
 Classify films into performance tiers based on rental frequency and compare their revenue contribution.

Requirements:
Use a CASE statement to categorize films as:
 "High Demand": Rented 30+ times | "Medium Demand": Rented 15-29 times | "Low Demand": Rented <15 times
 For each category, calculate: Number of films, Total revenue generated, Average rental rate
 Sort results by revenue contribution (highest to lowest).*/

--Cte to consolidate revenue per rental_id to handle edge cases where multiple payments exists for same rental_id (split payments)
WITH revenue_consolidation AS (
    SELECT r.rental_id, SUM(p.amount) tot_amount
    FROM rental r
    JOIN payment p ON r.rental_id = p.rental_id
    WHERE r.rental_date < '2006-01-01' AND r.rental_date > '2005-01-01'
    --Limiting analysis to the year 2005
    GROUP BY r.rental_id
),
--Base film information with its corresponding rentals, revenue
base_film_information AS (
    SELECT f.film_id, f.rental_rate,
           COUNT(f.film_id) total_rentals,
           SUM(cr.tot_amount) total_revenue_generated
    FROM film f
    JOIN inventory i ON f.film_id = i.film_id
    JOIN rental r ON i.inventory_id = r.inventory_id
    JOIN revenue_consolidation cr ON r.rental_id = cr.rental_id
    GROUP BY f.film_id
),
--CTE to categorize films into categories.
film_categorization AS (
    SELECT bfi.film_id, bfi.rental_rate, bfi.total_revenue_generated,
           CASE WHEN bfi.total_rentals >= 30 THEN 'High Demand'
                WHEN bfi.total_rentals BETWEEN 15 AND 29 THEN 'Medium Demand'
                ELSE 'Low Demand'
           END AS film_category
    FROM base_film_information bfi
)
--Main query to aggregate the metrics
SELECT fc.film_category,COUNT(*) no_of_films, ROUND(AVG(fc.rental_rate),2) average_rental_rate,
       SUM(fc.total_revenue_generated) total_category_revenue,
       ROUND ((coalesce(SUM(fc.total_revenue_generated),0)/NULLIF(SUM(SUM(fc.total_revenue_generated)) over (),0))*100,2) revenue_share
FROM film_categorization fc
GROUP BY fc.film_category;
