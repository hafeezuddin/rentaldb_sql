/* Create a basic system that suggests films to customers based on their rental history and preferences.
[FOR Customer_id =1]
Customer's Favorite Categories:find which film categories they rent most often
Top Films in Those Categories: Show the most popular films in the customer's favorite categories

Check which of these recommended films are actually in stock
Combine all this into a clean list of 10 film recommendations for customer_id = 1 */

-- CTE to find the top 3 most rented film categories for a specific customer (customer_id = 1)
--Considering all the data available including unpaid rentals and data from all years.

--Tests to avoid cartesian multiplication
SELECT fc.film_id, fc.category_id, COUNT(*)
FROM film_category fc
GROUP BY fc.film_id, fc.category_id
HAVING COUNT(*) > 1
--Test confirms each film has exactly one film category.

PREPARE film_recommendations(INT) AS
WITH base_rental AS (
    -- Foundation CTE: joins all rental activity to film and category data
    -- Used as a single reusable source by all downstream CTEs
    SELECT r.customer_id,
           r.rental_id,
           f.film_id,
           f.title,
           ct.name,
           fc.category_id
    FROM rental r
             JOIN inventory i ON r.inventory_id = i.inventory_id
             JOIN film f ON i.film_id = f.film_id
             JOIN film_category fc ON f.film_id = fc.film_id
             JOIN category ct ON fc.category_id = ct.category_id
),

customer_fav_category AS (
    -- Identifies each customer's top 3 most rented film categories
    -- RANK() with tiebreaker (name ASC) ensures deterministic results
    -- when two categories have equal rental counts
    SELECT t1.customer_id,
           t1.name AS customer_fav_category
    FROM (
        SELECT br.customer_id,
               br.name,
               COUNT(br.rental_id),
               RANK() OVER (
                   PARTITION BY br.customer_id
                   ORDER BY COUNT(br.rental_id) DESC, br.name ASC
               ) AS fav_cat_rank
        FROM base_rental br
        GROUP BY br.customer_id, br.name
    ) t1
    WHERE t1.fav_cat_rank <= 3  -- Top 3 categories for broader recommendation coverage
),

already_rented AS (
    -- Captures all films the target customer has previously rented
    -- Used to exclude already-seen films from recommendations
    SELECT DISTINCT br.film_id
    FROM base_rental br
    WHERE br.customer_id = $1
),

top_films_in_each_category AS (
    -- Finds the 10 most rented films per category across all customers
    -- Excludes films the target customer has already rented
    -- RANK() with tiebreaker (film_id ASC) ensures deterministic results
    -- when two films have equal rental counts within the same category
    SELECT t2.name,
           t2.film_id,
           t2.title
    FROM (
        SELECT br.name,
               br.film_id,
               br.title,
               COUNT(br.rental_id),
               RANK() OVER (
                   PARTITION BY br.name
                   ORDER BY COUNT(br.rental_id) DESC, br.film_id ASC
               ) AS top_film_cat
        FROM base_rental br
        WHERE br.film_id NOT IN (SELECT film_id FROM already_rented)  -- Exclude already-rented films
        GROUP BY br.name, br.film_id, br.title
    ) t2
    WHERE t2.top_film_cat <= 10
),

available_in_stock AS (
    -- Checks current inventory availability for each candidate film
    -- Anti-join pattern: LEFT JOIN + WHERE r.rental_id IS NULL
    -- filters out inventory items with an open rental (return_date IS NULL)
    -- COUNT gives the number of physical copies currently on the shelf
    SELECT tfiec.film_id,
           COUNT(i.inventory_id) AS available_inventory
    FROM top_films_in_each_category tfiec
             JOIN inventory i ON tfiec.film_id = i.film_id
             LEFT JOIN rental r ON i.inventory_id = r.inventory_id AND r.return_date IS NULL
    WHERE r.rental_id IS NULL
    GROUP BY tfiec.film_id
)

-- Final output: top 10 recommended films for the target customer
-- Ordered by available inventory so films most likely to be rentable appear first
SELECT tfiec.title               AS recommended_film,
       cfc.customer_fav_category AS film_category,
       ais.available_inventory
FROM customer_fav_category cfc
         JOIN top_films_in_each_category tfiec ON cfc.customer_fav_category = tfiec.name
         JOIN available_in_stock ais ON tfiec.film_id = ais.film_id
WHERE cfc.customer_id = $1
ORDER BY ais.available_inventory DESC
LIMIT 10;

-- Execute for a specific customer (replace argument to query any customer)
EXECUTE film_recommendations(2);

-- Uncomment to release the prepared statement from memory when done
-- DEALLOCATE film_recommendations;
The comments follow a consistent pattern throughout
