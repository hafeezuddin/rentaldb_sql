/*Find the top 2 cities in each country by number of rentals in the year 2005.
For each city, show:
  Country name, City name, Number of rentals in that city, Rank of the city within its country
If multiple cities tie for the same rank, they should all be included. */

--Base rental information cte for the year 2005
WITH base_rental_info AS (SELECT ci.city,
                                 co.country,
                                 COUNT(DISTINCT r.rental_id)                                                     AS total_rentals,
                                 --Metric used to rank the cities within each country
                                 rank()
                                 over (partition by co.country ORDER BY COUNT(DISTINCT r.rental_id) DESC)        AS position
                          FROM city ci
                                   JOIN address ad ON ci.city_id = ad.city_id
                                   JOIN country co ON ci.country_id = co.country_id
                                   JOIN customer c ON ad.address_id = c.address_id
                                   JOIN rental r ON c.customer_id = r.customer_id
                          --Considers both paid and unpaid rentals while calculating total rentals per city.
                          --Uncomment payment Join filter and consider only paid rentals for analysis
                          --JOIN payment p ON r.rental_id = p.rental_id
                          WHERE r.rental_date BETWEEN '2005-01-01' AND '2005-12-31'
                          GROUP BY ci.city, co.country)
--Main query to list top two cities in each country
SELECT br.country, br.city, br.total_rentals, br.position
FROM base_rental_info br
WHERE position <= 2
--Filters exactly top two or less cities in each country.
ORDER BY br.country;
