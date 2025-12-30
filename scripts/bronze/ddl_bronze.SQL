/*
===============================================================================
DDL Script: Create Bronze Tables
===============================================================================
Script Purpose:
    This script creates tables in the 'bronze' schema, dropping existing tables 
    if they already exist.
	  Run this script to re-define the DDL structure of 'bronze' Tables
===============================================================================
*/


-- File path 
-- /var/opt/mssql/dwh/raw/source_crm/"*.csv"
-- /var/opt/mssql/dwh/raw/source_erp/"*.csv"


use DataWarehouse;

if object_id('bronze.crm_cust_info', 'U') is not NULL
    drop table bronze.crm_cust_info;
create table bronze.crm_cust_info(
    cst_id int ,
    cst_key NVARCHAR(50),
    cst_firstname NVARCHAR(50),
    cst_lastname NVARCHAR(50),
    cst_marital_status VARCHAR(50),
    cst_gndr varchar(50),
    cst_create_date date

);

if object_id('bronze.crm_prod_info', 'U') is not NULL
    drop table bronze.crm_prod_info;
CREATE table bronze.crm_prod_info(
prd_id int,
prd_key NVARCHAR(50),
prd_nm  NVARCHAR(50),
prd_cost int,
prd_line NVARCHAR(50),
prd_start_dt date,
prd_end_dt date

);


if object_id('bronze.crm_sales_details', 'U') is not NULL
    drop table bronze.crm_sales_details;
CREATE table bronze.crm_sales_details(
    sls_ord_num NVARCHAR(50),
    sls_prd_key NVARCHAR(50),
    sls_cust_id int,
    sls_order_dt int,
    sls_ship_dt int, 
    sls_due_dt int, 
    sls_sales int, 
    sls_quantity int,
    sls_price int

)


if object_id('bronze.erp_cust_az12', 'U') is not NULL
    drop table  bronze.erp_cust_az12 ;
CREATE table bronze.erp_cust_az12 (
    CID NVARCHAR(50),
    BDATE date, 
    GEN VARCHAR(20)

)


if OBJECT_ID('bronze.erp_loc_a101','U') is not null
    drop table bronze.erp_loc_a101;
CREATE table bronze.erp_loc_a101(
    CID NVARCHAR(50),
    CNTRY NVARCHAR(50)

)


if OBJECT_ID('bronze.erp_px_cat_g1v2' , 'U') is not NULL
    drop table bronze.erp_px_cat_g1v2;
CREATE TABLE bronze.erp_px_cat_g1v2(
    ID NVARCHAR(50),
    CAT NVARCHAR(50),
    SUBCAT NVARCHAR(50),
    MAINTENANCE NVARCHAR(50)
