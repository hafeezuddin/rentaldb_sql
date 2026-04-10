/* Finding categories which are more profitable */
--Only paid rentals and 2005 data is considered for analysis

/* checks if each film belongs to exactly one category to avoid cartesian product */
-- SELECT fc.film_id, COUNT(fc.film_id)
-- FROM film_category fc
-- GROUP BY fc.film_id
-- HAVING COUNT(fc.film_id) > 1

--Pre Processing CTE to consolidated payments with same rental_id,
WITH consolidate_rental_payments AS (SELECT r.rental_id, SUM(p.amount) total_rental
                                     FROM rental r
                                              JOIN payment p ON r.rental_id = p.rental_id
                                     GROUP BY r.rental_id),
--base_rental cte
     base_rental AS (SELECT r.rental_id, r.inventory_id, f.film_id, ct.name, crp.total_rental
                     FROM rental r
                              JOIN inventory i ON r.inventory_id = i.inventory_id
                              JOIN film f ON i.film_id = f.film_id
                              JOIN consolidate_rental_payments crp ON r.rental_id = crp.rental_id
                              JOIN film_category fc ON f.film_id = fc.film_id
                              JOIN category ct ON fc.category_id = ct.category_id
                     WHERE r.rental_date BETWEEN '2005-01-01' AND '2005-12-31')
--Main query to aggregate metric
SELECT br.name,
       COUNT(br.rental_id)                                                          AS total_rentals,
       SUM(br.total_rental)                                                         AS total_revenue,
       ROUND(COALESCE(SUM(br.total_rental), 0) / NULLIF(COUNT(br.rental_id), 0), 2) AS average_revenue_per_rental
FROM base_rental br
GROUP BY br.name
ORDER BY ROUND(COALESCE(SUM(br.total_rental), 0) / NULLIF(COUNT(br.rental_id), 0), 2) DESC;