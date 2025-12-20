/*
  Combined Dimensions Exploration queries
  This file concatenates the small scripts from:
    - 001_distinct_categories.sql
    - 002_film_language_distribution.sql
    - 003_films_per_language.sql
    - 004_films_by_rating.sql
    - 005_films_in_each_category.sql
    - 006_small_categories.sql
    - 007_films_rented_by_category.sql

  License: MIT (see /LICENSE)
*/

-- ===== 001_distinct_categories.sql =====
/* 001 - Distinct categories */
SELECT DISTINCT c.name AS available_categories
FROM category c
ORDER BY c.name;

-- ===== 002_film_language_distribution.sql =====
/* 002 - Film language distribution */
SELECT 
  f.title AS film_name,
  l.name AS language
FROM film f
  JOIN language l ON f.language_id = l.language_id
  ORDER BY f.title ASC;

-- ===== 003_films_per_language.sql =====
/* 003 - Number of films in each language */
SELECT 
  l.name AS film_language,
  COUNT(f.film_id) AS no_of_films
FROM language l
  INNER JOIN film f ON l.language_id = f.language_id
GROUP BY 1
ORDER BY no_of_films DESC;

-- ===== 004_films_by_rating.sql =====
/* 004 - Films by rating */
SELECT 
  f.rating AS film_rating,
  COUNT(*) AS film_count
FROM film f
GROUP BY f.rating
ORDER BY film_count DESC;

-- ===== 005_films_in_each_category.sql =====
/* 005 - Number of films in each category */
SELECT 
  c.name AS category_name,
  COUNT(f.film_id) AS film_count
FROM category c
  JOIN film_category fc ON c.category_id = fc.category_id
  JOIN film f ON fc.film_id = f.film_id
GROUP BY c.name
ORDER BY film_count DESC;

-- ===== 006_small_categories.sql =====
/* 006 - Categories with less than 5 films */
SELECT 
  c.name AS category_name,
  COUNT(f.film_id) AS no_of_films
FROM category c
  INNER JOIN film_category fc ON c.category_id = fc.category_id
  JOIN film f ON fc.film_id = f.film_id
GROUP BY c.name
HAVING COUNT(f.film_id) < 5;

-- ===== 007_films_rented_by_category.sql =====
/* 007 - Films rented out in each category */
SELECT c.category_id,
  c.name,
  COUNT(r.rental_id) AS rental_count
FROM category c
  JOIN film_category fc ON c.category_id = fc.category_id
  JOIN inventory i ON fc.film_id = i.film_id
  JOIN rental r ON i.inventory_id = r.inventory_id --Includes paid and unpaid rentals
GROUP BY c.category_id,
  c.name
ORDER BY rental_count DESC;
