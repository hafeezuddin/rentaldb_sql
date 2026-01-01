/*Business case: 2005 Customer Onboarding & Premium Film Strategy

Background: Using only 2005 data, we need to determine if customers who started with premium films within the year became more valuable during that same year.
Your Mission: Analyze the relationship between a customer's first rental quality and their 2005 spending patterns.

Metric 1: 2005 Customer Value by Starting Tier
Objective: Compare the 2005 spending of customers based on their first rental's film quality.
Business Question: "Within their first year, do customers who start with premium films spend more than those who start with standard films?"
Calculation:

    First Rental Quality: Categorize by the replacement cost of their first 2005 rental:
        'Premium Start' (replacement_cost >= $20)
        'Standard Start' (replacement_cost < $20)
         2005 Customer Value: Total 2005 payments from their first rental to Dec 31, 2005
Required Analysis: Compare average 2005 spending between Premium-start vs Standard-start customers.


Metric 2: 2005 Engagement & Quality Progression
Objective: Analyze if starting with premium films leads to different rental behaviors within 2005.
Business Question: "Do premium-start customers rent more frequently and continue choosing premium films?"

Calculation:
    90-Day Retention: % of customers who rented again within 90 days of their first 2005 rental
    2005 Rental Frequency: Total 2005 rentals per customer
    
    Premium Mix: % of each customer's 2005 rentals that are premium films

Strategic Deliverable (2005 Analysis):
A focused analysis answering:
    Short-term ROI: Do premium-start customers generate enough additional 2005 revenue to justify the higher inventory cost?
    Engagement Pattern: Do they rent more frequently within their first year?
    Quality Preference: Do they develop a taste for premium content?
Data Scope: January 1 - December 31, 2005 only. Consider both paid and unpaid rentals */

--CTE to filter who started rentals with premium films (1st ever rental)
WITH customer_first_rental_analysis AS (
SELECT sq1.customer_id, 
    sq1.rental_date, 
    CASE
        WHEN sq1.replacement_cost >= 20
            THEN 'Premium Start'
        ELSE
            'Standard start'
        END AS first_rental_quality
FROM (
        SELECT c.customer_id, r.rental_date, f.title, f.replacement_cost,
            row_number() OVER (PARTITION BY c.customer_id ORDER BY c.customer_id, r.rental_date ASC) AS first_rental
            FROM customer c
        INNER JOIN rental r ON c.customer_id = r.customer_id
        INNER JOIN inventory i ON r.inventory_id = i.inventory_id
        INNER JOIN film f ON i.film_id = f.film_id
        WHERE r.return_date IS NOT NULL AND (r.rental_date BETWEEN '01-01-2005' AND '12-31-2005')
        ) sq1
WHERE sq1.first_rental =1
),

--CTE to calculate total spent by customer
total_spent AS (
    SELECT c.customer_id, SUM(p.amount) AS total_spent
    FROM customer c
    INNER JOIN rental r ON c.customer_id = r.customer_id
    INNER JOIN payment p ON r.rental_id = p.rental_id
    WHERE r.return_date IS NOT NULL AND (r.rental_date BETWEEN '01-01-2005' AND '12-31-2005')
    GROUP BY 1
),

--CTE to calculate customer who ordered in 90 days from their 1st order.
ret AS (
  SELECT sq2.customer_id, sq2.rental_date::date, sq2.rental_rank
        FROM (
        SELECT c.customer_id, r.rental_date, f.title, f.replacement_cost,
            row_number() OVER (PARTITION BY c.customer_id ORDER BY c.customer_id, r.rental_date ASC) AS rental_rank
            FROM customer c
        INNER JOIN rental r ON c.customer_id = r.customer_id
        INNER JOIN inventory i ON r.inventory_id = i.inventory_id
        INNER JOIN film f ON i.film_id = f.film_id
        WHERE r.return_date IS NOT NULL AND (r.rental_date BETWEEN '01-01-2005' AND '12-31-2005')
        ) sq2  
),
cal1 AS (
SELECT ret.customer_id, ret.rental_date, ret.rental_rank,
LEAD(ret.rental_date) OVER (PARTITION BY ret.customer_id ORDER BY ret.customer_id, ret.rental_date ASC) AS next_rental
FROM ret AS ret
),
retention_metric AS (
SELECT sq3.customer_id, sq3.retention_status FROM (
    SELECT cal1.customer_id, cal1.rental_date, cal1.next_rental,
    CASE
        WHEN cal1.next_rental - cal1.rental_date < 90
            THEN 'Retained'
        ELSE
            'Not Retained'
        END AS retention_status
    FROM cal1
    WHERE cal1.rental_rank =1
) sq3
),
rental_frequency AS (
    SELECT c.customer_id, COUNT(DISTINCT r.rental_id) AS total_rentals
    FROM customer c
    INNER JOIN rental r ON c.customer_id = r.customer_id
    WHERE r.return_date IS NOT NULL AND (r.rental_date BETWEEN '01-01-2005' AND '12-31-2005')
    GROUP BY 1
),
premium_rental AS (
    SELECT c.customer_id, COUNT(DISTINCT r.rental_id) AS premium_rentals
    FROM customer c
    INNER JOIN rental r ON c.customer_id = r.customer_id
    INNER JOIN inventory i ON r.inventory_id = i.inventory_id
    INNER JOIN film f ON i.film_id = f.film_id
    WHERE f.replacement_cost > 20
    GROUP BY 1
)
--Main query to generate executive summary insights
SELECT 
    first_rental_quality,
    COUNT(*) as customer_count,
    ROUND(AVG(total_spent), 2) as avg_customer_value,
    ROUND(AVG(total_rentals), 2) as avg_rental_frequency,
    ROUND(AVG(premium_mix_percentage), 2) as avg_premium_mix,
    ROUND(100.0 * SUM(CASE WHEN retention_90_days = 'Retained' THEN 1 ELSE 0 END) / COUNT(*), 2) as retention_rate_pct
    FROM (SELECT cfra.customer_id, cfra.rental_date,
            cfra.first_rental_quality ,
            ts.total_spent, 
            rm.retention_status AS retention_90_days, 
            rf.total_rentals, 
            pr.premium_rentals,
            ROUND((pr.premium_rentals::numeric/rf.total_rentals) * 100,2) AS premium_mix_percentage
        FROM customer_first_rental_analysis cfra
        INNER JOIN total_spent ts ON cfra.customer_id = ts.customer_id
        INNER JOIN rental_frequency rf ON cfra.customer_id = rf.customer_id
        INNER JOIN premium_rental pr ON cfra.customer_id = pr.customer_id
        LEFT JOIN retention_metric rm ON cfra.customer_id = rm.customer_id
)
GROUP BY first_rental_quality
ORDER BY first_rental_quality;
