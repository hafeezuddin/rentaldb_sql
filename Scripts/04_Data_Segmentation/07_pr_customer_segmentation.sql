/*Business Requirement: Customer Segmentation Analysis
Objective: Create a comprehensive customer segmentation analysis that classifies
customers into tiers based on their rental behavior, spending patterns, and engagement levels.

Requirements:
Platinum: Top 10% spending AND top 50% rental frequency → (spent_rank >= 0.9 AND frequency_rank >= 0.5)
Gold: Top 10% spending OR top 50% rental frequency but not both → ((spent_rank >= 0.9 OR frequency_rank >= 0.5) AND NOT (spent_rank >= 0.9 AND frequency_rank >= 0.5))
Silver: Middle 40–60% in both spending and frequency → (spent_rank BETWEEN 0.40 AND 0.60 AND frequency_rank BETWEEN 0.40 AND 0.60)
Bronze: Bottom 10% spending AND bottom 50% frequency → (spent_rank <= 0.10 AND frequency_rank <= 0.50)

    For each segment, calculate:
        Number of customers, Average total spending, Average rental frequency,
        Average days between rentals (engagement frequency),Percentage of late returns,
        Identify which segments have the highest customer retention (customers who rented in the last 30 days),
        Show the revenue contribution percentage of each segment, Most popular category in that segment.

  Expected Output Columns:
    customer_segment, customer_count, avg_total_spent, avg_rental_count, late_return_rate,
    avg_days_between_rentals, top_category,active_customer_percentage
    segment_revenue_share,  */
--Considering only paid rentals for all the metrics calculations.

--base_rental cte
WITH base_rental AS (SELECT r.customer_id,
                            r.rental_id,
                            r.rental_date::date,
                            r.return_date::date,
                            f.rental_duration,
                            ct.name,
                            LEAD(r.rental_date::date)
                            OVER (PARTITION BY r.customer_id ORDER BY r.rental_date::date) AS next_rental_date,
                            LEAD(r.rental_date::date) OVER (PARTITION BY r.customer_id ORDER BY r.rental_date::date) -
                            r.rental_date::date                                            AS gap_between_rentals,
                            CASE
                                WHEN r.return_date::date - r.rental_date::date <= f.rental_duration THEN 'In-time'
                                ELSE 'Late-Return'
                                End                                                        AS late_returns_flag,
                            p.amount
                     FROM rental r
                              JOIN payment p ON r.rental_id = p.rental_id
                         --Inner join is being used to only retain paid rentals as per the business requirement.
--Replace Inner join with LEFT Join to retain unpaid rentals as well if business requirement changes.
                              JOIN inventory i ON r.inventory_id = i.inventory_id
                              JOIN film f ON i.film_id = f.film_id
                              JOIN film_category fc ON f.film_id = fc.film_id
                         --This is based on each film belongs to exactly one category.
-- In cases where schema shows each film has multiple categories it cannot be joined here to avoid cartesian product and inflated totals.
--In cases where film column has two or more columns,
                         -- primary category has to be assigned first to the film and then Joined to calculate metrics.
                         --This approach would not inflate totals.
                              JOIN category ct ON fc.category_id = ct.category_id
                     WHERE r.rental_date BETWEEN '2005-01-01' AND '2005-12-31'),
--customer_fav_cat cte.
     customer_fav_cat AS (SELECT t1.customer_id, t1.name
                          FROM (SELECT br.customer_id,
                                       br.name,
                                       COUNT(*),
                                       row_number()
                                       OVER (PARTITION BY br.customer_id ORDER BY COUNT(*) DESC, br.name ASC) AS cat_rank
                                FROM base_rental br
                                GROUP BY br.customer_id, br.name) t1
                          WHERE t1.cat_rank = 1),
--CTE to calculate core metrics in single scan/pass to base_rental_cte
     core_metrics AS (SELECT br.customer_id,
                             cfc.name,
                             COUNT(DISTINCT br.rental_id)                                     AS total_rentals,
                             SUM(br.amount)                                                   AS total_spent,
                             COALESCE(COUNT(DISTINCT br.rental_id), 0) /
                             NULLIF((MAX(br.rental_date) - MIN(br.rental_date)) / 30.0, 0)    AS rental_frequency,
                             ROUND(AVG(gap_between_rentals), 2)                               AS average_rental_gap,
                             ROUND((coalesce(count(CASE WHEN late_returns_flag = 'Late-Return' THEN 1 ELSE NULL END),
                                             0)::numeric / NULLIF(COUNT(*), 0)) * 100, 2)     AS late_return_percentage,
                             CASE
                                 WHEN '2006-01-01' - MAX(br.return_date::date) <= 30 THEN 'active'
                                 --This 2026 & Assuming analysis is being made on 01-01-2006 on 2005 data.
                                 ELSE 'Inactive'
                                 END                                                          AS status,
                             ROUND(percent_rank() OVER (ORDER BY SUM(br.amount))::numeric, 2) AS spent_rank,
                             ROUND(percent_rank() OVER (ORDER BY COUNT(DISTINCT br.rental_id)::numeric /
                                                                 NULLIF((MAX(rental_date) - MIN(rental_date)) / 30.0, 0))::numeric,
                                   2)                                                         AS frequency_rank
                      FROM base_rental br
                               JOIN customer_fav_cat cfc ON br.customer_id = cfc.customer_id
                      GROUP BY br.customer_id, cfc.name),
--CTE to categorize customers in Platinum, gold, silver and bronze.
     customer_categorization AS (SELECT cm.customer_id,
                                        cm.name,
                                        cm.total_spent,
                                        cm.rental_frequency,
                                        cm.average_rental_gap,
                                        cm.late_return_percentage,
                                        cm.status,
                                        cm.spent_rank,
                                        cm.frequency_rank,
                                        cm.total_rentals,
                                        CASE
                                            WHEN (cm.spent_rank >= 0.90 AND cm.frequency_rank >= 0.50) THEN 'Platinum'
                                            WHEN ((cm.spent_rank >= 0.90 OR cm.frequency_rank >= 0.50) AND
                                                  NOT (cm.spent_rank >= 0.90 AND cm.frequency_rank >= 0.50)) THEN 'Gold'
                                            WHEN (cm.spent_rank BETWEEN 0.40 AND 0.60) AND
                                                 (cm.frequency_rank BETWEEN 0.40 AND 0.60) THEN 'Silver'
                                            WHEN (cm.spent_rank <= 0.10 AND cm.frequency_rank <= 0.50) THEN 'Bronze'
                                            ELSE 'Standard'
                                            END AS categorization
                                 FROM core_metrics cm),
--CTE to retrieve category fav category
     cat_fav AS (SELECT t2.categorization, t2.name
                 FROM (SELECT cc.categorization,
                              cc.name,
                              row_number()
                              over (PARTITION BY cc.categorization order by SUM(cc.total_rentals) DESC, cc.name asc) categorization_rank
                       --Handles edge case where SUM(cc.total_rentals) ensures the category is truly the most rented, not just the one with the most customers
                       FROM customer_categorization cc
                       GROUP BY cc.categorization, cc.name) t2
                 WHERE t2.categorization_rank = 1)
--Main query and category level aggregated metrics
SELECT cc.categorization                                                          customer_segment,
       cf.name                                                                    fav_category,
       COUNT(cc.customer_id) AS                                                   customer_count,
       SUM(cc.total_spent)                                                        total_revenue,
       round(AVG(cc.total_spent)::numeric, 2)                                     avg_total_spent,
       ROUND(AVG(cc.total_rentals)::numeric, 2)                                   avg_rental_count,
       ROUND(AVG(CC.late_return_percentage)::numeric, 2)                          avg_late_returns_percentage,
       ROUND(AVG(cc.rental_frequency)::numeric, 2)                                average_rental_frequency,
       ROUND(AVG(cc.average_rental_gap)::numeric, 2)                              average_gap_between_rentals,
       ROUND((SUM(COALESCE((CASE WHEN cc.status = 'active' THEN 1 ELSE NULL END), 0))::numeric /
              NULLIF(COUNT(cc.customer_id), 0) * 100), 2)                         active_customers_per,
       ROUND((sum(cc.total_spent) / (sum(sum(cc.total_spent)) OVER ())) * 100, 2) revenue_share
FROM customer_categorization cc
         JOIN cat_fav cf ON cc.categorization = cf.categorization
GROUP BY cc.categorization, cf.name;

-- [
--   {
--     "QUERY PLAN": "Planning Time: 6.026 ms"
--   },
--   {
--     "QUERY PLAN": "Execution Time: 119.324 ms"
--   }
-- ]