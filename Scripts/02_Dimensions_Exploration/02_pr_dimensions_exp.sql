/*
  Dimensions Exploration queries
  License: MIT (see /LICENSE)
*/

--Distinct categories
SELECT DISTINCT c.name AS available_categories
FROM category c
ORDER BY c.name ASC;

-- Film language distribution
SELECT 
  f.title AS film_name,
  l.name AS language
FROM film f
  JOIN language l ON f.language_id = l.language_id
  ORDER BY f.title ASC;


-- Number of films in each language
SELECT l.name           AS film_language,
       COUNT(f.film_id) AS no_of_films
FROM language l
         INNER JOIN film f ON l.language_id = f.language_id
GROUP BY l.name
ORDER BY no_of_films DESC;


-- Films by rating
SELECT f.rating AS film_rating,
       COUNT(f.film_id) AS total_films
FROM film f
GROUP BY f.rating
ORDER BY film_count DESC;


--Number of films in each category
SELECT c.name           AS category_name,
       COUNT(f.film_id) AS film_count
FROM category c
         JOIN film_category fc ON c.category_id = fc.category_id
         JOIN film f ON fc.film_id = f.film_id
GROUP BY c.name
ORDER BY film_count DESC;


-- Categories with less than 5 films.
SELECT c.name           AS category_name,
       COUNT(f.film_id) AS no_of_films
FROM category c
         INNER JOIN film_category fc ON c.category_id = fc.category_id
         JOIN film f ON fc.film_id = f.film_id
GROUP BY c.name
HAVING COUNT(f.film_id) < 5;


-- Films rented out in each category
SELECT c.category_id,
       c.name             AS category_name,
       COUNT(r.rental_id) AS rental_count
FROM category c
         JOIN film_category fc ON c.category_id = fc.category_id
         JOIN inventory i ON fc.film_id = i.film_id
         JOIN rental r ON i.inventory_id = r.inventory_id --Includes paid and unpaid rentals
GROUP BY c.category_id,
         c.name
ORDER BY rental_count DESC;
