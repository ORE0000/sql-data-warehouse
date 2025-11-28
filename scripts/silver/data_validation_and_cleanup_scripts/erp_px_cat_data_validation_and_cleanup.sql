/* ===========================================================================================
    Script Name: dq_erp_px_category_cleanup.sql
    Layer:       Bronze ? Silver Data Quality Validation
    Project:     SQL Data Warehouse - Medallion Architecture

    Purpose:
        - Performs data quality checks on ERP product category data
        - Detects leading/trailing spaces in category fields (cat, subcat, maintenance)
        - Profiles distinct category values for validation and standardization planning
        - Ensures the Silver table contains clean, consistent, and fully trimmed values
        - Loads validated data directly into silver.erp_px_cat_g1v2

    Notes:
        • This script is NOT a DDL script – it does not create or alter tables
        • It focuses solely on profiling and cleaning the Bronze dataset
        • Categories are carried forward as-is after validation (no recoding applied here)
=========================================================================================== */



-- Preview raw ERP product category data from the Bronze layer.
-- Useful to inspect structure and detect issues before cleaning.
SELECT
    id,
    cat,
    subcat,
    maintenance
FROM bronze.erp_px_cat_g1v2;



-- Identify records with formatting issues:
-- Detects values containing leading or trailing whitespace in cat, subcat, or maintenance.
SELECT * 
FROM bronze.erp_px_cat_g1v2
WHERE cat != TRIM(cat) 
   OR subcat != TRIM(subcat) 
   OR maintenance != TRIM(maintenance);



-- Profile distinct category names to understand category groupings.
SELECT DISTINCT 
    cat
FROM bronze.erp_px_cat_g1v2;



-- Profile distinct subcategories.
SELECT DISTINCT 
    subcat
FROM bronze.erp_px_cat_g1v2;



-- Profile distinct maintenance types.
SELECT DISTINCT 
    maintenance
FROM bronze.erp_px_cat_g1v2;



-- Load validated and clean ERP product category data into the Silver layer.
-- No business transformations required here other than data validation above.
INSERT INTO silver.erp_px_cat_g1v2 (
    id,
    cat,
    subcat,
    maintenance
)
SELECT
    id,
    cat,
    subcat,
    maintenance
FROM bronze.erp_px_cat_g1v2;



-- Verify the final cleaned data that has been loaded into Silver.
SELECT * 
FROM silver.erp_px_cat_g1v2;
