
/* Create a basic system that suggests films to customers based on their rental history and preferences.
[FOR Customer_id =1] 
Customer's Favorite Categories:find which film categories they rent most often
Top Films in Those Categories: Show the most popular films in the customer's favorite categories
Check which of these recommended films are actually in stock
Combine all this into a clean list of 10 film recommendations for customer_id = 1 */

-- CTE to find the top 3 most rented film categories for a specific customer (customer_id = 1)
--Considering all the data available including unpaid rentals and data from all years.
WITH pop_cat AS (
  SELECT 
    c.customer_id, 
    cat.name, 
    cat.category_id, 
    COUNT(r.rental_id) AS rental_count
  FROM customer c
    INNER JOIN rental r ON c.customer_id = r.customer_id
    INNER JOIN inventory i ON r.inventory_id = i.inventory_id
    INNER JOIN film_category fc ON i.film_id = fc.film_id
    INNER JOIN category cat ON fc.category_id = cat.category_id
  GROUP BY 1,2,3
  HAVING c.customer_id = 1 -- Filter for a specific customer
  ORDER BY COUNT(r.rental_id) DESC
  LIMIT 3 -- Limit to their top 3 favorite categories
),
-- CTE to find the most popular films (by rental count) within the customer's favorite categories
top_films_cat AS (
  SELECT 
    f.film_id, 
    f.title, 
    i2.inventory_id, 
    fc2.category_id,
    COUNT(r2.rental_id) AS total_rentals
  FROM film f
    INNER JOIN inventory i2 ON f.film_id = i2.film_id
    INNER JOIN rental r2 ON i2.inventory_id = r2.inventory_id
    INNER JOIN film_category fc2 ON f.film_id = fc2.film_id
  WHERE fc2.category_id IN (SELECT pop_cat.category_id FROM pop_cat) -- Filter for films in the favorite categories
  GROUP BY 1,2,3,4
  ORDER BY total_rentals DESC
),
-- CTE to identify all inventory items that are currently in stock (not rented out)
available_inventory AS (
  SELECT 
    i3.film_id, 
    i3.inventory_id
  FROM inventory i3
  WHERE i3.inventory_id NOT IN (SELECT r3.inventory_id FROM rental r3 WHERE r3.return_date IS NULL) -- Exclude items currently rented
)
-- Main query: Recommend the top 10 available films from the customer's favorite categories
SELECT 
  tfc.film_id, 
  tfc.title, 
  COUNT(*) AS tot_av_inven -- Count how many copies are available in inventory
FROM top_films_cat tfc
  INNER JOIN available_inventory ai ON tfc.inventory_id = ai.inventory_id -- Join with available inventory
GROUP BY 1,2
ORDER BY tot_av_inven DESC -- Order by the number of available copies
LIMIT 10; -- Limit to the top 10 recommendations