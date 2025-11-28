-- Identify duplicate or NULL product IDs in the bronze product table.
-- This helps detect data quality issues such as missing primary keys 
-- or repeated product definitions.
SELECT 
    prd_id,
    COUNT(*) AS occurrence_count
FROM bronze.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL




-- Retrieve product records whose extracted product key 
-- does NOT exist in the sales details table.
-- This identifies products that have never been sold or referenced in sales data.
SELECT 
    prd_key,
    REPLACE(SUBSTRING(prd_key,1,5),'-','_') AS cat_id,          -- Derive category ID
    SUBSTRING(prd_key,7,LEN(prd_key)) AS prd_key,               -- Extract cleaned product key
    prd_nm,
    prd_cost,
    prd_line,
    prd_start_dt,
    prd_end_dt
FROM bronze.crm_prd_info
WHERE SUBSTRING(prd_key,7,LEN(prd_key)) NOT IN (
    SELECT DISTINCT sls_prd_key FROM bronze.crm_sales_details
)




-- Detect product names that contain unnecessary leading or trailing spaces.
-- extra_space_count helps identify how many spaces should be cleaned.
SELECT 
    prd_nm,
    LEN(prd_nm) - LEN(TRIM(prd_nm)) AS extra_space_count
FROM bronze.crm_prd_info
WHERE prd_nm != TRIM(prd_nm);



-- Retrieve products with invalid or missing cost values (NULL or negative).
-- Also standardizes category ID, product key, product line descriptions,
-- and converts start/end dates to proper DATE format.
SELECT 
    prd_key,
    REPLACE(SUBSTRING(prd_key,1,5),'-','_') AS cat_id,          -- Derived category ID
    SUBSTRING(prd_key,7,LEN(prd_key)) AS prd_key,               -- Clean product key
    prd_nm,
    ISNULL(prd_cost,0) AS prd_cost,                             -- Replace NULL / invalid cost
    CASE UPPER(TRIM(prd_line))                                  -- Normalize product line codes
            WHEN 'M' THEN 'Mountains'
            WHEN 'R' THEN 'Roads'
            WHEN 'S' THEN 'Other Sales'
            WHEN 'T' THEN 'Touring'
            ELSE 'n/a'
    END AS prd_line,
    CAST(prd_start_dt AS DATE) AS prd_start_dt,                 -- Convert to DATE type
    CAST(
        (LEAD(prd_start_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt) - 1)
        AS DATE
    ) AS prd_end_dt
FROM bronze.crm_prd_info
WHERE prd_cost IS NULL OR prd_cost < 0




-- Final cleaned product dimension logic:
-- Normalizes category ID, product key, product line, cost, and date ranges.
-- Converts start/end dates and prepares data for the silver layer.
SELECT 
    prd_id,
    REPLACE(SUBSTRING(prd_key,1,5),'-','_') AS cat_id,          -- Standard category ID
    SUBSTRING(prd_key,7,LEN(prd_key)) AS prd_key,               -- Extract final product key
    prd_nm,
    ISNULL(prd_cost,0) AS prd_cost,                             -- Replace NULL cost with 0
    CASE UPPER(TRIM(prd_line))
            WHEN 'M' THEN 'Mountains'
            WHEN 'R' THEN 'Roads'
            WHEN 'S' THEN 'Other Sales'
            WHEN 'T' THEN 'Touring'
            ELSE 'n/a'
    END AS prd_line,
    CAST(prd_start_dt AS DATE) AS prd_start_dt,                 -- Convert to DATE
    CAST(
        LEAD(prd_start_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt) - 1 
        AS DATE
    ) AS prd_end_dt
FROM bronze.crm_prd_info





-- Display all existing records in the cleaned product info table
SELECT * FROM silver.crm_prd_info



-- Insert transformed and standardized product data 
-- from the bronze layer into the silver (cleaned) layer
INSERT INTO silver.crm_prd_info(
    prd_id,
    cat_id,
    prd_key,
    prd_nm,
    prd_cost,
    prd_line,
    prd_start_dt,
    prd_end_dt
)
SELECT 
    -- Product ID (kept as-is)
    prd_id,

    -- Create category ID by taking first 5 chars of prd_key 
    -- and replacing hyphens with underscores (e.g., 'A123-XYZ' ? 'A123_X')
    REPLACE(SUBSTRING(prd_key,1,5),'-','_') AS cat_id,

    -- Extract actual product key from position 7 onward
    -- (splits composite keys into a clean identifier)
    SUBSTRING(prd_key,7,LEN(prd_key)) AS prd_key,

    -- Product name
    prd_nm,

    -- Replace NULL cost with 0 to avoid missing values
    ISNULL(prd_cost,0) AS prd_cost,

    -- Clean and expand product line codes:
    -- M ? Mountains, R ? Roads, S ? Other Sales, T ? Touring
    -- Anything else ? 'n/a'
    CASE UPPER(TRIM(prd_line))
            WHEN 'M' THEN 'Mountains'
            WHEN 'R' THEN 'Roads'
            WHEN 'S' THEN 'Other Sales'
            WHEN 'T' THEN 'Touring'
            ELSE 'n/a'
    END AS prd_line,

    -- Convert product start date to proper DATE data type
    CAST(prd_start_dt AS DATE) AS prd_start_dt,

    -- Generate product end date:
    -- Use LEAD() to get the next product’s start date
    -- Then subtract 1 day to set the correct end date
    CAST(
        LEAD(prd_start_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt) - 1 
        AS DATE
    ) AS prd_end_dt

FROM bronze.crm_prd_info
