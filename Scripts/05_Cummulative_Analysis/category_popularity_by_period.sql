/* Category popularity by year/month (top category per period) */
WITH pop_cat_rank AS (
SELECT
  TO_CHAR(r.rental_date, 'YYYY') AS year,
  TO_CHAR(r.rental_date, 'MM') AS month,
  c.name AS category,
  COUNT(*) AS rental_count,
  DENSE_RANK() OVER (PARTITION BY TO_CHAR(r.rental_date, 'YYYY'), TO_CHAR(r.rental_date, 'MM') ORDER BY COUNT(*) DESC) as ranked_metric
FROM category c
  JOIN film_category fc ON c.category_id = fc.category_id
  JOIN inventory i ON fc.film_id = i.film_id
  JOIN rental r ON i.inventory_id = r.inventory_id
  JOIN payment p ON r.rental_id = p.rental_id
  WHERE r.return_date IS NOT NULL AND (r.rental_date >= '2005-01-01' AND r.rental_date <= '2005-12-31')
GROUP BY 1,2,3
ORDER BY Year, month
)
SELECT * FROM pop_cat_rank pcr
WHERE pcr.ranked_metric =1;
