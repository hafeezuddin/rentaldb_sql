/*Find each customer’s favorite film category based on rental count.
For each customer, show: Customer ID, First Name, Last Name
The film category they rented most frequently
The total number of rentals in that category
Their rank of that category among all categories they’ve rented
If a customer has ties for their most rented category, include all tied categories.*/

--CTE to calculate rental counts per customer per category
--Considering both paid and unpaid rentals to profile customer.
WITH rental_data AS (
    SELECT c.customer_id,
    c.first_name,
    c.last_name,
    cat.name,
    COUNT(r.rental_id) total_category_rental_count
    FROM customer c
    INNER JOIN rental r ON c.customer_id = r.customer_id
    INNER JOIN inventory i ON r.inventory_id = i.inventory_id
    INNER JOIN film_category fc ON i.film_id = fc.film_id
    INNER JOIN category cat ON fc.category_id = cat.category_id
    GROUP BY 1,2,3,4
    ),
--Rank cte
ranking_rentals AS (
SELECT rd.*, 
rank() OVER (PARTITION BY rd.customer_id ORDER BY rd.total_category_rental_count DESC) AS customer_preference
FROM rental_data rd
)
SELECT * FROM ranking_rentals
WHERE customer_preference <=3;