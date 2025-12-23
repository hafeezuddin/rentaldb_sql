/*Find the top 2 cities in each country by number of rentals in the year 2005.
For each city, show: Country name, City name, Number of rentals in that city, Rank of the city within its country
If multiple cities tie for the same rank, they should all be included. */

--CTE to consolidate and rank city,country wise data based on rentals
WITH ranking_cities AS (
        SELECT ci.city,
        co.country,
        COUNT(DISTINCT r.rental_id) AS total_rentals,
        --Ranking by partitioning by country and rentals in Desc
        RANK() OVER (PARTITION BY co.country ORDER BY COUNT(DISTINCT r.rental_id) DESC) AS ranking,
        --Calculating no.of.rentals of each country using partitioning
        SUM(COUNT(DISTINCT r.rental_id)) OVER (PARTITION BY co.country) AS country_total_rentals
    FROM rental r
    INNER JOIN customer c ON r.customer_id = c.customer_id
    INNER JOIN address a ON c.address_id = a.address_id
    INNER JOIN city ci ON a.city_id = ci.city_id
    INNER JOIN country co ON ci.country_id = co.country_id
    INNER JOIN payment p ON r.rental_id = p.rental_id --To consider only paid rentals
    WHERE r.return_date IS NOT NULL AND (r.rental_date >= '2005-01-01' AND r.rental_date <= '2005-12-31')  --Considering only 2005 Rentals
    GROUP BY 1,2
)
--Main query to filter top 2 cities in each country.
SELECT rc.city,
rc.country,
rc.total_rentals,
rc.ranking,
rc.country_total_rentals,
--city Percentage/share calculation
ROUND((rc.total_rentals::numeric/country_total_rentals)*100,2) AS city_share
FROM ranking_cities rc
WHERE rc.ranking <=2;