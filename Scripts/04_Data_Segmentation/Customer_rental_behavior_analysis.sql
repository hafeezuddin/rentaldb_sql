/* Business Requirement: ®
 Objective: Analyze customer rental patterns to identify different behavioral segments
 
 Specific Requirements:
 Find each customer's total rentals and total spending
 Calculate their average days between rentals (engagement frequency)
 Identify their most rented film category
 Flag if they've rented in the last 30 days (active status)
 
 Segment customers into:
 Customers who rent frequently AND spend a lot (top 25% in both metrics) 
 Customers who rent frequently but don't spend much (top 25% rentals, but lower spending)
 Customers who don't rent often but spend a lot when they do (lower rentals, but top 25% spending)
 Everyone else: Customers who rent infrequently AND don't spend much*/
--CTE to calculate basic metrics
WITH customer_metrics AS (
    SELECT c.customer_id,
        COUNT(DISTINCT r.rental_id) AS total_rentals,
        PERCENT_RANK() OVER (
            ORDER BY SUM(p.amount)
        ) AS p_total_spent,
        SUM(p.amount) AS total_spent,
        PERCENT_RANK() OVER (
            ORDER BY COUNT(DISTINCT r.rental_id)
        ) AS p_total_rentals
    FROM customer c
        INNER JOIN rental r ON c.customer_id = r.customer_id
        INNER JOIN payment p ON r.rental_id = p.rental_id
    GROUP BY 1
),
derived_metrics AS (
    SELECT DISTINCT cm.customer_id,
        DATE_TRUNC('Day', r2.rental_date)::date AS date_of_rental
    FROM customer_metrics cm
        INNER JOIN rental r2 ON cm.customer_id = r2.customer_id
    ORDER BY cm.customer_id ASC,
        DATE_TRUNC('Day', r2.rental_date)::date DESC
),
rental_days_diff AS (
    SELECT dm.customer_id,
        dm.date_of_rental,
        LAG(dm.date_of_rental) OVER (
            PARTITION BY dm.customer_id
            ORDER BY dm.date_of_rental DESC
        ),
        CASE
            WHEN LAG(dm.date_of_rental) OVER (
                PARTITION BY dm.customer_id
                ORDER BY dm.date_of_rental DESC
            ) IS NULL THEN 0
            ELSE LAG(dm.date_of_rental) OVER (
                PARTITION BY dm.customer_id
                ORDER BY dm.date_of_rental DESC
            ) - dm.date_of_rental
        END AS diff
    FROM derived_metrics dm
),
avg_engagement_frequency AS (
    SELECT rdd.customer_id,
        ROUND(AVG(rdd.diff), 2) AS engagement_frequency
    FROM rental_days_diff rdd
    GROUP BY 1
),
most_rented_category AS (
    SELECT x.customer_id,
        x.name
    FROM (
            SELECT cm.customer_id,
                cat.name,
                COUNT(*) AS rented_times,
                ROW_NUMBER() OVER (
                    PARTITION BY cm.customer_id
                    ORDER BY count(*) DESC,
                        cat.name ASC
                ) AS ranking
            FROM customer_metrics cm
                INNER JOIN rental r3 ON cm.customer_id = r3.customer_id
                INNER JOIN inventory i ON r3.inventory_id = i.inventory_id
                INNER JOIN film_category fc ON i.film_id = fc.film_id
                INNER JOIN category cat ON fc.category_id = cat.category_id
            GROUP BY 1,
                2
            ORDER BY 1 ASC,
                rented_times DESC
        ) x
    WHERE ranking = 1
),
active_status AS (
    SELECT cm.customer_id,
        max(r4.rental_date) AS latest_rental_date,
        CASE
            WHEN (CURRENT_DATE - max(r4.rental_date::date)) <= 30 THEN 'Active'
            ELSE 'Inactive'
        END AS user_status
    FROM customer_metrics cm
        INNER JOIN rental r4 ON cm.customer_id = r4.customer_id
    GROUP BY 1
    ORDER BY 1
),
averages_counts AS (
    SELECT avg(cm.total_rentals) AS avg_rentals,
        avg(cm.total_spent) AS avg_amount
    FROM customer_metrics cm
)
SELECT cm.customer_id,
    cm.total_rentals,
    cm.p_total_rentals,
    cm.p_total_spent,
    cm.total_spent,
    aef.engagement_frequency,
    mrc.name,
    ac.user_status,
    acs.avg_rentals,
    acs.avg_amount,
    CASE
        WHEN cm.p_total_rentals >= 0.75
        AND cm.p_total_spent >= 0.75 THEN 'Frequent High Spenders'
        WHEN cm.p_total_rentals >= 0.75
        AND cm.p_total_spent < 0.75 THEN 'Frequent Low Spenders'
        WHEN cm.p_total_rentals < 0.75
        AND cm.p_total_spent >= 0.75 THEN 'Occasional High Spenders'
        ELSE 'Occasional Low Spenders'
    END AS categorization
FROM customer_metrics cm
    INNER JOIN avg_engagement_frequency aef ON cm.customer_id = aef.customer_id
    INNER JOIN most_rented_category mrc ON aef.customer_id = mrc.customer_id
    INNER JOIN active_status ac ON mrc.customer_id = ac.customer_id
    CROSS JOIN averages_counts acs
GROUP BY 1,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    9,
    10;