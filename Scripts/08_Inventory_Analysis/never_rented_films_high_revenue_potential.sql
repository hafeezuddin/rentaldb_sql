
/* Task: Identify Never-Rented Films with High Revenue Potential. 
 Find films that meet all of these criteria: 

 Zero Rentals: Never been rented
 High Value: Rental rate above the average for their category 
 In Stock: Currently available in inventory. */

--CTE to find films that have never been rented
WITH film_with_no_rentals AS (
  SELECT f.film_id, i.inventory_id, f.title
  FROM film f
INNER JOIN inventory i ON f.film_id = i.film_id
LEFT JOIN rental r ON i.inventory_id = r.inventory_id
WHERE r.rental_id IS NULL
ORDER BY f.film_id
),
--CTE to find high value rentals
abv_avg_rental_rate AS (
  SELECT f.film_id, f.title, f.rental_rate
  FROM film f
  WHERE rental_rate > (
      SELECT AVG(rental_price)
      FROM (
          SELECT f.film_id, f.rental_rate AS rental_price
          FROM film f
        ) t
    )
  ORDER BY f.film_id
),
--CTE to get Current Inventory
available_in_inventory AS (
SELECT DISTINCT f.film_id
  FROM film f --Replace with * for detailed idea
    INNER JOIN inventory i ON f.film_id = i.film_id
    LEFT JOIN rental r ON i.inventory_id = r.inventory_id AND return_date IS NULL
    /* --You join to the rental table only if the inventory item is currently rented and NOT returned (return_date IS NULL).
     Because it’s a LEFT JOIN, even if there’s no active rental, the row will still appear — but with r.rental_id as NULL. */
  WHERE r.rental_id IS NULL
  ORDER BY f.film_id
)
--Main query
SELECT fwnr.film_id, fwnr.title
FROM film_with_no_rentals fwnr
INNER JOIN abv_avg_rental_rate aarr ON fwnr.film_id = aarr.film_id
INNER JOIN available_in_inventory aii ON aarr.film_id = aii.film_id;