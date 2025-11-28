/* ===========================================================================================
    Script Name: dq_erp_location_cleanup.sql
    Layer:       Bronze ? Silver Data Quality & Standardization
    Project:     SQL Data Warehouse - Medallion Architecture

    Purpose:
        - Cleans and standardizes ERP location data before loading into Silver layer
        - Removes invalid or inconsistent characters from customer/location IDs (CID)
        - Normalizes country names and codes into unified business-approved values
        - Ensures consistency across countries (e.g., US, USA ? United States)
        - Prepares clean, analytics-ready records for downstream dimensional modeling

    Notes:
        • This is NOT a DDL script — performs data validation and transformations only
        • Ensures uniformity in CID and CNTRY fields for Silver-layer consumption
=========================================================================================== */



-- Clean the CID field by removing hyphens.
-- Retains original country values for inspection.
SELECT 
    REPLACE(cid,'-','') AS cid,
    cntry
FROM bronze.erp_loc_a101;



-- Inspect and standardize country names/codes.
-- Applies business rules to unify variations:
--   DE  ? Germany
--   US, USA, United States ? United States
--   Empty or NULL ? n/a
SELECT DISTINCT 
    cntry,
    CASE 
        WHEN TRIM(cntry) = 'DE' THEN 'Germany'
        WHEN TRIM(cntry) IN ('United States','US','USA') THEN 'United States'
        WHEN TRIM(cntry) = '' OR TRIM(cntry) IS NULL THEN 'n/a'
        ELSE cntry
    END AS cntry
FROM bronze.erp_loc_a101;



-- Load cleaned location data into Silver layer.
-- Standardizes CID and normalizes country values according to mapping rules.
INSERT INTO silver.erp_loc_a101(
    cid,
    cntry
)
SELECT 
    REPLACE(cid,'-','') AS cid,
    CASE 
        WHEN TRIM(cntry) = 'DE' THEN 'Germany'
        WHEN TRIM(cntry) IN ('United States','US','USA') THEN 'United States'
        WHEN TRIM(cntry) = '' OR TRIM(cntry) IS NULL THEN 'n/a'
        ELSE cntry
    END AS cntry
FROM bronze.erp_loc_a101;
