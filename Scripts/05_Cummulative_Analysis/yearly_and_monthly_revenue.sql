/* Yearly and Year/Month revenue */
-- Yearly revenue
SELECT 
  EXTRACT(YEAR FROM p.payment_date) AS year,
  CONCAT(SUM(p.amount), '$') AS revenue
FROM payment p
GROUP BY year
ORDER BY year;

-- Revenue by Year and Month
SELECT 
    TO_CHAR(DATE_TRUNC('Year', p.payment_date), 'YYYY') AS Year,
    TO_CHAR(DATE_TRUNC('Month', p.payment_date), 'MM') AS Month,
    SUM(p.amount) AS total_revenue
FROM payment p
GROUP BY 1,2
ORDER BY Year, Month;