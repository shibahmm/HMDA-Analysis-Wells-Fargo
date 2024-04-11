-- Wells Fargo HMDA Data Analysis

-- 1.1 How many total apps are in your data?
SELECT COUNT(*) AS total_applications
FROM `learning-sql-exercises-5718280.Wells_Fargo.Loan_Apps_Results`;

-- 1.2 How many distinct "states"?
SELECT COUNT(DISTINCT state_abbr) AS distinct_states
FROM learning-sql-exercises-5718280.Wells_Fargo.Loan_Apps_Results;

-- 1.3 How many apps are from MN (across all years)?
SELECT COUNT(*) AS applications_from_MN
FROM learning-sql-exercises-5718280.Wells_Fargo.Loan_Apps_Results
WHERE state_abbr = 'MN';

-- 1.4 What % of total apps are for properties located in metro areas (versus non-metro areas)?
SELECT AVG(metro) * 100 AS percent_metro
FROM learning-sql-exercises-5718280.Wells_Fargo.Loan_Apps_Results;


-- 2.1 What is the mean loan-to-income ratio for Minnesota? For Texas?
SELECT
  state_abbr,
  AVG(loan_to_income) AS mean_loan_to_income
FROM
  learning-sql-exercises-5718280.Wells_Fargo.Loan_Apps_Results
WHERE
  state_abbr IN ('MN', 'TX')
GROUP BY
  state_abbr;

-- 2.2 What are the most extreme loan/income ratios in your data (highest and lowest three observations)? 

-- Smallest loans
SELECT
  loan_to_income
FROM
  learning-sql-exercises-5718280.Wells_Fargo.Loan_Apps_Results
ORDER BY
  loan_to_income
LIMIT 3;

-- Largest loans
SELECT
  loan_to_income
FROM
  learning-sql-exercises-5718280.Wells_Fargo.Loan_Apps_Results
ORDER BY
  loan_to_income DESC
LIMIT 3;

-- 2.3 Do you feel they are realistic or data errors?
-- Answered in GDocs


-- 3.1 Average rejection rate for each of the 5 mains applicant race categories
SELECT
  applicant_race_name,
  AVG(denial) AS avg_rejection_rate
FROM
  `learning-sql-exercises-5718280.Wells_Fargo.Loan_Apps_Results`
GROUP BY
  applicant_race_name;

-- 3.2 Most common denial reason is debt-to-income ratio. The second-most commonly used denial reason overall and for each race category?
CREATE OR REPLACE TABLE Wells_Fargo.denials AS
SELECT denial_reason_name, COUNT(*) AS instances
FROM `learning-sql-exercises-5718280.Wells_Fargo.Loan_Apps_Results`
WHERE  denial = 1
GROUP BY  denial_reason_name
ORDER BY instances DESC;

SELECT denial_reason_name, applicant_race_name, COUNT(*) AS instances
FROM `learning-sql-exercises-5718280.Wells_Fargo.Loan_Apps_Results`
WHERE  denial = 1
GROUP BY  denial_reason_name,  applicant_race_name
ORDER BY  applicant_race_name,  instances DESC;

SELECT applicant_race_name,denial_reason_name,instances, instances / SUM(instances) OVER (PARTITION BY applicant_race_name) * 100 AS percentage
FROM
  Wells_Fargo.denials
ORDER BY
  applicant_race_name,
  instances DESC;


-- 3.3 Why an applicant refuses to disclose his/her race. Implications of this "selection issues" on interpreting differences in rejection rates. Economic reasons explanations for difference in rejection rate across rates?
-- Answered in GDoc


-- 4.1 Percentage of orignated total loans (action_taken = 1)
SELECT
  AVG(IF(action_taken = 1, 1, 0))*100 AS originated_percentage
FROM
  `learning-sql-exercises-5718280.Wells_Fargo.Loan_Apps_Results`;


-- 4.2 Percentage of loans that aree subsequently sold to a gov guaranteed agency
SELECT
  AVG(IF(gov = 1, 1, 0))*100 AS sold_to_government_percentage
FROM
  `learning-sql-exercises-5718280.Wells_Fargo.Loan_Apps_Results`;



-- Part 4: Machine Learning
-- 5.1: Create the model
CREATE OR REPLACE MODEL Wells_Fargo.Loan_Apps_Model
OPTIONS(
    input_label_cols = ['denial'],
    model_type = 'logistic_reg',
    auto_class_weights = TRUE,
    calculate_p_values=true, 
    category_encoding_method='dummy_encoding'
)
AS
SELECT
    denial,
    black,
    female,
    loan_amount_000s,
    applicant_income_000s,
    loan_to_income,
    loan_type,
    gov,
FROM
    `learning-sql-exercises-5718280`.Wells_Fargo.Loan_Apps_Results;

-- 5.2: Evaluate the model

-- 5.3: Get weights (coefficients)
SELECT
    *
FROM
    ML.WEIGHTS(MODEL Wells_Fargo.Loan_Apps_Model, STRUCT(true AS standardize));

-- p value:
select * from ml.advanced_weights(MODEL Wells_Fargo.Loan_Apps_Model);


-- 6.
SELECT AVG(loan_amount_000s) AS avg_loan_amount FROM
`learning-sql-exercises-5718280`.Wells_Fargo.Loan_Apps_Results;

SELECT AVG(applicant_income_000s) AS avg_applicant_income FROM
`learning-sql-exercises-5718280`.Wells_Fargo.Loan_Apps_Results;

SELECT AVG(hud_median_family_income) AS avg_hud_median_family_income FROM
`learning-sql-exercises-5718280`.Wells_Fargo.Loan_Apps_Results;

SELECT AVG(tract_to_msamd_income) AS avg_tract_to_msamd_income FROM
`learning-sql-exercises-5718280`.Wells_Fargo.Loan_Apps_Results;

SELECT AVG(loan_to_income) AS avg_loan_to_income FROM
`learning-sql-exercises-5718280`.Wells_Fargo.Loan_Apps_Results;


SELECT * FROM ML.PREDICT(MODEL `learning-sql-exercises-5718280.Wells_Fargo.Loan_Apps_Model`,
(SELECT
CAST(364.3138394756 AS INT64) AS loan_amount_000s,
CAST(143.1535279598 AS INT64) AS applicant_income_000s,
CAST(73296.12988339 AS INT64) AS hud_median_family_income,
CAST(127.3977069537 AS FLOAT64) AS tract_to_msamd_income,
CAST(2.892359896630 AS FLOAT64) AS loan_to_income,
CAST(0 AS INT64) AS female,
CAST(0 AS INT64) AS black,
));


