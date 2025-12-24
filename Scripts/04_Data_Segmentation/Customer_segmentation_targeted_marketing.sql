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
    Fixed buget of 50000 */

--CTE to calculate Metric #1: recency_score
WITH recency_score AS (
    SELECT sq1.customer_id,
    sq1.latest_rental_month,
    CASE
        WHEN sq1.latest_rental_month = 12
            THEN 25
        WHEN sq1.latest_rental_month = 11
            THEN 20
        WHEN sq1.latest_rental_month = 10
            THEN 15
        WHEN sq1.latest_rental_month BETWEEN 07 AND 09
            THEN 10
        WHEN sq1.latest_rental_month BETWEEN 01 AND 06
            THEN 5
        END AS recency_score
    FROM
        (
        SELECT c.customer_id,
        EXTRACT('Month' FROM MAX(r.rental_date)) AS latest_rental_month
        FROM customer c
        INNER JOIN rental r ON c.customer_id = r.customer_id
        INNER JOIN payment p ON r.rental_id = p.rental_id
        WHERE r.return_date IS NOT NULL AND (r.rental_date BETWEEN '2005-01-01' AND '2005-12-31')
        GROUP BY 1
        ) sq1
),
--CTE to calculate Metric #1: frequency_score
frequency_score AS (
    SELECT sq2.customer_id,
    sq2.total_rentals,
    CASE
        WHEN sq2.total_rentals >= 15
            THEN 25
        WHEN sq2.total_rentals BETWEEN 10 AND 14
            THEN 20
        WHEN sq2.total_rentals BETWEEN 6 AND 9
            THEN 15
        WHEN sq2.total_rentals BETWEEN 3 AND 5
            THEN 10
        WHEN sq2.total_rentals BETWEEN 1 AND 2
            THEN 5
        END AS frequency_score
    FROM
        (
        SELECT c1.customer_id,
        COUNT(DISTINCT r1.rental_id) AS total_rentals
        FROM customer c1
        INNER JOIN rental r1 ON c1.customer_id = r1.customer_id
        INNER JOIN payment p1 ON r1.rental_id = p1.rental_id
        WHERE r1.return_date IS NOT NULL AND (r1.rental_date BETWEEN '01-01-2005' AND '12-31-2005')
        GROUP BY 1
        )sq2
),
--CTE to calculate Metric #1: monetary_score
monetary_score AS (
    SELECT sq3.customer_id, sq3.total_spent, sq3.spent_rank,
    CASE
        WHEN sq3.spent_rank >= 0.8
            THEN 25
        WHEN sq3.spent_rank BETWEEN 0.5 AND 0.79
            THEN 20
        WHEN sq3.spent_rank BETWEEN 0.20 AND 0.49
            THEN 15
        WHEN sq3.spent_rank BETWEEN 0.10 AND 0.19
            THEN 10
        ELSE 5
        END AS monetary_score
    FROM
        (
        SELECT c2.customer_id,
        SUM(p.amount) AS total_spent,
        PERCENT_RANK() OVER (ORDER BY SUM(p.amount)) AS spent_rank
        FROM customer c2
        INNER JOIN rental r2 ON c2.customer_id = r2.customer_id
        INNER JOIN payment p2 ON r2.rental_id = p2.rental_id
        INNER JOIN payment p ON r2.rental_id = p.rental_id
        WHERE r2.return_date IS NOT NULL AND (r2.rental_date BETWEEN '01-01-2005' AND '12-31-2005')
        GROUP BY 1
        )sq3
),

--CTE to calculate Metric #1: category_loyalty_score
--This cte pull's in customer top two rented categories and calculates category_share by dividing it with customer_total_rentals using multiple subquery implmentation
category_loyalty AS (
    SELECT sq7.customer_id, sq7.top_cat_share,
        CASE
            WHEN sq7.top_cat_share >= 80
                THEN 25
            WHEN sq7.top_cat_share >= 60
                THEN 20
            WHEN sq7.top_cat_share >= 40
                THEN 15
            WHEN sq7.top_cat_share >= 20
                THEN 10
            ELSE 5
            END AS loyalty_score
    FROM
    (
        SELECT sq6.customer_id, sq6.top_two_cat_rentals,
        COUNT(DISTINCT r4.rental_id) AS total_rentals,
        sq6.top_two_cat_rentals/COUNT(DISTINCT r4.rental_id) * 100 AS top_cat_share
        FROM
        (
            SELECT sq5.customer_id, SUM(sq5.total_rentals) AS top_two_cat_rentals
            FROM
            (
                SELECT sq4.customer_id, sq4.name, sq4.total_rentals
                FROM
                (
                    SELECT c3.customer_id,
                    cat.name,
                    COUNT(*) AS total_rentals,
                    ROW_NUMBER() OVER (PARTITION BY c3.customer_id ORDER BY COUNT(*) DESC) AS rn
                    FROM customer c3
                    INNER JOIN rental r3 ON c3.customer_id = r3.customer_id
                    INNER JOIN payment p3 ON r3.rental_id = p3.rental_id
                    INNER JOIN inventory i ON r3.inventory_id = i.inventory_id
                    INNER JOIN film f ON i.film_id = f.film_id
                    INNER JOIN film_category fc ON f.film_id = fc.film_id
                    INNER JOIN category cat ON fc.category_id = cat.category_id
                    WHERE r3.return_date IS NOT NULL AND (r3.rental_date BETWEEN '01-01-2005' AND '12-31-2005')
                    GROUP BY 1,2
                    ORDER BY 1
                )sq4
                    WHERE sq4.rn <=2
            )sq5
            GROUP BY 1
        ) sq6
        INNER JOIN rental r4 ON sq6.customer_id = r4.customer_id
        GROUP BY 1,2
    ) sq7
),

--Metric #2
--CTE to calculate Metric #2 seasonal pattern score
seasonal_pattern AS (
  SELECT sq8.customer_id,
  CASE
    WHEN has_november AND has_december IS TRUE
        THEN 50
    WHEN has_november OR has_december IS TRUE
        THEN 30
     ELSE 10
    END AS pattern_score
  FROM (
    SELECT
        rental.customer_id,
        --For each customer, look at ALL their rentals and flag if ANY were in November/december.
        BOOL_OR(EXTRACT(MONTH FROM rental_date) = 11) as has_november,
        BOOL_OR(EXTRACT(MONTH FROM rental_date) = 12) as has_december
    FROM rental
    INNER JOIN payment ON rental.rental_id = payment.rental_id
    WHERE rental.return_date IS NOT NULL AND (rental.rental_date BETWEEN '2005-01-01' AND '2005-12-31')
    GROUP BY rental.customer_id
  ) sq8
),
/*
--ALT TO BOOL_OR
SELECT sq0.customer_id,
    MAX(rented_november) AS has_rented_in_nov,
    MAX(rented_december) AS has rented_in_dec,
    CASE
        WHEN MAX(rented_november) = 1 AND MAX(rented_december) =1
            THEN 50
        WHEN MAX(rented_november) =1 OR MAX(rented_december)=1
            THEN 30
        ELSE 10
        END AS pattern_score
FROM (
        SELECT
        customer_id,
        CASE WHEN EXTRACT(MONTH FROM rental_date) = 11
            THEN 1 ELSE 0 END as rented_november_flag,

        CASE WHEN EXTRACT(MONTH FROM rental_date) = 12
            THEN 1 ELSE 0 END as rented_december_flag

    FROM rental
    WHERE rental_date BETWEEN '2005-01-01' AND '2005-12-31'
    ) sq0
    GROUP BY 1
*/
--CTE for rental gap analysis
rental_gap_analysis AS (
    SELECT sq9.customer_id, ROUND(AVG(diff),2) AS average_days_between_rentals,
    CASE
        WHEN ROUND(AVG(diff),2) < 30 THEN 50
        WHEN ROUND(AVG(diff),2) BETWEEN 30 AND 60
            THEN 30
        WHEN ROUND(AVG(diff),2) BETWEEN 61 AND 90
            THEN 20
        WHEN ROUND(AVG(diff),2) > 90
            THEN 10
        ELSE 0
        END AS rental_gap_score
    FROM
    (
    SELECT c4.customer_id,
    r4.rental_date::date,
    LAG(r4.rental_date::date) OVER (PARTITION BY c4.customer_id ORDER BY c4.customer_id, r4.rental_date::date ASC) AS lag_date,
    CASE
        WHEN LAG(r4.rental_date::date) OVER (PARTITION BY c4.customer_id ORDER BY c4.customer_id, r4.rental_date::date ASC) IS NULL
            THEN 0
        ELSE r4.rental_date::date - LAG(r4.rental_date::date) OVER (PARTITION BY c4.customer_id ORDER BY c4.customer_id, r4.rental_date::date ASC)
        END AS diff
    FROM customer c4
    INNER JOIN rental r4 ON c4.customer_id = r4.customer_id
    INNER JOIN payment p4 ON r4.rental_id = p4.rental_id
    WHERE r4.return_date IS NOT NULL AND (r4.rental_date BETWEEN '2005-01-01' AND '2005-12-31')
    ORDER BY 1,2 ASC
    ) sq9
    GROUP BY sq9.customer_id
),

--CTE to get top #1 category rented by customers by no_of_rentals
top_cat1 AS (
    SELECT sq10.customer_id, sq10.name
                FROM
                (
                    SELECT c3.customer_id,
                    cat.name,
                    COUNT(*) AS total_rentals,
                    ROW_NUMBER() OVER (PARTITION BY c3.customer_id ORDER BY COUNT(*) DESC) AS rn
                    FROM customer c3
                    INNER JOIN rental r3 ON c3.customer_id = r3.customer_id
                    INNER JOIN payment p5  ON r3.rental_id = p5.rental_id
                    INNER JOIN inventory i ON r3.inventory_id = i.inventory_id
                    INNER JOIN film f ON i.film_id = f.film_id
                    INNER JOIN film_category fc ON f.film_id = fc.film_id
                    INNER JOIN category cat ON fc.category_id = cat.category_id
                    WHERE r3.return_date IS NOT NULL AND (r3.rental_date BETWEEN '01-01-2005' AND '12-31-2005')
                    GROUP BY 1,2
                    ORDER BY 1
                )sq10
                    WHERE sq10.rn =1
),

--CTE to get top category #2 rented by customers by no_of_rentals
top_cat2 AS (
SELECT sq11.customer_id, sq11.name
                FROM
                (
                    SELECT c3.customer_id,
                    cat.name,
                    COUNT(*) AS total_rentals,
                    ROW_NUMBER() OVER (PARTITION BY c3.customer_id ORDER BY COUNT(*) DESC) AS rn
                    FROM customer c3
                    INNER JOIN rental r3 ON c3.customer_id = r3.customer_id
                    INNER JOIN payment p6 ON r3.rental_id = p6.rental_id
                    INNER JOIN inventory i ON r3.inventory_id = i.inventory_id
                    INNER JOIN film f ON i.film_id = f.film_id
                    INNER JOIN film_category fc ON f.film_id = fc.film_id
                    INNER JOIN category cat ON fc.category_id = cat.category_id
                    WHERE r3.return_date IS NOT NULL AND (r3.rental_date BETWEEN '01-01-2005' AND '12-31-2005')
                    GROUP BY 1,2
                    ORDER BY 1
                )sq11
                    WHERE sq11.rn =2
),
--CTE to aggregate all metrics (Metric: customer_health_score_metric, Reactivation metric)
aggregation_cte AS (
SELECT sq10.customer_id, CONCAT(c5.first_name,' ', c5.last_name), c5.email, sq10.recency_score, sq10.frequency_score, sq10.monetary_score,
    sq10.loyalty_score, sq10.pattern_score, sq10.rental_gap_score, sq10.customer_health_score, sq10.probability_score,
    sq10.composite_score,sq10.segmentation, MAX(r5.rental_date)::date AS last_rental_date,
    SUM(p2.amount) AS total_spent, COUNT(DISTINCT r5.rental_id) AS total_rentals, tc1.name AS top_category1, tc2.name AS top_category2,
    CASE
        WHEN sq10.segmentation = 'Champions'
            THEN 'Exclusive loyalty rewards (early access to new releases)'
        WHEN sq10.segmentation = 'At Risk Loyalist'
            THEN 'Offer: We Miss you. 25% Offer'
        WHEN sq10.segmentation = 'Rising Stars'
            THEN 'New release promotions + free rental'
        WHEN sq10.segmentation = 'Casual Viewers'
            THEN 'Budget bundle packages'
        ELSE
            'Win-back trial offer'
        END AS recommended_offer,
    CASE
        WHEN segmentation = 'Champions'
            THEN 15
        WHEN segmentation = 'At Risk Loyalist'
            THEN 12
        WHEN segmentation = 'Rising Stars'
            THEN 10
        WHEN segmentation = 'Casual Viewers'
            THEN 7
        ELSE 5  -- Inactive segment
        END AS max_bid_price
FROM (
    SELECT rs.customer_id, rs.recency_score, frequency_score, ms.monetary_score,
    cl.loyalty_score, sp.pattern_score, rga.rental_gap_score,
    rs.recency_score + frequency_score + ms.monetary_score + cl.loyalty_score AS customer_health_score,
    sp.pattern_score + rga.rental_gap_score AS probability_score,
    (rs.recency_score + frequency_score + ms.monetary_score + cl.loyalty_score ) * (sp.pattern_score + rga.rental_gap_score) AS composite_score,
    CASE
        WHEN rs.recency_score + frequency_score + ms.monetary_score + cl.loyalty_score >= 80
            AND sp.pattern_score + rga.rental_gap_score >=80
                THEN 'Champions'
        WHEN rs.recency_score + frequency_score + ms.monetary_score + cl.loyalty_score >= 70
            AND sp.pattern_score + rga.rental_gap_score < 60
                THEN 'At Risk Loyalist'
        WHEN rs.recency_score + frequency_score + ms.monetary_score + cl.loyalty_score BETWEEN 60 AND 79
            AND sp.pattern_score + rga.rental_gap_score >= 70
                THEN 'Rising Stars'
        WHEN rs.recency_score + frequency_score + ms.monetary_score + cl.loyalty_score < 60
            AND sp.pattern_score + rga.rental_gap_score >= 50
                THEN 'Casual Viewers'
        ELSE
            'Inactive'
        END AS segmentation
    FROM recency_Score rs
    INNER JOIN frequency_score fs ON rs.customer_id = fs.customer_id
    INNER JOIN monetary_score ms ON rs.customer_id = ms.customer_id
    INNER JOIN category_loyalty cl ON rs.customer_id = cl.customer_id
    INNER JOIN seasonal_pattern sp ON rs.customer_id = sp.customer_id
    INNER JOIN rental_gap_analysis rga ON rs.customer_id = rga.customer_id
    ORDER BY 1 ASC
) sq10
INNER JOIN rental r5 ON sq10.customer_id = r5.customer_id
INNER JOIN payment p7 ON r5.rental_id = p7.rental_id
INNER JOIN payment p2 ON r5.rental_id = p2.rental_id
INNER JOIN customer c5 ON sq10.customer_id = c5.customer_id
INNER JOIN top_cat1 tc1 ON sq10.customer_id = tc1.customer_id
INNER JOIN top_cat2 tc2 ON sq10.customer_id = tc2.customer_id
WHERE r5.return_date IS NOT NULL AND (r5.rental_date BETWEEN '01-01-2005' AND '12-31-2005')
GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,tc1.name, tc2.name
ORDER BY sq10.composite_score DESC
)
--Main query with added budget constraint
SELECT *
FROM (
    SELECT *,
    SUM(ac.max_bid_price) OVER (ORDER BY ac.composite_score DESC, customer_id ASC) AS cm_budget
    FROM aggregation_cte ac
)
WHERE cm_budget <= 50000;
