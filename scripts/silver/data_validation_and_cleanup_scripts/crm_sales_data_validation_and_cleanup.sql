/* ===========================================================================================
    Script Name: dq_sales_validation_and_cleanup.sql
    Layer:       Bronze ? Silver Data Quality Checks
    Project:     SQL Data Warehouse - Medallion Architecture

    Purpose:
        - Performs data profiling and validation on sales records in the Bronze layer
        - Identifies invalid, missing, or inconsistent sales fields before loading into Silver
        - Standardizes date formats (YYYYMMDD ? DATE)
        - Detects incorrect sales calculations and auto-corrects them
        - Ensures referential integrity with customer and product dimensions
        - Prepares clean, analytics-ready data for downstream ETL pipelines

    Notes:
        • This script does NOT create or drop tables (not a DDL script)
        • It focuses strictly on data quality checks and transformations
        • All transformations follow business rules and cleansing logic for the Silver layer
        • Final INSERT loads corrected results into silver.crm_sales_details

    Recommendation:
        ? Run this script before any Silver-layer fact/dimension processing
        ? Validate results periodically to ensure upstream Bronze data remains consistent
=========================================================================================== */



-- Fetch top 1000 sales records where the customer ID does NOT exist 
-- in the cleaned customer info table (possible orphan/unmatched customers)
SELECT TOP (1000) 
       sls_ord_num,
       sls_prd_key,
       sls_cust_id,
       sls_order_dt,
       sls_ship_dt,
       sls_due_dt,
       sls_sales,
       sls_quantity,
       sls_price
  FROM bronze.crm_sales_details
  WHERE sls_cust_id NOT IN (SELECT cst_id FROM silver.crm_cust_info)



-- Identify invalid or corrupted order dates:
-- 1. Date = 0
-- 2. Length not equal to 8 (YYYYMMDD format expected)
-- 3. Date beyond upper limit (2050)
-- 4. Date below lower limit (1900)
SELECT  
       sls_cust_id,
       NULLIF(sls_order_dt,0) AS sls_order_dt
  FROM bronze.crm_sales_details
  WHERE sls_order_dt <= 0  
  OR LEN(sls_order_dt) != 8
  OR sls_order_dt > 20500101
  OR sls_order_dt < 19000101



-- Convert numerical YYYYMMDD integers to DATE objects.
-- Invalid or corrupted dates are converted to NULL.
SELECT  
       sls_ord_num,
       sls_prd_key,
       sls_cust_id,
      CASE 
            WHEN sls_order_dt <= 0 OR LEN(sls_order_dt) != 8 THEN NULL
            ELSE CAST(CAST(sls_order_dt AS varchar) AS DATE)
      END AS sls_order_dt,
      CASE 
            WHEN sls_ship_dt <= 0 OR LEN(sls_ship_dt) != 8 THEN NULL
            ELSE CAST(CAST(sls_ship_dt AS varchar) AS DATE)
      END AS sls_ship_dt,
      CASE 
            WHEN sls_due_dt <= 0 OR LEN(sls_due_dt) != 8 THEN NULL
            ELSE CAST(CAST(sls_due_dt AS varchar) AS DATE)
      END AS sls_due_dt,
      sls_sales,
      sls_quantity,
      sls_price
  FROM bronze.crm_sales_details



-- Validate due date:
-- Check for 0, incorrect length, or unrealistic date ranges
SELECT  
       sls_cust_id,
       NULLIF(sls_due_dt,0) AS sls_due_dt
  FROM bronze.crm_sales_details
  WHERE sls_due_dt <= 0  
  OR LEN(sls_due_dt) != 8
  OR sls_due_dt > 20500101
  OR sls_due_dt < 19000101



-- Find sales rows where:
-- 1. sales != quantity * price  (inconsistent math)
-- 2. sales, price, or quantity is NULL
-- 3. sales, price, or quantity is <= 0
SELECT DISTINCT
      sls_sales,
      sls_quantity,
      sls_price
  FROM bronze.crm_sales_details
  WHERE sls_sales != sls_quantity * sls_price
  OR sls_sales IS NULL OR sls_price IS NULL OR sls_quantity IS NULL 
  OR sls_sales <= 0 OR sls_price <= 0 OR sls_quantity <= 0
  ORDER BY sls_sales, sls_quantity, sls_price



-- Auto-correct sales and price values:
-- Correct sls_sales if missing, negative, or mathematically incorrect
-- Correct sls_price if missing or invalid
SELECT DISTINCT
      sls_sales AS old_sls_sales,
      sls_quantity,
      sls_price AS old_sls_price,
      CASE 
           WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price)
           THEN sls_quantity * ABS(sls_price) 
           ELSE sls_sales
      END AS sls_sales,
      CASE 
           WHEN sls_price IS NULL OR sls_price <= 0
           THEN sls_sales / NULLIF(sls_quantity,0) 
           ELSE sls_price
      END AS sls_price
  FROM bronze.crm_sales_details
  WHERE sls_sales != sls_quantity * sls_price
  OR sls_sales IS NULL OR sls_price IS NULL OR sls_quantity IS NULL 
  OR sls_sales <= 0 OR sls_price <= 0 OR sls_quantity <= 0
  ORDER BY sls_sales, sls_quantity, sls_price



-- Final cleaned output:
-- Fix dates + fix sales/price + convert integer date fields to DATE format
SELECT  
       sls_ord_num,
       sls_prd_key,
       sls_cust_id,
      CASE 
            WHEN sls_order_dt <= 0 OR LEN(sls_order_dt) != 8 THEN NULL
            ELSE CAST(CAST(sls_order_dt AS varchar) AS DATE)
      END AS sls_order_dt,
      CASE 
            WHEN sls_ship_dt <= 0 OR LEN(sls_ship_dt) != 8 THEN NULL
            ELSE CAST(CAST(sls_ship_dt AS varchar) AS DATE)
      END AS sls_ship_dt,
      CASE 
            WHEN sls_due_dt <= 0 OR LEN(sls_due_dt) != 8 THEN NULL
            ELSE CAST(CAST(sls_due_dt AS varchar) AS DATE)
      END AS sls_due_dt,
      CASE 
           WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price)
           THEN sls_quantity * ABS(sls_price) 
           ELSE sls_sales
      END AS sls_sales,
      sls_quantity,
      CASE 
           WHEN sls_price IS NULL OR sls_price <= 0
           THEN sls_sales / NULLIF(sls_quantity,0) 
           ELSE sls_price
      END AS sls_price
  FROM bronze.crm_sales_details





-- Insert cleaned and validated sales data from the bronze layer 
-- into the silver.crm_sales_details table. 
-- This step fixes invalid dates, corrects inconsistent sales/price values, 
-- and standardizes the structure for analytics and reporting.
INSERT INTO silver.crm_sales_details (
       sls_ord_num,      -- Sales order number
       sls_prd_key,      -- Product key
       sls_cust_id,      -- Customer ID
       sls_order_dt,     -- Cleaned order date
       sls_ship_dt,      -- Cleaned ship date
       sls_due_dt,       -- Cleaned due date
       sls_sales,        -- Corrected sales amount
       sls_quantity,     -- Quantity sold
       sls_price         -- Corrected unit price
)
SELECT  
       sls_ord_num,
       sls_prd_key,
       sls_cust_id,

       -- Convert sls_order_dt to DATE; invalid or malformed dates become NULL
       CASE 
            WHEN sls_order_dt <= 0 OR LEN(sls_order_dt) != 8 THEN NULL
            ELSE CAST(CAST(sls_order_dt AS varchar) AS DATE)
       END AS sls_order_dt,

       -- Convert sls_ship_dt to DATE; invalid or malformed dates become NULL
       CASE 
            WHEN sls_ship_dt <= 0 OR LEN(sls_ship_dt) != 8 THEN NULL
            ELSE CAST(CAST(sls_ship_dt AS varchar) AS DATE)
       END AS sls_ship_dt,

       -- Convert sls_due_dt to DATE; invalid or malformed dates become NULL
       CASE 
            WHEN sls_due_dt <= 0 OR LEN(sls_due_dt) != 8 THEN NULL
            ELSE CAST(CAST(sls_due_dt AS varchar) AS DATE)
       END AS sls_due_dt,

       -- Correct sales value:
       -- If sales is NULL, negative, zero, or not equal to quantity * ABS(price), 
       -- then recalculate sales = quantity * ABS(price)
       CASE 
            WHEN sls_sales IS NULL 
              OR sls_sales <= 0 
              OR sls_sales != sls_quantity * ABS(sls_price)
            THEN sls_quantity * ABS(sls_price) 
            ELSE sls_sales
       END AS sls_sales,

       sls_quantity,

       -- Correct price value:
       -- If price is NULL or <= 0, derive it as sales / quantity (safe-divided)
       CASE 
            WHEN sls_price IS NULL OR sls_price <= 0
            THEN sls_sales / NULLIF(sls_quantity,0) 
            ELSE sls_price
       END AS sls_price
FROM bronze.crm_sales_details;
