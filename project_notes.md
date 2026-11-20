1. 
What are the recall classifications, how common is each, and what do they mean?
--SKILLS “JOIN, GROUP BY, COUNT”

Query:
SELECT r.classification, c.meaning, COUNT(*) AS total_recalls 
FROM recalls AS r
JOIN class_info AS c
	ON r.classification = c.classification
GROUP BY r.classification, c.meaning
ORDER BY total_recalls DESC;

Table added for classification meanings:
CREATE TABLE class_info (
    classification TEXT,
    meaning TEXT
);

INSERT INTO class_info VALUES
('Class I', 'Reasonable chance the product causes serious health problems or death'),
('Class II', 'May cause temporary or reversible health problems; serious harm is unlikely'),
('Class III', 'Unlikely to cause any health problems'),
('Not Yet Classified', 'Review still in progress');

Result:
Class II		May cause temporary or reversible health problems; serious harm is unlikely	14758
Class I			Reasonable chance the product causes serious health problems or death		12983
Class III		Unlikely to cause any health problems						1762
Not Yet Classified	Review still in progress							2

What it means:
- Biggest group: Class II, 14,758 recalls (about 50% of the total)
- Class I, the most serious category, is 12,983 recalls (about 44%). That is common, not rare: nearly half of all recalls carry a reasonable chance of serious harm.
- Class III is about 6% (1,762), and 2 recalls are not yet classified
- Business sentence: Serious (Class I) recalls are close to half of all food recalls, so food safety is a frequent, high-stakes problem for manufacturers and not a rare event.
- Check: counts add up to 29,505
------------------------------------------------------------------------------------------------------
2.
How has the number of recalls changed year to year, and which years had the most serious (Class I) recalls?
--SKILLS “SUBSTR, CASE, SUM, ROUND, WHERE, data checks/cleaning”

QUERY:
SELECT SUBSTR(recall_initiation_date, 1, 4) AS recall_year, COUNT(*) AS recalls_per_year,
		SUM(CASE WHEN classification = 'Class I' THEN 1 ELSE 0 END) AS class_I_recalls_per_year,
		ROUND(100.0 * SUM(CASE WHEN classification = 'Class I' THEN 1 ELSE 0 END) / COUNT(*), 1) AS class_I_percentage
FROM recalls
WHERE LENGTH(recall_initiation_date) = 8  --found when the year 2121 popped up
GROUP BY recall_year
ORDER BY recall_year DESC;

Checks I ran:
SELECT *
FROM recalls
WHERE SUBSTR(recall_initiation_date, 1, 4) = '2121';

SELECT *
FROM recalls
WHERE LENGTH(recall_initiation_date) != 8; --confirmed it was just that one entry

Result:
2026	919	350	38.1
2025	1571	717	45.6
2024	1387	515	37.1
2023	2221	1269	57.1
2022	1427	658	46.1
2021	1501	677	45.1
2020	1117	428	38.3
2019	1807	684	37.9
2018	1977	643	32.5
2017	2623	851	32.4
2016	3066	1561	50.9
2015	2750	1084	39.4
2014	2451	1183	48.3
2013	2420	1110	45.9
2012	2151	1218	56.6
2011	57	14	24.6
2010	3	2	66.7
2009	19	18	94.7
2008	37	1	2.7

Data notes:
- Found 1 row dated 2121 (7-digit date: 2121207); likely a typo for 20121207; excluded it and wrote down why
- Checked that it was the only malformed date (LENGTH != 8)
- Decision on 2008-2011: [kept with a footnote] because ___

What it means:
- Trend: highest year was 2016 (3,066 recalls); lowest full year was 2020 (1,117). Counts fell after 2016, then rose in 2023 (2,221).
- Years with the most Class I recalls: 2016 (1,561) and 2023 (1,269)
- Class I share runs from 32.4% (2017) to 57.1% (2023) from 2012 onward, with no clear steady direction
- Not claiming a cause, because the data does not say why counts or shares moved
- Caveats: 2026 is a partial year (through October); 2008-2011 have only 3 to 57 recalls per year, so their percentages are not meaningful
- Decision on 2008-2011: the SQL results keep them, but the dashboard starts at 2012 because those years have too few records to compare. The dashboard footnote says so.
- Data note: one row dated 2121 (7-digit date) was excluded as a likely typo
------------------------------------------------------------------------------------------------------
3. 
What share of recalls involve undeclared allergens versus other reasons?
--SKILLS “LIKE, WHERE, AND, OR, SUM, CASE, COUNT, ROUND, keyword matching”

Query:
SELECT COUNT(*) AS total_recalls,
	SUM(CASE 
		WHEN reason_for_recall LIKE '%undeclared%'
		AND(
			reason_for_recall LIKE '%allergen%'
			OR reason_for_recall LIKE '%milk%'
			OR reason_for_recall LIKE '%egg%'
			OR reason_for_recall LIKE '%peanut%'
			OR reason_for_recall LIKE '%tree nuts%'
			OR reason_for_recall LIKE '%fish%' --this also catches shellfish
			OR reason_for_recall LIKE '%wheat%'
			OR reason_for_recall LIKE '%soy%'
			OR reason_for_recall LIKE '%sesame%'
		)	THEN 1 ELSE 0 END) AS allergen_recalls,
	ROUND(100.0 * SUM(CASE
		WHEN reason_for_recall LIKE '%undeclared%'
		AND(
			reason_for_recall LIKE '%allergen%'
			OR reason_for_recall LIKE '%milk%'
			OR reason_for_recall LIKE '%egg%'
			OR reason_for_recall LIKE '%peanut%'
			OR reason_for_recall LIKE '%tree nuts%'
			OR reason_for_recall LIKE '%fish%' --this also catches shellfish
			OR reason_for_recall LIKE '%wheat%'
			OR reason_for_recall LIKE '%soy%'
			OR reason_for_recall LIKE '%sesame%'
		)	THEN 1 ELSE 0 END) / COUNT(*), 1) AS allergen_percentage

FROM recalls;

Results:
29505	5320	18.0

Data notes:
- Defined allergen recalls as containing “undeclared” and at least one allergen-related keyword
- Used free-text keyword matching, so some recalls may be missed or incorrectly counted

What it means:
- About 18.0% of recalls (5,320 of 29,505) match my definition of an undeclared-allergen recall
- Caveat: the definition requires the word "undeclared" plus an allergen keyword, so wording like "may contain soy" is not counted. The true share is likely higher.
- Keyword matching can also produce false matches (for example, "egg" inside another word). I did not manually review a sample of matches or misses.
- Next step: review samples of matches and misses, add a broader definition, and report both numbers as a range
------------------------------------------------------------------------------------------------------
4.
Which states have the most recalling firms, and which have more than 50 recalls?
--SKILLS: "COUNT", "COUNT(DISTINCT ...)", "WHERE", "GROUP BY", "HAVING", "ORDER BY", "!="

Query:
SELECT state, COUNT(*) AS recalls_per_state, COUNT(DISTINCT recalling_firm) AS firms_per_state
FROM recalls
WHERE state IS NOT NULL	--NULL has 237
AND state != 'N/A'		--N/A has 189
GROUP BY state
HAVING recalls_per_state > 50
ORDER BY recalls_per_state DESC;

Results:
CA	4049	946
TX	1968	307
IL	1887	228
NY	1801	492
WI	1426	128
WA	1411	235
FL	1405	286
MI	1383	172
OH	1227	211
OR	1070	234
NJ	1038	276
PA	957	170
MA	938	145
MN	868	128
MD	792	74
GA	684	98
NC	608	92
IA	417	62
NM	368	24
ID	357	40
MO	354	75
IN	351	56
CO	292	114
AZ	277	69
KS	275	35
TN	273	68
NH	266	16
VA	234	58
PR	229	66
UT	216	72
KY	198	33
CT	191	63
VT	146	24
NV	114	27
ND	106	12
ME	96	31
RI	93	19
NE	81	22
HI	71	30
AR	65	20
SC	63	32
WY	59	7
OK	59	25
LA	58	27
AK	58	14
AL	51	28

What it means:
- States are where the recalling firm is based, not where the product was sold
- California has the most recalls (4,049) and the most distinct firms (946); Texas (1,968) and Illinois (1,887) follow in recalls
- By distinct firms, the top five are CA (946), NY (492), TX (307), FL (286), NJ (276)
- High recall counts do not always mean many firms: Wisconsin has 1,426 recalls from 128 firms (about 11 per firm), and New Hampshire has 266 from 16 (about 17 per firm), so a few companies recall repeatedly
- Counts are not adjusted for how many food companies each state has
- 46 states and territories have more than 50 recalls; 237 rows with no state and 189 marked N/A were excluded
- Firm counts are approximate because company names may be spelled differently
