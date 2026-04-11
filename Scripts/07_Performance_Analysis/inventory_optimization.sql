/*
================================================================================
PROBLEM STATEMENT: DVD Rental Inventory Optimization
DATABASE: Sakila (MySQL sample database)
BUSINESS OWNER: Operations Team
GOAL: Reduce inventory holding costs while maintaining rental availability
================================================================================

CONTEXT & SCOPE
---------------
- Data spans: May 2005 – August 2006 (Sakila dataset range)
- "Active period" for monthly averages: 16 months (May 2005 – Aug 2006)
- Revenue = SUM(payment.amount) traced via: payment → rental → inventory → film
- Copies = COUNT(inventory_id) per film (total physical copies owned)
- Available copies = copies not currently linked to an open rental
  (rental.return_date IS NULL means copy is checked out)
- Replacement cost = film.replacement_cost per film record

================================================================================
METRIC DEFINITIONS
================================================================================

Metric 1: Film Profitability Score
-----------------------------------
  revenue_per_copy        = SUM(payment.amount) / COUNT(DISTINCT inventory_id)
  cost_recovery_multiple  = SUM(payment.amount) / SUM(film.replacement_cost per copy)
                          = total_revenue / (copy_count * replacement_cost)
  rentals_per_copy_month  = COUNT(rental_id) / copy_count / 16  -- 16-month window

Metric 2: Demand & Seasonality
--------------------------------
  peak_month_pct    = MAX(rentals in any single month) / SUM(all rentals)
                      -- signals seasonal concentration
  avg_rental_days   = AVG(DATEDIFF(rental.return_date, rental.rental_date))
                      -- films with long rental duration = fewer turnarounds


================================================================================
TIER CLASSIFICATION (mutually exclusive, priority order 1 → 5)
================================================================================

Tier 1 "Workhorses"   — Assign FIRST (highest priority)
  revenue_per_copy    > p75 of all films
  cost_recovery       > 3.0
  rentals_per_copy_mo > 2.0
  Action: Maintain copies, flag for wear-and-tear review

Tier 3 "Opportunities" — Assign SECOND (catch high-demand before Tier 2)
  peak_month_pct      > 0.30  (>30% of rentals in one month)
  revenue_per_copy    > p50 of all films
  copy_count          < 3
  Action: Add 2 copies

Tier 2 "Sleepers"     — Assign THIRD
  revenue_per_copy    > p60 of all films
  cost_recovery       > 2.0
  rentals_per_copy_mo < 1.5
  Action: Keep copies, flag for promotional pricing

Tier 4 "Cost Centers" — Assign FOURTH
  replacement_cost    > p75 of all films
  cost_recovery       < 1.5
  rentals_per_copy_mo < 1.0
  Action: Reduce to 1 copy, do not reorder

Tier 5 "Underperformers" — Assign LAST (catch-all for remaining poor performers)
  revenue_per_copy    < p25 of all films
  cost_recovery       < 1.0
  rentals_per_copy_mo < 0.5
  Action: Remove excess copies, keep 1 minimum

================================================================================
REQUIRED OUTPUT COLUMNS (one row per film)
================================================================================

  film_id
  title
  category
  copy_count                  -- current inventory
  total_revenue
  revenue_per_copy
  cost_recovery_multiple
  rentals_per_copy_month
  peak_month_pct
  tier_number                 -- 1–5
  tier_label                  -- "Workhorses", "Sleepers", etc.
  recommended_copy_change     -- e.g. +2, 0, -3
  recommended_copy_count      -- copy_count + recommended_copy_change
  revenue_at_risk             -- revenue_per_copy * copies_removed (for reductions)
  cost_savings                -- copies_removed * replacement_cost (for reductions)

================================================================================
CTE ARCHITECTURE (suggested build order)
================================================================================

  1. film_revenue      -- JOIN payment→rental→inventory→film, agg by film_id
  2. film_inventory    -- COUNT(inventory_id) per film_id from inventory table
  3. monthly_rentals   -- rentals per film per month (for peak_month_pct)
  4. film_metrics      -- combine CTEs 1-3, compute all metric columns
  5. percentiles       -- PERCENTILE_CONT or subquery to compute p25/p50/p60/p75
  6. film_tiers        -- apply CASE WHEN logic in priority order using CASE...END
  7. final_output      -- add recommendations + financial impact columns

================================================================================
*/

--pre-processing to consolidate payments and rental information
WITH payment_agg AS (
    SELECT p.rental_id, SUM(p.amount) rental_amount
    FROM payment p
    GROUP BY p.rental_id
),
base_rental AS (
    SELECT f.film_id, f.replacement_cost, r.rental_date, r.return_date, i.inventory_id, r.rental_id, pa.rental_amount
    FROM film f
    LEFT JOIN inventory i ON f.film_id = i.film_id
    LEFT JOIN rental r ON i.inventory_id = r.inventory_id
    LEFT JOIN payment_agg pa ON r.rental_id = pa.rental_id
    WHERE r.return_date IS NOT NULL
),
film_revenue AS (
    SELECT br.film_id, COUNT(DISTINCT br.rental_id) total_rentals,
           COUNT(DISTINCT br.inventory_id) total_inventory,
           COALESCE(SUM(br.rental_amount),0) total_revenue,
           COALESCE(SUM(br.rental_amount),0)/NULLIF(COUNT(DISTINCT br.inventory_id),0) revenue_per_copy,
           SUM(br.rental_amount)/(NULLIF(MAX(br.replacement_cost),0) * (COUNT(distinct br.inventory_id))) cost_recovery_multiple,
           COUNT(DISTINCT br.rental_id)::numeric/NULLIF(COUNT(DISTINCT br.inventory_id),0)/16 rentals__per_month
    FROM base_rental br
    GROUP BY br.film_id
),
--Metric #2
demand_seasonality AS (
    SELECT t1.film_id, MAX(t1.tot_monthly_rentals/t1.over_all_rentals)
    FROM (SELECT br.film_id,
                 COUNT(DISTINCT br.rental_id)                                     tot_monthly_rentals,
                 TO_CHAR(br.rental_date, 'YYYY-MM'),
                 SUM(COUNT(DISTINCT br.rental_id)) OVER (PARTITION BY br.film_id) over_all_rentals
          FROM base_rental br
          GROUP BY br.film_id, TO_CHAR(br.rental_date, 'YYYY-MM')) t1
    GROUP BY t1.film_id
)
SELECT * FROM demand_seasonality;