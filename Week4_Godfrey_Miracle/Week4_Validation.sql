/* =====================================================================
   AnalystLab Africa | Data Analytics Internship | Week 4
   Consumer Complaint Trends and Response Intelligence Platform
   Dataset: CFPB consumer complaints on Bank of America, 1 May 2017 to 28 Aug 2023
   Author : Godfrey Miracle
   Engine : MySQL 8.0

   PURPOSE
   Rebuild the Power Query cleaning in SQL, then recalculate every KPI shown in the
   Power BI dashboard so the dashboard figures can be checked independently.

   HOW TO USE
   1. Run Section 0 to create the database and the raw table.
   2. Import the CSV into complaints_raw (steps in the README / chat guide).
   3. Run Section 1 to build the cleaned view.
   4. Run Sections 2 to 4 one query at a time and compare with the dashboard.
   5. Run Section 5 for the automatic PASS / FAIL summary.

   The raw table is never edited. All cleaning happens in the view complaints_clean.
   ===================================================================== */


/* ---------------------------------------------------------------------
   SECTION 0: DATABASE AND RAW TABLE
   Column names match the CSV headers exactly so the Import Wizard maps them.
   --------------------------------------------------------------------- */
CREATE DATABASE IF NOT EXISTS analystlab_week4;
USE analystlab_week4;

-- The table is created only if it does not exist, so re-running this script never wipes the imported data.
-- (To start over deliberately, run: DROP TABLE complaints_raw; and re-import the CSV.)
CREATE TABLE IF NOT EXISTS complaints_raw (
    `Complaint ID`                 VARCHAR(20),
    `Submitted via`                VARCHAR(50),
    `Date submitted`               DATE,
    `Date received`                DATE,
    `State`                        VARCHAR(10),
    `Product`                      VARCHAR(150),
    `Sub-product`                  VARCHAR(150),
    `Issue`                        VARCHAR(200),
    `Sub-issue`                    VARCHAR(250),
    `Company public response`      VARCHAR(300),
    `Company response to consumer` VARCHAR(100),
    `Timely response?`             VARCHAR(10)
);

/* Import the CSV with: Table Data Import Wizard > Use existing table > complaints_raw.
   (Alternative, if local_infile is enabled on your server and client:
    LOAD DATA LOCAL INFILE 'C:/path/Consumer_Complaints_xlsx_-_Data.csv'
    INTO TABLE complaints_raw FIELDS TERMINATED BY ',' ENCLOSED BY '"'
    LINES TERMINATED BY '\r\n' IGNORE 1 LINES;)  */

SELECT COUNT(*) AS rows_loaded FROM complaints_raw;   -- expect 62516


/* ---------------------------------------------------------------------
   SECTION 1: CLEANED VIEW (mirrors the Power Query steps)
   - text trimmed; empty strings treated as missing
   - Web Referral merged into Referral
   - Sub-product / Sub-issue blanks -> 'Not specified'
   - Public Response Status separates In progress from closed-but-blank
   - Timely Status keeps In progress separate (blank is NOT treated as No)
   - year, month, quarter, forwarding interval and interval band added
   --------------------------------------------------------------------- */
CREATE OR REPLACE VIEW complaints_clean AS
SELECT
    TRIM(`Complaint ID`)                                             AS complaint_id,
    CASE WHEN TRIM(`Submitted via`) = 'Web Referral'
         THEN 'Referral' ELSE TRIM(`Submitted via`) END              AS submitted_via,
    `Date submitted`                                                 AS date_submitted,
    `Date received`                                                  AS date_received,
    TRIM(`State`)                                                    AS state,
    TRIM(`Product`)                                                  AS product,
    CASE
        WHEN TRIM(`Product`) LIKE 'Credit reporting%' THEN 'Credit reporting'
        WHEN TRIM(`Product`) LIKE 'Credit card%'      THEN 'Credit / prepaid card'
        WHEN TRIM(`Product`) LIKE 'Checking%'         THEN 'Checking / savings'
        WHEN TRIM(`Product`) LIKE 'Money transfer%'   THEN 'Money transfer / service'
        WHEN TRIM(`Product`) LIKE 'Payday%'           THEN 'Payday / personal loan'
        WHEN TRIM(`Product`) LIKE 'Vehicle%'          THEN 'Vehicle loan / lease'
        ELSE TRIM(`Product`)
    END                                                              AS product_short,
    COALESCE(NULLIF(TRIM(`Sub-product`), ''), 'Not specified')       AS sub_product,
    TRIM(`Issue`)                                                    AS issue,
    COALESCE(NULLIF(TRIM(`Sub-issue`), ''), 'Not specified')         AS sub_issue,
    TRIM(`Company response to consumer`)                             AS company_response,
    CASE
        WHEN TRIM(`Company response to consumer`) = 'In progress'
            THEN 'Pending (In progress)'
        WHEN NULLIF(TRIM(`Company public response`), '') IS NULL
            THEN 'Not recorded (closed)'
        ELSE TRIM(`Company public response`)
    END                                                              AS public_response_status,
    CASE
        WHEN TRIM(`Timely response?`) IN ('Yes', 'No') THEN TRIM(`Timely response?`)
        ELSE 'In progress'
    END                                                              AS timely_status,
    YEAR(`Date submitted`)                                           AS yr,
    MONTH(`Date submitted`)                                          AS mth,
    CONCAT('Q', QUARTER(`Date submitted`))                           AS qtr,
    DATE_SUB(`Date submitted`,
             INTERVAL DAYOFMONTH(`Date submitted`) - 1 DAY)          AS year_month_start,
    DATEDIFF(`Date received`, `Date submitted`)                      AS forwarding_days,
    CASE
        WHEN DATEDIFF(`Date received`, `Date submitted`) = 0  THEN '0 days'
        WHEN DATEDIFF(`Date received`, `Date submitted`) <= 3 THEN '1-3 days'
        WHEN DATEDIFF(`Date received`, `Date submitted`) <= 7 THEN '4-7 days'
        WHEN DATEDIFF(`Date received`, `Date submitted`) <= 30 THEN '8-30 days'
        ELSE 'Over 30 days'
    END                                                              AS interval_band
FROM complaints_raw;


/* ---------------------------------------------------------------------
   SECTION 2: DATA QUALITY CHECKS
   --------------------------------------------------------------------- */

-- 2.1 Structure and key: Complaint ID should be unique (candidate primary key)
SELECT COUNT(*)                        AS total_rows,
       COUNT(DISTINCT complaint_id)    AS distinct_ids,
       COUNT(*) - COUNT(DISTINCT complaint_id) AS duplicate_ids
FROM complaints_clean;                 -- 62516 / 62516 / 0

-- 2.2 Fully duplicated records
SELECT COUNT(*) AS fully_duplicated_rows FROM (
    SELECT complaint_id, submitted_via, date_submitted, date_received, state, product,
           sub_product, issue, sub_issue, company_response, public_response_status, timely_status,
           COUNT(*) AS n
    FROM complaints_clean
    GROUP BY complaint_id, submitted_via, date_submitted, date_received, state, product,
             sub_product, issue, sub_issue, company_response, public_response_status, timely_status
    HAVING n > 1) d;                   -- 0

-- 2.3 Missing values in the raw table (empty text counts as missing)
SELECT
    SUM(NULLIF(TRIM(`Sub-product`), '') IS NULL)             AS missing_sub_product,           -- 7
    SUM(NULLIF(TRIM(`Sub-issue`), '') IS NULL)               AS missing_sub_issue,             -- 10858
    SUM(NULLIF(TRIM(`Company public response`), '') IS NULL) AS missing_public_response,       -- 2175
    SUM(NULLIF(TRIM(`Timely response?`), '') IS NULL)        AS missing_timely_response        -- 1494
FROM complaints_raw;

-- 2.4 Blank timely response vs In progress (should be identical groups)
SELECT company_response,
       SUM(timely_status = 'In progress') AS blank_timely
FROM complaints_clean
GROUP BY company_response;             -- only In progress has blanks (1494)

-- 2.5 Blank public response: In progress (expected blank) vs closed (reason unknown)
SELECT public_response_status, COUNT(*) AS complaints
FROM complaints_clean
WHERE public_response_status IN ('Pending (In progress)', 'Not recorded (closed)')
GROUP BY public_response_status;       -- 1494 and 681

-- 2.6 Date validation: range, and any forwarding date earlier than the submission date
SELECT MIN(date_submitted) AS first_submitted, MAX(date_submitted) AS last_submitted,
       MIN(date_received)  AS first_received,  MAX(date_received)  AS last_received,
       SUM(forwarding_days < 0) AS negative_intervals
FROM complaints_clean;                 -- 2017-05-01 / 2023-08-28 / 2017-05-01 / 2023-08-28 / 0

-- 2.7 Category cardinality
SELECT COUNT(DISTINCT product)   AS products,      -- 9
       COUNT(DISTINCT sub_product) - 1 AS sub_products,  -- 46 (excluding 'Not specified')
       COUNT(DISTINCT issue)     AS issues,        -- 76
       COUNT(DISTINCT state)     AS states         -- 51
FROM complaints_clean;

-- 2.8 Submitted via after standardisation
SELECT submitted_via, COUNT(*) AS complaints
FROM complaints_clean GROUP BY submitted_via ORDER BY complaints DESC;
-- Web 45423, Referral 10856, Phone 4684, Postal mail 1318, Fax 233, Email 2


/* ---------------------------------------------------------------------
   SECTION 3: KPI QUERIES (same order as the brief)
   --------------------------------------------------------------------- */

-- KPI 1: Total complaints
SELECT COUNT(*) AS total_complaints FROM complaints_clean;               -- 62516

-- KPI 2: Annual complaint volume (2017 starts 1 May; 2023 ends 28 Aug: partial years)
SELECT yr, COUNT(*) AS complaints
FROM complaints_clean GROUP BY yr ORDER BY yr;
-- 5394, 7872, 7075, 8942, 11149, 12953, 9131

-- KPI 3: Monthly complaint volume (first 3 and last 3 shown; all 76 months in the full result)
SELECT year_month_start, COUNT(*) AS complaints
FROM complaints_clean GROUP BY year_month_start ORDER BY year_month_start;

-- KPI 3b: Highest and lowest month
(SELECT year_month_start, COUNT(*) AS complaints, 'highest' AS flag
 FROM complaints_clean GROUP BY year_month_start ORDER BY complaints DESC LIMIT 1)
UNION ALL
(SELECT year_month_start, COUNT(*) AS complaints, 'lowest' AS flag
 FROM complaints_clean GROUP BY year_month_start ORDER BY complaints ASC LIMIT 1);
-- highest 2023-07-01 = 1749 ; lowest 2019-02-01 = 356

-- KPI 4 and 7: Complaints by product and percentage contribution
SELECT product_short, COUNT(*) AS complaints,
       ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_total
FROM complaints_clean GROUP BY product_short ORDER BY complaints DESC;
-- Checking / savings 24814 (39.69) | Credit / prepaid card 16197 (25.91) | Credit reporting 7710 (12.33)
-- Mortgage 6601 (10.56) | Money transfer / service 3453 (5.52) | Debt collection 2736 (4.38)
-- Vehicle loan / lease 633 (1.01) | Payday / personal loan 333 (0.53) | Student loan 39 (0.06)

-- KPI 5: Complaints by reported issue (top 10)
SELECT issue, COUNT(*) AS complaints
FROM complaints_clean GROUP BY issue ORDER BY complaints DESC LIMIT 10;
-- Managing an account 15109 | Incorrect information on your report 4931 | Problem with a purchase
-- shown on your statement 4415 | Closing an account 2953 | Trouble during payment process 2827 ...

-- KPI 6a: Complaints by sub-product (top 10)
SELECT sub_product, COUNT(*) AS complaints
FROM complaints_clean GROUP BY sub_product ORDER BY complaints DESC LIMIT 10;
-- Checking account 20768 | General-purpose credit card or charge card 13404 | Credit reporting 7340 ...

-- KPI 6b: Complaints by sub-issue (top 10, including 'Not specified')
SELECT sub_issue, COUNT(*) AS complaints
FROM complaints_clean GROUP BY sub_issue ORDER BY complaints DESC LIMIT 10;
-- 'Not specified' = 10858 (blank in the source)

-- KPI 8: Company response category distribution
SELECT company_response, COUNT(*) AS complaints,
       ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_total
FROM complaints_clean GROUP BY company_response ORDER BY complaints DESC;
-- Closed with explanation 41044 | Closed with monetary relief 14697 |
-- Closed with non-monetary relief 5273 | In progress 1494 | Closed 8

-- KPI 9: Timely response rate (Yes + No only; In progress reported separately)
SELECT SUM(timely_status = 'Yes')                                          AS timely_yes,   -- 58619
       SUM(timely_status = 'No')                                           AS timely_no,    -- 2403
       SUM(timely_status IN ('Yes', 'No'))                                 AS valid_records,-- 61022
       ROUND(100 * SUM(timely_status = 'Yes') /
                   SUM(timely_status IN ('Yes', 'No')), 2)                 AS timely_pct,   -- 96.06
       SUM(timely_status = 'In progress')                                  AS excluded_in_progress -- 1494
FROM complaints_clean;

-- KPI 10: Complaints marked In progress
SELECT COUNT(*) AS in_progress FROM complaints_clean
WHERE company_response = 'In progress';                                    -- 1494

-- KPI 11a: Average forwarding interval (days)
SELECT ROUND(AVG(forwarding_days), 4) AS avg_days FROM complaints_clean;   -- 1.2249

-- KPI 11b: Median forwarding interval (days)
SELECT AVG(forwarding_days) AS median_days FROM (
    SELECT forwarding_days,
           ROW_NUMBER() OVER (ORDER BY forwarding_days) AS rn,
           COUNT(*)     OVER ()                         AS cnt
    FROM complaints_clean) t
WHERE rn IN (FLOOR((cnt + 1) / 2), FLOOR((cnt + 2) / 2));                  -- 0

-- KPI 11c: Same-day share and long intervals
SELECT ROUND(100 * SUM(forwarding_days = 0) / COUNT(*), 1) AS pct_same_day,   -- 79.4
       SUM(forwarding_days > 30)                           AS over_30_days,   -- 435
       MAX(forwarding_days)                                AS max_days        -- 275
FROM complaints_clean;

-- KPI 12: Year-over-year change (2018 and 2023 are not like-for-like: partial years)
SELECT yr, complaints,
       LAG(complaints) OVER (ORDER BY yr) AS prior_year,
       ROUND(100 * (complaints / LAG(complaints) OVER (ORDER BY yr) - 1), 2) AS yoy_pct
FROM (SELECT yr, COUNT(*) AS complaints FROM complaints_clean GROUP BY yr) y
ORDER BY yr;
-- 2018 +45.94 | 2019 -10.12 | 2020 +26.39 | 2021 +24.68 | 2022 +16.18 | 2023 -29.51

-- KPI 12b: Like-for-like check, 1 Jan to 28 Aug in 2022 vs 2023
SELECT SUM(date_submitted BETWEEN '2022-01-01' AND '2022-08-28') AS jan_aug_2022,   -- 8201
       SUM(date_submitted BETWEEN '2023-01-01' AND '2023-08-28') AS jan_aug_2023,   -- 9131
       ROUND(100 * (SUM(date_submitted BETWEEN '2023-01-01' AND '2023-08-28') /
                    SUM(date_submitted BETWEEN '2022-01-01' AND '2022-08-28') - 1), 1) AS pct_change  -- +11.3
FROM complaints_clean;


/* ---------------------------------------------------------------------
   SECTION 4: PAGE-LEVEL CHECKS (what each dashboard visual should show)
   --------------------------------------------------------------------- */

-- Page 3: Public response categories
SELECT public_response_status, COUNT(*) AS complaints
FROM complaints_clean GROUP BY public_response_status ORDER BY complaints DESC;
-- 60311 (company has responded ... chooses not to provide a public response) | 1494 | 681 | 12 | 7 | 6 | 3 | 2

-- Page 3: Untimely share by company response category (Yes/No records only)
SELECT company_response,
       SUM(timely_status = 'No') AS untimely,
       SUM(timely_status IN ('Yes', 'No')) AS valid_records,
       ROUND(100 * SUM(timely_status = 'No') / SUM(timely_status IN ('Yes', 'No')), 2) AS untimely_pct
FROM complaints_clean
WHERE company_response <> 'In progress'
GROUP BY company_response ORDER BY valid_records DESC;
-- explanation 3.72 | monetary relief 4.69 | non-monetary relief 3.38 | Closed 100.00 (8 records)

-- Page 4: Forwarding interval distribution
SELECT interval_band, COUNT(*) AS complaints
FROM complaints_clean GROUP BY interval_band
ORDER BY FIELD(interval_band, '0 days', '1-3 days', '4-7 days', '8-30 days', 'Over 30 days');
-- 49634 | 8431 | 2008 | 2008 | 435

-- Page 4: Forwarding interval by product (average, maximum, count over 30 days)
SELECT product_short, ROUND(AVG(forwarding_days), 2) AS avg_days,
       MAX(forwarding_days) AS max_days, SUM(forwarding_days > 30) AS over_30_days
FROM complaints_clean GROUP BY product_short ORDER BY avg_days DESC;
-- Student loan 2.13 | Mortgage 1.86 | Payday 1.68 | Debt collection 1.64 | Vehicle 1.44 |
-- Checking / savings 1.23 | Credit / prepaid card 1.13 | Money transfer 1.06 | Credit reporting 0.74

-- Page 4: Ten longest forwarding intervals
SELECT complaint_id, date_submitted, product_short, forwarding_days
FROM complaints_clean ORDER BY forwarding_days DESC LIMIT 10;
-- 4481803 (275) | 2879520 (181) | 3016782 (179) | 4490086 (161) | 3316804 (153) |
-- 3016783 (130) | 5773942 (129) | 5045425 (128) | 2627415 (123) | 3384869 (109)

-- Page 4: Records over 30 days by year
SELECT yr, COUNT(*) AS over_30_days
FROM complaints_clean WHERE forwarding_days > 30 GROUP BY yr ORDER BY yr;
-- 45 | 82 | 102 | 12 | 34 | 46 | 114

-- July 2023 peak by product (descriptive only; the data does not explain the cause)
SELECT product_short, COUNT(*) AS complaints
FROM complaints_clean WHERE year_month_start = '2023-07-01'
GROUP BY product_short ORDER BY complaints DESC;
-- Checking / savings 883 | Credit / prepaid card 483 | Credit reporting 182 | Money transfer / service 77 | Mortgage 60 ...


/* ---------------------------------------------------------------------
   SECTION 5: AUTOMATIC PASS / FAIL SUMMARY
   Expected values come from an independent calculation in Python (pandas).
   If every row shows PASS, SQL, pandas and the Power BI dashboard agree.
   --------------------------------------------------------------------- */
SELECT check_name, expected_value, actual_value,
       IF(expected_value = actual_value, 'PASS', 'FAIL') AS result
FROM (
    SELECT 'Rows loaded' AS check_name, '62516' AS expected_value,
           CAST((SELECT COUNT(*) FROM complaints_clean) AS CHAR) AS actual_value
    UNION ALL SELECT 'Distinct complaint IDs', '62516',
           CAST((SELECT COUNT(DISTINCT complaint_id) FROM complaints_clean) AS CHAR)
    UNION ALL SELECT 'Negative forwarding intervals', '0',
           CAST((SELECT SUM(forwarding_days < 0) FROM complaints_clean) AS CHAR)
    UNION ALL SELECT 'First date submitted', '2017-05-01',
           CAST((SELECT MIN(date_submitted) FROM complaints_clean) AS CHAR)
    UNION ALL SELECT 'Last date submitted', '2023-08-28',
           CAST((SELECT MAX(date_submitted) FROM complaints_clean) AS CHAR)
    UNION ALL SELECT 'Missing sub-issue (raw)', '10858',
           CAST((SELECT SUM(NULLIF(TRIM(`Sub-issue`), '') IS NULL) FROM complaints_raw) AS CHAR)
    UNION ALL SELECT 'Timely Yes', '58619',
           CAST((SELECT SUM(timely_status = 'Yes') FROM complaints_clean) AS CHAR)
    UNION ALL SELECT 'Timely No', '2403',
           CAST((SELECT SUM(timely_status = 'No') FROM complaints_clean) AS CHAR)
    UNION ALL SELECT 'In progress', '1494',
           CAST((SELECT COUNT(*) FROM complaints_clean WHERE company_response = 'In progress') AS CHAR)
    UNION ALL SELECT 'Timely response rate %', '96.06',
           CAST((SELECT ROUND(100 * SUM(timely_status = 'Yes') / SUM(timely_status IN ('Yes','No')), 2)
                 FROM complaints_clean) AS CHAR)
    UNION ALL SELECT 'Average forwarding interval', '1.2249',
           CAST((SELECT ROUND(AVG(forwarding_days), 4) FROM complaints_clean) AS CHAR)
    UNION ALL SELECT 'Complaints over 30 days', '435',
           CAST((SELECT SUM(forwarding_days > 30) FROM complaints_clean) AS CHAR)
    UNION ALL SELECT 'Maximum forwarding interval', '275',
           CAST((SELECT MAX(forwarding_days) FROM complaints_clean) AS CHAR)
    UNION ALL SELECT 'Complaints 2017', '5394',
           CAST((SELECT COUNT(*) FROM complaints_clean WHERE yr = 2017) AS CHAR)
    UNION ALL SELECT 'Complaints 2022', '12953',
           CAST((SELECT COUNT(*) FROM complaints_clean WHERE yr = 2022) AS CHAR)
    UNION ALL SELECT 'Complaints 2023', '9131',
           CAST((SELECT COUNT(*) FROM complaints_clean WHERE yr = 2023) AS CHAR)
    UNION ALL SELECT 'Checking / savings complaints', '24814',
           CAST((SELECT COUNT(*) FROM complaints_clean WHERE product_short = 'Checking / savings') AS CHAR)
    UNION ALL SELECT 'Mortgage complaints', '6601',
           CAST((SELECT COUNT(*) FROM complaints_clean WHERE product_short = 'Mortgage') AS CHAR)
    UNION ALL SELECT 'Distinct issues', '76',
           CAST((SELECT COUNT(DISTINCT issue) FROM complaints_clean) AS CHAR)
    UNION ALL SELECT 'Managing an account complaints', '15109',
           CAST((SELECT COUNT(*) FROM complaints_clean WHERE issue = 'Managing an account') AS CHAR)
    UNION ALL SELECT 'Pending public response (In progress)', '1494',
           CAST((SELECT COUNT(*) FROM complaints_clean WHERE public_response_status = 'Pending (In progress)') AS CHAR)
    UNION ALL SELECT 'Public response not recorded (closed)', '681',
           CAST((SELECT COUNT(*) FROM complaints_clean WHERE public_response_status = 'Not recorded (closed)') AS CHAR)
    UNION ALL SELECT 'Referral after merging Web Referral', '10856',
           CAST((SELECT COUNT(*) FROM complaints_clean WHERE submitted_via = 'Referral') AS CHAR)
    UNION ALL SELECT 'Same-day interval band', '49634',
           CAST((SELECT COUNT(*) FROM complaints_clean WHERE interval_band = '0 days') AS CHAR)
    UNION ALL SELECT 'July 2023 complaints (peak month)', '1749',
           CAST((SELECT COUNT(*) FROM complaints_clean WHERE year_month_start = '2023-07-01') AS CHAR)
) checks;

/* ---------------------------------------------------------------------
   SECTION 6: CHECKS BEHIND THE BUSINESS INSIGHTS
   Each query reproduces a figure used in Week4_Insights_and_Recommendations.docx.
   --------------------------------------------------------------------- */

-- 6.1 Concentration: share of complaints held by the two and three largest products
SELECT SUM(CASE WHEN rnk <= 2 THEN n END)                                  AS top2_complaints,   -- 41011
       ROUND(100 * SUM(CASE WHEN rnk <= 2 THEN n END) / SUM(n), 1)         AS top2_pct,          -- 65.6
       ROUND(100 * SUM(CASE WHEN rnk <= 3 THEN n END) / SUM(n), 1)         AS top3_pct           -- 77.9
FROM (SELECT product_short, COUNT(*) AS n,
             ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS rnk
      FROM complaints_clean GROUP BY product_short) p;

-- 6.2 Managing an account: share of all complaints and of Checking / savings complaints
SELECT SUM(issue = 'Managing an account')                                            AS managing_account,   -- 15109
       ROUND(100 * SUM(issue = 'Managing an account') / COUNT(*), 1)                 AS pct_of_all,         -- 24.2
       ROUND(100 * SUM(issue = 'Managing an account' AND product_short = 'Checking / savings')
                 / SUM(product_short = 'Checking / savings'), 1)                     AS pct_of_checking     -- 60.9
FROM complaints_clean;

-- 6.3 Issues that appear under exactly one product
SELECT SUM(products = 1) AS single_product_issues,   -- 63
       COUNT(*)          AS total_issues             -- 76
FROM (SELECT issue, COUNT(DISTINCT product_short) AS products
      FROM complaints_clean GROUP BY issue) i;

-- 6.4 Growth 2018 to 2022 (full years)
SELECT ROUND(100 * (SUM(yr = 2022) / SUM(yr = 2018) - 1), 1) AS growth_2018_to_2022_pct   -- 64.5
FROM complaints_clean;

-- 6.5 Recorded untimely rate by year (Yes + No records only)
SELECT yr, SUM(timely_status IN ('Yes', 'No')) AS valid_records,
       SUM(timely_status = 'No')               AS untimely,
       ROUND(100 * SUM(timely_status = 'No') / SUM(timely_status IN ('Yes', 'No')), 2) AS untimely_pct
FROM complaints_clean GROUP BY yr ORDER BY yr;
-- 2017 0.17 | 2018 0.15 | 2019 0.10 | 2020 0.69 | 2021 10.98 (1224 of 11149) | 2022 4.38 | 2023 6.84 (522 of 7637)

-- 6.6 Highest monthly untimely rate (months with at least 500 valid records)
SELECT year_month_start, SUM(timely_status IN ('Yes', 'No')) AS valid_records,
       SUM(timely_status = 'No') AS untimely,
       ROUND(100 * SUM(timely_status = 'No') / SUM(timely_status IN ('Yes', 'No')), 1) AS untimely_pct
FROM complaints_clean GROUP BY year_month_start
HAVING valid_records >= 500 ORDER BY untimely_pct DESC LIMIT 3;
-- 2021-06-01: 389 of 934 = 41.6

-- 6.7 In progress complaints by month received
SELECT year_month_start, COUNT(*) AS in_progress
FROM complaints_clean WHERE company_response = 'In progress'
GROUP BY year_month_start ORDER BY year_month_start;
-- 2023-05: 7 | 2023-06: 37 | 2023-07: 863 | 2023-08: 587  (first one received 2023-05-12)

-- 6.8 July 2023: share still In progress
SELECT COUNT(*) AS july_2023, SUM(company_response = 'In progress') AS in_progress,
       ROUND(100 * SUM(company_response = 'In progress') / COUNT(*), 1) AS pct_in_progress
FROM complaints_clean WHERE year_month_start = '2023-07-01';     -- 1749 / 863 / 49.3

-- 6.9 Monthly alert: months above 1.25 x the trailing 12-month average
SELECT year_month_start, complaints, ROUND(trailing_avg, 0) AS trailing_12m_avg,
       ROUND(complaints / trailing_avg, 2) AS ratio
FROM (SELECT year_month_start, COUNT(*) AS complaints,
             AVG(COUNT(*)) OVER (ORDER BY year_month_start ROWS BETWEEN 12 PRECEDING AND 1 PRECEDING) AS trailing_avg,
             COUNT(COUNT(*)) OVER (ORDER BY year_month_start ROWS BETWEEN 12 PRECEDING AND 1 PRECEDING) AS history_months
      FROM complaints_clean GROUP BY year_month_start) m
WHERE history_months = 12 AND complaints / trailing_avg > 1.25
ORDER BY ratio DESC;
-- 8 months flagged out of 64 with 12 months of history; highest = 2023-07 (1749 vs 1133, ratio 1.54)

-- 6.10 Long forwarding intervals as a share of each product's complaints
SELECT product_short, COUNT(*) AS complaints, SUM(forwarding_days > 30) AS over_30,
       ROUND(100 * SUM(forwarding_days > 30) / COUNT(*), 2) AS over_30_pct
FROM complaints_clean GROUP BY product_short ORDER BY over_30_pct DESC;
-- Vehicle loan / lease 1.42 | Mortgage 1.41 | Debt collection 0.77 | Money transfer 0.75 |
-- Credit / prepaid card 0.65 | Checking / savings 0.63 | Credit reporting 0.32 | Payday 0 | Student loan 0

-- 6.11 Blank sub-issue rate by product
SELECT product_short, COUNT(*) AS complaints, SUM(sub_issue = 'Not specified') AS blank_sub_issue,
       ROUND(100 * SUM(sub_issue = 'Not specified') / COUNT(*), 1) AS blank_pct
FROM complaints_clean GROUP BY product_short ORDER BY blank_pct DESC;
-- Money transfer 100.0 | Mortgage 96.4 | Payday 93.1 | Credit / prepaid card 3.6 | Credit reporting 1.8 | Checking 0.1
-- Debt collection, Student loan, Vehicle: 0.0

-- 6.12 Complaints by product and year (full years 2018 to 2022 for growth comparisons)
SELECT product_short,
       SUM(yr = 2018) AS y2018, SUM(yr = 2022) AS y2022,
       ROUND(100 * (SUM(yr = 2022) / SUM(yr = 2018) - 1), 0) AS change_pct
FROM complaints_clean
WHERE product_short IN ('Checking / savings', 'Credit / prepaid card', 'Credit reporting', 'Mortgage')
GROUP BY product_short;
-- Checking 3176 -> 5186 (+63) | Credit card 1804 -> 3445 (+91) | Credit reporting 761 -> 1858 (+144) | Mortgage 1294 -> 774 (-40)