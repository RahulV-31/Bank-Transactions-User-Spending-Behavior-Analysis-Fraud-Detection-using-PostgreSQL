
-- ====================================================
-- Advanced SQL Fraud Detection Project (PostgreSQL)
-- Dataset: Synthetic Financial Datasets For Fraud Detection
-- ====================================================

-- 🔹 1. Basic Exploration
-- ----------------------------------------------------
-- Total number of rows
SELECT COUNT(*) FROM transactions;

-- Preview data
SELECT * FROM transactions LIMIT 10;

-- Unique transaction types
SELECT DISTINCT type FROM transactions;

-- Fraud distribution
SELECT isFraud, COUNT(*) FROM transactions GROUP BY isFraud;

-- Total amount and frequency by transaction type
SELECT type, COUNT(*) AS txn_count, SUM(amount) AS total_amount
FROM transactions
GROUP BY type
ORDER BY total_amount DESC;

-- Fraud rate by transaction type
SELECT type,
       COUNT(*) AS total_txns,
       SUM(CASE WHEN isFraud THEN 1 ELSE 0 END) AS fraud_txns,
       ROUND(SUM(CASE WHEN isFraud THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS fraud_rate
FROM transactions
GROUP BY type
ORDER BY fraud_rate DESC;

-- 🔹 2. Focused Fraud Analysis
-- ----------------------------------------------------
-- Fraudulent transfers & cash outs with average amount
WITH filtered AS (
    SELECT *
    FROM transactions
    WHERE type IN ('TRANSFER', 'CASH_OUT') AND isFraud = TRUE
)
SELECT type, COUNT(*) AS fraud_count, ROUND(AVG(amount)::numeric, 2) AS avg_amount
FROM filtered
GROUP BY type;

-- Users with more than 3 fraud attempts
SELECT nameOrig, COUNT(*) AS fraud_attempts, SUM(amount) AS total_loss
FROM transactions
WHERE isFraud = TRUE
GROUP BY nameOrig
HAVING COUNT(*) > 3
ORDER BY total_loss DESC;

-- Users with at least 2 fraud attempts (none found)
SELECT nameOrig, COUNT(*) AS fraud_attempts, SUM(amount) AS total_loss
FROM transactions
WHERE isFraud = TRUE
GROUP BY nameOrig
HAVING COUNT(*) >= 2
ORDER BY total_loss DESC;

-- Total fraud cases and unique fraudsters
SELECT COUNT(*) FROM transactions WHERE isFraud = TRUE;
SELECT COUNT(DISTINCT nameOrig) FROM transactions WHERE isFraud = TRUE;

-- Frequent fraud targets
SELECT nameDest, COUNT(*) AS times_targeted, SUM(amount) AS total_received
FROM transactions
WHERE isFraud = TRUE
GROUP BY nameDest
HAVING COUNT(*) > 1
ORDER BY times_targeted DESC;

-- Most frequent fraudulent amounts
SELECT amount, COUNT(*) AS freq, SUM(amount) AS total_value
FROM transactions
WHERE isFraud = TRUE
GROUP BY amount
HAVING COUNT(*) > 5
ORDER BY freq DESC;

-- 🔹 3. Pattern Mining with CTEs + Window Functions
-- ----------------------------------------------------
-- Fraud chains within same user
WITH fraud_txns AS (
    SELECT
        nameOrig,
        nameDest,
        step,
        amount,
        type,
        ROW_NUMBER() OVER (PARTITION BY nameOrig ORDER BY step) AS txn_num,
        LAG(step) OVER (PARTITION BY nameOrig ORDER BY step) AS prev_step
    FROM transactions
    WHERE isFraud = TRUE
),
fraud_chains AS (
    SELECT *,
           (step - prev_step) AS step_gap
    FROM fraud_txns
    WHERE prev_step IS NOT NULL
)
SELECT *
FROM fraud_chains
WHERE step_gap <= 5
ORDER BY nameOrig, step;

-- Users with more than 1 fraud (none found)
SELECT nameOrig, COUNT(*) 
FROM transactions
WHERE isFraud = TRUE
GROUP BY nameOrig
HAVING COUNT(*) >= 2;
