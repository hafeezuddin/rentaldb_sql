# RentalDB SQL

SQL analysis project built on the classic PostgreSQL DVD Rental sample database. 
This repository contains focused query scripts for exploring data, ranking customers and films, segmenting behavior, analyzing inventory, and generating business insights.

## What's Inside

- `Database/` - Sample database archive (`dvdrental.tar`)
- `Scripts/` - Topic-wise SQL scripts for analytics and reporting
- `Scheme Design/` - Schema design references

## Key Highlights

- PostgreSQL-based analytical SQL
- Uses CTEs, joins, aggregations, and window functions
- Covers customer insights, recommendations, performance, and inventory analysis
- Organized as small, reusable scripts instead of one large SQL file

## Quick Start

1. Restore `Database/dvdrental.tar` into a PostgreSQL database named `dvdrental`
2. Run any script with `psql`

```bash
psql -U <your_user> -d dvdrental -f Scripts/01_Basic_Data_Exploration/basic_Analysis.sql
```

## Use Cases

- Practice advanced SQL
- Explore reporting and BI-style queries
- Learn query structuring for real-world analytics scenarios

## License
MIT