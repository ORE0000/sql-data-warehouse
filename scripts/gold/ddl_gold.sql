/* ===========================================================================================
    Script Name: ddl_gold.sql
    Layer:       Gold (Business-Ready / Semantic Layer)
    Project:     SQL Data Warehouse - Medallion Architecture

    Purpose:
        This script creates Gold layer views that serve as finalized, 
        analytics-ready dimensional models for BI dashboards & reporting.

        It includes:
            • dim_customers  – conformed customer dimension
            • dim_products   – conformed product dimension
            • fact_sales     – sales fact table with surrogate keys

    Notes:
        • Gold layer contains no raw fields; everything is standardized.
        • Views join Silver-cleaned tables to produce business entities.
        • Safe to re-run; views are replaced automatically by CREATE OR ALTER.

    Output:
        ✔ Clean customer dimension
        ✔ Clean product dimension
        ✔ Fact table with surrogate keys linked to dimensions
=========================================================================================== */



/* ================================================================================
   1. GOLD DIMENSION: dim_customers
   Creates a business-ready customer dimension by merging CRM + ERP clean data.
================================================================================ */
CREATE OR ALTER VIEW gold.dim_customers AS 
SELECT 
    ROW_NUMBER() OVER(ORDER BY ci.cst_id) AS customer_key, -- Surrogate key

    ci.cst_id              AS customer_id,
    ci.cst_key             AS customer_number,
    ci.cst_firstname       AS first_name,
    ci.cst_lastname        AS last_name,
    la.cntry               AS country,
    ci.cst_marital_status  AS marital_status,

    -- Prefer CRM gender; fallback to ERP gender if CRM has n/a
    CASE 
        WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr
        ELSE COALESCE(ca.gen, 'n/a')
    END AS gender,

    ca.bdate               AS birth_date,
    ci.cst_create_date     AS customer_created_date

FROM silver.crm_cust_info AS ci
LEFT JOIN silver.erp_cust_az12 AS ca
       ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 AS la
       ON ci.cst_key = la.cid;



/* ================================================================================
   2. GOLD DIMENSION: dim_products
   Creates a conformed product dimension combining CRM product data
   with ERP category metadata (cat, subcat, maintenance).
================================================================================ */
CREATE OR ALTER VIEW gold.dim_products AS 
SELECT
    ROW_NUMBER() OVER(ORDER BY pn.prd_start_dt, pn.prd_key) AS product_key, -- Surrogate key

    pn.prd_id              AS product_id,
    pn.prd_key             AS product_number,
    pn.prd_nm              AS product_name,
    pn.cat_id              AS category_id,

    pc.cat                 AS category,
    pc.subcat              AS subcategory,
    pc.maintenance         AS maintenance,

    pn.prd_cost            AS cost,
    pn.prd_line            AS product_line,
    pn.prd_start_dt        AS start_date

FROM silver.crm_prd_info AS pn
LEFT JOIN silver.erp_px_cat_g1v2 AS pc
       ON pn.cat_id = pc.id
WHERE pn.prd_end_dt IS NULL; -- Only active products included



/* ================================================================================
   3. GOLD FACT: fact_sales
   Main sales fact table joining surrogate keys from both dimensions.
================================================================================ */
CREATE OR ALTER VIEW gold.fact_sales AS
SELECT 
    sd.sls_ord_num      AS order_number,

    pr.product_key      AS product_key,      -- From dim_products
    cu.customer_key     AS customer_key,     -- From dim_customers

    sd.sls_order_dt     AS order_date,
    sd.sls_ship_dt      AS shipping_date,
    sd.sls_due_dt       AS due_date,

    sd.sls_sales        AS sales_amount,
    sd.sls_quantity     AS quantity,
    sd.sls_price        AS unit_price

FROM silver.crm_sales_details AS sd
LEFT JOIN gold.dim_products AS pr
       ON sd.sls_prd_key = pr.product_number

LEFT JOIN gold.dim_customers AS cu
       ON sd.sls_cust_id = cu.customer_id;
