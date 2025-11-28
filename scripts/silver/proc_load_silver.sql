/* ===========================================================================================
    Stored Procedure: Load Silver Layer (Bronze -> Silver)
    Layer:           Silver (Cleansed / Standardized)
    Project:         SQL Data Warehouse - Medallion Architecture

    Purpose:
        Loads cleansed, standardized, and validated data from Bronze tables 
        into Silver layer tables.
        - Applies business transformation rules
        - Fixes invalid dates, missing values, inconsistent categories
        - Enforces referential & structural consistency
        - Tracks load duration at table-level and batch-level

    WARNING:
        ⚠ This procedure TRUNCATES Silver tables before loading.
        ⚠ All Silver data will be overwritten.
        ⚠ Run only after bronze.load_bronze completes successfully.
=========================================================================================== */

CREATE OR ALTER PROCEDURE silver.load_silver 
AS 
BEGIN
    SET NOCOUNT ON;

    DECLARE @rows INT;
    DECLARE @start_time DATETIME, @end_time DATETIME;
    DECLARE @batch_start_time DATETIME, @batch_end_time DATETIME;

    SET @batch_start_time = GETDATE();

    BEGIN TRY

        PRINT('=============================================================');
        PRINT('                STARTING SILVER LAYER LOAD');
        PRINT(' Batch Start Time: ' + CONVERT(NVARCHAR, @batch_start_time, 120));
        PRINT('=============================================================');


        /* ====================================================================
           1. Load CRM Data
        ==================================================================== */
        PRINT('-------------------------------------------------------------');
        PRINT('                        LOADING CRM DATA');
        PRINT('-------------------------------------------------------------');


        /* -----------------------------------------------------------
             1. CRM Customer Info
        ----------------------------------------------------------- */
        SET @start_time = GETDATE();
        PRINT '>> Truncating silver.crm_cust_info';
        TRUNCATE TABLE silver.crm_cust_info;

        INSERT INTO silver.crm_cust_info (
            cst_id, cst_key, cst_firstname, cst_lastname,
            cst_marital_status, cst_gndr, cst_create_date
        )
        SELECT
            cst_id,
            cst_key,
            TRIM(cst_firstname),
            TRIM(cst_lastname),
            CASE 
                WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
                WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
                ELSE 'n/a'
            END,
            CASE 
                WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
                WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
                ELSE 'n/a'
            END,
            cst_create_date
        FROM (
            SELECT *, ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
            FROM bronze.crm_cust_info
            WHERE cst_id IS NOT NULL
        ) t
        WHERE flag_last = 1;

        SET @end_time = GETDATE();
        PRINT '>> Duration: ' + CAST(DATEDIFF(MILLISECOND,@start_time,@end_time) AS NVARCHAR) + ' ms';


        /* -----------------------------------------------------------
             2. CRM Product Info
        ----------------------------------------------------------- */
        SET @start_time = GETDATE();
        PRINT '>> Truncating silver.crm_prd_info';
        TRUNCATE TABLE silver.crm_prd_info;

        INSERT INTO silver.crm_prd_info (
            prd_id, cat_id, prd_key, prd_nm,
            prd_cost, prd_line, prd_start_dt, prd_end_dt
        )
        SELECT
            prd_id,
            REPLACE(SUBSTRING(prd_key,1,5),'-','_'),
            SUBSTRING(prd_key,7,LEN(prd_key)),
            prd_nm,
            ISNULL(prd_cost,0),
            CASE 
                WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountains'
                WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Roads'
                WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Other Sales'
                WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring'
                ELSE 'n/a'
            END,
            CAST(prd_start_dt AS DATE),
            CAST(LEAD(prd_start_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt) - 1 AS DATE)
        FROM bronze.crm_prd_info;

        SET @end_time = GETDATE();
        PRINT '>> Duration: ' + CAST(DATEDIFF(MILLISECOND,@start_time,@end_time) AS NVARCHAR) + ' ms';



        /* -----------------------------------------------------------
             3. CRM Sales Details
        ----------------------------------------------------------- */
        SET @start_time = GETDATE();
        PRINT '>> Truncating silver.crm_sales_details';
        TRUNCATE TABLE silver.crm_sales_details;

        INSERT INTO silver.crm_sales_details (
            sls_ord_num, sls_prd_key, sls_cust_id,
            sls_order_dt, sls_ship_dt, sls_due_dt,
            sls_sales, sls_quantity, sls_price
        )
        SELECT 
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,
            CASE WHEN sls_order_dt <= 0 OR LEN(sls_order_dt)!=8 THEN NULL
                 ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE) END,
            CASE WHEN sls_ship_dt <= 0 OR LEN(sls_ship_dt)!=8 THEN NULL
                 ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE) END,
            CASE WHEN sls_due_dt <= 0 OR LEN(sls_due_dt)!=8 THEN NULL
                 ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE) END,
            CASE 
                WHEN sls_sales IS NULL OR sls_sales <=0 OR sls_sales != sls_quantity*ABS(sls_price)
                     THEN sls_quantity * ABS(sls_price)
                ELSE sls_sales
            END,
            sls_quantity,
            CASE 
                WHEN sls_price IS NULL OR sls_price <=0
                     THEN sls_sales / NULLIF(sls_quantity,0)
                ELSE sls_price
            END
        FROM bronze.crm_sales_details;

        SET @end_time = GETDATE();
        PRINT '>> Duration: ' + CAST(DATEDIFF(MILLISECOND,@start_time,@end_time) AS NVARCHAR) + ' ms';



        /* ====================================================================
           2. Load ERP Data
        ==================================================================== */
        PRINT('-------------------------------------------------------------');
        PRINT('                        LOADING ERP DATA');
        PRINT('-------------------------------------------------------------');


        /* -----------------------------------------------------------
             4. ERP Customer Master
        ----------------------------------------------------------- */
        SET @start_time = GETDATE();
        PRINT '>> Truncating silver.erp_cust_az12';
        TRUNCATE TABLE silver.erp_cust_az12;

        INSERT INTO silver.erp_cust_az12 (
            cid, bdate, gen
        )
        SELECT
            CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid,4,LEN(cid)) ELSE cid END,
            CASE WHEN bdate > GETDATE() THEN NULL ELSE bdate END,
            CASE 
                WHEN UPPER(TRIM(gen)) IN ('F','FEMALE') THEN 'Female'
                WHEN UPPER(TRIM(gen)) IN ('M','MALE') THEN 'Male'
                ELSE 'n/a'
            END
        FROM bronze.erp_cust_az12;

        SET @end_time = GETDATE();
        PRINT '>> Duration: ' + CAST(DATEDIFF(MILLISECOND,@start_time,@end_time) AS NVARCHAR) + ' ms';



        /* -----------------------------------------------------------
             5. ERP Location Mapping
        ----------------------------------------------------------- */
        SET @start_time = GETDATE();
        PRINT '>> Truncating silver.erp_loc_a101';
        TRUNCATE TABLE silver.erp_loc_a101;

        INSERT INTO silver.erp_loc_a101 (
            cid, cntry
        )
        SELECT
            REPLACE(cid,'-',''),
            CASE 
                WHEN TRIM(cntry) = 'DE' THEN 'Germany'
                WHEN TRIM(cntry) IN ('US','USA','United States') THEN 'United States'
                WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
                ELSE TRIM(cntry)
            END
        FROM bronze.erp_loc_a101;

        SET @end_time = GETDATE();
        PRINT '>> Duration: ' + CAST(DATEDIFF(MILLISECOND,@start_time,@end_time) AS NVARCHAR) + ' ms';



        /* -----------------------------------------------------------
             6. ERP Product Categories
        ----------------------------------------------------------- */
        SET @start_time = GETDATE();
        PRINT '>> Truncating silver.erp_px_cat_g1v2';
        TRUNCATE TABLE silver.erp_px_cat_g1v2;

        INSERT INTO silver.erp_px_cat_g1v2 (
            id, cat, subcat, maintenance
        )
        SELECT
            id, cat, subcat, maintenance
        FROM bronze.erp_px_cat_g1v2;

        SET @end_time = GETDATE();
        PRINT '>> Duration: ' + CAST(DATEDIFF(MILLISECOND,@start_time,@end_time) AS NVARCHAR) + ' ms';



        /* ====================================================================
           BATCH END
        ==================================================================== */
        SET @batch_end_time = GETDATE();

        PRINT('=============================================================');
        PRINT('           SILVER LOAD COMPLETED SUCCESSFULLY');
        PRINT(' Batch End Time:   ' + CONVERT(NVARCHAR, @batch_end_time, 120));
        PRINT(' Total Duration:   ' 
              + CAST(DATEDIFF(MILLISECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) 
              + ' ms');
        PRINT('=============================================================');

    END TRY


    BEGIN CATCH
        PRINT('XXXXXXXX  ERROR OCCURRED DURING SILVER LOAD  XXXXXXXX');
        PRINT('Error Number:       ' + CAST(ERROR_NUMBER() AS NVARCHAR(10)));
        PRINT('Error Message:      ' + ERROR_MESSAGE());
        PRINT('Error Line:         ' + CAST(ERROR_LINE() AS NVARCHAR(10)));
        PRINT('Error Procedure:    ' + ISNULL(ERROR_PROCEDURE(), 'N/A'));
        THROW;
    END CATCH;

END;
GO



