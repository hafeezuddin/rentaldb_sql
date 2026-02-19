/* Category popularity by year/month (top category per period) */
With rental_metrics AS (SELECT to_char(date_trunc('Month', r.rental_date), 'YYYY-MM') period,
                               ct.name                                                category_name,
                               COUNT(*)                                               rentals,
                               row_number()
                               OVER (PARTITION BY to_char(date_trunc('Month', r.rental_date), 'YYYY-MM')
                                   ORDER BY COUNT(*) DESC, ct.name ASC)               category_rank
                        FROM rental r
                                 JOIN public.inventory i on r.inventory_id = i.inventory_id
                                 JOIN public.film f on i.film_id = f.film_id
                                 JOIN film_category fc ON f.film_id = fc.film_id
                                 JOIN category ct ON fc.category_id = ct.category_id
                        GROUP BY to_char(date_trunc('Month', r.rental_date), 'YYYY-MM'), ct.name)
SELECT rm.period, rm.category_name, rm.rentals
FROM rental_metrics rm
WHERE rm.category_rank = 1;