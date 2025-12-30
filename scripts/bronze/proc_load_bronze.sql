/*
===============================================================================
Stored Procedure: Load Bronze Layer (Source -> Bronze)
===============================================================================
Script Purpose:
    This stored procedure loads data into the 'bronze' schema from external CSV files. 
    It performs the following actions:
    - Truncates the bronze tables before loading data.
    - Uses the `BULK INSERT` command to load data from csv Files to bronze tables.

Parameters:
    None. 
	  This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC bronze.load_bronze;
===============================================================================
*/



create or alter PROCEDURE bronze.load_bronze AS
BEGIN
    DECLARE @start_time DATETIME, @end_time DATETIME, @start_batch_time DATETIME, @end_batch_time DATETIME;
    BEGIN TRY

        set @start_batch_time = GETDATE();
        PRINT '================================================';
        print 'Loading Bronze Layer';
        PRINT '================================================';


        -- Inserting the cust_info from crm source file
        print'---------------------------------------------------';
        print('Loading CRM Table ')
        print'---------------------------------------------------';

        set @start_time = GETDATE();
        print('     >> Truncating the table :bronze.crm_cust_info ')
        truncate table bronze.crm_cust_info

        print('     >> Inserting values into :bronze.crm_cust_info ')
        BULK INSERT bronze.crm_cust_info
        FROM '/var/opt/mssql/dwh/raw/source_crm/cust_info.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '\n',
            TABLOCK
    );
    set @end_time = GETDATE();
    print'>> Load Duration: ' + cast(DATEDIFF(second, @start_time,@end_time) as NVARCHAR) + 'seconds';


        set @start_time = getdate();
        print('     >> Truncating the table :bronze.crm_prod_info ')
        truncate table bronze.crm_prod_info

        print('     >> inserting values into :bronze.crm_prod_info ')
        bulk insert bronze.crm_prod_info
        from '/var/opt/mssql/dwh/raw/source_crm/prd_info.csv'
        with (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',' ,
            rowterminator = '\n',
            tablock
    );
    set @end_time = getdate();
    print '>> Load Duration: ' + cast(datediff(second, @start_time, @end_time) as NVARCHAR) + 'second';


    set @start_time = getdate();
        print('     >> Truncating the table: bronze.crm_sales_details ')
        truncate table bronze.crm_sales_details

        print('     >> Inserting values into :bronze.crm_sales_details ')
        bulk insert bronze.crm_sales_details
        from '/var/opt/mssql/dwh/raw/source_crm/sales_details.csv'
        with (
            firstrow =2,
            FIELDTERMINATOR = ',',
            rowterminator ='\n',
            tablock
    );
    set @end_time = getdate();
    print'>> Load Duration' + cast( datediff(second, @start_time, @end_time) as NVARCHAR) + 'second';



        print'---------------------------------------------------';
        print('Loading CRM Table ')
        print'---------------------------------------------------';


    set @start_time = getdate();
        print('     >> Truncating the table: bronze.erp_cust_az12 ')
        truncate table bronze.erp_cust_az12

        print('     >> Inserting values into the table: bronze.erp_cust_az12 ')
        bulk insert bronze.erp_cust_az12
        from '/var/opt/mssql/dwh/raw/source_erp/CUST_AZ12.csv'
        with (
            firstrow =2,
            fieldterminator = ',',
            rowterminator = '\n',
            tablock
    );
    set @end_time = getdate();
    print'>> Load Duration ' + cast(datediff(second,@start_time, @end_time) as NVARCHAR)


    set @start_time = getdate();
        print('     >> Truncating the table: bronze.erp_loc_a101');
        truncate table bronze.erp_loc_a101

        print('     >> Inserting values into : bronze.erp_loc_a101');
        BULK insert bronze.erp_loc_a101
        from '/var/opt/mssql/dwh/raw/source_erp/LOC_A101.csv'
        with (
            firstrow = 2,
            fieldterminator = ',',
            rowterminator = '\n',
            tablock
    );
    set @end_time = GETDATE();
    print'>> Load Duration ' + cast(datediff(second, @start_time, @end_time) as NVARCHAR);
    

    set @start_time = getdate();
        print('     >> Truncating the table:  bronze.erp_px_cat_g1v2');
        truncate table bronze.erp_px_cat_g1v2

        print('     >> inserting values into: bronze.erp_px_cat_g1v2');
        bulk insert bronze.erp_px_cat_g1v2
        from '/var/opt/mssql/dwh/raw/source_erp/PX_CAT_G1V2.csv'
        with(
            firstrow =2,
            fieldterminator = ',',
            rowterminator = '\n',
            tablock
        );
    set @end_time = getdate();
    print'>> Load Duration ' + cast(datediff(second, @start_time, @end_time) as NVARCHAR)

    set @end_batch_time = GETDATE();

    print ' Loading Bronze Layer is completed ';
    print ' >> Total Load Duration : '+ cast(datediff(second, @start_batch_time, @end_batch_time) as NVARCHAR);
END TRY
BEGIN CATCH
    PRINT '===============================================================';
    PRINT 'Error Occured During Loading Bronze Layer'
    PRINT 'Error Message '+ Error_message();
    PRINT 'Error Message '+ CAST (Error_Number() as NVARCHAR);
    PRINT 'Error Message '+ CAST(Error_State() as NVARCHAR);
    PRINT '==============================================================';
End CATCH

END

EXEC bronze.load_bronze;
