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

B. Frequency Score (25 points)
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
    top_category_1, top_category_2

Business Rules:
    Sort customers by composite_score DESC (Health × Probability)
    Include only customers with at least one 2005 rental
    All calculations based on 2005 data only.
    Fixed budget of 50000 */

WITH base_rental AS (SELECT r.customer_id, r.rental_id, r.inventory_id, r.rental_date::date, p.amount
                     FROM rental r
                              LEFT JOIN payment p ON r.rental_id = p.rental_id
--LEFT JOIN retains unpaid rentals.
                     WHERE r.rental_date BETWEEN '2005-01-01' AND '2005-12-31'
--Rentals filtered to 2005 financial year.
),
--Aggregated metrics
    agg_metrics AS (
        SELECT br.customer_id, MAX(br.rental_date) AS  last_rental_date,
               SUM(br.amount) AS total_2005_spent,
               count(DISTINCT br.rental_id) AS total_rentals
        FROM base_rental br
        GROUP BY br.customer_id
    ),
--CTE To assign recency score to based on rentals
     recency_score AS (SELECT t1.customer_id,
                              CASE
                                  WHEN t1.latest_month = 12 THEN 25
                                  WHEN t1.latest_month = 11 THEN 20
                                  WHEN t1.latest_month = 10 THEN 15
                                  WHEN t1.latest_month BETWEEN 7 AND 9 THEN 10
                                  ELSE 5
                                  END as recency_score
                       FROM (SELECT br.customer_id, extract(MONTH FROM MAX(br.rental_date)) AS latest_month
                             FROM base_rental br
                             GROUP BY br.customer_id) t1),
--This cte assigns frequency score to the customers.
--Frequency: total rentals/No.of active months in period
     frequency_score AS (SELECT t2.customer_id,
                                CASE
                                    WHEN t2.frequency >= 15 THEN 25
                                    WHEN t2.frequency BETWEEN 10 AND 14 THEN 20
                                    WHEN t2.frequency BETWEEN 6 AND 9 THEN 15
                                    WHEN t2.frequency BETWEEN 2 AND 5 THEN 10
                                    ELSE 5
                                    END AS frequency_score
                         FROM (SELECT br.customer_id,
                                      COUNT(DISTINCT br.rental_id) /
                                      COUNT(DISTINCT DATE_TRUNC('month', br.rental_date)) AS frequency
                               --Caution: Rental count includes both paid and unpaid rentals.
                               --Change left join to inner join in base_rental cte to consider paid rentals exclusively
                               FROM base_rental br
                               GROUP BY br.customer_id) t2),
--This CTE calculates monetary score
     monetary_score AS (SELECT customer_id,
                               CASE ntile_10
                                   WHEN 10 THEN 25
                                   WHEN 7 THEN 20
                                   WHEN 4 THEN 15
                                   WHEN 3 THEN 10
                                   ELSE 5
                                   END AS monetary_score
                        FROM (SELECT customer_id,
                                     NTILE(10) OVER (ORDER BY SUM(amount) DESC) AS ntile_10
                              FROM base_rental
                              GROUP BY customer_id) t),

--This cte is a pre-processing cte (To assign primary film category to the films)
-- To handle edge case when film belongs to two or more categories
     film_primary_cat AS (SELECT fc.film_id, MAX(fc.category_id) AS film_primary_category
                          FROM base_rental br
                                   JOIN inventory i ON br.inventory_id = i.inventory_id
                                   JOIN film_category fc ON i.film_id = fc.film_id
                          GROUP BY fc.film_id),

--     category_loyalty AS (SELECT t8.customer_id,
--                                  CASE
--                                      WHEN t8.top_cat_share >= 80 THEN 25
--                                      WHEN t8.top_cat_share >= 60 THEN 20
--                                      WHEN t8.top_cat_share >= 40 THEN 15
--                                      WHEN t8.top_cat_share >= 20 THEN 10
--                                      ELSE 5
--                                      END AS category_loyalty_score
--                           FROM (SELECT t7.customer_id,
--                                        t7.top_two_cat_rentals,
--                                        COUNT(DISTINCT br.rental_id),
--                                        ROUND((COALESCE(t7.top_two_cat_rentals, 0) /
--                                               NULLIF(COUNT(DISTINCT br.rental_id), 0)) * 100, 2) top_cat_share
--                                 FROM (SELECT t6.customer_id, SUM(t6.cat_rentals) AS top_two_cat_rentals
--                                       FROM (SELECT t5.customer_id, t5.film_primary_category, t5.cat_rank, t5.cat_rentals
--                                             FROM (SELECT t4.customer_id,
--                                                          t4.film_primary_category,
--                                                          COUNT(DISTINCT t4.rental_id) AS                                               cat_rentals,
--                                                          row_number()
--                                                          over (partition by t4.customer_id ORDER BY count(distinct t4.rental_id) DESC) cat_rank
--                                                   FROM (SELECT br.customer_id,
--                                                                br.rental_id,
--                                                                br.inventory_id,
--                                                                fpc.film_primary_category
--                                                         FROM base_rental br
--                                                                  JOIN inventory i ON br.inventory_id = i.inventory_id
--                                                                  JOIN film_primary_cat fpc ON i.film_id = fpc.film_id) t4
--                                                   GROUP BY t4.customer_id, t4.film_primary_category) t5
--                                             WHERE cat_rank <= 2) t6
--                                       GROUP BY t6.customer_id) t7
--                                          JOIN base_rental br ON t7.customer_id = br.customer_id
--                                 GROUP BY t7.customer_id, t7.top_two_cat_rentals) t8),
     --Metric #2 starts here
     --Flagging customers based on their holiday rentals
     seasonal_pattern_score AS (SELECT t9.customer_id,
                                       CASE
                                           WHEN t9.november_flag IS TRUE AND t9.december_flag IS TRUE
                                               THEN 50
                                           WHEN t9.november_flag IS TRUE OR t9.december_flag IS TRUE
                                               THEN 30
                                           ELSE 10
                                           END AS seasonal_rental_score
                                FROM (SELECT br.customer_id,
                                             BOOL_OR(EXTRACT(MONTH FROM br.rental_date::date) = 11) AS november_flag,
                                             BOOL_OR(extract(MONTH FROM br.rental_date::date) = 12) AS december_flag
                                      FROM base_rental br
                                      GROUP BY br.customer_id) t9),
    --This CTE calculates Average days between rentals per customer and assigns score.
    rental_gap_score AS (
                        SELECT t11.customer_id,
                        CASE WHEN t11.average_diff_between_rentals < 30 THEN 50
                             WHEN t11.average_diff_between_rentals BETWEEN 30 AND 60 THEN 30
                             WHEN t11.average_diff_between_rentals BETWEEN 60 AND 90 THEN 20
                             ELSE 10
                             END AS rental_gap_score
                         FROM (SELECT t10.customer_id, ROUND(AVG(t10.rental_date_diff), 2) AS average_diff_between_rentals
                             FROM (SELECT br.customer_id, CASE
                             WHEN LAG(br.rental_date)
                             OVER (partition by br.customer_id ORDER BY br.rental_date) IS NULL
                             THEN 0
                             ELSE br.rental_date -
                             LAG(br.rental_date)
                             OVER (partition by br.customer_id ORDER BY br.rental_date)
                             END as rental_date_diff
                             FROM base_rental br) t10
                             GROUP BY t10.customer_id
                             ) t11),
    score_agg AS (
        SELECT rs.customer_id,
               rs.recency_score + ms.monetary_score + fs.frequency_score + category_loyalty_score AS health_score,
               sps.seasonal_rental_score + rgs.rental_gap_score AS probability_score,
               rs.recency_score + ms.monetary_score + fs.frequency_score + category_loyalty_score + sps.seasonal_rental_score + rgs.rental_gap_score AS composite_score
        FROM recency_score rs
        JOIN frequency_score fs ON rs.customer_id = fs.customer_id
        JOIN monetary_score ms ON fs.customer_id = ms.customer_id
        JOIN category_loyalty cl ON ms.customer_id = cl.customer_id
        JOIN seasonal_pattern_score sps ON cl.customer_id = sps.customer_id
        JOIN rental_gap_score rgs ON sps.customer_id = rgs.customer_id

    ),
    segmentation AS (SELECT sagg.customer_id,
                            sagg.health_score,
                            sagg.probability_score,
                            sagg.composite_score,
                            CASE
                                WHEN sagg.health_score >= 80 AND sagg.probability_score >= 80
                                    THEN 'CHAMPIONS'
                                WHEN sagg.health_score >= 70 AND sagg.probability_score < 60
                                    THEN 'AT-RISK LOYALISTS'
                                WHEN (sagg.health_score BETWEEN 60 AND 70) AND (sagg.probability_score < 60)
                                    THEN 'RISING STARS'
                                WHEN sagg.health_score < 60 AND sagg.probability_score >= 50
                                    THEN 'CASUAL VIEWERS'
                                ELSE 'Inactive'
                                END AS segmentation
                     FROM score_agg sagg),
    assigning_offer_cte AS (
        SELECT segg.customer_id,
        CASE WHEN segg.segmentation = 'CHAMPIONS' THEN 'Exclusive loyalty rewards (early access to new releases)'
             WHEN segg.segmentation = 'AT-RISK LOYALISTS' THEN 'We Miss You" 25% discount'
             WHEN segg.segmentation = 'RISING STARS' THEN 'New release promotions + free rental'
             WHEN segg.segmentation = 'CASUAL VIEWERS' THEN 'Budget bundle packages'
             WHEN segg.segmentation = 'Inactive' THEN 'Win-back trial offer'
        END AS segment_offer,
        CASE WHEN segg.segmentation = 'CHAMPIONS' THEN 15
             WHEN segg.segmentation = 'AT-RISK LOYALISTS' THEN 12
             WHEN segg.segmentation = 'RISING STARS' THEN 10
             WHEN segg.segmentation = 'CASUAL VIEWERS' THEN 7
             WHEN segg.segmentation = 'Inactive' THEN 5
        END AS max_bid_price_in_dollars

        FROM segmentation segg
    )
SELECT aoc.customer_id, c.first_name, c.last_name, c.email, am.last_rental_date, am.total_rentals,am.total_2005_spent,
       sa.health_score, sa.probability_score, sa.composite_score,
       aoc.segment_offer AS recommended_offer,  sg.segmentation,  aoc.max_bid_price_in_dollars

FROM assigning_offer_cte aoc
JOIN customer c  ON aoc.customer_id = c.customer_id
JOIN agg_metrics am ON c.customer_id = am.customer_id
JOIN score_agg sa ON am.customer_id = sa.customer_id
JOIN segmentation sg ON sa.customer_id = sg.customer_id;