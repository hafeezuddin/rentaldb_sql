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
Data Scope: January 1 - December 31,2005 only. Consider both paid and unpaid rentals */

--PARAM CTE to filter rentals in 2005
WITH param_cte AS (SELECT DATE '2005-01-01' AS analysis_period_start_date_2005,
                          DATE '2005-12-31' AS analysis_period_end_date_2005),
--Base CTE to map customers to their rental information, filtered to 2005 data
     rental_info AS (SELECT r.customer_id,
                            r.rental_id,
                            r.rental_date::date,
                            f.film_id,
                            f.replacement_cost,
                            f.rental_rate,
                            p.amount                                                              AS rental_paid,
                            row_number() over (PARTITION BY r.customer_id ORDER BY r.rental_date) AS rank_based_date
                     FROM rental r
                              JOIN inventory i ON r.inventory_id = i.inventory_id
                              LEFT JOIN payment p ON r.rental_id = p.rental_id
                         --Replace LEFT JOIN with INNER JOIN in order to consider only paid rental information for analysis
                              JOIN film f ON i.film_id = f.film_id
                              CROSS JOIN param_cte pc
                     WHERE r.rental_date BETWEEN pc.analysis_period_start_date_2005 AND pc.analysis_period_end_date_2005),

--This CTE calculates total amount spent by each customer in the year 2005
     total_spent AS (SELECT ri.customer_id, SUM(ri.rental_paid) AS total_rental_by_customer
                     FROM rental_info ri
                     GROUP BY ri.customer_id),
--This CTE calculates rental frequency of the customer.
     -- Frequency is calculated by considering rentals and no.of months the customer is active.
     rental_frequency_of_each_customer AS (SELECT ri.customer_id,
                                                  COUNT(DISTINCT ri.rental_id) /
                                                  COUNT(distinct EXTRACT(MONTH FROM ri.rental_date)) AS frequency_of_rentals
                                           FROM rental_info ri
                                           GROUP BY ri.customer_id),
--CTE calculates no.of premium films rented by each customer (Also used in calculation of % of premium mix)
     premium_rentals_per_customer AS (SELECT ri.customer_id, COUNT(*) AS premium_rentals
                                      FROM rental_info ri
                                      WHERE ri.replacement_cost > 20
                                      GROUP BY ri.customer_id),

--CTE calculates total rentals (premium and standard) (Also used in calculation of % of premium mix)
     total_rentals AS (SELECT ri.customer_id, COUNT(DISTINCT ri.rental_id) AS total_rentals
                       FROM rental_info ri
                       GROUP BY ri.customer_id),

--This CTE calculates percentage of premium rentals share from his total rentals for each customer.
     percent_mix AS (SELECT tr.customer_id,
                            ROUND((prpc.premium_rentals::numeric / NULLIF(tr.total_rentals, 0)) * 100,
                                  2) AS premium_percent
                     FROM total_rentals tr
                              JOIN premium_rentals_per_customer prpc ON tr.customer_id = prpc.customer_id),

--This CTE Tags customer as Retained and non-retained based on criteria defined in the business requirement (2nd rental within 90 days)
     --Window functions are used to filter and calculate difference between first and second rental
     retention AS (SELECT t4.customer_id,
                          t4.first_rental_date,
                          t4.next_rental_date,
                          CASE
                              WHEN t4.next_rental_date - t4.first_rental_date < 90 THEN 'Retained'
                              ELSE 'Not Retained'
                              END AS retention_status
                   FROM (SELECT ri.customer_id,
                                ri.rental_date                                             AS first_rental_date,
                                LEAD(ri.rental_date)
                                OVER (PARTITION BY ri.customer_id ORDER BY ri.rental_date) AS next_rental_date,
                                ri.rank_based_date
                         FROM rental_info ri
                         WHERE rank_based_date <= 2) t4
                   WHERE t4.rank_based_date = 1),
--This CTE aggregates metrics
     customer_categorization AS (SELECT t1.customer_id,
                                        t1.first_rental_date,
                                        ts.total_rental_by_customer,
                                        rfec.frequency_of_rentals,
                                        pm.premium_percent,
                                        re.retention_status,
                                        CASE
                                            WHEN t1.replacement_cost > 20 THEN 'Premium Start'
                                            ELSE 'Standard Start'
                                            END AS start_cat
                                 FROM (SELECT ri.customer_id, ri.rental_date AS first_rental_date, ri.replacement_cost
                                       FROM rental_info ri
                                       WHERE ri.rank_based_date = 1) t1
                                          JOIN total_spent ts ON t1.customer_id = ts.customer_id
                                          JOIN rental_frequency_of_each_customer rfec
                                               ON t1.customer_id = rfec.customer_id
                                          JOIN percent_mix pm ON t1.customer_id = pm.customer_id
                                          JOIN retention re ON t1.customer_id = re.customer_id)
--Main query groups customer and derive required metrics from aggregated metrics CTE
SELECT cc.start_cat,
       COUNT(distinct cc.customer_id)                                                      AS no_of_customers,
       SUM(cc.total_rental_by_customer)                                                    AS total_amount_spent,
       ROUND(SUM(cc.total_rental_by_customer) /
             NULLIF(COUNT(distinct cc.customer_id), 0))                                    AS average_spent_per_customer,
       ROUND(AVG(cc.frequency_of_rentals), 2)                                              AS avg_frequency,
       ROUND(AVG(cc.premium_percent), 2)                                                   AS premium_mix,
       COUNT(CASE WHEN retention_status = 'Retained' THEN 1 END)                           AS retained_customers
FROM customer_categorization cc
GROUP BY cc.start_cat;
