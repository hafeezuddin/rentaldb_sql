/*
================================================================================
PROBLEM STATEMENT: DVD Rental Inventory Optimization
DATABASE: Sakila (PostgreSQL)
BUSINESS OWNER: Operations Team
GOAL: Reduce inventory holding costs while maintaining rental availability
================================================================================

CONTEXT & SCOPE
---------------
- Data spans          : May 2005 – August 2006 (16-month Sakila dataset)
- Revenue definition  : SUM(payment.amount) traced via
                        payment → rental → inventory → film
- Copies definition   : COUNT(DISTINCT inventory_id) per film (physically owned)
- Replacement cost    : film.replacement_cost (cost to restock one copy)
- Active rentals      : return_date IS NULL (copy currently checked out)
- Completed rentals   : return_date IS NOT NULL (copy has been returned)

================================================================================
METRIC DEFINITIONS
================================================================================

Metric 1: Film Profitability
-----------------------------
  total_revenue           = COALESCE(SUM(payment.amount), 0)
  revenue_per_copy        = total_revenue / COUNT(DISTINCT inventory_id)
  cost_recovery_multiple  = total_revenue / (replacement_cost * copy_count)
  rentals_per_copy_month  = COUNT(DISTINCT rental_id) / copy_count / 16

Metric 2: Demand & Seasonality
--------------------------------
  peak_month_pct    = MAX(rentals in any single month) / SUM(all rentals) * 100
                      -- signals seasonal demand concentration
                      -- computed on completed rentals (return_date IS NOT NULL)
  avg_rental_days   = AVG(return_date::date - rental_date::date)
                      -- how long a copy stays checked out per rental
                      -- computed on completed rentals only

================================================================================
PERCENTILE THRESHOLDS
(computed as window functions over all films in film_metrics CTE)
================================================================================

  p25_revenue_per_copy      → lower bound for low performers
  p50_revenue_per_copy      → baseline revenue threshold
  p60_revenue_per_copy      → above-average revenue threshold
  p75_revenue_per_copy      → top performer revenue threshold
  p75_replacement_cost      → high cost threshold

================================================================================
TIER CLASSIFICATION
(mutually exclusive, evaluated in priority order 1 → 5)
================================================================================

  Tier 1 | "Workhorses"      | HIGH utilization + HIGH ROI
  --------|-------------------|------------------------------------------
  Criteria:  revenue_per_copy    > p75
             cost_recovery       > 3.0
             rentals_per_month   > 2.0
  Action:    Maintain copies, monitor for wear
  Priority:  1st — best performers, claim before all others

  Tier 2 | "Sleepers"        | LOW utilization but PROFITABLE when rented
  --------|-------------------|------------------------------------------
  Criteria:  revenue_per_copy    > p60   ← stricter than Tier 3, evaluated first
             cost_recovery       > 2.0
             rentals_per_month   < 1.5
  Action:    Keep copies, flag for promotional pricing
  Priority:  2nd — stricter revenue bar than Tier 3, must precede it

  Tier 3 | "Opportunities"   | HIGH seasonal demand, UNDERSUPPLIED
  --------|-------------------|------------------------------------------
  Criteria:  peak_month_pct      > 30%  (demand spikes in one month)
             revenue_per_copy    > p50  ← looser than Tier 2
             copy_count          < 3
  Action:    Add 2 copies ahead of peak season
  Priority:  3rd — looser revenue bar, evaluated after Tier 2

  Tier 4 | "Cost Centers"    | EXPENSIVE inventory, LOW return
  --------|-------------------|------------------------------------------
  Criteria:  replacement_cost    > p75
             cost_recovery       < 1.5
             rentals_per_month   < 1.0
  Action:    Reduce to 1 copy, do not reorder
  Priority:  4th — expensive films earning below replacement cost

  Tier 5 | "Underperformers" | LOW cost, LOW usage, LOW return
  --------|-------------------|------------------------------------------
  Criteria:  catch-all for remaining films not meeting any tier above
             revenue_per_copy    < p25
             cost_recovery       < 1.0
             rentals_per_month   < 0.5
  Action:    Remove excess copies, retain 1 minimum
  Priority:  5th — last resort classification

================================================================================
COPY COUNT RECOMMENDATION LOGIC
================================================================================

  Tier 1  →  recommended_copy_change =  0   (maintain)
  Tier 2  →  recommended_copy_change =  0   (maintain, promote)
  Tier 3  →  recommended_copy_change = +2   (expand supply)
  Tier 4  →  recommended_copy_change =  -(copy_count - 1)  (reduce to 1)
  Tier 5  →  recommended_copy_change =  -(copy_count - 1)  (reduce to 1)

================================================================================
FINANCIAL IMPACT COLUMNS
================================================================================

  recommended_copy_count  = copy_count + recommended_copy_change
  copies_removed          = ABS(recommended_copy_change) when change < 0
  cost_savings            = copies_removed * replacement_cost
  revenue_at_risk         = copies_removed * revenue_per_copy

================================================================================
REQUIRED OUTPUT (one row per film)
================================================================================

  film_id, title, category
  copy_count, total_revenue, revenue_per_copy
  cost_recovery_multiple, rentals_per_copy_month
  peak_month_pct, avg_rental_days
  tier_number, tier_label
  recommended_copy_change, recommended_copy_count
  cost_savings, revenue_at_risk

================================================================================
CTE BUILD ORDER
================================================================================

  1. payment_agg          GROUP payments by rental_id
  2. base_rental          film → inventory → rental → payment (LEFT JOINs)
  3. film_revenue         profitability metrics per film
  4. avg_rental_duration  AVG days checked out (completed rentals only)
  5. peak_month_pct       seasonal concentration per film
  6. film_metrics         consolidate CTEs 3 + 4 + 5 into one row per film
  7. percentiles          compute p25/p50/p60/p75 thresholds from film_metrics
  8. film_tiers           apply CASE WHEN tier logic in priority order
  9. final_output         add recommendations + financial impact columns

================================================================================
*/
WITH payment_agg AS (SELECT p.rental_id, SUM(p.amount) rental_amount
                     FROM payment p
                     GROUP BY p.rental_id),
     base_rental AS (SELECT f.film_id,
                            f.title,
                            ct.name,
                            f.replacement_cost,
                            r.rental_date,
                            r.return_date,
                            i.inventory_id,
                            r.rental_id,
                            pa.rental_amount
                     FROM film f
                              LEFT JOIN inventory i ON f.film_id = i.film_id
                              LEFT JOIN rental r ON i.inventory_id = r.inventory_id
                              LEFT JOIN payment_agg pa ON r.rental_id = pa.rental_id
                              LEFT JOIN film_category fc ON f.film_id = fc.film_id
                              LEFT JOIN category ct ON fc.category_id = ct.category_id),
     film_revenue AS (SELECT br.film_id,
                             br.title,
                             br.name,
                             MAX(br.replacement_cost)                   replacementcost,
                             COUNT(DISTINCT br.rental_id)               total_rentals,
                             COUNT(DISTINCT br.inventory_id)            total_inventory,
                             COALESCE(SUM(br.rental_amount), 0)         total_revenue,
                             COALESCE(SUM(br.rental_amount), 0) /
                             NULLIF(COUNT(DISTINCT br.inventory_id), 0) revenue_per_copy,
                             COALESCE(SUM(br.rental_amount), 0) /
                             NULLIF(MAX(br.replacement_cost) * COUNT(DISTINCT br.inventory_id),
                                    0)                                  cost_recovery_multiple,
                             COUNT(DISTINCT br.rental_id)::numeric / NULLIF(COUNT(DISTINCT br.inventory_id), 0) /
                             16                                         rentals_per_month
                      FROM base_rental br
                      GROUP BY br.film_id, br.title, br.name),
     avg_rental_duration AS (SELECT br.film_id,
                                    AVG(br.return_date::date - br.rental_date::date) avg_rental_duration
                             FROM base_rental br
                             WHERE br.return_date IS NOT NULL
                             GROUP BY br.film_id),
     peak_month_pct AS (SELECT t1.film_id,
                               (MAX(total_monthly_rentals)::numeric / NULLIF(SUM(t1.total_monthly_rentals), 0)) *
                               100 peak_month_pct
                        FROM (SELECT br.film_id,
                                     to_char(br.rental_date, 'yyyy-mm') rental_month_year,
                                     COUNT(distinct br.rental_id)       total_monthly_rentals
                              FROM base_rental br
                              WHERE br.rental_date IS NOT NULL
                              GROUP BY br.film_id, to_char(br.rental_date, 'yyyy-mm')) t1
                        GROUP BY t1.film_id),
     -- percent_rank() computed once, referenced as plain columns in film_tiers
     metrics_agg AS (SELECT fr.film_id,
                            fr.title,
                            fr.name,
                            fr.replacementcost,
                            fr.total_rentals,
                            fr.total_inventory,
                            fr.total_revenue,
                            fr.revenue_per_copy,
                            fr.cost_recovery_multiple,
                            fr.rentals_per_month,
                            ard.avg_rental_duration,
                            pmp.peak_month_pct,
                            percent_rank() OVER (ORDER BY fr.revenue_per_copy) rev_per_copy_rank,
                            percent_rank() OVER (ORDER BY fr.replacementcost)  replacementcost_rank
                     FROM film_revenue fr
                              LEFT JOIN avg_rental_duration ard ON fr.film_id = ard.film_id
                              LEFT JOIN peak_month_pct pmp ON fr.film_id = pmp.film_id),
     film_tiers AS (SELECT ma.*,
                           CASE
                               WHEN ma.rev_per_copy_rank    > 0.75
                                AND ma.cost_recovery_multiple > 3
                                AND ma.rentals_per_month    > 2                THEN 'Tier_1'
                               WHEN ma.rev_per_copy_rank    > 0.60
                                AND ma.cost_recovery_multiple > 2
                                AND ma.rentals_per_month    < 1.5              THEN 'Tier_2'
                               WHEN ma.peak_month_pct       > 30
                                AND ma.rev_per_copy_rank    > 0.50
                                AND ma.total_inventory      < 3                THEN 'Tier_3'
                               WHEN ma.replacementcost_rank > 0.75
                                AND ma.cost_recovery_multiple < 1.5
                                AND ma.rentals_per_month    < 1                THEN 'Tier_4'
                               ELSE                                                 'Tier_5'
                               END AS category
                    FROM metrics_agg ma)
SELECT ma.film_id,
       ma.title,
       ma.name,
       ma.total_inventory,
       ma.total_revenue,
       ROUND(ma.revenue_per_copy, 2)       revenue_per_copy,
       ROUND(ma.cost_recovery_multiple, 2) cost_recovery_multiple,
       ROUND(ma.rentals_per_month, 2)      rentals_per_month,
       ROUND(ma.peak_month_pct, 2)         peak_month_pct,
       ROUND(ma.avg_rental_duration, 2)    avg_rental_duration,
       ma.category,
       CASE
           WHEN ma.category = 'Tier_1' THEN 'Maintain copies, monitor for wear'
           WHEN ma.category = 'Tier_2' THEN 'Keep copies, flag for promotional pricing'
           WHEN ma.category = 'Tier_3' THEN 'Add 2 copies ahead of peak season'
           WHEN ma.category = 'Tier_4' THEN 'Reduce to 1 copy, do not reorder'
           WHEN ma.category = 'Tier_5' THEN 'Remove excess copies, retain 1 minimum'
           END AS                          action,
       -- financial impact
       CASE
           WHEN ma.category = 'Tier_3'              THEN 2
           WHEN ma.category IN ('Tier_4', 'Tier_5') THEN -(ma.total_inventory - 1)
           ELSE                                           0
           END                                      AS recommended_copy_change,
       ma.total_inventory +
       CASE
           WHEN ma.category = 'Tier_3'              THEN 2
           WHEN ma.category IN ('Tier_4', 'Tier_5') THEN -(ma.total_inventory - 1)
           ELSE                                           0
           END                                      AS recommended_copy_count,
       CASE
           WHEN ma.category IN ('Tier_4', 'Tier_5')
               THEN ROUND(GREATEST(ma.total_inventory - 1, 0) * ma.replacementcost, 2)
           ELSE 0
           END                                      AS cost_savings,
       CASE
           WHEN ma.category IN ('Tier_4', 'Tier_5')
               THEN ROUND(GREATEST(ma.total_inventory - 1, 0) * ma.revenue_per_copy, 2)
           ELSE 0
           END                                      AS revenue_at_risk
FROM film_tiers ma
ORDER BY ma.film_id;


