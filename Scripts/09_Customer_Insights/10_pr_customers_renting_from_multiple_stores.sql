/* Customers renting from multiple stores */
SELECT r.customer_id, CONCAT(c.first_name, ' ', c.last_name) AS full_name
FROM rental r
         JOIN staff st ON r.staff_id = st.staff_id
         JOIN customer c ON r.customer_id = c.customer_id
         JOIN store so ON st.store_id = so.store_id
WHERE so.store_id IN (1, 2)
--Filters stores to be filtered. This optional filter can be used to filter from specific stores.
--For this business case 1,2 stores are the only two stores.
GROUP BY r.customer_id, full_name
HAVING COUNT(DISTINCT st.store_id) = 2;
--Filters customers who rented from both stores 1,2