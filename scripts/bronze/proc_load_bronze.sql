/* ===========================================================================================
    Stored Procedure: bronze.load_bronze
    Layer:           Bronze (Raw Ingestion)
    Project:         SQL Data Warehouse - Medallion Architecture

    Purpose:
        - Loads raw CRM and ERP CSV files into Bronze staging tables
        - Tracks load performance at table level AND batch level
        - BULK INSERT + row count + duration

    WARNING:
        ⚠ This procedure TRUNCATES all Bronze tables before loading.
        ⚠ All existing data will be overwritten.
        ⚠ Validate file paths before running in production.
=========================================================================================== */

CREATE OR ALTER PROCEDURE bronze.load_bronze 
AS 
BEGIN
    SET NOCOUNT ON;

    DECLARE @rows INT;
    DECLARE @start_time DATETIME, @end_time DATETIME;
    DECLARE @batch_start_time DATETIME, @batch_end_time DATETIME;

    SET @batch_start_time = GETDATE();

    BEGIN TRY

        PRINT('=============================================================');
        PRINT('               STARTING BRONZE LAYER LOAD');
        PRINT(' Batch Start Time: ' + CONVERT(NVARCHAR, @batch_start_time, 120));
        PRINT('=============================================================');


        /* ====================================================================
           1. Load CRM Data
        ==================================================================== */
        PRINT('-------------------------------------------------------------');
        PRINT('                       LOADING CRM DATA');
        PRINT('-------------------------------------------------------------');


        /* -----------------------------------------------------------
             1. CRM Customer Info
        ----------------------------------------------------------- */
        SET @start_time = GETDATE();
        PRINT '>> Truncating bronze.crm_cust_info';
        TRUNCATE TABLE bronze.crm_cust_info;

        BULK INSERT bronze.crm_cust_info
        FROM 'D:\ASHUTOSH\DATA WAREHOUSE\sql-data-warehouse\datasets\source_crm\cust_info.csv'
        WITH ( FIRSTROW = 2, FIELDTERMINATOR = ',', TABLOCK );

        SET @rows = @@ROWCOUNT;
        SET @end_time = GETDATE();

        PRINT '>> Rows inserted: ' + CAST(@rows AS NVARCHAR(20));
        PRINT '>> Duration: ' + CAST(DATEDIFF(MILLISECOND,@start_time,@end_time) AS NVARCHAR(20)) + ' ms';


        /* -----------------------------------------------------------
             2. CRM Product Info
        ----------------------------------------------------------- */
        SET @start_time = GETDATE();
        PRINT '>> Truncating bronze.crm_prd_info';
        TRUNCATE TABLE bronze.crm_prd_info;

        BULK INSERT bronze.crm_prd_info
        FROM 'D:\ASHUTOSH\DATA WAREHOUSE\sql-data-warehouse\datasets\source_crm\prd_info.csv'
        WITH ( FIRSTROW = 2, FIELDTERMINATOR = ',', TABLOCK );

        SET @rows = @@ROWCOUNT;
        SET @end_time = GETDATE();

        PRINT '>> Rows inserted: ' + CAST(@rows AS NVARCHAR(20));
        PRINT '>> Duration: ' + CAST(DATEDIFF(MILLISECOND,@start_time,@end_time) AS NVARCHAR(20)) + ' ms';


        /* -----------------------------------------------------------
             3. CRM Sales Details
        ----------------------------------------------------------- */
        SET @start_time = GETDATE();
        PRINT '>> Truncating bronze.crm_sales_details';
        TRUNCATE TABLE bronze.crm_sales_details;

        BULK INSERT bronze.crm_sales_details
        FROM 'D:\ASHUTOSH\DATA WAREHOUSE\sql-data-warehouse\datasets\source_crm\sales_details.csv'
        WITH ( FIRSTROW = 2, FIELDTERMINATOR = ',', TABLOCK );

        SET @rows = @@ROWCOUNT;
        SET @end_time = GETDATE();

        PRINT '>> Rows inserted: ' + CAST(@rows AS NVARCHAR(20));
        PRINT '>> Duration: ' + CAST(DATEDIFF(MILLISECOND,@start_time,@end_time) AS NVARCHAR(20)) + ' ms';



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
        PRINT '>> Truncating bronze.erp_cust_az12';
        TRUNCATE TABLE bronze.erp_cust_az12;

        BULK INSERT bronze.erp_cust_az12
        FROM 'D:\ASHUTOSH\DATA WAREHOUSE\sql-data-warehouse\datasets\source_erp\CUST_AZ12.csv'
        WITH ( FIRSTROW = 2, FIELDTERMINATOR = ',', TABLOCK );

        SET @rows = @@ROWCOUNT;
        SET @end_time = GETDATE();

        PRINT '>> Rows inserted: ' + CAST(@rows AS NVARCHAR(20));
        PRINT '>> Duration: ' + CAST(DATEDIFF(MILLISECOND,@start_time,@end_time) AS NVARCHAR(20)) + ' ms';


        /* -----------------------------------------------------------
             5. ERP Location Mapping
        ----------------------------------------------------------- */
        SET @start_time = GETDATE();
        PRINT '>> Truncating bronze.erp_loc_a101';
        TRUNCATE TABLE bronze.erp_loc_a101;

        BULK INSERT bronze.erp_loc_a101
        FROM 'D:\ASHUTOSH\DATA WAREHOUSE\sql-data-warehouse\datasets\source_erp\LOC_A101.csv'
        WITH ( FIRSTROW = 2, FIELDTERMINATOR = ',', TABLOCK );

        SET @rows = @@ROWCOUNT;
        SET @end_time = GETDATE();

        PRINT '>> Rows inserted: ' + CAST(@rows AS NVARCHAR(20));
        PRINT '>> Duration: ' + CAST(DATEDIFF(MILLISECOND,@start_time,@end_time) AS NVARCHAR(20)) + ' ms';


        /* -----------------------------------------------------------
             6. ERP Product Categories
        ----------------------------------------------------------- */
        SET @start_time = GETDATE();
        PRINT '>> Truncating bronze.erp_px_cat_g1v2';
        TRUNCATE TABLE bronze.erp_px_cat_g1v2;

        BULK INSERT bronze.erp_px_cat_g1v2
        FROM 'D:\ASHUTOSH\DATA WAREHOUSE\sql-data-warehouse\datasets\source_erp\PX_CAT_G1V2.csv'
        WITH ( FIRSTROW = 2, FIELDTERMINATOR = ',', TABLOCK );

        SET @rows = @@ROWCOUNT;
        SET @end_time = GETDATE();

        PRINT '>> Rows inserted: ' + CAST(@rows AS NVARCHAR(20));
        PRINT '>> Duration: ' + CAST(DATEDIFF(MILLISECOND,@start_time,@end_time) AS NVARCHAR(20)) + ' ms';



        /* ====================================================================
           BATCH END
        ==================================================================== */
        SET @batch_end_time = GETDATE();

        PRINT('=============================================================');
        PRINT('           BRONZE LOAD COMPLETED SUCCESSFULLY');
        PRINT(' Batch End Time:   ' + CONVERT(NVARCHAR, @batch_end_time, 120));
        PRINT(' Total Duration:   ' 
              + CAST(DATEDIFF(MILLISECOND, @batch_start_time, @batch_end_time) AS NVARCHAR(20)) 
              + ' ms');
        PRINT('=============================================================');

    END TRY

    BEGIN CATCH
        PRINT('XXXXXXXX  ERROR OCCURRED DURING BRONZE LOAD  XXXXXXXX');
        PRINT('Error Number: ' + CAST(ERROR_NUMBER() AS NVARCHAR(10)));
        PRINT('Error Message: ' + ERROR_MESSAGE());
        PRINT('Error Line: ' + CAST(ERROR_LINE() AS NVARCHAR(10)));
        PRINT('Error Procedure: ' + ISNULL(ERROR_PROCEDURE(), 'N/A'));
        THROW;
    END CATCH;

END;
GO


