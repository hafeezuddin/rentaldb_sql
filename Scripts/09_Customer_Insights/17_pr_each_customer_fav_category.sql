/*Find each customer’s favorite film category based on rental count.
For each customer, show: Customer ID, First Name, Last Name
The film category they rented most frequently
The total number of rentals in that category
Their rank of that category among all categories they’ve rented
If a customer has ties for their most rented category, include all tied categories.*/

--Base CTE for customers and their rentals (Including film category)
--Base CTE includes paid and unpaid rentals.
-- INNER JOIN payment table on customer_id in rental_data CTE to analyze/consider paid rental data

WITH rental_data AS (SELECT c.customer_id,
                            concat(c.first_name, ' ', c.last_name) AS customer_full_name,
                            cat.name                               AS genre
                     FROM customer c
                              INNER JOIN rental r ON c.customer_id = r.customer_id
                              INNER JOIN inventory i ON r.inventory_id = i.inventory_id
                              INNER JOIN film_category fc ON i.film_id = fc.film_id
                              INNER JOIN category cat ON fc.category_id = cat.category_id),
--CTE Counts each customer's rental counts segregated by genre's and rank them based on rental count in DESC order.
     customer_genre_count AS (SELECT rd.customer_id,
                                     rd.customer_full_name,
                                     rd.genre                                                                             AS favorite_genre,
                                     COUNT(rd.customer_id)                                                                AS genre_rentals,
                                     RANK()
                                     over (PARTITION BY rd.customer_id ORDER BY COUNT(rd.customer_id) DESC, rd.genre) AS genre_rank
                              FROM rental_data rd
                              GROUP BY rd.customer_id, rd.customer_full_name, rd.genre)
--Filtering customers most favourite category based on number of rentals using rank from customer_genre_count CTE
SELECT cgc.customer_id, cgc.customer_full_name, cgc.genre_rentals, cgc.favorite_genre
FROM customer_genre_count cgc
WHERE genre_rank = 1
ORDER BY cgc.genre_rentals DESC;