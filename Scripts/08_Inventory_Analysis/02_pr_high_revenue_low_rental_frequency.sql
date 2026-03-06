/*Identify Films with High Revenue but Low Rental Frequency
 Find films that generate above-average revenue per rental but have below-average rental frequency,
 indicating potentially undervalued content in your catalog
 Considering only paid rentals with all the available data (No cut off date*/

WITH pre_processing_cte AS (SELECT f.film_id,
                                   i.inventory_id,
                                   r.rental_id,
                                   r.rental_date::date
                            FROM film f
                                     JOIN inventory i ON f.film_id = i.film_id
                                     LEFT JOIN rental r ON i.inventory_id = r.inventory_id),
--This cte avoids cartesian product in cases where customer made multiple payments on same rental id.
     --Eg: rental_id 4591 has multiple split payments.
     consolidate_revenue AS (SELECT p.rental_id, SUM(p.amount) AS amt
                             FROM payment p
                             GROUP BY p.rental_id),
     base_rental_cte AS (SELECT ppc.film_id, ppc.inventory_id, ppc.rental_id, ppc.rental_date, cr.amt
                         FROM pre_processing_cte ppc
                                  LEFT JOIN consolidate_revenue cr ON ppc.rental_id = cr.rental_id
                         WHERE cr.amt IS NOT NULL
         --Considering Paid rentals
     ),
--metrics Calculation
     metrics AS (SELECT brc.film_id,
                        SUM(brc.amt)                           film_revenue,
                        COUNT(brc.rental_id)                as total_rentals,
                        SUM(brc.amt) / COUNT(brc.rental_id) as revenue_per_rental
                 FROM base_rental_cte brc
                 group by brc.film_id),
     averages AS (SELECT m.film_id,
                         m.revenue_per_rental,
                         ROUND(AVG(m.revenue_per_rental) OVER (), 2) average_revenue_benchmark,
                         m.total_rentals,
                         ROUND(AVG(m.total_rentals) OVER (), 2)      avg_rentals_bench_mark
                  FROM metrics m)

--Main query to filter films
SELECT a.film_id,
       f.title                        film_name,
       ct.name                        film_category,
       ROUND(a.revenue_per_rental, 2) generated_revenue_per_rental,
       a.average_revenue_benchmark,
       a.total_rentals,
       a.avg_rentals_bench_mark
FROM averages a
         JOIN film f ON a.film_id = f.film_id
         JOIN film_category fc ON f.film_id = fc.film_id
         JOIN category ct ON fc.category_id = ct.category_id
WHERE a.revenue_per_rental > a.average_revenue_benchmark
  AND a.total_rentals < a.avg_rentals_bench_mark
ORDER BY a.revenue_per_rental DESC;



/* Check to see if joining payment table is safe without cartesian product
   Rental id 4591 has multiple records in payment table. Not Safe to join as it will inflate numbers*/
WITH temp as (SELECT *, row_number() over (partition by p.rental_id) rn
               FROM payment p)
SELECT * from temp WHERE rn>1;

SELECT * FROM rental r WHERE r.rental_id = 4591
