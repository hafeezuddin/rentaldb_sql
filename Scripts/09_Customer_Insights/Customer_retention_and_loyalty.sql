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
                --Analysis is being done on historical data till 2005 end on 01-01-2006.
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
),


---Metric #2 Calculation:
 /** Metric 2: Churn Risk Assessment:
 Months since last rental
 Rental frequency decline rate
 Payment pattern changes **/
Churn_Risk_Assessment AS (
    SELECT cvs.customer_id,
        cvs.days_since_last_rental/30 AS months_since_last_rental,
        
        CASE
            WHEN cvs.recency_quartile >=1 THEN 1 ELSE 0
        END as recency_flag,

        CASE
            WHEN cvs.spent_quartile = 1 THEN 1 ELSE 0
        END as spent_flag,

        CASE
            WHEN cvs.total_rentals_quartile = 1 THEN 1 ELSE 0
        END AS total_rentals_flag    

    FROM customer_value_scoring cvs
),

pre_aggregator AS (
SELECT cvs.customer_id,
    cvs.latest_rental_date,
    cvs.days_since_last_rental,
    cra.months_since_last_rental,
    cvs.life_time_rentals,
    cvs.total_spent,
    cvs.average_active_month_rentals,
    cvs.categorization,
    cvs.program,
    fhr.count AS first_half_rentals,
    shr.count AS second_half_rentals,
    ROUND(((shr.count - fhr.count)::numeric/cvs.life_time_rentals)*100,2) AS rental_change_percentage,
    cra.recency_flag,
    cra.spent_flag,
    cra.total_rentals_flag,
    (cra.recency_flag + cra.spent_flag + cra.total_rentals_flag) AS risk_score,
    CASE
        WHEN (cra.recency_flag + cra.spent_flag + cra.total_rentals_flag) >=2
            THEN 'High risk'
        WHEN (cra.recency_flag + cra.spent_flag + cra.total_rentals_flag) =1
            THEN 'Medium risk'
        WHEN (cra.recency_flag + cra.spent_flag + cra.total_rentals_flag) = 0
            THEN 'Low Risk'
        ELSE
            'TBA'
    END AS risk_cat                    
FROM customer_value_scoring cvs
INNER JOIN First_half_Rentals fhr ON cvs.customer_id = fhr.customer_id
INNER JOIN second_half_Rentals shr ON cvs.customer_id = shr.customer_id
INNER JOIN Churn_Risk_Assessment cra ON cvs.customer_id = cra.customer_id
),
favs_cat AS (
  SELECT sq2.categorization, sq2.name, sq2.cat_rentals, sq2.top_cat
  FROM
    (
    SELECT sq1.categorization, sq1.name, COUNT(*) AS cat_rentals,
    ROW_NUMBER() OVER (PARTITION BY sq1.categorization ORDER BY COUNT(*) DESC) AS top_cat
        FROM
            (
            SELECT pa.customer_id, pa.categorization,cat.name
            FROM
            pre_aggregator pa
            INNER JOIN rental r ON pa.customer_id = r.customer_id
            INNER JOIN inventory i ON r.inventory_id = i.inventory_id
            INNER JOIN film_category fc ON i.film_id = fc.film_id
            INNER JOIN category cat ON fc.category_id = cat.category_id
            )sq1
        GROUP BY 1,2
    )sq2
    WHERE sq2.top_cat =1    
),
fav_actors_by_segment AS 
(
      SELECT sq4.categorization, sq4.actor_name, sq4.actor_occurence, sq4.top_act
      FROM
            (  
            SELECT sq3.categorization, sq3.actor_name, COUNT(*) AS actor_occurence,
            ROW_NUMBER() OVER (PARTITION BY sq3.categorization ORDER BY COUNT(*) DESC) AS top_act
            FROM(
                SELECT pa.customer_id, pa.categorization, CONCAT(a.first_name,' ', a.last_name) AS actor_name
                    FROM pre_aggregator pa
                INNER JOIN rental r ON pa.customer_id = r.customer_id
                INNER JOIN inventory i ON r.inventory_id = i.inventory_id
                INNER JOIN film_actor fa ON i.film_id = fa.film_id
                INNER JOIN actor a ON fa.actor_id = a.actor_id
                ) sq3
                GROUP BY 1,2
            )sq4
       WHERE sq4.top_act =1     
),
monthly_category_preferences_by_segment AS
(
   SELECT pa.customer_id, pa.categorization
   FROM pre_aggregator pa
)
SELECT * FROM monthly_category_preferences_by_segment; 