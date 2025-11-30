/* Business Problem: Customer Retention & Loyalty Program Optimization
 Business Context:The DVD rental company is facing increased competition from streaming services. 
 They want to launch a targeted loyalty program to retain their most valuable customers and win back at-risk customers.
 
 Business Questions:
 "Who are our most valuable customers and what are their rental patterns?"
 "Which customers are at risk of churning based on declining activity?"
 "What film categories and actors drive the most customer loyalty?"
 "How should we segment customers for targeted marketing campaigns?"
 
 Available Data (Sakila Schema):
 Customer Demographics: customer table with join dates
 Rental History: rental table with timestamps
 Payment Data: payment table for customer lifetime value
 Film Preferences: film, film_category, category tables
 Actor Preferences: film_actor, actor tables
 Store Locations: store, address tables for geographic patterns
 
 Analytical Framework:
 Metric 1: Customer Value Scoring:
 Recency, Frequency, Customer Lifetime Value calculation, 
 Monetary (RFM) analysis - Based on total_money_spent, total_rentals, days_since_last_rental
 Rental frequency trends over time
 
 Metric 2: Churn Risk Assessment:
 Months since last rental
 Rental frequency decline rate
 Payment pattern changes
 
 Metric 3: Content Preference Analysis:
 Favorite categories per customer segment
 Actor popularity across value tiers
 Seasonal rental patterns
 
 Required Deliverables:
 Customer segmentation with clear value tiers
 Churn risk scoring with at-risk customer list
 Personalized film recommendations for each segment
 Loyalty program structure with tier-specific benefits
 Expected ROI for retention campaigns */
--CTE to calculate metric #1
WITH customer_value_scoring AS (
    SELECT *,
        CASE
            WHEN sq1.recency_quartile = 4
            AND sq1.total_rentals_quartile = 4
            AND sq1.spent_quartile = 4 THEN 'Champions'
            WHEN sq1.recency_quartile = 1 THEN 'At Risk'
            WHEN sq1.recency_quartile >= 3
            AND sq1.total_rentals_quartile >= 3
            AND sq1.spent_quartile <= 2 THEN 'Loyal - Low Spend'
            WHEN sq1.spent_quartile = 4
            AND sq1.recency_quartile <= 2 THEN 'Big Spenders - Less Active'
            ELSE 'Occasional Renters'
        END AS categorization,
        CASE
            WHEN sq1.recency_quartile = 4
            AND sq1.total_rentals_quartile = 4
            AND sq1.spent_quartile = 4 THEN 'Premium loyalty tier, exclusive offers'
            WHEN sq1.recency_quartile = 1 THEN 'Win-back campaigns, "We miss you" offers'
            WHEN sq1.recency_quartile >= 3
            AND sq1.total_rentals_quartile >= 3
            AND sq1.spent_quartile <= 2 THEN 'Upsell campaigns, bundle offers'
            WHEN sq1.spent_quartile = 4
            AND sq1.recency_quartile <= 2 THEN 'Reactivation offers, premium content access'
            ELSE 'Standard loyalty program, discovery offers'
        END AS program
    
    FROM (
            SELECT c.customer_id,
                MAX(r.rental_date::date) AS latest_rental_date,
                --Assuming current_Date to be 12-31-2005 (Cut off date)
                --CURRENT_DATE - MAX(r.rental_date::date) AS days_since_last_rental to be used if the data us current.
                '01-01-2006' - MAX(r.rental_date::date) AS days_since_last_rental,
                
                NTILE(4) OVER (
                    ORDER BY '01-01-2006' - MAX(r.rental_date::date) DESC
                ) AS recency_quartile,

                COUNT(DISTINCT r.rental_id) AS life_time_rentals,

                NTILE(4) OVER (
                    ORDER BY COUNT(DISTINCT r.rental_id)
                ) AS total_rentals_quartile,
                SUM(p.amount) AS total_spent,

                NTILE(4) OVER (
                    ORDER BY SUM(p.amount)
                ) AS spent_quartile,

                COUNT(DISTINCT r.rental_id) / COUNT (
                    DISTINCT EXTRACT(
                        MONTH
                        FROM r.rental_date
                    )
                ) AS average_active_month_rentals

            FROM customer c
                INNER JOIN rental r ON c.customer_id = r.customer_id
                LEFT JOIN payment p ON r.rental_id = p.rental_id
            WHERE r.return_date IS NOT NULL
                AND (
                    r.rental_date BETWEEN '01-01-2005' AND '12-31-2005'
                )
                GROUP BY 1
        ) sq1
),
First_half_Rentals AS (
    (SELECT c.customer_id, COUNT(DISTINCT r.rental_id)
    FROM customer c
    INNER JOIN rental r ON c.customer_id = r.customer_id
    WHERE r.return_date IS NOT NULL AND (r.rental_date BETWEEN '01-01-2005' AND '06-30-2005')
    GROUP BY 1)
),
second_half_Rentals AS (
    SELECT c.customer_id, COUNT(DISTINCT r.rental_id)
    FROM customer c
    INNER JOIN rental r ON c.customer_id = r.customer_id
    WHERE r.return_date IS NOT NULL AND (r.rental_date BETWEEN '07-01-2005' AND '12-31-2005')
    GROUP BY 1
)
SELECT cvs.customer_id,
    cvs.latest_rental_date,
    cvs.days_since_last_rental,
    cvs.life_time_rentals,
    cvs.total_spent,
    cvs.average_active_month_rentals,
    cvs.categorization,
    cvs.program,
    fhr.count AS first_half_rentals,
    shr.count AS second_half_rentals,
    ROUND(((shr.count - fhr.count)::numeric/cvs.life_time_rentals)*100,2) AS rental_change_percentage
FROM customer_value_scoring cvs
INNER JOIN First_half_Rentals fhr ON cvs.customer_id = fhr.customer_id
INNER JOIN second_half_Rentals shr ON cvs.customer_id = shr.customer_id;