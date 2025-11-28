/* ===============================================================
   CHECK 1: Find NULLs and Duplicate Customer IDs
   Purpose:
       - Identify rows with missing cst_id (data quality issue)
       - Identify duplicate customer IDs (should be unique in CRM)
================================================================ */
SELECT 
    cst_id,
    COUNT(*) AS occurrence_count
FROM bronze.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1      -- shows duplicates  
   OR cst_id IS NULL;    -- shows records where ID is missing



/* ===============================================================
   CHECK 2: Find the Latest Record Per Customer
   Purpose:
       - Detect duplicate customer records by choosing the most recent one
       - ROW_NUMBER assigns a ranking per cst_id
       - Flag_last = 1 returns only the newest record for each duplicate group
================================================================ */
SELECT *
FROM (
        SELECT 
            *,
            ROW_NUMBER() OVER (
                PARTITION BY cst_id 
                ORDER BY cst_create_date DESC     -- latest record = Flag_last = 1
            ) AS Flag_last
        FROM bronze.crm_cust_info
     ) t
WHERE Flag_last = 1;       -- keeps the most recent row for each customer



/* ===============================================================
   CHECK 3: Find Extra Spaces in Gender Field
   Purpose:
       - Detect and measure unwanted leading/trailing spaces
       - LEN(x) - LEN(TRIM(x)) > 0 means there were extra spaces
================================================================ */
SELECT 
    cst_gndr,
    LEN(cst_gndr) - LEN(TRIM(cst_gndr)) AS extra_space_count
FROM bronze.crm_cust_info
WHERE cst_gndr != TRIM(cst_gndr);    -- returns only rows containing whitespace issues




/* ===============================================================
   CHECK 4A: List all distinct marital status values
   Purpose:
       - Identify unexpected or inconsistent entries
       - Useful before standardizing marital status in Silver layer
================================================================ */
SELECT DISTINCT cst_marital_status
FROM bronze.crm_cust_info;




/* ===============================================================
   CHECK 4B: List all distinct gender values
   Purpose:
       - Detect inconsistent values like: 'm', ' M ', 'female', 'F ', etc.
       - Helps build a standardized gender mapping in Silver layer
================================================================ */
SELECT DISTINCT cst_gndr
FROM bronze.crm_cust_info;



/* ===============================================================
   CHECK 4C: Preview Cleaned & Standardized Customer Data

   Purpose:
       - Trim whitespace from names
       - Standardize gender to 'Male'/'Female'
       - Standardize marital status using CASE expressions
       - Prepare for Silver layer transformation

   Notes:
       - Upper() normalization makes comparisons case-insensitive
       - TRIM() removes leading/trailing spaces
       - CASE expressions map raw CRM codes to standardized values
================================================================ */
SELECT 
    cst_id,
    cst_key,
    
    TRIM(cst_firstname) AS cst_firstname_clean,
    TRIM(cst_lastname)  AS cst_lastname_clean,

    /* ---------------------------
         Standardized Marital Status
         (Sample logic - replace later if ERP provides real values)
       --------------------------- */
    CASE 
        WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
        WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
        ELSE 'n/a'
    END AS cst_marital_status,

    /* ---------------------------
         Standardized Gender Mapping
       --------------------------- */
    CASE 
        WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
        WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
        ELSE 'n/a'
    END AS cst_gndr,

    cst_create_date

FROM bronze.crm_cust_info;






/* ===========================================================================================
    Script Name: load_silver_crm_cust_info.sql
    Layer:       Silver (Cleansed / Standardized Layer)

    Purpose:
        - Load cleansed CRM Customer data into Silver layer
        - Apply trimming, standardization, NULL checks
        - Deduplicate by selecting the latest record per cst_id
        - Map gender + marital status to standardized business values

    Notes:
        - Silver layer = cleaned data (NOT raw)
        - Using ROW_NUMBER ensures only the latest version of each customer loads
=========================================================================================== */

INSERT INTO silver.crm_cust_info (
      cst_id,
      cst_key,
      cst_firstname,
      cst_lastname,
      cst_marital_status,
      cst_gndr,
      cst_create_date
)
SELECT 
      cst_id,
      cst_key,

      -- Remove extra spaces from first/last name
      TRIM(cst_firstname) AS cst_firstname_clean,
      TRIM(cst_lastname)  AS cst_lastname_clean,

      /* ------------------------------------------------------------
            Standardize Marital Status
            -> CRM raw code M = Married, S = Single
            -> All other / unknown = 'n/a'
      ------------------------------------------------------------ */
      CASE 
            WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
            WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
            ELSE 'n/a'
      END AS cst_marital_status,

      /* ------------------------------------------------------------
            Standardize Gender Values
            -> Raw values ('M','F') cleaned to 'Male'/'Female'
            -> Anything unexpected becomes 'n/a'
      ------------------------------------------------------------ */
      CASE 
            WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
            WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
            ELSE 'n/a'
      END AS cst_gndr,

      cst_create_date

FROM (
        /* ===========================================================
            Step 1: Deduplication Logic
            - Assigns ROW_NUMBER per cst_id ordered by create date
            - The most recent row (Flag_last = 1) is kept
            - Older duplicates are filtered out in outer SELECT
        =========================================================== */
        SELECT 
            *,
            ROW_NUMBER() OVER (
                PARTITION BY cst_id
                ORDER BY cst_create_date DESC
            ) AS Flag_last
        FROM bronze.crm_cust_info
        WHERE cst_id IS NOT NULL          -- remove bad/null keys
     ) t
WHERE Flag_last = 1;                       -- keep the newest record only


