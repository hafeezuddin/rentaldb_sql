/* Task: "Identify Underpriced Films"
 Find films where:
    High Rental Demand: Above-average rental frequency
    Low Rental Rate: Priced below the average rental rate for their category
    Available to Rent: Currently in stock. All available rental data from all years. */


--Condition to check of each film has only one category
-- SELECT f.film_id, COUNT(f.film_id)
-- FROM film f
-- JOIN film_category fc ON f.film_id = fc.film_id
-- GROUP BY f.film_id
-- HAVING COUNT(f.film_id)>1;
--Above code confirms each film as exactly one category it is safe to Join (No Cartesian Product).


WITH base_film_info AS (SELECT f.film_id,
                               f.title,
                               ct.category_id,
                               ROUND(AVG(f.rental_rate) OVER (partition by ct.category_id), 2)      category_rental_rate_avg,
                               f.rental_rate                                                        film_rental_rate,
                               ROUND(AVG(COUNT(r.rental_id)) OVER (PARTITION BY ct.category_id),
                                     2)                                                             category_rentals_avg,
                               COUNT(r.rental_id)                                                   rentals
                        FROM film f
                                 JOIN inventory i ON f.film_id = i.film_id
                                 JOIN rental r ON i.inventory_id = r.inventory_id
                                 JOIN film_category ct ON f.film_id = ct.film_id
                        GROUP BY f.film_id, f.rental_rate, ct.category_id),
     available_inventory AS (SELECT f.film_id, COUNT(i.inventory_id) available_inventory
                             FROM film f
                                      JOIN inventory i ON f.film_id = i.film_id
                                      LEFT JOIN rental r ON i.inventory_id = r.inventory_id AND r.return_date IS NULL
                             WHERE r.rental_id IS NULL
                             GROUP BY f.film_id)
SELECT bf.film_id, bf.title, ai.available_inventory
FROM base_film_info bf
         JOIN available_inventory ai ON bf.film_id = ai.film_id
WHERE (bf.film_rental_rate < bf.category_rental_rate_avg)
  AND (bf.rentals > bf.category_rentals_avg)

-- Planning Time: 1.055 ms
-- Execution Time: 24.735 ms
