# ⚙️ ETL Process Documentation

**Complete ETL workflow, data transformations, and orchestration procedures**

---

## Table of Contents

1. [ETL Overview](#etl-overview)
2. [Extract Phase](#extract-phase)
3. [Transform Phase](#transform-phase)
4. [Load Phase](#load-phase)
5. [Data Quality Checks](#data-quality-checks)
6. [Error Handling](#error-handling)
7. [Monitoring & Alerts](#monitoring--alerts)

---

## ETL Overview

### ETL Architecture

```
┌─────────────────────────────────────────────────────────────┐
│               DAILY ETL PIPELINE (2:00 AM)                 │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  EXTRACT                                                    │
│  ├─ CRM: Query customers, orders (Delta)                   │
│  └─ ERP: Query products, sales (Full)                      │
│                                                              │
│  LOAD TO BRONZE                                            │
│  ├─ Backup existing data                                   │
│  ├─ Truncate & Reload                                      │
│  └─ Log audit trail                                        │
│                                                              │
│  TRANSFORM TO SILVER                                       │
│  ├─ Deduplication                                          │
│  ├─ Data quality rules                                     │
│  ├─ Standardization                                        │
│  └─ Reconciliation                                         │
│                                                              │
│  MODEL TO GOLD                                             │
│  ├─ Create dimensions                                      │
│  ├─ Create facts                                           │
│  ├─ SCD updates                                            │
│  └─ Index creation                                         │
│                                                              │
│  VALIDATION                                                │
│  ├─ Data quality tests                                     │
│  ├─ Reconciliation checks                                  │
│  └─ Alert notifications                                    │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## Extract Phase

### Data Sources

#### CRM System

**Connection**: ODBC via linked server

**Tables Extracted**:
- `customers` - Customer master
- `orders` - Order headers
- `order_items` - Order line items

**Extract Method**: 
- **Customers**: Full extraction (daily)
- **Orders**: Delta extraction (last 7 days)

**Sample Extract Query**:
```sql
-- Extract CRM customers (full)
SELECT 
    customer_id,
    customer_number,
    first_name,
    last_name,
    email,
    phone,
    address,
    city,
    state,
    country,
    postal_code,
    marital_status,
    gender,
    birthdate,
    create_date,
    CAST(GETDATE() AS DATE) AS dwh_load_date,
    CAST(GETDATE() AS TIME) AS dwh_load_time
FROM [CRM_LINKED_SERVER].[crm_db].dbo.customers
WHERE 1=1  -- No delta filter for full extract
```

#### ERP System

**Connection**: ODBC via linked server

**Tables Extracted**:
- `products` - Product catalog
- `sales_orders` - Sales transactions

**Extract Method**: 
- **Products**: Full extraction (daily)
- **Sales**: Delta extraction (last 3 days for incremental)

**Sample Extract Query**:
```sql
-- Extract ERP sales (delta last 3 days)
SELECT 
    sales_order_id,
    order_number,
    product_id,
    customer_id,
    order_date,
    quantity,
    unit_price,
    sales_amount,
    discount_percent,
    tax_amount,
    CAST(GETDATE() AS DATE) AS dwh_load_date
FROM [ERP_LINKED_SERVER].[erp_db].dbo.sales_transactions
WHERE order_date >= DATEADD(DAY, -3, CAST(GETDATE() AS DATE))
```

### Extract Best Practices

| Practice | Implementation |
|----------|-----------------|
| **Incremental Extraction** | Track last extraction date, only pull new/modified records |
| **Full Extraction Fallback** | If incremental fails, default to full extract |
| **Change Data Capture** | Use CDC on source systems if available |
| **Connection Pooling** | Reuse connections, avoid connection leaks |
| **Timeout Handling** | Set reasonable timeouts (15-30 minutes) |

---

## Transform Phase

### Layer 1: Bronze → Silver Transformation

#### Step 1: Deduplication

**Algorithm**: Keep latest by load date, remove duplicates on natural key

```sql
-- Deduplication Logic
WITH ranked_customers AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id 
            ORDER BY dwh_load_date DESC
        ) AS row_num
    FROM bronze.crm_customer_info
)
DELETE FROM bronze.crm_customer_info
WHERE customer_id IN (
    SELECT customer_id 
    FROM ranked_customers 
    WHERE row_num > 1
);
```

**Duplicate Detection Criteria**:
- Exact match on: `customer_id`, `email`
- Keep: Most recent by `dwh_load_date`
- Mark: Duplicates for audit logging

#### Step 2: Data Standardization

**Transformations Applied**:

| Field | Transformation | Example |
|-------|---|---|
| **Names** | Trim, Title Case | ' john  ' → 'John' |
| **Email** | Lowercase, validate format | 'JOHN@X.COM' → 'john@x.com' |
| **Phone** | Remove non-digits, format | '1234567890' → '123-456-7890' |
| **Gender** | Standardize values | 'M'/'Male'/'m' → 'Male' |
| **Status** | Uppercase, validate list | 'married' → 'MARRIED' |
| **Dates** | Validate format, range | '31/13/2025' → NULL (invalid) |

**Standardization SQL Example**:
```sql
-- Standardize customer data
UPDATE silver.crm_customers
SET 
    first_name = LTRIM(RTRIM(UPPER(LEFT(first_name, 1)) + LOWER(SUBSTRING(first_name, 2, 255)))),
    last_name = LTRIM(RTRIM(UPPER(LEFT(last_name, 1)) + LOWER(SUBSTRING(last_name, 2, 255)))),
    email = LOWER(LTRIM(RTRIM(email))),
    phone = REPLACE(REPLACE(phone, '-', ''), ' ', ''),
    gender = CASE 
        WHEN UPPER(LTRIM(RTRIM(gender))) IN ('M', 'MALE') THEN 'Male'
        WHEN UPPER(LTRIM(RTRIM(gender))) IN ('F', 'FEMALE') THEN 'Female'
        ELSE 'Unknown'
    END
WHERE dwh_load_date = CAST(GETDATE() AS DATE);
```

#### Step 3: Null Value Handling

**Strategy**: Context-dependent standardization

| Data Type | Null Handling | Example |
|-----------|---|---|
| **Text** | 'Unknown' | NULL phone → 'Unknown' |
| **Date** | NULL (preserve) | NULL birthdate → NULL |
| **Numeric** | 0 or NULL (domain-dependent) | NULL quantity → 0 |
| **Status** | 'Unknown' or 'N/A' | NULL status → 'Unknown' |

```sql
-- Null standardization
UPDATE silver.crm_customers
SET 
    gender = ISNULL(gender, 'Unknown'),
    marital_status = ISNULL(marital_status, 'Unknown'),
    phone = ISNULL(NULLIF(phone, ''), 'Unknown'),
    address = ISNULL(NULLIF(address, ''), 'Unknown')
WHERE dwh_load_date = CAST(GETDATE() AS DATE);
```

#### Step 4: Data Validation

**Business Rules**:

```sql
-- Validation example: Sales transactions
UPDATE silver.erp_sales
SET is_valid = 0, validation_errors = 'Order date > Shipping date'
WHERE order_date > shipping_date;

UPDATE silver.erp_sales
SET is_valid = 0, validation_errors = 'Price < 0'
WHERE unit_price <= 0;

UPDATE silver.erp_sales
SET is_valid = 0, validation_errors = 'Customer not found'
WHERE sid_customer IS NULL;

UPDATE silver.erp_sales
SET is_valid = 1, validation_errors = NULL
WHERE is_valid IS NULL;
```

#### Step 5: Referential Integrity

**Foreign Key Validation**:

```sql
-- Validate customer FK in orders
UPDATE silver.crm_orders
SET is_valid = 0, validation_errors = 'Customer does not exist'
WHERE sid_customer NOT IN (
    SELECT DISTINCT sid_customer 
    FROM silver.crm_customers
    WHERE is_duplicate = 0
);

-- Validate product FK in sales
UPDATE silver.erp_sales
SET is_valid = 0, validation_errors = 'Product does not exist'
WHERE sid_product NOT IN (
    SELECT DISTINCT sid_product 
    FROM silver.erp_products
    WHERE is_active = 1
);
```

---

### Layer 2: Silver → Gold Transformation

#### Step 1: Dimension Creation

**Dimension Table Load Process**:

```sql
-- Create/Update dim_customers (SCD Type 2)
MERGE INTO gold.dim_customers AS target
USING (
    SELECT 
        customer_id,
        customer_number,
        first_name,
        last_name,
        email,
        phone,
        address,
        city,
        state,
        country,
        postal_code,
        marital_status,
        gender,
        birthdate,
        DATEDIFF(YEAR, birthdate, GETDATE()) AS age_years
    FROM silver.crm_customers
    WHERE is_duplicate = 0 AND dwh_load_date = CAST(GETDATE() AS DATE)
) AS source
ON target.customer_id = source.customer_id AND target.is_current = 1
WHEN MATCHED AND (
    target.first_name != source.first_name OR
    target.email != source.email OR
    target.country != source.country
) THEN
    -- SCD Type 2: Close old version, insert new version
    UPDATE SET 
        is_current = 0,
        expiration_date = DATEADD(DAY, -1, CAST(GETDATE() AS DATE))
WHEN NOT MATCHED THEN
    -- Insert new customer
    INSERT (
        customer_id, customer_number, first_name, last_name,
        email, phone, address, city, state, country, postal_code,
        marital_status, gender, birthdate, age_years,
        effective_date, expiration_date, is_current, dwh_load_date
    )
    VALUES (
        source.customer_id, source.customer_number, source.first_name, 
        source.last_name, source.email, source.phone, source.address,
        source.city, source.state, source.country, source.postal_code,
        source.marital_status, source.gender, source.birthdate, 
        source.age_years, CAST(GETDATE() AS DATE), 
        CAST('99991231' AS DATE), 1, CAST(GETDATE() AS DATE)
    );
```

**Dimension Load Patterns**:

| Pattern | Use Case | SCD Type |
|---------|----------|----------|
| **Snapshot** | Overwrite all | Type 1 |
| **Change History** | Track changes | Type 2 |
| **Accumulated** | Add flag columns | Type 3 |

#### Step 2: Fact Table Load

**Fact Table Inserts**:

```sql
-- Load fact_sales (Atomic level)
INSERT INTO gold.fact_sales (
    order_number, customer_key, product_key, date_key, geography_key,
    order_date, shipping_date, quantity, unit_price, sales_amount,
    discount_percent, discount_amount, tax_amount, net_sales_amount,
    cost_amount, profit_amount, profit_margin_percent, dwh_load_date
)
SELECT 
    s.order_number,
    dc.customer_key,
    dp.product_key,
    dd.date_key,
    dg.geography_key,
    s.order_date,
    s.shipping_date,
    s.quantity,
    s.unit_price,
    s.sales_amount,
    s.discount_percent,
    ISNULL(s.discount_percent * s.sales_amount / 100, 0) AS discount_amount,
    ISNULL(s.tax_amount, 0) AS tax_amount,
    s.sales_amount - ISNULL(s.discount_percent * s.sales_amount / 100, 0) + ISNULL(s.tax_amount, 0) AS net_sales_amount,
    dp.cost,
    (s.sales_amount - ISNULL(s.discount_percent * s.sales_amount / 100, 0) + ISNULL(s.tax_amount, 0)) - dp.cost AS profit_amount,
    CASE 
        WHEN (s.sales_amount - ISNULL(s.discount_percent * s.sales_amount / 100, 0) + ISNULL(s.tax_amount, 0)) > 0
        THEN (((s.sales_amount - ISNULL(s.discount_percent * s.sales_amount / 100, 0) + ISNULL(s.tax_amount, 0)) - dp.cost) / (s.sales_amount - ISNULL(s.discount_percent * s.sales_amount / 100, 0) + ISNULL(s.tax_amount, 0))) * 100
        ELSE 0
    END AS profit_margin_percent,
    CAST(GETDATE() AS DATE) AS dwh_load_date
FROM silver.erp_sales s
JOIN gold.dim_customers dc ON s.sid_customer = dc.customer_key AND dc.is_current = 1
JOIN gold.dim_products dp ON s.sid_product = dp.product_key
JOIN gold.dim_date dd ON s.order_date = dd.full_date
JOIN gold.dim_geography dg ON dc.country = dg.country
WHERE s.is_valid = 1 AND s.dwh_load_date = CAST(GETDATE() AS DATE)
AND s.sales_order_id NOT IN (SELECT DISTINCT sales_order_id FROM gold.fact_sales);
```

#### Step 3: Aggregate Table Refresh

**Aggregate Materialization**:

```sql
-- Refresh monthly sales aggregates
TRUNCATE TABLE gold.agg_sales_monthly;

INSERT INTO gold.agg_sales_monthly (
    year_month_key, customer_key, product_key,
    month_sales_amount, month_quantity, month_cost_amount, 
    month_profit_amount, order_count, dwh_load_date
)
SELECT 
    CAST(FORMAT(f.order_date, 'yyyyMM') AS INT) AS year_month_key,
    f.customer_key,
    f.product_key,
    SUM(f.net_sales_amount) AS month_sales_amount,
    SUM(f.quantity) AS month_quantity,
    SUM(f.cost_amount) AS month_cost_amount,
    SUM(f.profit_amount) AS month_profit_amount,
    COUNT(DISTINCT f.order_number) AS order_count,
    CAST(GETDATE() AS DATE) AS dwh_load_date
FROM gold.fact_sales f
GROUP BY 
    CAST(FORMAT(f.order_date, 'yyyyMM') AS INT),
    f.customer_key,
    f.product_key;
```

---

## Data Quality Checks

### Quality Check Framework

```sql
-- Comprehensive data quality validation
DECLARE @load_date DATE = CAST(GETDATE() AS DATE);

-- 1. Row Count Comparison
SELECT 
    'Bronze' AS layer,
    'crm_customers' AS table_name,
    COUNT(*) AS row_count
FROM bronze.crm_customer_info
WHERE dwh_load_date = @load_date;

-- 2. Null Percentage Check
SELECT 
    COLUMN_NAME,
    COUNT(*) - COUNT(email) AS null_count,
    CAST(((COUNT(*) - COUNT(email)) * 100.0 / COUNT(*)) AS DECIMAL(5,2)) AS null_percent
FROM bronze.crm_customer_info
WHERE dwh_load_date = @load_date
GROUP BY COLUMN_NAME
HAVING (COUNT(*) - COUNT(email)) * 100.0 / COUNT(*) > 5
ORDER BY null_percent DESC;

-- 3. Duplicate Detection
SELECT 
    customer_id,
    COUNT(*) AS duplicate_count
FROM silver.crm_customers
WHERE is_duplicate = 1
GROUP BY customer_id
HAVING COUNT(*) > 1;

-- 4. Invalid Data Percentage
SELECT 
    COUNT(*) AS total_records,
    SUM(CASE WHEN is_valid = 0 THEN 1 ELSE 0 END) AS invalid_records,
    CAST((SUM(CASE WHEN is_valid = 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) AS DECIMAL(5,2)) AS invalid_percent
FROM silver.erp_sales
WHERE dwh_load_date = @load_date;

-- 5. Reconciliation: Source vs Warehouse
SELECT 
    'CRM Customers' AS source,
    COUNT(DISTINCT c.customer_id) AS source_count,
    COUNT(DISTINCT dc.customer_id) AS warehouse_count,
    COUNT(DISTINCT c.customer_id) - COUNT(DISTINCT dc.customer_id) AS variance
FROM silver.crm_customers c
LEFT JOIN gold.dim_customers dc ON c.sid_customer = dc.customer_key AND dc.is_current = 1
WHERE c.dwh_load_date = @load_date;
```

---

## Error Handling

### Try-Catch Error Management

```sql
-- Error handling pattern
BEGIN TRY
    BEGIN TRANSACTION;
    
    -- Data load operations
    INSERT INTO silver.crm_customers (...)
    SELECT ... FROM bronze.crm_customer_info;
    
    -- Data validation
    IF (SELECT COUNT(*) FROM silver.crm_customers) = 0
        THROW 50001, 'No data loaded to Silver layer', 1;
    
    COMMIT TRANSACTION;
    PRINT 'Load successful';

END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    
    -- Log error
    INSERT INTO audit.etl_error_log (
        error_number, error_severity, error_state,
        error_procedure, error_line, error_message, error_datetime
    )
    VALUES (
        ERROR_NUMBER(), ERROR_SEVERITY(), ERROR_STATE(),
        ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE(), GETDATE()
    );
    
    -- Alert notification
    EXECUTE msdb.dbo.sp_send_dbmail
        @profile_name = 'DW_Admin',
        @recipients = 'dw-team@company.com',
        @subject = 'ETL FAILURE - Silver Layer Load',
        @body = 'Error: ' + ERROR_MESSAGE();
    
    THROW;
END CATCH;
```

---

## Monitoring & Alerts

### Execution Log Table

```sql
-- Create execution log
CREATE TABLE audit.etl_execution_log (
    execution_id INT IDENTITY(1,1) PRIMARY KEY,
    layer NVARCHAR(50),
    procedure_name NVARCHAR(255),
    execution_start_datetime DATETIME2,
    execution_end_datetime DATETIME2,
    duration_seconds INT,
    row_count INT,
    status NVARCHAR(20),  -- SUCCESS, FAILURE, WARNING
    error_message NVARCHAR(MAX),
    created_datetime DATETIME2 DEFAULT GETDATE()
);

-- Log template
INSERT INTO audit.etl_execution_log (
    layer, procedure_name, execution_start_datetime,
    row_count, status
)
VALUES ('SILVER', 'usp_load_silver', GETDATE(), 1250, 'SUCCESS');
```

### Performance Metrics

| Metric | Target | Alert Threshold |
|--------|--------|-----------------|
| **Bronze Load** | < 5 min | > 10 min |
| **Silver Transform** | < 10 min | > 20 min |
| **Gold Model** | < 15 min | > 30 min |
| **Total ETL** | < 30 min | > 45 min |
| **Data Quality** | > 99% | < 95% |

---

## Orchestration Script

```sql
-- Master ETL orchestration
CREATE PROCEDURE usp_run_full_etl_pipeline
    @debug BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @etl_start DATETIME2 = GETDATE();
    
    TRY
        -- Phase 1: Load Bronze
        PRINT 'Starting Bronze Layer Load...';
        EXEC usp_load_bronze;
        
        -- Phase 2: Load Silver
        PRINT 'Starting Silver Layer Transform...';
        EXEC usp_load_silver;
        
        -- Phase 3: Load Gold
        PRINT 'Starting Gold Layer Model...';
        EXEC usp_load_gold;
        
        -- Phase 4: Quality Checks
        PRINT 'Running Data Quality Checks...';
        EXEC usp_run_quality_checks;
        
        -- Phase 5: Build Aggregates
        PRINT 'Building Aggregate Tables...';
        EXEC usp_build_aggregates;
        
        DECLARE @etl_end DATETIME2 = GETDATE();
        DECLARE @duration_seconds INT = DATEDIFF(SECOND, @etl_start, @etl_end);
        
        PRINT 'ETL Pipeline completed successfully in ' + CAST(@duration_seconds AS NVARCHAR(10)) + ' seconds';
        
        -- Send success notification
        EXECUTE msdb.dbo.sp_send_dbmail
            @recipients = 'dw-team@company.com',
            @subject = 'ETL SUCCESS - Daily Warehouse Load',
            @body = 'ETL Pipeline completed in ' + CAST(@duration_seconds AS NVARCHAR(10)) + ' seconds';
    
    END TRY
    BEGIN CATCH
        PRINT 'ETL Pipeline FAILED: ' + ERROR_MESSAGE();
        THROW;
    END CATCH;
END;
```

---

For SQL script examples, see `/scripts/` directory organized by layer.
