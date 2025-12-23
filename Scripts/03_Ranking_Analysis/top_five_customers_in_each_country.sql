
/* Find the top 5 customers in each country by total rental amount.
For each customer, show: Country name, Customer ID and name
Total amount spent
Their rank within the country, 
Their percentage share of that country’s rental revenue */

-- CTE to retrieve customer details and rank them by amount spent within each country
WITH customer_ranks AS (
  SELECT 
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    ci.city,
    co.country,
    co.country_id,
    SUM(p.amount) AS total_spent,
    RANK() OVER (PARTITION BY co.country ORDER BY SUM(p.amount) DESC) AS rank_within_country
  FROM customer c
    INNER JOIN address a ON c.address_id = a.address_id
    INNER JOIN city ci ON a.city_id = ci.city_id
    INNER JOIN country co ON ci.country_id = co.country_id
    INNER JOIN rental r ON c.customer_id = r.customer_id
    INNER JOIN payment p ON r.rental_id = p.rental_id --Considering paid rentals
    --Considering only 2005 rentals
    WHERE r.return_date IS NOT NULL AND r.rental_date >= '2005-01-01' AND r.rental_date <= '2005-12-31'
  GROUP BY 1,2,3,4,5
),
-- CTE to calculate total rental revenue for each country for percentage share calculation
country_totals AS (
  SELECT 
    co2.country, 
    co2.country_id,
    SUM(p2.amount) AS country_total
  FROM country co2
    INNER JOIN city ci2 ON co2.country_id = ci2.country_id
    INNER JOIN address a2 ON ci2.city_id = a2.city_id
    INNER JOIN customer c2 ON a2.address_id = c2.address_id
    INNER JOIN rental r2 ON c2.customer_id = r2.customer_id
    INNER JOIN payment p2 ON r2.rental_id = p2.rental_id
  GROUP BY 1,2
)
-- Main query: Top 5 customers per country, their spend, rank, and percentage share of country revenue
SELECT 
  cr.customer_id,
  cr.customer_name,
  cr.city,
  cr.country,
  cr.total_spent,
  cr.rank_within_country,
  ct.country_total,
  ROUND((cr.total_spent / ct.country_total) * 100, 2) AS percentage_share
FROM customer_ranks cr
  INNER JOIN country_totals ct ON cr.country_id = ct.country_id
WHERE cr.rank_within_country <= 5;





--Method/Solution 2: 
-- =============================================
-- Top 5 Customers in Each Country by Total Rental Amount
-- For each customer: Country name, Customer ID, City, Total amount spent,
-- Their rank within the country, Their percentage share of that country’s rental revenue
-- =============================================

-- CTE to aggregate customer spend, country totals, rank, and share within each country
WITH customer_data AS (
  SELECT 
    c.customer_id, 
    ci.city, 
    co.country, 
    SUM(p.amount) AS total_spent, -- Total amount spent by the customer
    -- Total amount spent in the country
    --(No order by - SUM for country is calculated and is added as column with same value in all rows for that country)
    SUM(SUM(p.amount)) OVER (PARTITION BY co.country) AS country_sum,  --May not work in all databases.
    RANK() OVER (PARTITION BY co.country ORDER BY SUM(p.amount) DESC) AS rank, -- Customer's rank within the country by total spent
    ROUND((SUM(p.amount) / SUM(SUM(p.amount)) OVER (PARTITION BY co.country)) * 100, 2) AS share -- Percentage share of country revenue
  FROM payment p
    INNER JOIN rental r ON p.rental_id = r.rental_id
    INNER JOIN customer c ON r.customer_id = c.customer_id
    INNER JOIN address a ON c.address_id = a.address_id
    INNER JOIN city ci ON a.city_id = ci.city_id
    INNER JOIN country co ON ci.country_id = co.country_id
    --Considering only 2005 rentals
    WHERE r.return_date IS NOT NULL AND r.rental_date >= '2005-01-01' AND r.rental_date <= '2005-12-31'
  GROUP BY c.customer_id, ci.city, co.country
)
-- Main query: Filter top 5 customers per country and show their spend, rank, and share
SELECT 
  cd.customer_id, 
  cd.city, 
  cd.country, 
  cd.total_spent, 
  cd.country_sum, 
  cd.rank, 
  cd.share
FROM customer_data cd
WHERE cd.rank <= 5
ORDER BY cd.country, cd.rank;


