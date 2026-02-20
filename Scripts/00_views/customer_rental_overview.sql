CREATE OR REPLACE VIEW customer_rental_overview AS
(
SELECT c.customer_id, c.first_name, c.last_name,
       r.rental_id,
       p.amount
FROM customer c
    LEFT JOIN rental r ON c.customer_id = r.customer_id
    LEFT JOIN payment p ON r.rental_id = p.rental_id
    );