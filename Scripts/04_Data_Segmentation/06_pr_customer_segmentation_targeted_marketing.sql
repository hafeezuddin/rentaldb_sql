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
    15+ rentals in 2005: 25 points
    10-14 rentals: 20 points
    6-9 rentals: 15 points
    3-5 rentals: 10 points
    1-2 rentals: 5 points

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

WITH base_rental AS (SELECT r.customer_id, r.rental_id, r.inventory_id, r.rental_date, p.amount
                     FROM rental r
                              LEFT JOIN payment p ON r.rental_id = p.rental_id
--LEFT JOIN retains unpaid rentals.
                     WHERE r.rental_date BETWEEN '2005-01-01' AND '2005-12-31'
--Rentals filtered to 2005 financial year.
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
     monetary_score AS (SELECT t3.customer_id,
                               CASE
                                   WHEN spent_rank >= 0.80 THEN 25
                                   WHEN spent_rank >= 0.50 THEN 20
                                   WHEN spent_rank >= 0.20 THEN 15
                                   WHEN spent_rank >= 0.11 THEN 10
                                   ELSE 5
                                   END AS monetary_score
                        FROM (SELECT br.customer_id,
                                     SUM(br.amount)                                                   AS total_rentals,
                                     ROUND(percent_rank() OVER (ORDER BY sum(br.amount))::numeric, 2) AS spent_rank
                              FROM base_rental br
                              GROUP BY br.customer_id) t3),
--This cte is a pre-processing cte (To assign primary film category to the films)
-- To handle edge case when film belongs to two or more categories
     film_primary_cat AS (SELECT fc.film_id, MAX(fc.category_id) AS film_primary_category
                          FROM base_rental br
                                   JOIN inventory i ON br.inventory_id = i.inventory_id
                                   JOIN film_category fc ON i.film_id = fc.film_id
                          GROUP BY fc.film_id),
     category_loyalty AS (SELECT t6.customer_id,
                                 SUM(t6.cat_rentals) AS top_two_cat_rentals
                          FROM (SELECT t5.customer_id, t5.film_primary_category, t5.cat_rank, t5.cat_rentals
                                FROM (SELECT t4.customer_id,
                                             t4.film_primary_category,
                                             COUNT(DISTINCT t4.rental_id) AS                                               cat_rentals,
                                             row_number()
                                             over (partition by t4.customer_id ORDER BY count(distinct t4.rental_id) DESC) cat_rank
                                      FROM (SELECT br.customer_id,
                                                   br.rental_id,
                                                   br.inventory_id,
                                                   fpc.film_primary_category
                                            FROM base_rental br
                                                     JOIN inventory i ON br.inventory_id = i.inventory_id
                                                     JOIN film_primary_cat fpc ON i.film_id = fpc.film_id) t4
                                      GROUP BY t4.customer_id, t4.film_primary_category) t5
                                WHERE cat_rank <= 2) t6
                          GROUP BY t6.customer_id)
SELECT *
from category_loyalty;