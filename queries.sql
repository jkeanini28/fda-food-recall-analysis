-- ============================================================
-- FDA Food Recall Analysis: SQL queries
-- Database: SQLite (DB Browser for SQLite)
-- Table: recalls (29,505 rows imported from recalls.csv)
-- Source: openFDA Food Enforcement Reports
-- ============================================================


--------------------------------------------------------------
-- SETUP CHECKS
--------------------------------------------------------------

-- Confirm the import loaded every row (expected: 29505)
SELECT COUNT(*) FROM recalls;

-- Preview the data
SELECT * FROM recalls LIMIT 5;


--------------------------------------------------------------
-- Q1. What are the recall classifications, how common is each, and what do they mean?
-- Skills: JOIN, GROUP BY, COUNT
--------------------------------------------------------------

-- Lookup table so the classifications can be joined to their meanings
CREATE TABLE class_info (
    classification TEXT,
    meaning TEXT
);

INSERT INTO class_info VALUES
('Class I', 'Reasonable chance the product causes serious health problems or death'),
('Class II', 'May cause temporary or reversible health problems; serious harm is unlikely'),
('Class III', 'Unlikely to cause any health problems'),
('Not Yet Classified', 'Review still in progress');

SELECT r.classification, c.meaning, COUNT(*) AS total_recalls
FROM recalls AS r
JOIN class_info AS c
    ON r.classification = c.classification
GROUP BY r.classification, c.meaning
ORDER BY total_recalls DESC;
-- Check: the four counts add up to 29,505


--------------------------------------------------------------
-- Q2. How has the number of recalls changed year to year, and which years had the most serious (Class I) recalls?
-- Skills: SUBSTR, CASE, SUM, ROUND, WHERE, data cleaning
--------------------------------------------------------------

-- Data checks: one row had a year of 2121 (a 7-digit date)
SELECT *
FROM recalls
WHERE SUBSTR(recall_initiation_date, 1, 4) = '2121';

-- Confirm that row is the only malformed date (all others have 8 digits)
SELECT *
FROM recalls
WHERE LENGTH(recall_initiation_date) != 8;

-- Main query (matches the dashboard)
-- Excludes the malformed date, and starts at 2012 because
-- 2008-2011 have only 3 to 57 recalls per year, too few to compare.
-- 2026 is a partial year (through October).
SELECT SUBSTR(recall_initiation_date, 1, 4) AS recall_year,
       COUNT(*) AS recalls_per_year,
       SUM(CASE WHEN classification = 'Class I' THEN 1 ELSE 0 END) AS class_I_recalls_per_year,
       ROUND(100.0 * SUM(CASE WHEN classification = 'Class I' THEN 1 ELSE 0 END) / COUNT(*), 1) AS class_I_percentage
FROM recalls
WHERE LENGTH(recall_initiation_date) = 8
  AND recall_initiation_date >= '20120101'
GROUP BY recall_year
ORDER BY recall_year DESC;

-- Exploratory version, before choosing a 2012 cutoff
-- (all years with a valid date, including the thin 2008-2011 data):
-- SELECT SUBSTR(recall_initiation_date, 1, 4) AS recall_year,
--        COUNT(*) AS recalls_per_year,
--        SUM(CASE WHEN classification = 'Class I' THEN 1 ELSE 0 END) AS class_I_recalls_per_year,
--        ROUND(100.0 * SUM(CASE WHEN classification = 'Class I' THEN 1 ELSE 0 END) / COUNT(*), 1) AS class_I_percentage
-- FROM recalls
-- WHERE LENGTH(recall_initiation_date) = 8
-- GROUP BY recall_year
-- ORDER BY recall_year DESC;


--------------------------------------------------------------
-- Q3. What share of recalls involve undeclared allergens versus other reasons?
-- Skills: LIKE, AND/OR, CASE, SUM, COUNT, ROUND, keyword matching
--------------------------------------------------------------

-- Definition: the reason contains "undeclared" AND at least one allergen keyword. This is keyword matching on free text, so it
-- is a conservative estimate. Wording such as "may contain soy" without "undeclared" is not counted.
SELECT COUNT(*) AS total_recalls,
    SUM(CASE
        WHEN reason_for_recall LIKE '%undeclared%'
        AND (
            reason_for_recall LIKE '%allergen%'
            OR reason_for_recall LIKE '%milk%'
            OR reason_for_recall LIKE '%egg%'
            OR reason_for_recall LIKE '%peanut%'
            OR reason_for_recall LIKE '%tree nuts%'
            OR reason_for_recall LIKE '%fish%'   -- also catches shellfish
            OR reason_for_recall LIKE '%wheat%'
            OR reason_for_recall LIKE '%soy%'
            OR reason_for_recall LIKE '%sesame%'
        ) THEN 1 ELSE 0 END) AS allergen_recalls,
    ROUND(100.0 * SUM(CASE
        WHEN reason_for_recall LIKE '%undeclared%'
        AND (
            reason_for_recall LIKE '%allergen%'
            OR reason_for_recall LIKE '%milk%'
            OR reason_for_recall LIKE '%egg%'
            OR reason_for_recall LIKE '%peanut%'
            OR reason_for_recall LIKE '%tree nuts%'
            OR reason_for_recall LIKE '%fish%'
            OR reason_for_recall LIKE '%wheat%'
            OR reason_for_recall LIKE '%soy%'
            OR reason_for_recall LIKE '%sesame%'
        ) THEN 1 ELSE 0 END) / COUNT(*), 1) AS allergen_percentage
FROM recalls;
-- Result: 29505 total, 5320 allergen recalls, 18.0%


--------------------------------------------------------------
-- Q4. Which states have the most recalling firms, and which have more than 50 recalls?
-- Skills: COUNT, COUNT(DISTINCT), WHERE, GROUP BY, HAVING, ORDER BY
--------------------------------------------------------------

-- State is where the recalling firm is based, not where the
-- product was sold. 237 rows have no state (NULL) and 189 are
-- marked 'N/A'; both are excluded.
SELECT state,
       COUNT(*) AS recalls_per_state,
       COUNT(DISTINCT recalling_firm) AS firms_per_state
FROM recalls
WHERE state IS NOT NULL
  AND state != 'N/A'
GROUP BY state
HAVING recalls_per_state > 50
ORDER BY recalls_per_state DESC;

-- Top 10 version used for the dashboard chart: add LIMIT 10
