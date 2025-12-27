/* Analyze film performance across rental metrics and inventory efficiency to identify optimization opportunities.

Specific Requirements:
For each film, calculate: Total rentals and total revenue generated
Average rental duration vs. actual rental period
Rental frequency (rentals per day available)
Inventory utilization rate (% of inventory copies rented at least once in last 90 days)

Categorize films into:
"Blockbusters": Top 20% by revenue AND rental frequency
"Underperformers": Bottom 30% by revenue AND rental frequency
"Efficient Classics": High utilization rate (>80%) AND above average rental duration
"Slow Movers": Low utilization rate (<30%) AND below average rentals
"Balanced Performers": All other films

Include store-level analysis:
Compare performance between store locations
Identify films that perform well in one store but poorly in another


Desired Output Business requirement:
film_id, title, category_name, total_rentals, total_revenue, avg_rental_duration, rental_frequency, inventory_utilization_rate
performance_category, store_1_rentals, store_2_rentals, performance_disparity */

--CTE to calculate core business metrics
WITH film_metrics AS (
    SELECT f.film_id, f.title,
        COUNT(DISTINCT r.rental_id) AS total_rentals, 
        SUM(p.amount) AS total_revenue,
        PERCENT_RANK() OVER (ORDER BY SUM(p.amount)) AS rev_rank
    FROM film f
    INNER JOIN inventory i ON f.film_id = i.film_id
    INNER JOIN rental r ON i.inventory_id = r.inventory_id
    INNER JOIN payment p ON r.rental_id = p.rental_id
    WHERE r.return_date IS NOT NULL --Account only films that are returned.
    GROUP BY 1,2
),
--CTE to calculate average_rental_duration per film and pull  actual allowed duration
filmwise_avg_rental_duration AS (
        SELECT f.film_id, 
        f.rental_duration AS allowed_rental_duration,
        ROUND(AVG(r.return_date::date - r.rental_date::date),2) AS actual_average_duration
        FROM film f
        INNER JOIN inventory i ON f.film_id = i.film_id
        INNER JOIN rental r ON i.inventory_id = r.inventory_id
        INNER JOIN payment p ON r.rental_id = p.rental_id
        GROUP BY 1,2
),
--CTE to calculate rental_frequency
rental_frequency AS (
    SELECT f.film_id, COUNT(*),
    COUNT(*)::numeric/365 AS rental_frequency_2005,
    PERCENT_RANK() OVER (ORDER BY COUNT(*)::numeric/365) AS rf_rank
    FROM film f
    INNER JOIN inventory i ON f.film_id = i.film_id
    INNER JOIN rental r ON i.inventory_id = r.inventory_id
    INNER JOIN payment p ON r.rental_id = p.rental_id
    WHERE r.return_date IS NOT NULL
    GROUP BY 1
    ORDER BY 1 ASC
),
--CTE to calculate total copies of each film
total_copies AS (
    SELECT f.film_id, COUNT(*) AS total_invent
    FROM film f
    INNER JOIN inventory i ON f.film_id = i.film_id
    GROUP BY 1
),
--CTE to calculate rentals in last 90 days assumming currect_date as 2006-01-01 (As latest data not available)
last_ninety_days AS (
    SELECT f.film_id, COUNT(DISTINCT i.inventory_id) AS active_invent
    FROM film f
    INNER JOIN inventory i ON f.film_id = i.film_id
    INNER JOIN rental r ON i.inventory_id = r.inventory_id
    INNER JOIN payment p ON r.rental_id = p.rental_id
    WHERE r.rental_date > '2006-01-01'::date - 90
    GROUP BY 1
),
--CTE to calculate utilization rate (% of inventory copies rented at least once in last 90 days): active_inventory/total inventory.
Utilization_calculation AS (
    SELECT tc.film_id, 
    lnd.active_invent::numeric/tc.total_invent AS util,
    PERCENT_RANK() OVER (ORDER BY lnd.active_invent::numeric/tc.total_invent) AS util_rank
    FROM total_copies tc
    INNER JOIN last_ninety_days lnd ON tc.film_id = lnd.film_id
    ORDER BY 1 ASC
),
--CTE to calculate store wise film rentals. Using inner join to account only for films that are rented and returned.
--Can use left join to account for films that are not rented.
store_wise_analysis AS (
    SELECT f.film_id, 
        COUNT(CASE WHEN i.store_id =1 THEN 1 END) AS store1_rental,
        COUNT(CASE WHEN i.store_id =2 THEN 1 END) AS store2_rental
    FROM film f
    INNER JOIN inventory i ON f.film_id = i.film_id
    INNER JOIN rental r ON i.inventory_id = r.inventory_id
    INNER JOIN payment p ON r.rental_id = p.rental_id
    WHERE r.return_date IS NOT NULL
    GROUP BY 1
    ORDER BY f.film_id ASC
)
--Main aggregator query.
SELECT fm.film_id,fm.title, cat.name,
    fm.total_rentals,
    fm.total_revenue,
    ROUND(fm.rev_rank::numeric,2) AS rev_rank,
    fard.allowed_rental_duration,
    fard.actual_average_duration,
    ROUND(rf.rental_frequency_2005::numeric,2) AS rental_frequency_2005,
    ROUND(rf.rf_rank::numeric,2) AS rf_rank,
    ROUND(uc.util * 100,2) AS inventory_utilisation_rate,
    ROUND(uc.util_rank::numeric,2) AS util_rank,
    swa.store1_rental,
    swa.store2_rental,
    (swa.store1_rental - swa.store2_rental) AS disparity,
    CASE
        WHEN rev_rank > 0.8 AND rf_rank > 0.8
            THEN 'Blockbusters'
        WHEN rev_rank < 0.3 AND rf_rank < 0.3
            THEN 'Underperformers'
        WHEN uc.util > 80 AND fard.actual_average_duration > fard.allowed_rental_duration
            THEN 'Efficient Classics'
        WHEN util < 30 AND fm.total_rentals < (SELECT AVG(total_rentals) FROM film_metrics) --SQ to calculate average rentals per film and compare it to total rentals.
            THEN 'Slow-Movers'
        ELSE 'Balanced Performers'
        END AS performance_category
FROM film_metrics fm
INNER JOIN filmwise_avg_rental_duration fard ON fm.film_id = fard.film_id
INNER JOIN rental_frequency rf ON fard.film_id = rf.film_id
LEFT JOIN utilization_calculation  uc ON rf.film_id = uc.film_id
INNER JOIN film_category fc ON fm.film_id = fc.film_id
INNER JOIN category cat ON fc.category_id = cat.category_id
INNER JOIN store_wise_analysis swa ON fm.film_id = swa.film_id;