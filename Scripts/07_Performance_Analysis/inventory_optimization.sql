/* The Operations team needs to reduce inventory costs while maintaining customer satisfaction. 
 They want data-driven recommendations on which films to keep, which to acquire more copies of, and which to phase out.
 
 Business Questions:
 "Which films give us the best return on our inventory investment?"
 "Are we over-invested in some films and under-invested in others?"
 "When do we need more copies available to meet demand?"
 "What's the optimal inventory mix for maximum profitability?"
 
 Analytical Framework:
 
 Metric 1: Film Profitability Score
 Calculate return on inventory investment for each film.
 Components:
 Revenue per Copy = Total film revenue / Number of copies
 Cost Recovery Multiple = Total revenue / Total replacement cost
 Rental Efficiency = Rentals per copy per month
 
 Metric 2: Demand Patterns & Seasonality
 Identify when and how films are rented.
 Components:
 Monthly Rental Patterns - Peak demand periods
 Rental Duration Analysis - How long films stay out
 Copy Utilization Rate - How intensely each copy is used
 
 Film Tiering System:
 Tier 1: "Workhorses" - High utilization, high ROI
 Tier 2: "Sleepers" - Low utilization but profitable when rented
 Tier 3: "Opportunities" - High demand, need more copies
 Tier 4: "Cost Centers" - Expensive but rarely rented
 Tier 5: "Underperformers" - Low cost but also low usage
 
 Tier Classification Framework
 
 Tier 1: "Workhorses" - High Utilization, High ROI
 Criteria:
 Revenue per copy > 75th percentile
 Cost recovery multiple > 3.0
 Average monthly rentals per copy > 2
 Action: Maintain current copies, monitor for wear
 
 Tier 2: "Sleepers" - Low Utilization but Profitable
 Criteria:
 Revenue per copy > 60th percentile
 Cost recovery multiple > 2.0
 Average monthly rentals per copy < 1.5
 Action: Keep but don't expand, potential for promotion
 
 Tier 3: "Opportunities" - High Demand, Need More Copies
 Criteria:
 Peak month concentration > 30% (high seasonal demand)
 Revenue per copy > 50th percentile
 Current copies < 3 (undersupplied)
 Action: Increase copy count by 1-2 copies
 
 Tier 4: "Cost Centers" - Expensive but Rarely Rented
 Criteria:
 Replacement cost > 75th percentile
 Cost recovery multiple < 1.5
 Average monthly rentals per copy < 1
 Action: Phase out, reduce to 1 copy
 
 Tier 5: "Underperformers" - Low Cost, Low Usage
 Criteria:
 Revenue per copy < 25th percentile
 Cost recovery multiple < 1.0
 Average monthly rentals per copy < 0.5
 Action: Remove excess copies, keep minimum only
 
 Required Deliverables:
 Film-tier recommendations with specific copy count changes
 Expected financial impact of optimization
 */
--CTE to retrieve core metrics for each film (#Integrated)
WITH film_data AS (
    SELECT f.film_id, f.replacement_cost, f.title,
        COUNT(i.inventory_id) AS no_of_copies_avilable,
        SUM(p.amount) as total_revenue_generated,
        ROUND(SUM(p.amount) / COUNT(i.inventory_id), 2) AS revenue_per_copy,
        ROUND(SUM(p.amount) / f.replacement_cost, 2) AS cost_recovery_multiple
    FROM film f
        INNER JOIN inventory i ON f.film_id = i.film_id
        INNER JOIN rental r ON i.inventory_id = r.inventory_id
        INNER JOIN payment p ON r.rental_id = p.rental_id
    WHERE r.return_date IS NOT NULL
        AND r.rental_date BETWEEN '01-01-2005' AND '12-31-2005'
    GROUP BY 1,2,3
    ORDER BY 1 ASC
),
--CTE to retrieve Monthly film rental patterns (#Integrated)
rentals_monthly AS (
    SELECT f.film_id, f.title,
        EXTRACT('Month' FROM r.rental_date) AS month,
        COUNT(*) AS rentals
    FROM film f
        INNER JOIN inventory i ON f.film_id = i.film_id
        INNER JOIN rental r ON i.inventory_id = r.inventory_id
        INNER JOIN payment p ON r.rental_id = p.rental_id
    WHERE r.return_date IS NOT NULL
        AND r.rental_date BETWEEN '01-01-2005' AND '12-31-2005'
    GROUP BY 1,2,3
    ORDER BY 1
),
--CTE to identify Peak Demand Periods (#Integrated)
peak_period AS (
    SELECT *
    FROM (
            SELECT sq3.film_id,
                sq3.title,
                sq3.month,
                sq3.concentration,
                ROW_NUMBER() OVER (
                    PARTITION BY sq3.film_id
                    ORDER BY sq3.concentration DESC
                ) AS row_number
            FROM (
                    SELECT *,
                        SUM(sq1.rentals) OVER (PARTITION BY sq1.film_id) AS total_rentals,
                        ROUND(
                            (
                                sq1.rentals / SUM(sq1.rentals) OVER (PARTITION BY sq1.film_id)
                            ) * 100,
                            2
                        ) AS concentration
                    FROM (
                            SELECT f.film_id,
                                f.title,
                                EXTRACT(
                                    'Month'
                                    FROM r.rental_date
                                ) AS month,
                                COUNT(*) AS rentals
                            FROM film f
                                INNER JOIN inventory i ON f.film_id = i.film_id
                                INNER JOIN rental r ON i.inventory_id = r.inventory_id
                                INNER JOIN payment p ON r.rental_id = p.rental_id
                            WHERE r.return_date IS NOT NULL
                                AND r.rental_date BETWEEN '01-01-2005' AND '12-31-2005'
                            GROUP BY 1,
                                2,
                                3
                            ORDER BY 1
                        ) sq1
                ) sq3
        ) sq4
    WHERE sq4.row_number = 1
),
--CTE for Rental Duration Analysis. (#Integrated)
rental_duration_analysis AS (
    SELECT sq2.film_id,
        ROUND(AVG(sq2.rental_duration), 2) AS average_rental_duration
    FROM (
            SELECT f.film_id,
                i.inventory_id,
                r.rental_id,
                r.rental_date::date,
                r.return_date::date,
                (r.return_date::date - r.rental_date::date) AS rental_duration
            FROM film f
                INNER JOIN inventory i ON f.film_id = i.film_id
                INNER JOIN rental r ON i.inventory_id = r.inventory_id
                INNER JOIN payment p ON r.rental_id = p.rental_id
            WHERE r.return_date IS NOT NULL
                AND r.rental_date BETWEEN '01-01-2005' AND '12-31-2005'
            ORDER BY f.film_id ASC
        ) sq2
    GROUP BY sq2.film_id
),
--CTE for Copy utilization (#Integrated)
copy_utilization AS (
    SELECT sq5.film_id,
        ROUND(AVG(sq5.rentals), 2) AS avg_monthly_rentals_per_copy
    FROM (
            SELECT f.film_id,
                f.title,
                i.inventory_id,
                EXTRACT(
                    'Month'
                    FROM r.rental_date
                ) AS month,
                COUNT(*) AS rentals
            FROM film f
                INNER JOIN inventory i ON f.film_id = i.film_id
                INNER JOIN rental r ON i.inventory_id = r.inventory_id
                INNER JOIN payment p ON r.rental_id = p.rental_id
            WHERE r.return_date IS NOT NULL
                AND r.rental_date BETWEEN '01-01-2005' AND '12-31-2005'
            GROUP BY 1,2,3,4
            ORDER BY 1,3,4 ASC
        ) sq5
    GROUP BY 1
)
SELECT SUM(cost_savings) AS total_cost_savings,
    SUM(revenue_potential) AS total_revenue_potential,
    SUM(net_impact) AS total_net_impact,
    -- Count films by action type
    COUNT(
        CASE
            WHEN inventory_diff < 0 THEN 1
        END
    ) AS films_to_reduce,
    COUNT(
        CASE
            WHEN inventory_diff > 0 THEN 1
        END
    ) AS films_to_expand,
    COUNT(
        CASE
            WHEN inventory_diff = 0 THEN 1
        END
    ) AS films_unchanged
    FROM (
        SELECT *,
            sq8.recommended_copies - sq8.no_of_copies_avilable AS inventory_diff,
            -- For films with reduced copies (Tiers 4 & 5)
            CASE
                WHEN sq8.recommended_copies - sq8.no_of_copies_avilable < 0 THEN ABS(
                    sq8.recommended_copies - sq8.no_of_copies_avilable
                ) * replacement_cost
                ELSE 0
            END AS cost_savings,
            -- For films with added copies (Tier 3)  
            CASE
                WHEN sq8.recommended_copies - sq8.no_of_copies_avilable > 0 THEN (
                    sq8.recommended_copies - sq8.no_of_copies_avilable
                ) * revenue_per_copy
                ELSE 0
            END AS revenue_potential,
            -- Net financial impact
            CASE
                WHEN sq8.recommended_copies - sq8.no_of_copies_avilable < 0 THEN ABS(
                    sq8.recommended_copies - sq8.no_of_copies_avilable
                ) * replacement_cost
                WHEN sq8.recommended_copies - sq8.no_of_copies_avilable > 0 THEN (
                    sq8.recommended_copies - sq8.no_of_copies_avilable
                ) * revenue_per_copy
                ELSE 0
            END AS net_impact
        FROM (
                SELECT *,
                    CASE
                        WHEN sq7.category = 'Work Horses - Maintain Copies'
                        OR sq7.category = 'Sleepers - Keep but dont expand' THEN sq7.no_of_copies_avilable
                        WHEN sq7.category = 'Opportunities -Increase by 1-2 copies' THEN sq7.no_of_copies_avilable + 1
                        WHEN sq7.category = 'Cost Centers -  Phase out'
                        OR sq7.category = 'Underperformers - Remove excess copies' THEN 1
                        WHEN sq7.category = 'TBA' THEN sq7.no_of_copies_avilable
                        ELSE 0
                    END AS recommended_copies
                FROM (
                        SELECT *,
                            CASE
                                --Tier #1
                                WHEN sq6.p_rank > 0.75
                                AND sq6.cost_recovery_multiple > 3
                                AND avg_monthly_rentals_per_copy > 2 THEN 'Work Horses - Maintain Copies' --Tier #2
                                WHEN sq6.p_rank > 0.60
                                AND sq6.cost_recovery_multiple > 2
                                AND avg_monthly_rentals_per_copy < 1.5 THEN 'Sleepers - Keep but dont expand' --Tier #3
                                WHEN sq6.concentration > 30
                                AND sq6.p_rank > 0.50
                                AND sq6.no_of_copies_avilable < 3 THEN 'Opportunities -Increase by 1-2 copies' --Tier #4
                                WHEN sq6.rep_rank > 0.75
                                AND sq6.cost_recovery_multiple < 1.5
                                AND sq6.avg_monthly_rentals_per_copy < 1 THEN 'Cost Centers -  Phase out' --Tier #5
                                WHEN sq6.rev_rank < 0.25
                                AND sq6.cost_recovery_multiple < 1.0
                                AND sq6.avg_monthly_rentals_per_copy < 0.5 THEN 'Underperformers - Remove excess copies'
                                ELSE 'TBA'
                            END AS category
                        FROM (
                                SELECT fd.film_id,
                                    fd.title,
                                    fd.no_of_copies_avilable,
                                    fd.replacement_cost,
                                    fd.revenue_per_copy,
                                    fd.cost_recovery_multiple,
                                    pd.month AS peak_month,
                                    rda.average_rental_duration,
                                    cu.avg_monthly_rentals_per_copy,
                                    pd.concentration,
                                    PERCENT_RANK() OVER (
                                        ORDER BY fd.revenue_per_copy
                                    ) AS p_rank,
                                    PERCENT_RANK() OVER (
                                        ORDER BY fd.replacement_cost
                                    ) AS rep_rank,
                                    PERCENT_RANK() OVER (
                                        ORDER BY fd.revenue_per_copy
                                    ) AS rev_rank
                                FROM film_data fd
                                    INNER JOIN peak_period pd ON fd.film_id = pd.film_id
                                    INNER JOIN rental_duration_analysis rda ON fd.film_id = rda.film_id
                                    INNER JOIN copy_utilization cu ON fd.film_id = cu.film_id
                            ) sq6
                    ) sq7
            ) sq8
    ) sq9;