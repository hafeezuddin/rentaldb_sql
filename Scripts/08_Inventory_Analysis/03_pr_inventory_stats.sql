/* Task: Film Inventory & Availability Analysis */
--CAUTION: Inventory table is considered for base cte not the films table to avoid unnecessary join. This is inventory
    --level analysis not the film level.
--CTE to retrieve total inventory items store_wise.
WITH base_cte AS (SELECT i.store_id, COUNT(i.inventory_id) total_inventory
                  FROM inventory i
                  GROUP BY i.store_id),
--CTE retrieves total rented inventory store wise.
     --This cte accounts for rentals that are currently rented out/Unreturned inventory.
     rented_inventory AS (SELECT i.store_id, COUNT(r.inventory_id) rented_inventory
                          FROM rental r
                                   JOIN inventory i ON r.inventory_id = i.inventory_id
                          WHERE r.return_date IS NULL
                          GROUP BY i.store_id)
--Main query to aggregate and derive metrics
SELECT bc.store_id,
       bc.total_inventory,
       ri.rented_inventory,
       bc.total_inventory - COALESCE(ri.rented_inventory,0) AS available_inventory,
       ROUND((bc.total_inventory - (COALESCE(ri.rented_inventory,0)))::numeric / NULLIF(bc.total_inventory, 0) * 100,
             2)                                 as percentage_available
FROM base_cte bc
         LEFT JOIN rented_inventory ri ON bc.store_id = ri.store_id;
--Safe when there are no outstanding rentals for a store.
