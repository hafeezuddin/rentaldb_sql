/* # SQL Problem Statement: Top Spenders in Action and Comedy Categories

## Problem Title
Identify High-Value Customers in Action and Comedy Movie Rentals

## Problem Description
You are tasked with analyzing customer rental spending patterns across specific movie categories.
Your goal is to find customers who are spending significantly above average in the "Action" and "Comedy" categories.

## Requirements
### Data Selection
- Include rental transactions from **only** the "Action" and "Comedy" movie categories
- A customer may appear in the results for one or both categories

### Filtering Criteria
For each category independently:
- Calculate the **average spending per customer** within that category (across all customers who rented from that category)
- Include only customer-category combinations where the customer's total spending **exceeds** that category's average
- Example: If the average spend in "Action" is $150, only include customers with >$150 in Action rentals

### Output Columns (in this order)
1. `customer_id` – Unique identifier for the customer
2. `first_name` – Customer's first name
3. `last_name` – Customer's last name
4. `category_name` – The movie category ("Action" or "Comedy")
5. `total_spent` – Total dollar amount spent on rentals in that category by that customer

### Sorting Requirements
1. **Primary Sort:** `category_name` (alphabetical: "Action" before "Comedy")
2. **Secondary Sort:** `total_spent` (descending: highest to lowest)

### Result Limit
Return the **top 10 rows** after sorting (a customer appearing in both categories counts as 2 rows)

## Assumptions */

--BASE CTE for customer and rentals
--Base filter of action and comedy filters are applied.
WITH rental_info AS (
    SELECT r.customer_id, concat(c.first_name,' ',c.last_name) AS full_name, f.film_id, ct.name, p.amount
    FROM rental r
    LEFT JOIN payment p ON r.rental_id = p.rental_id
    --Left joins retains both paid and unpaid rentals
    --Replace left join with Inner join to perform analysis on paid rentals only.
    JOIN inventory i ON r.inventory_id = i.inventory_id
    JOIN film f ON i.film_id = f.film_id
    JOIN film_category fc ON f.film_id = fc.film_id
    JOIN category ct ON fc.category_id = ct.category_id
    JOIN customer c ON r.customer_id =  c.customer_id
    WHERE ct.name IN ('Action','Comedy')
),
--CTE to Calculate customer spend in action and comedy category.
metrics AS (
    SELECT ri.customer_id, ri.full_name, ri.name, COALESCE(SUM(ri.amount),0) AS total_spent
    FROM rental_info ri
    GROUP BY ri.customer_id, ri.name, ri.full_name
),
--CTE to calculate average category spend to be used in filtering customers who spend above average
overall_average_metrics AS (
    SELECT m.name, ROUND(AVG(m.total_spent),2) AS category_average
    FROM metrics m
    GROUP BY m.name
)
--Main query to filter customers who spend more than average in action, comedy category ordered by spent amount in descending order.
SELECT t.customer_id, t.full_name, t.name, t.total_spent, t.category_position
FROM (SELECT m.customer_id,
             m.full_name,
             m.name,
             m.total_spent,
             dense_rank() OVER (PARTITION BY m.name ORDER BY m.total_spent DESC) AS category_position
      FROM metrics m
               JOIN overall_average_metrics ovm ON m.name = ovm.name
      WHERE total_spent > category_average) t
WHERE t.category_position <= 5
ORDER BY t.name ASC, t.category_position ASC;