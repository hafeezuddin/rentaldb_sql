/* Active customers who rented at least once in year 2005. Consider only paid rentals*/
SELECT t.customer_id, t.first_rental_date, t.no_of_times_rented
FROM (SELECT r.customer_id AS customer_id,
             COUNT(DISTINCT r.rental_id) no_of_times_rented,
             to_char(DATE_TRUNC('Day', Min(r.rental_date)),'YYYY-MM-DD') AS first_rental_date
      FROM rental r
               JOIN customer c ON r.customer_id = c.customer_id
               JOIN payment p ON r.rental_id = p.rental_id --Filtering paid rentals
      WHERE r.rental_date >= '2005-01-01'
        AND r.rental_date <= '2005-12-31' --2005 Rentals
      GROUP BY r.customer_id
      ORDER BY r.customer_id) t
WHERE t.no_of_times_rented >=1;

--Added comment to debug branching issues
