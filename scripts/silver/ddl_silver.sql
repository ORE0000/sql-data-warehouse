/* ===========================================================================================
    Script Name: ddl_silver.sql
    Layer:       Silver (Cleansed / Standardized Layer)
    Project:     SQL Data Warehouse - Medallion Architecture

    Purpose:
        - Creates cleaned and standardized Silver tables
        - Structures closely follow Bronze data but with improved datatypes
        - Includes DWH metadata columns for lineage and auditing
        - Designed for transformations applied by ETL (bronze → silver)

    WARNING:
        ⚠ This script will DROP and RECREATE existing Silver tables
        ⚠ All existing data will be permanently deleted
        ⚠ DO NOT run in production without full backups
=========================================================================================== */

USE DataWarehouse;
GO

/* ============================================================================
   1. CRM Customer Information (Cleansed)
============================================================================ */
IF OBJECT_ID('silver.crm_cust_info', 'U') IS NOT NULL
    DROP TABLE silver.crm_cust_info;
GO

CREATE TABLE silver.crm_cust_info (
    cst_id              INT,
    cst_key             NVARCHAR(50),
    cst_firstname       NVARCHAR(100),
    cst_lastname        NVARCHAR(100),
    cst_marital_status  NVARCHAR(50),
    cst_gndr            NVARCHAR(20),
    cst_create_date     DATE,
    dwh_create_date     DATETIME2 DEFAULT GETDATE()
);
GO


/* ============================================================================
   2. CRM Product Information (Cleansed)
============================================================================ */
IF OBJECT_ID('silver.crm_prd_info', 'U') IS NOT NULL
    DROP TABLE silver.crm_prd_info;
GO

CREATE TABLE silver.crm_prd_info (
    prd_id             INT,
    cat_id             NVARCHAR(50),
    prd_key            NVARCHAR(50),
    prd_nm             NVARCHAR(200),
    prd_cost           DECIMAL(18,2),
    prd_line           NVARCHAR(100),
    prd_start_dt       DATE,
    prd_end_dt         DATE,
    dwh_create_date    DATETIME2 DEFAULT GETDATE()
);
GO


/* ============================================================================
   3. CRM Sales Details (Cleansed)
============================================================================ */
IF OBJECT_ID('silver.crm_sales_details', 'U') IS NOT NULL
    DROP TABLE silver.crm_sales_details;
GO

CREATE TABLE silver.crm_sales_details (
    sls_ord_num     NVARCHAR(50),
    sls_prd_key     NVARCHAR(50),
    sls_cust_id     INT,
    sls_order_dt    DATE,
    sls_ship_dt     DATE,
    sls_due_dt      DATE,
    sls_sales       INT,
    sls_quantity    INT,
    sls_price       INT,
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO


/* ============================================================================
   4. ERP Customer Master (Cleansed)
============================================================================ */
IF OBJECT_ID('silver.erp_cust_az12', 'U') IS NOT NULL
    DROP TABLE silver.erp_cust_az12;
GO

CREATE TABLE silver.erp_cust_az12 (
    cid              NVARCHAR(50),
    bdate            DATE,
    gen              NVARCHAR(20),
    dwh_create_date  DATETIME2 DEFAULT GETDATE()
);
GO


/* ============================================================================
   5. ERP Location (Cleansed)
============================================================================ */
IF OBJECT_ID('silver.erp_loc_a101', 'U') IS NOT NULL
    DROP TABLE silver.erp_loc_a101;
GO

CREATE TABLE silver.erp_loc_a101 (
    cid              NVARCHAR(50),
    cntry            NVARCHAR(100),
    dwh_create_date  DATETIME2 DEFAULT GETDATE()
);
GO


/* ============================================================================
   6. ERP Product Category Mapping (Cleansed)
============================================================================ */
IF OBJECT_ID('silver.erp_px_cat_g1v2', 'U') IS NOT NULL
    DROP TABLE silver.erp_px_cat_g1v2;
GO

CREATE TABLE silver.erp_px_cat_g1v2 (
    id               NVARCHAR(50),
    cat              NVARCHAR(100),
    subcat           NVARCHAR(100),
    maintenance      NVARCHAR(100),
    dwh_create_date  DATETIME2 DEFAULT GETDATE()
);
GO


PRINT 'Silver layer table creation completed successfully.';
