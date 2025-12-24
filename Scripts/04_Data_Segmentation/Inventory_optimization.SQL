/* Business Case: You're analyzing the DVD rental business to optimize inventory purchasing and identify underperforming films. 
Management wants to make data-driven decisions about which films to keep, restock, or remove from inventory.

Specific Requirements:
Calculate for each film:
    Total number of rentals
    Total revenue generated
    Average rental duration (days between rental and return)
    Number of copies in inventory
    Utilization rate (% of time the film was rented vs. available)

Categorize films into performance tiers:
    "Blockbuster": Top 15% by revenue AND rental count
    "Underperforming": Bottom 25% by revenue AND replacement_cost > $20
    "Efficient": Above average revenue per copy AND utilization rate > 60%
    "Standard": All other films

Additional Requirements:
    Only include films with at least 5 rentals
    Exclude films with missing return dates
    Include film category and replacement cost
    Calculate ROI: (total_revenue / replacement_cost) * 100
*/

-- CTE for core film metrics: Calculates revenue, rentals, and duration statistics
WITH film_metrics AS (
SELECT f.film_id AS fid, 
    f.title AS title,
    cat.name,
    f.replacement_cost,
    COUNT(DISTINCT r.rental_id) AS no_of_rentals,
    SUM(p.amount) AS total_revenue_generated,
    -- Calculate percentile ranks for revenue and rental counts
    PERCENT_RANK() OVER (ORDER BY SUM(p.amount)) AS percent_rev_rank,
    PERCENT_RANK() OVER (ORDER BY COUNT(r.rental_id)) AS percent_rent_rank,
    -- Calculate average revenue per copy of film
    SUM(p.amount) /COUNT(DISTINCT i.inventory_id) AS avg_rev_per_copy,
    EXTRACT(DAY FROM AVG(r.return_date - r.rental_date)) AS avg_rental_duration
FROM film f
INNER JOIN inventory i ON f.film_id = i.film_id
INNER JOIN rental r ON i.inventory_id = r.inventory_id
INNER JOIN film_category fc ON f.film_id = fc.film_id
INNER JOIN category cat ON fc.category_id = cat.category_id
INNER JOIN payment p ON r.rental_id = p.rental_id AND r.return_date IS NOT NULL
WHERE r.return_date IS NOT NULL AND (r.rental_date >= '2005-01-01' AND r.rental_date <= '2005-12-31')
GROUP BY 1,2,3,4
),
-- CTE to find currently available inventory (excluding unreturned rentals)
available_inventory AS (
    SELECT f.film_id,
    COUNT(*) AS available_inventory
    FROM film f
    INNER JOIN inventory i ON f.film_id = i.film_id
    LEFT JOIN rental r ON i.inventory_id = r.inventory_id AND r.return_date IS NULL
    WHERE r.rental_id IS NULL
    GROUP BY 1
),
-- CTE to calculate total inventory regardless of rental status
available_inventory2 AS (
    SELECT f.film_id, COUNT(i.inventory_id) AS total_invent
    FROM film f
    INNER JOIN inventory i ON f.film_id = i.film_id
    GROUP BY 1
), 
-- CTE to calculate utilization rate (percentage of time film was rented in 2005)
utilization_rate_calculation AS (
SELECT x2.film_id, 
    -- Calculate utilization as (total rental days / (total inventory * 365 days)) * 100
    ROUND(SUM(x2.rental_duration::numeric)/(x2.total_invent*365)*100,2) AS utlisation_rate_for_2005 FROM 
    (
        SELECT f.film_id,av_ai.total_invent, r.rental_date, r.return_date,
        r.return_date::date - r.rental_date::date AS rental_duration
        FROM film f
        INNER JOIN inventory i ON f.film_id = i.film_id
        INNER JOIN rental r ON i.inventory_id = r.inventory_id
        INNER JOIN available_inventory2 av_ai ON i.film_id = av_ai.film_id
        WHERE r.return_date IS NOT NULL AND (r.rental_date >= '2005-01-01' AND r.rental_date <= '2005-12-31')
        ORDER BY f.film_id, i.inventory_id
    ) x2
GROUP BY 1, x2.total_invent
ORDER BY 1
),
-- CTE to calculate overall average revenue per copy for comparison
overall_avg_cte AS (
    SELECT AVG(fm.avg_rev_per_copy) AS overall_average
    FROM film_metrics fm
),
-- Final aggregation CTE combining all metrics and categorizing films
agg AS (
    SELECT fm.fid, 
    fm.title,
    fm.name,
    fm.replacement_cost,
    ROUND(fm.avg_rev_per_copy::numeric,2) avg_revenue_per_copy,
    ROUND(oac.overall_average::numeric,2) AS overall_avg,
    fm.total_revenue_generated,
    ROUND(fm.percent_rev_rank::numeric,2) AS per_rev_rank,
    fm.no_of_rentals, 
    ROUND(fm.percent_rent_rank::numeric,2) AS per_rent_rank,
    ai.available_inventory,
    urc.utlisation_rate_for_2005,
    -- Calculate ROI as (revenue/cost)*100
    ROUND((fm.total_revenue_generated/fm.replacement_cost)*100,2) AS ROI,
    -- Categorize films based on performance metrics
    CASE
        WHEN fm.percent_rev_rank >= 0.85 AND fm.percent_rent_rank >= 0.85
            THEN 'Blockbuster'
        WHEN fm.percent_rev_rank <= 0.25 AND fm.replacement_cost > 20
            THEN 'Underperforming'
        WHEN fm.avg_rev_per_copy > oac.overall_average AND urc.utlisation_rate_for_2005 > 60
            THEN 'Efficient'
        ELSE
            'Standard'
        END AS categorization
FROM film_metrics fm
INNER JOIN available_inventory ai ON fm.fid = ai.film_id
INNER JOIN utilization_rate_calculation urc ON ai.film_id = urc.film_id
CROSS JOIN overall_avg_cte oac
WHERE fm.no_of_rentals >= 5
)
SELECT * FROM agg;