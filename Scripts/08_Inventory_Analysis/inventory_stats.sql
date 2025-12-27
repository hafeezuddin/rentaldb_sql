/* Task: Film Inventory & Availability Analysis */
/*Count total films vs available films per store */
--CTE to retrieve total available inventory store_wise.
WITH total_inventory AS (
SELECT s.store_id, count(*) AS total_inventory
FROM store s
INNER JOIN inventory i ON
s.store_id = i.store_id
GROUP BY 1
),
--CTE to retrieve total current rented inventory across both stores store_wise
rented_inventory AS (
  SELECT s.store_id, COUNT(*) AS rent_iv
    FROM store s
    INNER JOIN inventory i ON s.store_id = i.store_id
    INNER JOIN rental r ON i.inventory_id = r.inventory_id
    WHERE r.return_date IS NULL
    GROUP BY 1
),
--CTE for available inventory after accounting for rented inventory
available_inventory AS (
  SELECT ri.store_id, ti.total_inventory, ri.rent_iv,
  ti.total_inventory - ri.rent_iv AS av_inv
  FROM rented_inventory ri
  INNER JOIN total_inventory ti ON ti.store_id = ri.store_id
)
SELECT *,
ROUND(av.rent_iv::decimal/av.total_inventory::decimal*100,3) AS rented_percentage,
100-ROUND(av.rent_iv::decimal/av.total_inventory::decimal*100,3) AS available_inventory_percentage
FROM available_inventory av;