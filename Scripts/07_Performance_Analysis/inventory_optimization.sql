/* The Operations team needs to reduce inventory costs while maintaining customer satisfaction. 
They want data-driven recommendations on which films to keep, which to acquire more copies of, and which to phase out.

Business Questions:
    "Which films give us the best return on our inventory investment?"
    "Are we over-invested in some films and under-invested in others?"
    "When do we need more copies available to meet demand?"
    "What's the optimal inventory mix for maximum profitability?"

Analytical Framework:

Metric 1: Film Profitability Score
Calculate return on inventory investment for each film.
Components:
    Revenue per Copy = Total film revenue / Number of copies
    Cost Recovery Multiple = Total revenue / Total replacement cost
    Rental Efficiency = Rentals per copy per month
    
Metric 2: Demand Patterns & Seasonality
Identify when and how films are rented.
Components:
    Monthly Rental Patterns - Peak demand periods
    Rental Duration Analysis - How long films stay out
    Copy Utilization Rate - How intensely each copy is used
    
Film Tiering System:
Tier 1: "Workhorses" - High utilization, high ROI
Tier 2: "Sleepers" - Low utilization but profitable when rented
Tier 3: "Opportunities" - High demand, need more copies
Tier 4: "Cost Centers" - Expensive but rarely rented
Tier 5: "Underperformers" - Low cost but also low usage

Required Deliverables:
Film-tier recommendations with specific copy count changes
Expected financial impact of optimization
Seasonal staffing recommendations based on demand patterns
Priority list of films to acquire/remove
 */

 --CTE to retrieve core metrics for each film
 WITH film_data AS (
    SELECT f.film_id, 
        f.title, COUNT(i.inventory_id) AS no_of_copies_avilable, 
        SUM(p.amount) as total_revenue_generated,
        ROUND(SUM(p.amount)/COUNT(i.inventory_id),2) AS revenue_per_copy,
        ROUND(SUM(p.amount)/f.replacement_cost,2) AS cost_recovery_multiple
    FROM film f
    INNER JOIN inventory i ON f.film_id = i.film_id
    INNER JOIN rental r ON i.inventory_id = r.inventory_id
    INNER JOIN payment p ON r.rental_id = p.rental_id
    WHERE r.return_date IS NOT NULL AND r.rental_date BETWEEN '01-01-2005' AND '12-31-2005'
    GROUP BY 1,2
    ORDER BY 1 ASC
 ),
 --CTE to retrieve Monthly film rental patterns
rentals_per_copy AS (
    SELECT f.film_id, f.title,
    EXTRACT('Month' FROM r.rental_date) AS month,
    COUNT(*) AS rentals
    FROM film f
    INNER JOIN inventory i ON f.film_id = i.film_id
    INNER JOIN rental r ON i.inventory_id = r.inventory_id
    WHERE r.return_date IS NOT NULL AND r.rental_date BETWEEN '01-01-2005' AND '12-31-2005'
    GROUP BY 1,2,3
    ORDER BY 1
 )
--CTE to identify Peak Demand Periods
peak_period AS (
   SELECT *,
    SUM(sq1.rentals) OVER (PARTITION BY sq1.film_id) AS total_rentals,
    ROUND((sq1.rentals/SUM(sq1.rentals) OVER (PARTITION BY sq1.film_id))*100,2) AS concentration
    FROM (
    SELECT f.film_id, f.title,
    EXTRACT('Month' FROM r.rental_date) AS month,
    COUNT(*) AS rentals
    FROM film f
    INNER JOIN inventory i ON f.film_id = i.film_id
    INNER JOIN rental r ON i.inventory_id = r.inventory_id
    WHERE r.return_date IS NOT NULL AND r.rental_date BETWEEN '01-01-2005' AND '12-31-2005'
    GROUP BY 1,2,3
    ORDER BY 1
    ) sq1
)
--CTE for Rental Duration Analysis.
rental_duration_analysis AS (
   SELECT sq2.film_id, 
   ROUND(AVG(sq2.rental_duration),2) AS average_rental_duration
   FROM (
    SELECT f.film_id, 
        i.inventory_id, 
        r.rental_id, 
        r.rental_date::date, r.return_date::date,
        (r.return_date::date - r.rental_date::date) AS rental_duration
    FROM film f
    INNER JOIN inventory i ON f.film_id = i.film_id
    INNER JOIN rental r ON i.inventory_id = r.inventory_id
    WHERE r.return_date IS NOT NULL AND r.rental_date BETWEEN '01-01-2005' AND '12-31-2005'
    ORDER BY f.film_id ASC
   ) sq2
  GROUP BY sq2.film_id 
)
--CTE for Copy utilization
copy_utilization AS (
    EXPLAIN ANALYZE
    SELECT f.film_id, f.title, i.inventory_id,
    EXTRACT('Month' FROM r.rental_date) AS month,
    COUNT(*) AS rentals
    FROM film f
    INNER JOIN inventory i ON f.film_id = i.film_id
    INNER JOIN rental r ON i.inventory_id = r.inventory_id
    WHERE r.return_date IS NOT NULL AND r.rental_date BETWEEN '01-01-2005' AND '12-31-2005'
    GROUP BY 1,2,3,4
    ORDER BY 1,3,4 ASC
)
