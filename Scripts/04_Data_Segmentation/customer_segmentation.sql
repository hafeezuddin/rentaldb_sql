
/*Business Requirement: Customer Segmentation Analysis
Objective: Create a comprehensive customer segmentation analysis that classifies
customers into tiers based on their rental behavior, spending patterns, and engagement levels.

Requirements:
    Platinum: Top 10% by spending AND Top 50% by rental frequency
    Gold: Top 10% by spending OR Top 50% by rental frequency (but not both)
    Silver: Between 40th-60th percentile for both metrics  
    Bronze: Bottom 10% by spending AND Bottom 50% by rental frequency

    For each segment, calculate:
        Number of customers, Average total spending, Average rental frequency, 
        Average days between rentals (engagement frequency),Percentage of late returns,
        Identify which segments have the highest customer retention (customers who rented in the last 30 days),
        Show the revenue contribution percentage of each segment, Most popular category in that segment.
Expected Output Columns:
    customer_segment, customer_count, avg_total_spent, avg_rental_count, top_category, late_return_rate, avg_days_between_rentals, 
    segment_revenue_share, active_customer_percentage */

-- CTE to compute total spend and spend percentile per customer.
--Considering only paid rentals for all the metrics calculations.
WITH customer_spend_analysis AS (
  SELECT
    c.customer_id,
    SUM(p.amount) AS total_spend_by_each_customer,
    -- Percentile rank of customer by total spend (0..1)
    PERCENT_RANK() OVER (ORDER BY SUM(p.amount) DESC) AS spend_percentile
  FROM customer c
  INNER JOIN rental r ON c.customer_id = r.customer_id
  INNER JOIN payment p ON r.rental_id = p.rental_id
  WHERE r.return_date IS NOT NULL
  GROUP BY 1
  ORDER BY total_spend_by_each_customer DESC
),
overall_total AS (
  SELECT sum(total_spend_by_each_customer) AS overall_total
  FROM customer_spend_analysis
),

-- CTE to compute rounded average spend across all customers (single value)
spend_across_all AS (
  SELECT ROUND(AVG(total_spend_by_each_customer)) AS avg_spend_across_all
  FROM customer_spend_analysis
),

-- CTE to compute total number of rentals per customer and their percentile/rank
rental_analysis AS (
  SELECT
    csa.customer_id,
    COUNT(r.rental_id) AS total_rentals,
    -- Percentile rank (0..1) of customers by rental count
    PERCENT_RANK() OVER (ORDER BY COUNT(r.rental_id) DESC) AS rental_rank
  FROM customer_spend_analysis csa
  INNER JOIN rental r ON csa.customer_id = r.customer_id
  INNER JOIN payment p ON r.rental_id = p.rental_id
  WHERE r.return_date IS NOT NULL
  GROUP BY 1
  ORDER BY total_rentals DESC
),
-- CTE with rounded average rental count across customers (single value)
rental_across_all AS (
  SELECT ROUND(AVG(total_rentals), 2) AS avg_rental_across_all
  FROM rental_analysis
),

-- CTE to compute category counts per customer (used to determine popular categories later)
category_analysis AS (
  SELECT
    csa.customer_id,
    cat.name,
    COUNT(*) AS customer_category_count,
    ROW_NUMBER() OVER (PARTITION BY csa.customer_id ORDER BY COUNT(*) DESC , cat.name ASC) AS category_rank
  FROM customer_spend_analysis csa
  INNER JOIN rental r ON csa.customer_id = r.customer_id
  INNER JOIN payment p ON r.rental_id = p.rental_id
  INNER JOIN inventory i ON r.inventory_id = i.inventory_id
  INNER JOIN film f ON i.film_id = f.film_id
  INNER JOIN film_category fc ON f.film_id = fc.film_id
  INNER JOIN category cat ON fc.category_id = cat.category_id
  WHERE r.return_date IS NOT NULL
  GROUP BY 1,2
  ORDER BY csa.customer_id
),
top_category_per_customer AS (
SELECT csa.customer_id, cat_ana1.name, cat_ana1.category_rank
 FROM customer_spend_analysis csa
INNER JOIN category_analysis cat_ana1 ON csa.customer_id = cat_ana1.customer_id
WHERE cat_ana1.category_rank = 1
), -- Top category per customer

-- CTE to compute number and percentage of late returns per customer
late_returns_percentage AS (
  SELECT
    csa.customer_id,
    ra.total_rentals,
    COUNT(*) AS no_of_late_returns,
    -- Percentage of this customer's rentals that were late
    ROUND((COUNT(*)::numeric / ra.total_rentals::numeric) * 100, 2) AS late_return_percentage
  FROM customer_spend_analysis csa
  INNER JOIN rental r ON csa.customer_id = r.customer_id
  INNER JOIN payment p ON r.rental_id = p.rental_id
  INNER JOIN inventory i ON r.inventory_id = i.inventory_id
  INNER JOIN film f ON i.film_id = f.film_id
  INNER JOIN rental_analysis ra ON csa.customer_id = ra.customer_id
  WHERE
    -- A rental is late if returned after rental_duration or still outstanding past duration
    (r.return_date IS NOT NULL AND (r.return_date::date - r.rental_date::date) > f.rental_duration::numeric)
    OR (r.return_date IS NULL AND (CURRENT_DATE - r.rental_date::date) > f.rental_duration::numeric)
  GROUP BY 1,2
),
active_customers2 AS (
  SELECT csa.customer_id, 
    CASE
      WHEN CURRENT_DATE - MAX(r.rental_date::date) <= 30 THEN 'active'
      ELSE 'Inactive'
      END AS status
    FROM customer_spend_analysis csa
    INNER JOIN rental r ON csa.customer_id = r.customer_id
    INNER JOIN payment p ON r.rental_id = p.rental_id
    GROUP BY 1
),
-- CTE to compute days between consecutive rentals per customer (engagement)
customer_engagement AS (
  SELECT
    csa.customer_id,
    r.rental_id,
    r.rental_date,
    LAG(r.rental_date) OVER (PARTITION BY csa.customer_id ORDER BY csa.customer_id, r.rental_date) AS lag_date,
    CASE
      WHEN LAG(r.rental_date) OVER (PARTITION BY csa.customer_id ORDER BY csa.customer_id, r.rental_date) IS NULL THEN 0
      ELSE EXTRACT(DAY FROM r.rental_date - LAG(r.rental_date) OVER (PARTITION BY csa.customer_id ORDER BY csa.customer_id, r.rental_date))
    END AS days_between_rentals
  FROM customer_spend_analysis csa
  INNER JOIN rental r ON csa.customer_id = r.customer_id
  INNER JOIN payment p ON r.rental_id = p.rental_id
  ORDER BY csa.customer_id, r.rental_date
),
-- CTE to compute average days between rentals per customer
avg_gap AS (
  SELECT
    csa.customer_id,
    ROUND(AVG(days_between_rentals), 2) AS average_gap
  FROM customer_spend_analysis csa
  INNER JOIN customer_engagement ce ON csa.customer_id = ce.customer_id
  GROUP BY 1
),
-- Final segmentation CTE: joins spend/rental metrics and assigns segment using CASE
segmentation_cte AS (
  SELECT
    csa.customer_id,
    csa.spend_percentile,
    ra.rental_rank,
    csa.total_spend_by_each_customer,
    sal.avg_spend_across_all,
    ra.total_rentals,
    ral.avg_rental_across_all,
    ag.average_gap,
    lrp.late_return_percentage,
    ac2.status AS customer_activity_status,
    ot.overall_total,
    tcpc.name AS top_category,
    -- Segment assignment rules:
    -- Platinum: Top 10% by spending AND Top 50% by rental frequency
    -- Gold: Top 10% by spending OR Top 50% by rental frequency (but not both)
    -- Silver: Between 40th-60th percentile for both metrics
    -- Bronze: Bottom 10% by spending AND Bottom 50% by rental frequency
    CASE
      WHEN csa.spend_percentile <= 0.10 AND ra.rental_rank <= 0.50 THEN 'Platinum'
      WHEN (csa.spend_percentile <= 0.10 OR ra.rental_rank <= 0.50)
           AND NOT (csa.spend_percentile <= 0.10 AND ra.rental_rank <= 0.50) THEN 'Gold'
      WHEN csa.spend_percentile BETWEEN 0.40 AND 0.60
           AND ra.rental_rank BETWEEN 0.40 AND 0.60 THEN 'Silver'
      WHEN csa.spend_percentile >= 0.90 AND ra.rental_rank >= 0.50 THEN 'Bronze'
      ELSE 'Regular'
    END AS categorization
  FROM customer_spend_analysis csa
  INNER JOIN rental_analysis ra ON csa.customer_id = ra.customer_id
  INNER JOIN avg_gap ag ON ra.customer_id = ag.customer_id
  INNER JOIN late_returns_percentage lrp ON ag.customer_id = lrp.customer_id
  INNER JOIN active_customers2 ac2 ON lrp.customer_id = ac2.customer_id
  INNER JOIN top_category_per_customer tcpc ON ac2.customer_id = tcpc.customer_id
  CROSS JOIN rental_across_all ral  -- provides avg rental across all customers
  CROSS JOIN spend_across_all sal   -- provides avg spend across all customers
  CROSS JOIN overall_total ot        -- provides overall total spend across all customers
),
categ_top_cat AS (
  SELECT sq1.categorization, sq1.top_category  
    FROM (SELECT 
            sc.categorization, 
            sc.top_category,
            COUNT(*),
            ROW_NUMBER() OVER (PARTITION BY sc.categorization ORDER BY COUNT(*) DESC) AS rank_within_segment  
  FROM segmentation_cte sc 
  GROUP BY 1,2) AS sq1
  WHERE sq1.rank_within_segment = 1
)
-- Aggregation by segment:
-- avg_tier_spend: average spend in segment
-- avg_tier_rentals: average rentals in segment
-- total_customers_in_tier: count of customers in segment
SELECT
  scte.categorization,
  ROUND(AVG(total_spend_by_each_customer), 2) AS avg_tier_spend,
  ROUND(AVG(total_rentals), 2) AS avg_tier_rentals,
  ROUND(AVG(average_gap),2) AS average_gap,
  COUNT(*) AS total_customers_in_tier,
  ROUND(COUNT(customer_activity_status) FILTER (WHERE customer_activity_status = 'active')::numeric/COUNT(*)::numeric*100,2) AS active_per,
  ROUND(AVG(late_return_percentage),2) AS avg_late_return_percentage,
  ROUND(SUM((total_spend_by_each_customer)/scte.overall_total) *100,2) AS segment_revenue_share,
  ctc.top_category
FROM segmentation_cte scte
INNER JOIN categ_top_cat ctc ON scte.categorization = ctc.categorization
GROUP BY scte.categorization,ctc.top_category;