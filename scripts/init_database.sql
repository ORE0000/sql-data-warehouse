/* ===========================================================================================
    Script Name: 01_initialize_database.sql
    Project:     SQL Data Warehouse (Medallion Architecture)
    Purpose:
        - Create the DataWarehouse database
        - Check if DB exists (no DROP here for safety)
        - Initialize Medallion layer schemas (bronze, silver, gold)

    WARNING:
        ⚠ Do NOT run DROP DATABASE in production environments
        ⚠ Always back up before destructive operations
=========================================================================================== */

-- ==========================================================
-- 1. Create database if not exists
-- ==========================================================
IF NOT EXISTS (
    SELECT 1 FROM sys.databases WHERE name = 'DataWarehouse'
)
BEGIN
    PRINT 'Creating database: DataWarehouse...';
    CREATE DATABASE DataWarehouse;
END
ELSE 
BEGIN
    PRINT 'Database already exists. Skipping creation.';
END
GO

-- Switch to the warehouse database
USE DataWarehouse;
GO

-- ==========================================================
-- 2. Create schemas safely using dynamic SQL
-- ==========================================================

-- Bronze Schema
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'bronze')
BEGIN
    PRINT 'Creating BRONZE schema...';
    EXEC('CREATE SCHEMA bronze');
END
ELSE
BEGIN
    PRINT 'BRONZE schema already exists. Skipping.';
END
GO

-- Silver Schema
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'silver')
BEGIN
    PRINT 'Creating SILVER schema...';
    EXEC('CREATE SCHEMA silver');
END
ELSE
BEGIN
    PRINT 'SILVER schema already exists. Skipping.';
END
GO

-- Gold Schema
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'gold')
BEGIN
    PRINT 'Creating GOLD schema...';
    EXEC('CREATE SCHEMA gold');
END
ELSE
BEGIN
    PRINT 'GOLD schema already exists. Skipping.';
END
GO

PRINT 'Database initialization completed successfully.';
