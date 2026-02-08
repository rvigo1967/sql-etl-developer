# Insurance Claims Mini DWH (SQL Server)

This project demonstrates SQL Server database design, ETL patterns, performance tuning,
and reporting-layer delivery for a claims analytics warehouse.

## What it shows
- Star-schema modeling (Dimensions + Fact)
- Incremental ETL with staging, audit logging, and reject handling
- Stored procedures for reliable loads + TRY/CATCH
- Reporting views for BI tools (Power BI/SSRS/Tableau)
- Indexing and query optimization demo using execution-plan-friendly patterns

## How to run
1) Run sql/01_schema.sql
2) Run sql/02_seed_data.sql
3) Run sql/03_etl_load.sql
4) Run sql/05_reporting_views.sql
5) Optional: run sql/06_optimization_demo.sql

## Key objects
- Staging: stg.*
- Core: dim.*, fact.*
- ETL audit: etl.LoadRun, etl.LoadRunError, etl.RejectRow
- Reporting: rpt.*
