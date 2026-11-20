# fda-food-recall-analysis
SQL analysis and Power BI dashboard of 29,500 FDA food recall records: hazard classes, trends over time, undeclared allergens, and recalling firms by state.

# FDA Food Recall Analysis

Analysis of 29,505 FDA food enforcement (recall) records using SQL, with a four-page Power BI dashboard.

## Goal
Understand how food recalls are classified, how they change over time, how often they involve undeclared allergens, and where the recalling firms are based.

## Data
- Source: openFDA Food Enforcement Reports (https://open.fda.gov/apis/food/enforcement/)
- Downloaded October 2026
- 29,505 records, 24 columns
- The raw data is not included in this repo because of its size. See "How to reproduce" below.

## Tools
- Python (pandas) to convert the JSON download to CSV
- SQLite (DB Browser for SQLite) for the queries
- Power BI Desktop for the dashboard

## Questions and findings

**1. What are the recall classifications, and how common is each?**
Class II is the most common (14,758, about 50%), but Class I, the most serious category, is close behind (12,983, about 44%). Only about 6% are Class III.
Skills: JOIN, GROUP BY, COUNT

**2. How has the number of recalls changed over time, and what share are Class I?**
Recalls peaked in 2016 (3,066) and were lowest among full years in 2020 (1,117). The Class I share ranged from 32.4% (2017) to 57.1% (2023) with no steady direction.
Skills: SUBSTR, CASE, SUM, ROUND, data cleaning

**3. What share of recalls involve undeclared allergens?**
About 18% (5,320 of 29,505) under a strict keyword definition. This is likely an underestimate.
Skills: LIKE, AND/OR, CASE, keyword matching

**4. Which states have the most recalling firms?**
California leads in both recalls (4,049) and distinct firms (946). Some states, such as Wisconsin, have many recalls from relatively few firms.
Skills: COUNT(DISTINCT), GROUP BY, HAVING

## Data cleaning decisions
- One record has an invalid date (2121, a 7-digit value) and was excluded as a likely typo. I checked that it was the only malformed date.
- Years before 2012 have 3 to 57 recalls each, so the dashboard starts at 2012.
- 2026 is a partial year (through October).
- 237 records with no state and 189 marked N/A were excluded from the state analysis.

## Limitations
- The allergen definition requires the word "undeclared," so recalls worded as "may contain" are not counted. The real share is probably higher. I did not manually audit a sample of matches or misses.
- State is where the recalling firm is based, not where the product was sold, and counts are not adjusted for the number of food companies in each state.
- Company names may be spelled inconsistently, so distinct firm counts are approximate.

## What I would do next
- Review samples of allergen matches and misses, then report a range using both a strict and a broader definition
- Normalize company names to improve firm counts
- Compute the allergen share by year

## How to reproduce
1. Download the food enforcement data from openFDA and unzip the JSON file.
2. Run `python convert.py` to create `recalls.csv`.
3. In DB Browser for SQLite, create a new database and import `recalls.csv` as a table named `recalls` (check "Column names in first line").
4. Run the queries in `queries.sql`.

## Files
- `queries.sql`: all SQL queries
- `convert.py`: JSON to CSV conversion
- `project_notes.md`: notes and findings
- `recall_dashboard.pdf` and `recall_dashboard.pbix`: the dashboard
- `screenshots/` and `results/`: dashboard images and exported query results
