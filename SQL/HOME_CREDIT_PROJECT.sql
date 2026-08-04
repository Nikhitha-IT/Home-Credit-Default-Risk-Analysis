/*=========================================================
PROJECT NAME  : Home Credit Default Risk Analysis
AUTHOR        : Nikhitha Boda
DOMAIN        : Banking / Financial Services
DATABASE      : MySQL
DATASET       : Home Credit Default Risk
PROJECT TYPE  : End-to-End SQL Portfolio Project

DESCRIPTION:
This project analyzes customer loan applications and credit
history to identify default risk, customer behavior, and
business insights using SQL.

TOOLS USED:
• MySQL
• SQL Workbench
• Power BI
• GitHub

TABLES USED:
1. application_train
2. bureau
3. previous_application
4. installments_payments
=========================================================*/
/*=========================================================
BUSINESS PROBLEM STATEMENT
===========================================================

A financial institution aims to reduce the risk of loan defaults
by identifying customers who are more likely to face repayment
difficulties. The bank wants to analyze customer demographics,
credit history, previous loan applications, and installment
payment behavior to understand the key factors influencing loan
default.

This project uses SQL to transform raw banking data into
meaningful business insights. By analyzing customer profiles,
loan history, and repayment patterns, the project helps identify
high-risk customer segments, evaluate loan performance, and
support data-driven lending decisions.

The analysis focuses on customer segmentation, credit risk
assessment, repayment trends, and overall loan portfolio
performance using real-world banking data.
=========================================================*/
/*=========================================================
PROJECT OBJECTIVES
===========================================================

The primary objective of this project is to perform a
comprehensive analysis of customer loan applications and
credit history using SQL to generate meaningful business
insights for a financial institution.

Specific objectives include:

• Analyze customer demographics and financial information.
• Evaluate previous credit history and loan performance.
• Identify factors associated with loan default.
• Study installment payment behavior and repayment trends.
• Segment customers based on income, education, family
  status, and occupation.
• Calculate key business KPIs related to lending.
• Demonstrate SQL concepts including Joins, CTEs, Views,
  Aggregate Functions, Window Functions, and Ranking.
• Support data-driven decision making for credit risk
  assessment and loan approval strategies.

=========================================================*/
/*=========================================================
DATASET DESCRIPTION
===========================================================

This project uses four relational tables from the Home Credit
Default Risk dataset.

1. application_train
--------------------
Contains customer loan application details including
demployment, income, education, family status, housing,
loan amount, and target variable indicating loan default.

Primary Key:
SK_ID_CURR

---------------------------------------------------------

2. bureau
---------
Contains customers' previous credit history obtained from
external financial institutions.

Important Fields:
• Credit Status
• Credit Amount
• Debt
• Credit Duration
• Overdue Information

Foreign Key:
SK_ID_CURR

---------------------------------------------------------

3. previous_application
------------------------
Contains historical loan applications submitted by customers
before their current application.

Important Fields:
• Loan Amount
• Contract Type
• Application Status
• Interest Information
• Payment Details

Foreign Key:
SK_ID_CURR

---------------------------------------------------------

4. installments_payments
-------------------------
Contains installment payment history including payment
amounts, due dates, delays, and repayment behavior.

Foreign Key:
SK_ID_CURR

=========================================================*/

/* =====================================================
-- PART 1 : DATABASE DESIGN & DATA IMPORT
===========================================================
This section focuses on designing the relational database,
creating tables, defining appropriate data types, and
importing raw CSV files into MySQL.

Activities performed include:

• Creating the project database.
• Creating relational tables.
• Defining primary identifiers.
• Importing CSV files.
• Validating imported records.
• Handling import errors.
• Using LOAD DATA LOCAL INFILE.
• Preparing the database for analytical queries.
=========================================================*/
-- 1. Creating the Database
CREATE DATABASE home_credit_project;
USE home_credit_project;


-- 2. Creating application_train Table
-- Main table: one row per loan application, 21 selected columns
CREATE TABLE application_train (
    SK_ID_CURR INT PRIMARY KEY,
    TARGET TINYINT,
    NAME_CONTRACT_TYPE VARCHAR(30),
    CODE_GENDER VARCHAR(5),
    FLAG_OWN_CAR VARCHAR(1),
    FLAG_OWN_REALTY VARCHAR(1),
    CNT_CHILDREN INT,
    AMT_INCOME_TOTAL DECIMAL(12,2),
    AMT_CREDIT DECIMAL(12,2),
    AMT_ANNUITY DECIMAL(12,2),
    AMT_GOODS_PRICE DECIMAL(12,2),
    NAME_INCOME_TYPE VARCHAR(30),
    NAME_EDUCATION_TYPE VARCHAR(50),
    NAME_FAMILY_STATUS VARCHAR(30),
    NAME_HOUSING_TYPE VARCHAR(30),
    DAYS_BIRTH INT,
    DAYS_EMPLOYED INT,
    OCCUPATION_TYPE VARCHAR(30),
    CNT_FAM_MEMBERS INT,
    REGION_RATING_CLIENT INT,
    ORGANIZATION_TYPE VARCHAR(50)
);


-- 3. Importing CSV Data into application_train
-- Note: local_infile must be enabled on both client and server side
SHOW GLOBAL VARIABLES LIKE 'local_infile';
SET GLOBAL local_infile = 1;

LOAD DATA LOCAL INFILE 'C:/Users/nikhi/Downloads/application_train_trimmed.csv'
INTO TABLE application_train
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT COUNT(*) FROM application_train;  -- Expected: 307511


-- 4. Creating the bureau Table
-- Applicant's credit history from other financial institutions
CREATE TABLE bureau (
    SK_ID_CURR INT,
    SK_ID_BUREAU INT PRIMARY KEY,
    CREDIT_ACTIVE VARCHAR(20),
    CREDIT_CURRENCY VARCHAR(20),
    DAYS_CREDIT INT,
    CREDIT_DAY_OVERDUE INT,
    DAYS_CREDIT_ENDDATE INT,
    AMT_CREDIT_MAX_OVERDUE DECIMAL(14,2),
    CNT_CREDIT_PROLONG INT,
    AMT_CREDIT_SUM DECIMAL(14,2),
    AMT_CREDIT_SUM_DEBT DECIMAL(14,2),
    AMT_CREDIT_SUM_OVERDUE DECIMAL(14,2),
    CREDIT_TYPE VARCHAR(50),
    FOREIGN KEY (SK_ID_CURR) REFERENCES application_train(SK_ID_CURR)
);

-- 5. Importing bureau Data
LOAD DATA LOCAL INFILE 'C:/Users/nikhi/Downloads/bureau_trimmed.csv'
INTO TABLE bureau
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT COUNT(*) FROM bureau;  -- Expected: 1465325 (orphan applicant_test IDs excluded via FK)


-- 6. Creating the previous_application Table
-- Applicant's past loan applications with Home Credit itself
CREATE TABLE previous_application (
    SK_ID_PREV INT PRIMARY KEY,
    SK_ID_CURR INT,
    NAME_CONTRACT_TYPE VARCHAR(30),
    AMT_ANNUITY DECIMAL(12,2),
    AMT_APPLICATION DECIMAL(12,2),
    AMT_CREDIT DECIMAL(12,2),
    AMT_GOODS_PRICE DECIMAL(12,2),
    NAME_CONTRACT_STATUS VARCHAR(30),
    DAYS_DECISION INT,
    NAME_PAYMENT_TYPE VARCHAR(50),
    CODE_REJECT_REASON VARCHAR(30),
    NAME_CLIENT_TYPE VARCHAR(30),
    CNT_PAYMENT DECIMAL(5,1),
    FOREIGN KEY (SK_ID_CURR) REFERENCES application_train(SK_ID_CURR)
);

-- 7. Importing previous_application Data
LOAD DATA LOCAL INFILE 'C:/Users/nikhi/Downloads/previous_application_trimmed.csv'
INTO TABLE previous_application
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT COUNT(*) FROM previous_application;  -- Expected: 1413701


-- 8. Creating the installments_payments Table
-- Actual repayment/installment history — largest table, no single-column primary key
CREATE TABLE installments_payments (
    SK_ID_PREV INT,
    SK_ID_CURR INT,
    NUM_INSTALMENT_VERSION DECIMAL(10,2),
    NUM_INSTALMENT_NUMBER INT,
    DAYS_INSTALMENT DECIMAL(10,2),
    DAYS_ENTRY_PAYMENT DECIMAL(10,2),
    AMT_INSTALMENT DECIMAL(12,2),
    AMT_PAYMENT DECIMAL(12,2),
    FOREIGN KEY (SK_ID_CURR) REFERENCES application_train(SK_ID_CURR)
);

-- 9. Importing installments_payments Data
-- Note: due to file size (13.6M rows), foreign_key_checks and unique_checks
-- were temporarily disabled during this specific load, then re-enabled after.
SET foreign_key_checks = 0;
SET unique_checks = 0;

LOAD DATA LOCAL INFILE 'C:/Users/nikhi/Downloads/installments_payments.csv/installments_payments.csv'
INTO TABLE installments_payments
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

COMMIT;
SET foreign_key_checks = 1;
SET unique_checks = 1;

SELECT COUNT(*) FROM installments_payments;  -- Expected: 13605401

SHOW TABLES;


/*=========================================================
PART 2 : SQL ANALYSIS
===========================================================

This section contains SQL queries developed to analyze
customer loan applications, repayment behavior, and
credit history.

The analysis progresses from basic SQL concepts to
advanced analytical techniques including:

• Aggregate Functions
• GROUP BY Analysis
• HAVING Clause
• Multi-table Joins
• Common Table Expressions (CTEs)
• Views
• Window Functions
• Ranking
• Running Totals
• Customer Segmentation

The objective is to transform raw banking data into
meaningful business insights for decision makers.

=========================================================*/
/*=========================================================
SQL CONCEPTS COVERED
===========================================================

Database Design

✓ CREATE DATABASE
✓ CREATE TABLE
✓ Data Types
✓ Constraints

---------------------------------------------------------

Data Import

✓ LOAD DATA LOCAL INFILE
✓ TRUNCATE TABLE
✓ Data Validation

---------------------------------------------------------

Data Analysis

✓ SELECT
✓ WHERE
✓ DISTINCT
✓ ORDER BY
✓ LIMIT

---------------------------------------------------------

Aggregate Functions

✓ COUNT()
✓ SUM()
✓ AVG()
✓ MIN()
✓ MAX()

---------------------------------------------------------

Grouping

✓ GROUP BY
✓ HAVING

---------------------------------------------------------

Joins

✓ INNER JOIN
✓ LEFT JOIN

---------------------------------------------------------

Advanced SQL

✓ Common Table Expressions (CTE)
✓ VIEW
✓ CASE Statement

---------------------------------------------------------

Window Functions

✓ RANK()
✓ NTILE()
✓ LAG()
✓ SUM() OVER()

=========================================================*/
-- =====================================================
-- ---------- SECTION A: BASELINE AGGREGATION ----------

-- A1. Overall default rate baseline (application_train)
SELECT 
    COUNT(*) AS total_applications,
    SUM(TARGET) AS total_defaults,
    ROUND(AVG(TARGET) * 100, 2) AS default_rate_percent,
    ROUND(AVG(AMT_INCOME_TOTAL), 2) AS avg_income,
    ROUND(AVG(AMT_CREDIT), 2) AS avg_credit_amount
FROM application_train;

-- ---------- SECTION B: GROUP BY & HAVING ----------

-- B1. Default rate by gender
SELECT 
    CODE_GENDER,
    COUNT(*) AS total_applications,
    SUM(TARGET) AS total_defaults,
    ROUND(AVG(TARGET) * 100, 2) AS default_rate_percent
FROM application_train
GROUP BY CODE_GENDER
ORDER BY default_rate_percent DESC;

-- B2. Default rate by education level
SELECT 
    NAME_EDUCATION_TYPE,
    COUNT(*) AS total_applications,
    SUM(TARGET) AS total_defaults,
    ROUND(AVG(TARGET) * 100, 2) AS default_rate_percent,
    ROUND(AVG(AMT_INCOME_TOTAL), 2) AS avg_income
FROM application_train
GROUP BY NAME_EDUCATION_TYPE
ORDER BY default_rate_percent DESC;

-- B3. Default rate by income type, filtered to statistically meaningful group sizes
SELECT 
    NAME_INCOME_TYPE,
    COUNT(*) AS total_applicants,
    ROUND(AVG(TARGET) * 100, 2) AS default_rate_percent,
    RANK() OVER (ORDER BY AVG(TARGET) DESC) AS risk_rank
FROM application_train
GROUP BY NAME_INCOME_TYPE
HAVING COUNT(*) >= 1000
ORDER BY default_rate_percent DESC;

-- B4. Top 10 riskiest organization types (filtered to reliable sample sizes)
SELECT 
    ORGANIZATION_TYPE,
    COUNT(*) AS total_applicants,
    ROUND(AVG(TARGET) * 100, 2) AS default_rate_percent
FROM application_train
GROUP BY ORGANIZATION_TYPE
HAVING COUNT(*) >= 500
ORDER BY default_rate_percent DESC
LIMIT 10;

-- ---------- SECTION C: JOINS ----------

-- C1. Applicant bureau record count (LEFT JOIN, application_train + bureau)
SELECT 
    a.SK_ID_CURR,
    a.TARGET,
    COUNT(b.SK_ID_BUREAU) AS num_bureau_records
FROM application_train a
LEFT JOIN bureau b ON a.SK_ID_CURR = b.SK_ID_CURR
GROUP BY a.SK_ID_CURR, a.TARGET
LIMIT 20;

-- C2. Does bureau history relate to default risk? (JOIN + subquery)
SELECT 
    CASE 
        WHEN bureau_count = 0 THEN 'No Bureau History'
        WHEN bureau_count BETWEEN 1 AND 5 THEN '1-5 Records'
        WHEN bureau_count BETWEEN 6 AND 10 THEN '6-10 Records'
        ELSE '10+ Records'
    END AS bureau_history_group,
    COUNT(*) AS total_applicants,
    ROUND(AVG(TARGET) * 100, 2) AS default_rate_percent
FROM (
    SELECT 
        a.SK_ID_CURR,
        a.TARGET,
        COUNT(b.SK_ID_BUREAU) AS bureau_count
    FROM application_train a
    LEFT JOIN bureau b ON a.SK_ID_CURR = b.SK_ID_CURR
    GROUP BY a.SK_ID_CURR, a.TARGET
) AS applicant_bureau_summary
GROUP BY bureau_history_group
ORDER BY default_rate_percent DESC;

-- C3. Same result as C2, rewritten as a CTE (cleaner, more readable structure)
WITH applicant_bureau_summary AS (
    SELECT 
        a.SK_ID_CURR,
        a.TARGET,
        COUNT(b.SK_ID_BUREAU) AS bureau_count
    FROM application_train a
    LEFT JOIN bureau b ON a.SK_ID_CURR = b.SK_ID_CURR
    GROUP BY a.SK_ID_CURR, a.TARGET
)
SELECT 
        CASE 
        WHEN bureau_count = 0 THEN 'No Bureau History'
        WHEN bureau_count BETWEEN 1 AND 5 THEN '1-5 Records'
        WHEN bureau_count BETWEEN 6 AND 10 THEN '6-10 Records'
        ELSE '10+ Records'
    END AS bureau_history_group,
    COUNT(*) AS total_applicants,
    ROUND(AVG(TARGET) * 100, 2) AS default_rate_percent
FROM applicant_bureau_summary
GROUP BY bureau_history_group 
ORDER BY default_rate_percent DESC;

-- C4. Joining a third table: does refusal history in previous_application relate to default risk?
WITH prev_summary AS (
        SELECT 
        SK_ID_CURR,
        COUNT(*) AS total_prev_applications,
        SUM(CASE WHEN NAME_CONTRACT_STATUS = 'Refused' THEN 1 ELSE 0 END) AS times_refused,
        SUM(CASE WHEN NAME_CONTRACT_STATUS = 'Approved' THEN 1 ELSE 0 END) AS times_approved
    FROM previous_application GROUP BY SK_ID_CURR
)
SELECT 
        CASE 
        WHEN times_refused = 0 THEN 'Never Refused'
        WHEN times_refused BETWEEN 1 AND 2 THEN 'Refused 1-2 Times'
        ELSE 'Refused 3+ Times'
    END AS refusal_history,
    COUNT(*) AS total_applicants,
    ROUND(AVG(a.TARGET) * 100, 2) AS default_rate_percent
FROM application_train a
JOIN prev_summary p ON a.SK_ID_CURR = p.SK_ID_CURR
GROUP BY refusal_history 
HAVING COUNT(*) >= 1000
ORDER BY default_rate_percent DESC;


-- ---------- SECTION D: ADVANCED SQL — WINDOW FUNCTIONS & VIEWS ----------

-- D1. Running total of applicants by income type
SELECT 
    NAME_INCOME_TYPE,
    COUNT(*) AS total_applicants,
    SUM(COUNT(*)) OVER (ORDER BY COUNT(*) DESC) AS running_total
FROM application_train
GROUP BY NAME_INCOME_TYPE
ORDER BY total_applicants DESC;

-- D2. Creating a reusable VIEW joining all three main tables
CREATE VIEW applicant_risk_summary AS
SELECT 
    a.SK_ID_CURR,
    a.TARGET,
    a.CODE_GENDER,
    a.NAME_EDUCATION_TYPE,
    a.NAME_INCOME_TYPE,
    a.AMT_INCOME_TOTAL,
    a.AMT_CREDIT,
    COUNT(DISTINCT b.SK_ID_BUREAU) AS bureau_record_count,
    COUNT(DISTINCT p.SK_ID_PREV) AS previous_application_count
FROM application_train a
LEFT JOIN bureau b ON a.SK_ID_CURR = b.SK_ID_CURR
LEFT JOIN previous_application p ON a.SK_ID_CURR = p.SK_ID_CURR
GROUP BY a.SK_ID_CURR, a.TARGET, a.CODE_GENDER, a.NAME_EDUCATION_TYPE, 
         a.NAME_INCOME_TYPE, a.AMT_INCOME_TOTAL, a.AMT_CREDIT;

SELECT * FROM applicant_risk_summary LIMIT 10;

-- D3. NTILE() — splitting applicants into income quartiles
WITH income_quartiles AS (
    SELECT 
        SK_ID_CURR,
        TARGET,
        AMT_INCOME_TOTAL,
        NTILE(4) OVER (ORDER BY AMT_INCOME_TOTAL) AS income_quartile
    FROM application_train
)
SELECT 
    income_quartile,
    COUNT(*) AS total_applicants,
    ROUND(MIN(AMT_INCOME_TOTAL), 2) AS min_income_in_group,
    ROUND(MAX(AMT_INCOME_TOTAL), 2) AS max_income_in_group,
    ROUND(AVG(TARGET) * 100, 2) AS default_rate_percent
FROM income_quartiles
GROUP BY income_quartile
ORDER BY income_quartile;

-- D4. LAG() — comparing each income quartile's default rate to the previous quartile    
WITH quartile_summary AS (
    SELECT 
        NTILE(4) OVER (ORDER BY AMT_INCOME_TOTAL) AS income_quartile,
        TARGET
    FROM application_train
),
quartile_rates AS (
    SELECT 
        income_quartile,
        ROUND(AVG(TARGET) * 100, 2) AS default_rate_percent
    FROM quartile_summary
    GROUP BY income_quartile
)
SELECT 
    income_quartile,
    default_rate_percent,
    LAG(default_rate_percent) OVER (ORDER BY income_quartile) AS previous_quartile_rate,
    ROUND(default_rate_percent - LAG(default_rate_percent) OVER (ORDER BY income_quartile), 2) AS change_from_previous
FROM quartile_rates 
ORDER BY income_quartile;

-- ---------- SECTION E: FINAL BUSINESS QUESTIONS ----------
/*=========================================================
FINAL BUSINESS INSIGHTS
===========================================================

Based on the SQL analysis, the following business insights
can be derived:

• Customer income and employment characteristics have a
  significant impact on loan repayment behavior.

• Customers with adverse credit history demonstrate a
  higher probability of loan default.

• Previous loan performance is a strong indicator of
  future credit risk.

• Installment payment delays are closely associated with
  repayment difficulties.

• Customer segmentation helps identify high-risk and
  low-risk borrower groups.

• Credit history analysis supports more accurate loan
  approval decisions.

These insights can help financial institutions improve
risk management strategies and optimize lending policies.

=========================================================*/

-- E1. Most common reasons for loan rejection
SELECT 
    CODE_REJECT_REASON,
    COUNT(*) AS total_rejections
FROM previous_application
WHERE NAME_CONTRACT_STATUS = 'Refused'
GROUP BY CODE_REJECT_REASON
ORDER BY total_rejections DESC;

-- E2. Credit-to-income ratio risk banding
SELECT 
    CASE 
        WHEN AMT_CREDIT / AMT_INCOME_TOTAL < 2 THEN 'Low Ratio (<2x)'
        WHEN AMT_CREDIT / AMT_INCOME_TOTAL BETWEEN 2 AND 5 THEN 'Medium Ratio (2-5x)'
        ELSE 'High Ratio (5x+)'
    END AS credit_income_ratio_band,
    COUNT(*) AS total_applicants,
    ROUND(AVG(TARGET) * 100, 2) AS default_rate_percent
FROM application_train
GROUP BY credit_income_ratio_band
ORDER BY default_rate_percent DESC;

-- E3. Default rate by family status
SELECT 
    NAME_FAMILY_STATUS,
    COUNT(*) AS total_applicants,
    ROUND(AVG(TARGET) * 100, 2) AS default_rate_percent
FROM application_train
GROUP BY NAME_FAMILY_STATUS
HAVING COUNT(*) >= 500
ORDER BY default_rate_percent DESC;

-- E4. Installment payment behavior — average days late per payment
-- Positive value = paid late, negative/zero = paid on time or early
SELECT 
    ROUND(AVG(DAYS_ENTRY_PAYMENT - DAYS_INSTALMENT), 2) AS avg_days_late,
    ROUND(AVG(AMT_PAYMENT - AMT_INSTALMENT), 2) AS avg_payment_shortfall
FROM installments_payments
WHERE DAYS_ENTRY_PAYMENT IS NOT NULL;

-- E5. Default rate comparison: applicants who paid installments late vs on time
CREATE TABLE payment_behavior_summary AS
SELECT 
    SK_ID_CURR,
    AVG(DAYS_ENTRY_PAYMENT - DAYS_INSTALMENT) AS avg_days_late
FROM installments_payments
WHERE DAYS_ENTRY_PAYMENT IS NOT NULL
GROUP BY SK_ID_CURR;

SELECT 
    CASE 
        WHEN avg_days_late <= 0 THEN 'Paid On Time / Early'
        ELSE 'Paid Late On Average'
    END AS payment_behavior_group,
    COUNT(*) AS total_applicants,
    ROUND(AVG(a.TARGET) * 100, 2) AS default_rate_percent
FROM application_train a
JOIN payment_behavior_summary p ON a.SK_ID_CURR = p.SK_ID_CURR
GROUP BY payment_behavior_group
ORDER BY default_rate_percent DESC;
-- Result: Paid Late On Average → 11.82% default rate (8,226 applicants)
--         Paid On Time / Early → 8.08% default rate (283,417 applicants)


/*=========================================================
-- Key Business Findings:
===========================================================
-- - Overall default rate: 8.07%
-- - Male applicants default at a higher rate than female applicants (10.14% vs 7.00%)
-- - Default rate decreases steadily as education level rises (10.93% down to 1.83%)
-- - Applicants with NO bureau credit history default at a higher rate (10.12%)
--   than those with an established credit history
-- - Applicants refused 3+ times previously default nearly twice as often
--   as those never refused (12.61% vs 7.07%)
-- - Working professionals are the highest-risk large income segment (9.59%)
-- - Late installment payment behavior is associated with higher default risk
-- =====================================================*/

/*=========================================================
PROJECT SUMMARY
===========================================================

Project Name
------------
Home Credit Default Risk Analysis using SQL

---------------------------------------------------------

Domain
------
Banking & Financial Services

---------------------------------------------------------

Database
--------
MySQL

---------------------------------------------------------

Dataset
-------
Home Credit Default Risk

---------------------------------------------------------

Tables Used
-----------
• application_train
• bureau
• previous_application
• installments_payments

---------------------------------------------------------

SQL Concepts Implemented
------------------------
✓ Database Design
✓ Data Import
✓ Aggregate Functions
✓ GROUP BY
✓ HAVING
✓ INNER JOIN
✓ LEFT JOIN
✓ Common Table Expressions
✓ Views
✓ Window Functions
✓ Ranking Functions
✓ Running Totals

---------------------------------------------------------

Business Areas Covered
----------------------
✓ Customer Analysis
✓ Credit Risk Analysis
✓ Loan Performance
✓ Installment Payment Analysis
✓ Customer Segmentation
✓ Business KPI Reporting

---------------------------------------------------------

Project Outcome
---------------
This project demonstrates the practical application of SQL
for solving real-world banking and credit risk problems.
The analysis provides valuable business insights that can
support informed lending decisions, improve risk assessment,
and enhance overall loan portfolio performance.

==================== END OF PROJECT ======================
*/
