/* Which specific films are hardest to keep in stock across our stores?
Film titles and IDs, Store locations, Total copies per film per store,
   Currently rented copies, Availability percentage
   Rank films by worst availability
Consider all the available data of all years*/

--BASE FILM CTE
WITH base_film_data AS (SELECT f.film_id, f.title, i.store_id, COUNT(DISTINCT i.inventory_id) total_inventory
                        FROM film f
                                 LEFT JOIN inventory i ON f.film_id = i.film_id
                        GROUP BY f.film_id, f.title, i.store_id
                        ORDER BY f.film_id),

     --CTE TO CALCULATE EACH FILM INVENTORY ACROSS EACH STORE
     available_inventory AS (SELECT i.film_id, i.store_id, COUNT(i.inventory_id) available_inventory
                             FROM inventory i
                                      LEFT JOIN rental r ON r.inventory_id = i.inventory_id AND r.return_date IS NULL
                             WHERE r.rental_id IS NULL
                             GROUP BY i.film_id, i.store_id),
     --CTE TO CALCULATE AVAILABILITY PERCENTAGE, RENTED INVENTORY, AVAILABLE INVENTORY, AVAILABILITY RANKING (IN ORDER OF LEAST OF AVAILABLE)
     availability_percentage AS (SELECT bfd.film_id,
                                        bfd.title,
                                        bfd.store_id,
                                        bfd.total_inventory,
                                        COALESCE(ai.available_inventory, 0)                       available_inventory,
                                        bfd.total_inventory - COALESCE(ai.available_inventory, 0) rented_inventory,
                                        ROUND(100 -
                                              ((bfd.total_inventory - COALESCE(ai.available_inventory, 0))::numeric /
                                               NULLIF(bfd.total_inventory, 0)) * 100, 2) as       available_percentage,
                                        dense_rank() OVER (ORDER BY ROUND(100 -
                                                                          ((bfd.total_inventory - COALESCE(ai.available_inventory, 0))::numeric /
                                                                           NULLIF(bfd.total_inventory, 0)) * 100,
                                                                          2) ASC)                 availability_ranking
                                 FROM base_film_data bfd
                                          LEFT JOIN available_inventory ai
                                                    ON bfd.film_id = ai.film_id AND bfd.store_id = ai.store_id)
--Main query to filter films which are least available.
SELECT *
FROM availability_percentage
WHERE availability_ranking <= 3;


-- Planning Time: 0.556 ms
-- Execution Time: 11.854 ms
