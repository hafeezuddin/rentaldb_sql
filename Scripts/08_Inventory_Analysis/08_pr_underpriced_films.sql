/* Task: "Identify Underpriced Films"
 Find films where:
    High Rental Demand: Above-average rental frequency
    Low Rental Rate: Priced below the average rental rate for their category
    Available to Rent: Currently in stock. All available rental data from all years. */

WITH base_film_info AS (
    SELECT f.film_id,
           f.rental_rate film_rental_rate,
           ROUND(AVG(f.rental_rate) OVER (),2) avg_rental_rate,
           COUNT(r.rental_id) rentals,
           ROUND(AVG(COUNT(r.rental_id)) OVER (),2) avg_rental_frequency
    FROM film f
    JOIN inventory i ON f.film_id = i.film_id
    JOIN rental r ON i.inventory_id = r.inventory_id
    GROUP BY f.film_id, f.rental_rate
),
available_inventory AS (
    SELECT f.film_id, COUNT(i.inventory_id) available_inventory
    FROM film f
    JOIN inventory i ON f.film_id = i.film_id
    LEFT JOIN rental r ON i.inventory_id = r.inventory_id AND r.return_date IS NULL
    WHERE r.rental_id IS NULL
    GROUP BY f.film_id
)
SELECT bf.film_id, ai.available_inventory
FROM base_film_info bf
JOIN available_inventory ai ON bf.film_id = ai.film_id
WHERE (bf.film_rental_rate > bf.avg_rental_rate) AND (bf.rentals > bf.avg_rental_frequency) AND ai.available_inventory IS NOT NULL
