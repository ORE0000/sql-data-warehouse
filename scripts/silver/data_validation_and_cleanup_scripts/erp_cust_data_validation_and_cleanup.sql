/* ===========================================================================================
    Script Name: dq_erp_customer_cleanup.sql
    Layer:       Bronze ? Silver Data Validation & Standardization
    Project:     SQL Data Warehouse - Medallion Architecture

    Purpose:
        - Cleans ERP customer master data before loading into the Silver layer
        - Fixes inconsistent customer IDs (removes 'NAS' prefix when present)
        - Validates and standardizes birthdates (bdate)
        - Normalizes gender field with proper format: 'Male', 'Female', or 'n/a'
        - Ensures referential integrity with CRM customer dimension
        - Loads fully standardized customer records into silver.erp_cust_az12

    Notes:
        • This is NOT a DDL script — no table creation or schema changes
        • Strictly performs data quality checks and transformations
        • All cleaning logic is aligned with business rules for Silver layer models
=========================================================================================== */



-- Identify customer IDs that do not match CRM customer keys after cleaning.
-- If CID begins with 'NAS', remove the prefix and compare with silver.crm_cust_info.
SELECT 
    cid,
    CASE 
        WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid,4,LEN(cid))  -- Remove NAS prefix
        ELSE cid
    END AS New_cid,
    bdate,
    gen 
FROM bronze.erp_cust_az12
WHERE CASE 
          WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid,4,LEN(cid))
          ELSE cid
      END NOT IN (
        SELECT DISTINCT cst_key FROM silver.crm_cust_info
      );



-- Validate birthdates:
-- Identify records with unrealistic DOBs:
--  • Earlier than 1924-01-01
--  • Future dates beyond today
SELECT 
    bdate,
    gen 
FROM bronze.erp_cust_az12
WHERE bdate < '1924-01-01' 
   OR bdate > GETDATE();



-- Clean and standardize birthdate values:
-- Convert future birthdates into NULL.
SELECT 
    cid,
    CASE 
        WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid,4,LEN(cid))   -- Remove NAS prefix
        ELSE cid
    END AS New_cid,
    CASE 
        WHEN bdate > GETDATE() THEN NULL                      -- Invalid future DOB
        ELSE bdate
    END AS bdate,
    gen 
FROM bronze.erp_cust_az12;



-- Normalize gender values:
-- Map codes and variations to uniform values:
-- 'F', 'female' ? Female
-- 'M', 'male'   ? Male
-- Anything else ? n/a
SELECT DISTINCT 
    gen,
    CASE 
        WHEN UPPER(TRIM(gen)) IN ('F','FEMALE') THEN 'Female'
        WHEN UPPER(TRIM(gen)) IN ('M','MALE') THEN 'Male'
        ELSE 'n/a'
    END AS gen
FROM bronze.erp_cust_az12;



-- Load fully cleaned and standardized customer data into Silver layer.
-- Applies:
--   • CID prefix removal
--   • Birthdate validation
--   • Gender normalization
INSERT INTO silver.erp_cust_az12(
    cid,
    bdate,
    gen
) 
SELECT 
    CASE 
        WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid,4,LEN(cid))   -- Remove NAS prefix
        ELSE cid
    END AS cid,

    CASE 
        WHEN bdate > GETDATE() THEN NULL                      -- Replace invalid DOB with NULL
        ELSE bdate
    END AS bdate,

    CASE 
        WHEN UPPER(TRIM(gen)) IN ('F','FEMALE') THEN 'Female'
        WHEN UPPER(TRIM(gen)) IN ('M','MALE') THEN 'Male'
        ELSE 'n/a'
    END AS gen
FROM bronze.erp_cust_az12;
