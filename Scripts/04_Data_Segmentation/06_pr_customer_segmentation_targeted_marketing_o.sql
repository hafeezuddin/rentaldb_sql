/*
We have $50,000 allocated for a Q1 2006 customer reactivation campaign. With thousands of 2005 customers,
we need to strategically target those most likely to respond to our offers.
Your Mission: Identify which 2005 customers to target, determine the optimal offer for each segment,
and ensure we maximize ROI within our budget constraints.

ANALYTICAL REQUIREMENTS
METRIC 1: CUSTOMER HEALTH SCORE (0-100 Points)

A. Recency Score (25 points)
    Last rental in December 2005: 25 points
    Last rental in November 2005: 20 points
    Last rental in October 2005: 15 points
    Last rental in July-September 2005: 10 points
    Last rental in January-June 2005: 5 points

B. Frequency Score (25 points): rentals/active_months
    15+ frequency in 2005: 25 points
    10-14 frequency: 20 points
    6-9 frequency: 15 points
    3-5 frequency: 10 points
    1-2 frequency: 5 points

C. Monetary Score (25 points)
    Top 20% of 2005 spenders: 25 points
    Next 30% of spenders: 20 points
    Middle 30% of spenders: 15 points
    Next 10% of spenders: 10 points
    Bottom 10% of spenders: 5 points

D. Category Loyalty Score (25 points)
    80%+ of rentals in top 2 categories: 25 points
    60-79% in top 2 categories: 20 points
    40-59% in top 2 categories: 15 points
    20-39% in top 2 categories: 10 points
    <20% category concentration: 5 points

METRIC 2: REACTIVATION PROBABILITY SCORE (0-100 Points)
A. Seasonal Pattern Score (50 points)
    Rented in BOTH November & December 2005: 50 points
    Rented in EITHER November or December: 30 points
    No holiday period rentals: 10 points

B. Rental Gap Analysis (50 points)
    Average days between rentals < 30 days: 50 points
    Average days between rentals 30-60 days: 30 points
    Average days between rentals 60-90 days: 20 points
    Average days >90 days OR only one rental: 10 points



CUSTOMER SEGMENTATION & OFFER STRATEGY
SEGMENT 1: CHAMPIONS
    Criteria: Health Score ≥ 80 AND Probability Score ≥ 80
    Offer: Exclusive loyalty rewards (early access to new releases)
    Max Bid Price: $15 per customer

SEGMENT 2: AT-RISK LOYALISTS
    Criteria: Health Score ≥ 70 AND Probability Score < 60
    Offer: "We Miss You" 25% discount
    Max Bid Price: $12 per customer

SEGMENT 3: RISING STARS
    Criteria: Health Score 60-79 AND Probability Score ≥ 70
    Offer: New release promotions + free rental
    Max Bid Price: $10 per customer

SEGMENT 4: CASUAL VIEWERS
    Criteria: Health Score < 60 AND Probability Score ≥ 50
    Offer: Budget bundle packages
    Max Bid Price: $7 per customer

SEGMENT 5: INACTIVE
    Criteria: All other customers
    Offer: Win-back trial offer
    Max Bid Price: $5 per customer

DELIVERABLE REQUIREMENTS
Final Output Must Include:
    customer_id, first_name, last_name, email
    health_score, probability_score, composite_score
    customer_segment, recommended_offer, total_2005_spent, last_rental_date,
    total_2005_rentals, max_bid_price
    top_category_1, top_category_2 (Can be added together into one column)

Business Rules:
    Sort customers by composite_score DESC (Health × Probability)
    Include only customers with at least one 2005 rental
    All calculations based on 2005 data only.
    Fixed budget of 50000 */

--Base rental cte to populate customer, rentals and corresponding payment details.
WITH base_rental AS (SELECT r.customer_id,
                            r.rental_id,
                            r.rental_date,
                            r.inventory_id,
                            p.amount,
                            r.rental_date::date - LAG(r.rental_date::date)
                                                  OVER (PARTITION BY r.customer_id ORDER BY r.rental_date::date) AS rental_days_diff
                     --To be in calculating average duration between two rentals
                     FROM rental r
                              LEFT JOIN payment p ON r.rental_id = p.rental_id
                     --Left Join retains paid and unpaid rentals
                     -- Replace Left join with inner join to consider paid rentals only
                     WHERE r.rental_date BETWEEN '2005-01-01' AND '2005-12-31'
    --Filters 2005 data
),
     --Core metrics cte calculates aggregate metrics of each customers like total rentals, amount paid, flags holiday months rentals
     --Single scan/pass aggregation
     core_metrics AS (SELECT br.customer_id,
                             MAX(extract(MONTH FROM br.rental_date))                       latest_rental_month,
                             COALESCE(COUNT(DISTINCT br.rental_id), 0) /
                             NULLIF(COUNT(DISTINCT extract(MONTH FROM br.rental_date)), 0) rental_frequency,
                             COUNT(DISTINCT br.rental_id)                                  total_rentals,
                             --Accounts for rentals without over counting
                             ROUND(AVG(br.rental_days_diff), 2) AS                         avg_gap_between_rentals,
                             SUM(br.amount)                                                total_spent,
                             bool_or(extract(MONTH FROM br.rental_date) = 11)              last_rental_in_november_flag,
                             --Flags november month rentals. Returns true if customer rented in november.
                             --bool_or returns true for if one row in each customer group before aggregation is true.
                             bool_or(extract(MONTH FROM br.rental_date) = 12)              last_rental_in_december_flag,
                             --Flags december month rentals. Returns true if customer rented in december.
                             --bool_or returns true for if one row in each customer group before aggregation is true.
                             NTILE(10) OVER (ORDER BY SUM(br.amount))                      spend_bucket
                      --Ntile() window function is preferred here over percent rank to uniformly distribute customers and filter.
                      --percent_rank() may not return bucket like top exact top 20% of customers based on amount spent.

                      FROM base_rental br
                      GROUP BY br.customer_id),
--Cte to calculate film primary category to derive customer fav category
--Safe case where film belongs to more than two categories and film doesn't have primary category assigned.
--In cases where primary category is assigned to film,
-- category table can be directly joined in the base query and derive customer preferences and related metric.
     film_primary_cat AS (SELECT i.film_id, MIN(fc.category_id) film_primary_cat
                          FROM inventory i
                                   JOIN film_category fc ON i.film_id = fc.film_id
                                   JOIN category ct ON fc.category_id = ct.category_id
                          GROUP BY i.film_id),
     customer_preferences AS (SELECT t3.customer_id,
                                     string_agg(t3.name, ',' ORDER BY t3.name) top_two_categories,
                                     SUM(t3.cat_rentals)                       top_two_cat_rentals
                              FROM (SELECT t2.customer_id, cat.name, t2.cat_rentals
                                    FROM (SELECT t1.customer_id,
                                                 t1.film_primary_cat,
                                                 COUNT(*)                                                               cat_rentals,
                                                 row_number() over (partition by t1.customer_id ORDER BY count(*) DESC) cat_rank
                                          FROM (SELECT br.customer_id, br.inventory_id, fpc.film_primary_cat
                                                FROM base_rental br
                                                         JOIN inventory i ON br.inventory_id = i.inventory_id
                                                         JOIN film_primary_cat fpc ON i.film_id = fpc.film_id) t1
                                          GROUP BY t1.customer_id, t1.film_primary_cat) t2
                                             JOIN category cat ON t2.film_primary_cat = cat.category_id
                                    WHERE t2.cat_rank <= 2) t3
                                       JOIN core_metrics cm ON t3.customer_id = cm.customer_id
                              GROUP BY t3.customer_id),
     --Aggregation cte to integrate all core metrics.
     --Preparatory cte for assigning scores to customers on their behavior.
     metrics_agg AS (SELECT cm.customer_id,
                            cm.rental_frequency,
                            cm.total_rentals,
                            cm.total_spent,
                            cm.avg_gap_between_rentals,
                            cm.last_rental_in_november_flag,
                            cm.last_rental_in_december_flag,
                            cm.latest_rental_month,
                            cp.top_two_categories,
                            cm.spend_bucket,
                            ROUND((coalesce(cp.top_two_cat_rentals, 0) / NULLIF(cm.total_rentals, 0)) * 100,
                                  2) top_two_cat_rental_share
                     FROM core_metrics cm
                              JOIN customer_preferences cp ON cm.customer_id = cp.customer_id),
--Assigning score to customers based on customer behavior pattern
     scoring_metrics AS (SELECT ma.customer_id,
                                ma.latest_rental_month,
                                ma.rental_frequency,
                                ma.total_spent,
                                ma.spend_bucket,
                                ma.top_two_categories,
                                ma.last_rental_in_november_flag,
                                ma.last_rental_in_december_flag,
                                ma.avg_gap_between_rentals,
                                CASE
                                    WHEN ma.latest_rental_month = 12 THEN 25
                                    WHEN ma.latest_rental_month = 11 THEN 20
                                    WHEN ma.latest_rental_month = 10 THEN 15
                                    WHEN ma.latest_rental_month BETWEEN 7 AND 9 THEN 10
                                    ELSE 5
                                    END as recency_score,

                                CASE
                                    WHEN ma.rental_frequency >= 15 THEN 25
                                    WHEN ma.rental_frequency BETWEEN 10 AND 14 THEN 20
                                    WHEN ma.rental_frequency BETWEEN 6 AND 9 THEN 15
                                    WHEN ma.rental_frequency BETWEEN 3 AND 5 THEN 10
                                    ELSE 5
                                    END AS frequency_score,

                                CASE
                                    WHEN ma.spend_bucket >= 8 THEN 25
                                    WHEN ma.spend_bucket >= 6 THEN 20
                                    WHEN ma.spend_bucket >= 4 THEN 15
                                    WHEN ma.spend_bucket >= 2 THEN 10
                                    ELSE 5
                                    END AS monetary_score,

                                CASE
                                    WHEN ma.top_two_cat_rental_share >= 80 THEN 25
                                    WHEN ma.top_two_cat_rental_share >= 60 THEN 20
                                    WHEN ma.top_two_cat_rental_share >= 40 THEN 15
                                    WHEN ma.top_two_cat_rental_share >= 20 THEN 10
                                    ELSE 5
                                    END AS category_loyalty_score,

                                CASE
                                    WHEN ma.last_rental_in_december_flag = TRUE AND
                                         ma.last_rental_in_november_flag = TRUE THEN 50
                                    WHEN ma.last_rental_in_december_flag = TRUE OR
                                         ma.last_rental_in_november_flag = TRUE THEN 30
                                    ELSE 10
                                    END AS seasonal_pattern_score,

                                CASE
                                    WHEN ma.avg_gap_between_rentals < 30 THEN 50
                                    WHEN ma.avg_gap_between_rentals < 60 THEN 30
                                    WHEN ma.avg_gap_between_rentals < 90 THEN 20
                                    ELSE 10
                                    END AS rental_gap_score
                         FROM metrics_agg ma),
--CTE to calculate ove all health score, probablity score and composite score.
     --Preparatory step for customer segmentation.
     score_agg AS (SELECT *,
                          sm.recency_score + sm.frequency_score + sm.monetary_score +
                          sm.category_loyalty_score                         health_score,
                          sm.rental_gap_score + sm.seasonal_pattern_score   probablity_score,
                          (sm.recency_score + sm.frequency_score + sm.monetary_score + sm.category_loyalty_score) *
                          (sm.rental_gap_score + sm.seasonal_pattern_score) composite_score
                   FROM scoring_metrics sm),
--CTE to segment customers based on probability and health scores.
     segmentation AS (SELECT *,
                             CASE
                                 WHEN sagg.health_score >= 80 AND sagg.probablity_score >= 80 THEN 'CHAMPIONS'
                                 WHEN sagg.health_score >= 70 AND sagg.probablity_score < 60 THEN 'AT-RISK LOYALISTS'
                                 WHEN sagg.health_score >= 60 AND sagg.probablity_score >= 70 THEN 'RISING STARS'
                                 WHEN sagg.health_score < 60 AND sagg.probablity_score >= 50 THEN 'CASUAL VIEWERS'
                                 ELSE 'Inactive'
                                 END AS segment,

                             CASE
                                 WHEN sagg.health_score >= 80 AND sagg.probablity_score >= 80
                                     THEN 'Exclusive loyalty rewards (early access to new releases)'
                                 WHEN sagg.health_score >= 70 AND sagg.probablity_score < 60
                                     THEN 'We Miss You" 25% discount'
                                 WHEN sagg.health_score >= 60 AND sagg.probablity_score >= 70
                                     THEN 'New release promotions + free rental'
                                 WHEN sagg.health_score < 60 AND sagg.probablity_score >= 50
                                     THEN 'Budget bundle packages'
                                 ELSE 'Win-back trial offer'
                                 END AS Offer,

                             CASE
                                 WHEN sagg.health_score >= 80 AND sagg.probablity_score >= 80 THEN 15
                                 WHEN sagg.health_score >= 70 AND sagg.probablity_score < 60 THEN 12
                                 WHEN sagg.health_score >= 60 AND sagg.probablity_score >= 70 THEN 10
                                 WHEN sagg.health_score < 60 AND sagg.probablity_score >= 50 THEN 7
                                 ELSE 5
                                 END AS budget
                      FROM score_agg sagg)
--Main query to retrieve customer and their corresponding metrics, scores and their segment, eligible offer, assigned budget.
SELECT *
FROM (SELECT sg.customer_id,
             sg.total_spent,
             sg.health_score,
             sg.top_two_categories,
             sg.probablity_score,
             sg.composite_score,
             sg.segment,
             sg.Offer,
             sg.budget,
             SUM(sg.budget) OVER (ORDER BY sg.composite_score DESC, sg.customer_id) rolling_total
      FROM segmentation sg) t4
WHERE rolling_total <= 50000;
--Filters/Populates customers based on metrics and till assigned budget is exhausted.

-- [
--   {
--     "QUERY PLAN": "Planning Time: 6.819 ms"
--   },
--   {
--     "QUERY PLAN": "Execution Time: 176.806 ms"
--   }
-- ]