
/*Identify which film categories (like Action, Comedy, etc.) are growing the fastest month-over-month based on total rental revenue.*/
WITH cat_stats AS (
SELECT 
  cat.category_id, 
  cat.name,
  TO_CHAR(DATE_TRUNC('Month',r.rental_date),'YYYY-MM') AS month,
  SUM(p.amount) AS total_revenue
FROM category cat
INNER JOIN film_category fc ON cat.category_id = fc.category_id
INNER JOIN inventory i ON fc.film_id = i.film_id
INNER JOIN rental r ON i.inventory_id = r.inventory_id
INNER JOIN payment p ON r.rental_id = p.rental_id
WHERE r.return_date IS NOT NULL AND (r.rental_date >= '2005-01-01' AND r.rental_date <= '2005-12-31')
GROUP BY 1,2,3
ORDER BY cat.category_id
),
pmr_cal AS (
SELECT 
  cs.category_id, 
  cs.name, 
  cs.month, 
  cs.total_revenue,
  LAG(cs.total_revenue) OVER (PARTITION BY cs.category_id ORDER BY cs.month) AS pmr
  FROM cat_stats cs
),
per_change_cal AS (
  SELECT 
    pmr_cal.category_id, 
    pmr_cal.name, 
    pmr_cal.month, 
    pmr_cal.total_revenue, 
    pmr_cal.pmr,
    CASE
      WHEN pmr_cal.pmr IS NULL
        THEN 0
      ELSE
        (pmr_cal.total_revenue - pmr_cal.pmr)/pmr_cal.pmr * 100
      END AS percentage_change
  FROM pmr_cal
),
ranking_months AS (
  Select
  pcl.category_id, 
  pcl.name, 
  pcl.month, 
  pcl.total_revenue, 
  pcl.pmr,
  ROUND(pcl.percentage_change,2) AS percentage_change,
  RANK() OVER (PARTITION BY pcl.month ORDER BY ROUND(pcl.percentage_change,2) DESC) AS ranking
FROM per_change_cal pcl
)
SELECT * FROM ranking_months rm
WHERE rm.percentage_change !=0 AND rm.ranking=1;


 