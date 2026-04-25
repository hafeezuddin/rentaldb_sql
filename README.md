# RentalDB SQL

PostgreSQL analytics project built on the classic DVD Rental sample database.
The repository contains a local database archive, a schema reference image, and
75 focused SQL scripts for exploration, reporting, customer analytics,
recommendations, inventory analysis, and operational performance review.

## Project Goals

- Analytical SQL on a realistic relational schema.
- Answer common retail rental business questions with reusable query files.
- Demonstrate CTEs, joins, aggregations, conditional logic, date handling, and
  window functions.
- Keep each analysis small enough to run, inspect, and adapt independently.

## Repository Layout

```text
.
|-- Database/
|   `-- dvdrental.tar
|-- Scheme Design/
|   `-- Screenshot 2025-03-15 at 15.06.26.png
|-- Scripts/
|   |-- 01_Basic_Data_Exploration/
|   |-- 02_Dimensions_Exploration/
|   |-- 03_Ranking_Analysis/
|   |-- 04_Data_Segmentation/
|   |-- 05_Cummulative_Analysis/
|   |-- 06_Recommendation_System/
|   |-- 07_Performance_Analysis/
|   |-- 08_Inventory_Analysis/
|   `-- 09_Customer_Insights/
|-- LICENSE
`-- README.md
```

## Database

The project uses `Database/dvdrental.tar`, a PostgreSQL dump of the DVD Rental
sample database. The archive contains the standard public schema objects,
including:

- Core tables such as `actor`, `address`, `category`, `city`, `country`,
  `customer`, `film`, `film_actor`, `film_category`, `inventory`, `language`,
  `payment`, `rental`, `staff`, and `store`.
- Views such as `actor_info`, `customer_list`, `film_list`,
  `nicer_but_slower_film_list`, and `sales_by_film_category`.
- Utility functions and triggers from the sample database, including inventory
  stock checks and last-updated triggers.
- Data for the sample store, customers, films, rentals, payments, and inventory.

The schema image in `Scheme Design/` can be used as a quick visual reference
while reading or modifying the scripts.

## Requirements

- PostgreSQL with `psql`, `createdb`, and `pg_restore` available on your PATH.
- A database user with permission to create and restore a local database.

The dump was generated from PostgreSQL 11.x, but the scripts use broadly
compatible PostgreSQL syntax and should work on newer versions.

## Quick Start

Create and restore the sample database:

```bash
createdb dvdrental
pg_restore -U <your_user> -d dvdrental Database/dvdrental.tar
```

Run any script with `psql`:

```bash
psql -U <your_user> -d dvdrental -f Scripts/01_Basic_Data_Exploration/01_pr_basic_Data_Exp.sql
```

Run a query interactively:

```bash
psql -U <your_user> -d dvdrental
\i Scripts/03_Ranking_Analysis/01_pr_top_five_customers.sql
```

If your PostgreSQL instance uses a non-default host or port, add `-h` and `-p`
to the commands.

## Script Catalog

| Folder | Scripts | Focus |
| --- | ---: | --- |
| `01_Basic_Data_Exploration` | 1 | Table discovery, column metadata, sample customer rows, database-level counts, and basic rental summaries. |
| `02_Dimensions_Exploration` | 1 | Distinct categories, language distribution, rating distribution, category film counts, and category rental counts. |
| `03_Ranking_Analysis` | 19 | Top customers, lifetime value, top cities, top actors, top films, country-level customer ranks, category-level film ranks, revenue months, and loyalty rankings. |
| `04_Data_Segmentation` | 9 | Revenue-per-customer, premium film customers, customer behavior segmentation, targeted marketing, engagement scoring, and inventory optimization. |
| `05_Cummulative_Analysis` | 7 | 2005 revenue, rental trends by location, rental duration, monthly revenue, category popularity, busiest hours, and cumulative stats. |
| `06_Recommendation_System` | 1 | Category and actor-based customer recommendation logic. |
| `07_Performance_Analysis` | 6 | Staff rental counts, fastest-growing categories, film categorization, category profitability, and inventory performance. |
| `08_Inventory_Analysis` | 13 | Films missing from inventory, availability, store inventory, underpriced films, hard-to-stock films, overlooked films, and inventory efficiency. |
| `09_Customer_Insights` | 18 | Active customers, customer value, late returns, monthly renters, premium customers, churn risk, health scores, high-value customers, onboarding, favorite categories, and weekend rental behavior. |

## Analysis Themes

### Exploration and dimensions

The first two folders establish the base schema and dimensions. They inspect
available tables and columns, sample customer records, total customers/films/
rentals, category membership, languages, ratings, and category-level demand.

### Rankings and cumulative reporting

Ranking scripts answer questions such as:

- Which customers rent or spend the most?
- Which films, categories, actors, cities, countries, and months perform best?
- Which customers rank highest within each country or category?
- Which films have high rental duration, high rental counts, or premium pricing?

The cumulative analysis scripts add time-series reporting for 2005 revenue,
monthly revenue, busiest hours, category popularity, and location-level trends.

### Customer analytics

Customer-focused scripts segment and score customers using rental behavior,
spending, recency, category preference, store usage, late returns, churn risk,
and onboarding patterns. Several scripts intentionally distinguish between
paid-only analysis and all-rental analysis by using either `INNER JOIN payment`
or `LEFT JOIN payment`.

### Inventory and performance

Inventory scripts analyze stock coverage, currently unavailable copies,
high-revenue low-availability films, underpriced films, hard-to-keep-in-stock
titles, overlooked titles, store-level inventory balance, and efficiency
categories such as blockbusters, efficient classics, and slow movers.

Performance scripts focus on staff activity, category growth, film
classification, and profitability.

### Recommendations

The recommendation script builds customer suggestions from historical rental
behavior, category affinity, and film metadata. It is intended as a SQL-first
recommendation example rather than a production recommendation engine.

## SQL Techniques Used

- Common table expressions for readable multi-step analysis.
- Window functions such as `ROW_NUMBER`, `RANK`, `DENSE_RANK`, and
  `PERCENT_RANK`.
- Conditional aggregation with `CASE` expressions.
- Date bucketing with `DATE_TRUNC`, `TO_CHAR`, and explicit 2005 analysis
  windows.
- Defensive calculations with `COALESCE` and `NULLIF`.
- Payment pre-aggregation in scripts where split payments could otherwise
  inflate rental-level metrics.
- Cardinality checks before joining film/category data in inventory analyses.

## Assumptions and Notes

- Most business questions are scoped to the sample rental activity in 2005.
- `payment` represents paid rental activity. Scripts that use `LEFT JOIN payment`
  often keep unpaid rentals in the result and use `COALESCE` for spend metrics.
- Several scripts include comments explaining how to switch from all rentals to
  paid-only rentals.
- The directory name `05_Cummulative_Analysis` is kept as-is to match the
  existing repository path.
- The SQL files are standalone analysis scripts. They do not create permanent
  reporting tables unless you adapt them to do so.

## Example Workflows

Explore the database:

```bash
psql -U <your_user> -d dvdrental -f Scripts/01_Basic_Data_Exploration/01_pr_basic_Data_Exp.sql
```

Find top customers:

```bash
psql -U <your_user> -d dvdrental -f Scripts/03_Ranking_Analysis/01_pr_top_five_customers.sql
```

Review customer churn risk:

```bash
psql -U <your_user> -d dvdrental -f Scripts/09_Customer_Insights/09_pr_churn_risk.sql
```

Analyze inventory efficiency:

```bash
psql -U <your_user> -d dvdrental -f Scripts/08_Inventory_Analysis/13_pr_inventory_efficiency.sql
```

## Working With the Scripts

1. Restore the database locally.
2. Start with the exploration scripts to understand the schema.
3. Move into the topic folder that matches the business question.
4. Read the comments at the top of the script, when present, before running it.
5. Adjust date windows, category filters, thresholds, or join choices for your
   analysis scenario.

## License

This project is licensed under the MIT License. See `LICENSE` for details.
