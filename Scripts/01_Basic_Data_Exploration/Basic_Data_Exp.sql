/*
  Combined Basic Data Exploration queries
  This file concatenates the small scripts from:
    - 001_list_tables_and_address_columns
    - 002_customer_sample
    - 003_total_counts
    - 004_customer_full_names
    - 005_customer_full_names

  License: MIT (see /LICENSE)
*/

-- ===== 001_list_tables_and_address_columns =====
/* 001 - List tables and address columns */
-- List all tables in public schema
SELECT * 
FROM information_schema.tables 
WHERE table_schema = 'public';

-- Retrieve column names and data types for the 'address' table
SELECT column_name,
    data_type
FROM information_schema.columns
WHERE table_name = 'address'
    AND table_schema = 'public';

-- ===== 002_customer_sample =====
/* 002 - Customer sample */
SELECT c.customer_id, c.first_name, c.last_name, c.email
FROM customer c
ORDER BY c.customer_id
LIMIT 5;

-- ===== 003_total_counts =====
/* 003 - Total distinct customers, films, rentals (subquery + CTE versions) */
-- Subquery version
SELECT 
  (SELECT COUNT(DISTINCT c.customer_id) FROM customer c) AS total_customers,
  (SELECT COUNT(DISTINCT f.film_id) FROM film f) AS total_films,
  (SELECT COUNT(DISTINCT r.rental_id) FROM rental r) AS total_rentals; --Includes paid and unpaid rentals

-- CTE + CROSS JOIN version` 
WITH 
  total_customers AS (
    SELECT COUNT(DISTINCT c.customer_id) AS total_customers FROM customer c
  ),
  total_films AS (
    SELECT COUNT(DISTINCT f.film_id) AS total_films FROM film f
  ),
  total_rentals AS (
    SELECT COUNT(DISTINCT r.rental_id) AS total_rentals FROM rental r --Includes paid and unpaid rentals
  )
SELECT * FROM total_customers CROSS JOIN total_films CROSS JOIN total_rentals;

-- ===== 004_customer_full_names =====
/* 004 - Customer full names and emails */
SELECT CONCAT(c.first_name, ' ', c.last_name) AS full_name,
    c.email
FROM customer c
ORDER BY c.first_name
LIMIT 100;


-- ===== 005_customer_full_names =====
/* Top 10 customers by rentals, their locations and last rental date */
EXPLAIN ANALYZE
SELECT c.customer_id,
    CONCAT(c.first_name,' ', c.last_name) AS full_name,
    ci.city,
    DATE_TRUNC('DAY', MAX(r.rental_date))::date AS latest_rental_date,
    COUNT(DISTINCT r.rental_id) AS total_rentals --Includes paid and unpaid rentals
FROM customer c
    INNER JOIN rental r ON c.customer_id = r.customer_id
    INNER JOIN address a ON c.address_id = a.address_id
    INNER JOIN city ci on a.city_id = ci.city_id
GROUP BY 1,2,3
ORDER BY total_rentals DESC
LIMIT 10;

