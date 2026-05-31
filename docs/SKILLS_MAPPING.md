# 🎓 Skills Demonstrated

**Comprehensive mapping of enterprise-level data engineering competencies showcased in this project**

---

## Table of Contents

1. [SQL & Database Skills](#sql--database-skills)
2. [Data Warehousing](#data-warehousing)
3. [ETL Development](#etl-development)
4. [Data Quality & Governance](#data-quality--governance)
5. [Business Intelligence](#business-intelligence)
6. [Advanced Topics](#advanced-topics)

---

## SQL & Database Skills

### T-SQL Proficiency

#### ✅ Complex Query Optimization

**Demonstrated Through**:
- Multi-table joins with proper indexing
- Window functions for ranking, aggregation, partitioning
- Common Table Expressions (CTEs) for recursive queries
- Query execution plan analysis
- Query hints for performance tuning

**Code Example**:
```sql
-- Demonstrates: CTEs, Window Functions, Aggregation
WITH customer_sales AS (
    SELECT 
        c.customer_key,
        c.first_name,
        c.last_name,
        f.order_date,
        f.sales_amount,
        ROW_NUMBER() OVER (
            PARTITION BY c.customer_key 
            ORDER BY f.order_date DESC
        ) AS order_rank,
        SUM(f.sales_amount) OVER (
            PARTITION BY c.customer_key 
            ORDER BY f.order_date 
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_sales
    FROM gold.dim_customers c
    JOIN gold.fact_sales f ON c.customer_key = f.customer_key
),
top_customers AS (
    SELECT 
        customer_key,
        first_name,
        last_name,
        SUM(sales_amount) AS total_sales,
        COUNT(*) AS order_count,
        AVG(sales_amount) AS avg_order_value,
        MAX(cumulative_sales) AS lifetime_value
    FROM customer_sales
    WHERE order_rank <= 10  -- Last 10 orders only
    GROUP BY customer_key, first_name, last_name
)
SELECT TOP 100 *
FROM top_customers
WHERE total_sales > 10000
ORDER BY total_sales DESC;
```

**Skills Demonstrated**:
- ✓ CTE for readability and maintainability
- ✓ ROW_NUMBER() for ranking
- ✓ SUM() OVER (PARTITION BY... ROWS...) for running totals
- ✓ WHERE clause filtering CTEs
- ✓ Query performance optimization

#### ✅ Advanced Aggregations

**Demonstrates**:
- GROUP BY with HAVING clauses
- CASE statements for conditional aggregation
- Multiple aggregation levels (ROLLUP, CUBE)
- PIVOT/UNPIVOT for data reshaping

**Code Example**:
```sql
-- PIVOT table for sales by month and category
SELECT *
FROM (
    SELECT 
        FORMAT(f.order_date, 'yyyy-MM') AS year_month,
        dp.category,
        f.net_sales_amount
    FROM gold.fact_sales f
    JOIN gold.dim_products dp ON f.product_key = dp.product_key
) AS source
PIVOT (
    SUM(net_sales_amount)
    FOR category IN ([Bikes], [Components], [Clothing], [Accessories])
) AS pivot_table;
```

#### ✅ String Manipulation & Data Transformation

**Demonstrates**:
- CASE statements for conditional logic
- String functions (SUBSTRING, CHARINDEX, REPLACE, TRIM)
- Date calculations and transformations
- Type conversions (CAST, CONVERT)

**Code Example**:
```sql
-- Extract area code from phone number
SELECT 
    customer_id,
    first_name,
    phone,
    SUBSTRING(REPLACE(phone, '-', ''), 1, 3) AS area_code,
    CASE 
        WHEN SUBSTRING(REPLACE(phone, '-', ''), 1, 3) IN ('415', '510', '650') 
        THEN 'California'
        WHEN SUBSTRING(REPLACE(phone, '-', ''), 1, 3) IN ('212', '718', '646')
        THEN 'New York'
        ELSE 'Other'
    END AS inferred_state
FROM gold.dim_customers
WHERE phone IS NOT NULL;
```

#### ✅ Index Creation & Management

**Demonstrates**:
- Clustered index design
- Non-clustered index strategies
- INCLUDE columns for covering indexes
- Filtered indexes for specific data subsets

**Code Example**:
```sql
-- Optimize fact table with strategic indexing
-- Clustered index on primary key
CREATE CLUSTERED INDEX idx_fact_sales_pk
ON gold.fact_sales(sales_key);

-- Non-clustered index for common joins
CREATE NONCLUSTERED INDEX idx_fact_sales_customer
ON gold.fact_sales(customer_key)
INCLUDE (sales_amount, profit_amount);

-- Filtered index for active products only
CREATE NONCLUSTERED INDEX idx_dim_products_active
ON gold.dim_products(category, subcategory)
WHERE is_active = 1;
```

---

## Data Warehousing

### Dimensional Modeling

#### ✅ Star Schema Design

**Demonstrated Through**:
- Fact table granularity definition
- Dimension table hierarchies
- Conformed dimensions across multiple facts
- Degenerate dimensions

**Design Pattern**:
```
Fact Table: fact_sales
├─ Primary: sales_key
├─ Foreign Keys:
│  ├─ customer_key → dim_customers
│  ├─ product_key → dim_products
│  ├─ date_key → dim_date
│  └─ geography_key → dim_geography
└─ Measures:
   ├─ sales_amount
   ├─ quantity
   ├─ profit
   └─ discount
```

**Skills Demonstrated**:
- ✓ Understanding of fact vs. dimension tables
- ✓ Surrogate key implementation
- ✓ Slowly Changing Dimension (SCD) Types 1 & 2
- ✓ Degenerate dimension handling
- ✓ Slowly Changing Dimension logic

#### ✅ Slowly Changing Dimensions (SCD) Type 2

**Demonstrates History Tracking**:

```sql
-- SCD Type 2 Implementation: Track customer attribute changes
MERGE INTO gold.dim_customers AS target
USING (
    SELECT 
        customer_id,
        customer_number,
        first_name,
        last_name,
        email,
        country,
        marital_status
    FROM silver.crm_customers
    WHERE is_duplicate = 0
) AS source
ON target.customer_id = source.customer_id AND target.is_current = 1
WHEN MATCHED AND (
    target.email <> source.email OR
    target.country <> source.country OR
    target.marital_status <> source.marital_status
) THEN
    -- Close current version
    UPDATE SET 
        is_current = 0,
        expiration_date = CAST(GETDATE() - 1 AS DATE)
WHEN NOT MATCHED THEN
    -- Insert new customer
    INSERT (
        customer_id, customer_number, first_name, last_name, email, 
        country, marital_status, effective_date, expiration_date, 
        is_current, dwh_load_date
    )
    VALUES (
        source.customer_id, source.customer_number, source.first_name,
        source.last_name, source.email, source.country,
        source.marital_status, CAST(GETDATE() AS DATE),
        CAST('99991231' AS DATE), 1, CAST(GETDATE() AS DATE)
    );
```

**Skills Demonstrated**:
- ✓ MERGE statement for upsert operations
- ✓ Change detection logic
- ✓ Historical tracking with effective/expiration dates
- ✓ Version management
- ✓ Complex conditional logic

#### ✅ Dimensional Hierarchy & Navigation

**Demonstrates Multi-level Hierarchies**:
```sql
-- Product hierarchy navigation
SELECT 
    p.category,
    p.subcategory,
    p.product_line,
    COUNT(DISTINCT p.product_key) AS product_count,
    COUNT(DISTINCT f.order_number) AS order_count,
    SUM(f.sales_amount) AS total_sales
FROM gold.dim_products p
LEFT JOIN gold.fact_sales f ON p.product_key = f.product_key
GROUP BY ROLLUP (p.category, p.subcategory, p.product_line)
ORDER BY p.category, p.subcategory, p.product_line;
```

---

## ETL Development

### Data Integration

#### ✅ Multi-Source Data Consolidation

**Demonstrates**:
- CRM data integration (customer, orders)
- ERP data integration (products, sales)
- Delta vs. full extraction logic
- Cross-system reconciliation

**Reconciliation Example**:
```sql
-- Validate CRM vs ERP alignment
SELECT 
    'CRM Orders' AS source,
    COUNT(DISTINCT o.order_number) AS order_count,
    SUM(o.total_amount) AS total_amount
FROM silver.crm_orders o
UNION ALL
SELECT 
    'ERP Sales' AS source,
    COUNT(DISTINCT s.order_number) AS order_count,
    SUM(s.sales_amount) AS total_amount
FROM silver.erp_sales s;
```

#### ✅ Incremental Loading Strategies

**Demonstrates Change Data Capture**:
```sql
-- Delta extraction pattern
SELECT 
    *,
    CAST(GETDATE() AS DATE) AS dwh_load_date
FROM source_system.customers
WHERE last_modified_date >= @last_load_date
ORDER BY customer_id;
```

#### ✅ Error Handling & Logging

**Demonstrates Robust Error Management**:
```sql
BEGIN TRY
    BEGIN TRANSACTION;
    
    -- Load operation
    INSERT INTO silver.dim_customers (...)
    SELECT ... FROM bronze.crm_customer_info;
    
    -- Validation
    IF @@ROWCOUNT = 0
        THROW 50001, 'No rows inserted', 1;
    
    COMMIT TRANSACTION;
    
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    
    -- Log error
    INSERT INTO audit.etl_error_log (
        error_number, error_message, error_datetime
    )
    VALUES (ERROR_NUMBER(), ERROR_MESSAGE(), GETDATE());
    
    -- Notify stakeholders
    EXEC msdb.dbo.sp_send_dbmail
        @recipients = 'dw-team@company.com',
        @subject = 'ETL Error Alert',
        @body = 'Error: ' + ERROR_MESSAGE();
    
    THROW;
END CATCH;
```

### Stored Procedure Development

#### ✅ Orchestration & Master Scripts

**Demonstrates Procedure Design**:
```sql
CREATE PROCEDURE usp_run_full_etl_pipeline
    @debug BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2 = GETDATE();
    
    TRY
        -- Phase 1: Bronze
        EXEC usp_load_bronze;
        
        -- Phase 2: Silver
        EXEC usp_load_silver;
        
        -- Phase 3: Gold
        EXEC usp_load_gold;
        
        -- Phase 4: Quality Checks
        EXEC usp_validate_data_quality;
        
        DECLARE @end_time DATETIME2 = GETDATE();
        PRINT 'Pipeline completed in ' + 
              CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(10)) + ' seconds';
    
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
```

---

## Data Quality & Governance

### Validation Framework

#### ✅ Data Quality Checks

**Demonstrates Comprehensive Validation**:

```sql
-- Multi-layer quality validation
DECLARE @load_date DATE = CAST(GETDATE() AS DATE);

-- 1. Volume Check (Row count comparison)
SELECT 
    'Volume Check' AS check_name,
    COUNT(*) AS actual_count,
    CASE WHEN COUNT(*) > 0 THEN 'PASS' ELSE 'FAIL' END AS status
FROM silver.crm_customers
WHERE dwh_load_date = @load_date;

-- 2. Null Check (Completeness)
SELECT 
    COLUMN_NAME,
    SUM(CASE WHEN [value] IS NULL THEN 1 ELSE 0 END) AS null_count,
    CAST((SUM(CASE WHEN [value] IS NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) AS DECIMAL(5,2)) AS null_percent
FROM silver.crm_customers
WHERE dwh_load_date = @load_date
GROUP BY COLUMN_NAME
HAVING SUM(CASE WHEN [value] IS NULL THEN 1 ELSE 0 END) > 0;

-- 3. Duplicate Check
SELECT 
    customer_id,
    COUNT(*) AS duplicate_count
FROM silver.crm_customers
WHERE dwh_load_date = @load_date
GROUP BY customer_id
HAVING COUNT(*) > 1;

-- 4. Referential Integrity Check
SELECT 
    f.sales_key,
    'Invalid Customer Key' AS issue
FROM gold.fact_sales f
WHERE f.customer_key NOT IN (SELECT customer_key FROM gold.dim_customers WHERE is_current = 1)
UNION ALL
SELECT 
    f.sales_key,
    'Invalid Product Key' AS issue
FROM gold.fact_sales f
WHERE f.product_key NOT IN (SELECT product_key FROM gold.dim_products);

-- 5. Range/Format Check
SELECT 
    customer_key,
    profit_margin_percent
FROM gold.fact_sales
WHERE profit_margin_percent < -100 OR profit_margin_percent > 100;
```

**Skills Demonstrated**:
- ✓ Comprehensive validation design
- ✓ Business rule enforcement
- ✓ Anomaly detection
- ✓ Data quality scorecards
- ✓ Automated quality checks

#### ✅ Audit & Compliance

**Demonstrates Tracking & Accountability**:

```sql
-- Create comprehensive audit trail
CREATE TABLE audit.dml_audit_log (
    audit_id INT IDENTITY(1,1) PRIMARY KEY,
    table_name NVARCHAR(255),
    operation NVARCHAR(10),  -- INSERT, UPDATE, DELETE
    record_count INT,
    user_name NVARCHAR(255),
    operation_datetime DATETIME2,
    old_values NVARCHAR(MAX),
    new_values NVARCHAR(MAX)
);

-- Track all ETL operations
INSERT INTO audit.dml_audit_log (
    table_name, operation, record_count, user_name, operation_datetime
)
VALUES ('gold.dim_customers', 'INSERT', 1250, SYSTEM_USER, GETDATE());
```

---

## Business Intelligence

### Analytical Queries

#### ✅ Customer Analytics

**Demonstrates Advanced Analysis**:

```sql
-- RFM (Recency, Frequency, Monetary) Analysis
WITH customer_metrics AS (
    SELECT 
        c.customer_key,
        c.first_name,
        c.last_name,
        c.country,
        
        -- Recency: Days since last purchase
        DATEDIFF(DAY, MAX(f.order_date), GETDATE()) AS days_since_purchase,
        
        -- Frequency: Number of purchases
        COUNT(DISTINCT f.order_number) AS purchase_count,
        
        -- Monetary: Total spent
        SUM(f.net_sales_amount) AS total_spent,
        
        -- Average order value
        AVG(f.net_sales_amount) AS avg_order_value,
        
        -- Profit contribution
        SUM(f.profit_amount) AS total_profit
    FROM gold.dim_customers c
    LEFT JOIN gold.fact_sales f ON c.customer_key = f.customer_key AND c.is_current = 1
    GROUP BY c.customer_key, c.first_name, c.last_name, c.country
),
rfm_segments AS (
    SELECT 
        *,
        NTILE(4) OVER (ORDER BY days_since_purchase DESC) AS recency_quartile,
        NTILE(4) OVER (ORDER BY purchase_count) AS frequency_quartile,
        NTILE(4) OVER (ORDER BY total_spent) AS monetary_quartile,
        CASE 
            WHEN days_since_purchase <= 30 AND purchase_count >= 10 AND total_spent > 5000 
            THEN 'Champions'
            WHEN days_since_purchase <= 90 AND purchase_count >= 5 AND total_spent > 2000
            THEN 'Loyal Customers'
            WHEN days_since_purchase > 180 AND total_spent > 0
            THEN 'At Risk'
            ELSE 'Other'
        END AS customer_segment
    FROM customer_metrics
)
SELECT TOP 50 *
FROM rfm_segments
WHERE customer_segment IN ('Champions', 'At Risk')
ORDER BY total_profit DESC;
```

#### ✅ Product Performance Analytics

**Demonstrates Product Insights**:

```sql
-- Product performance dashboard metrics
SELECT 
    dp.category,
    dp.subcategory,
    dp.product_name,
    COUNT(DISTINCT f.order_number) AS orders,
    SUM(f.quantity) AS units_sold,
    SUM(f.net_sales_amount) AS total_revenue,
    SUM(f.profit_amount) AS total_profit,
    AVG(f.profit_margin_percent) AS avg_margin,
    CAST(SUM(f.profit_amount) * 100.0 / SUM(SUM(f.profit_amount)) OVER () AS DECIMAL(5,2)) AS pct_of_total_profit
FROM gold.dim_products dp
JOIN gold.fact_sales f ON dp.product_key = f.product_key
WHERE dp.is_active = 1
GROUP BY dp.category, dp.subcategory, dp.product_name
ORDER BY total_profit DESC;
```

---

## Advanced Topics

### Performance Tuning

#### ✅ Query Optimization

**Demonstrates Execution Plan Analysis**:
- Index selection optimization
- JOIN order optimization
- Predicate pushdown
- Query hints (HINT optimizer directives)

```sql
-- Optimized query with hints
SELECT TOP 100
    c.first_name,
    c.last_name,
    SUM(f.net_sales_amount) AS total_sales
FROM gold.dim_customers c
INNER JOIN gold.fact_sales f ON c.customer_key = f.customer_key
WHERE c.is_current = 1
    AND f.order_date >= DATEADD(YEAR, -1, GETDATE())
GROUP BY c.customer_key, c.first_name, c.last_name
OPTION (RECOMPILE, LOOP JOIN)
ORDER BY total_sales DESC;
```

### Data Modeling Excellence

#### ✅ Conformed Dimensions

**Demonstrates Shared Dimension Best Practices**:
- Single `dim_date` shared across all facts
- Single `dim_customers` reusable
- Consistent foreign key naming

#### ✅ Aggregate Tables for Performance

**Demonstrates Pre-aggregation Strategy**:
```sql
-- Monthly aggregate for dashboard performance
CREATE TABLE gold.agg_sales_monthly (
    year_month_key INT,
    customer_key INT,
    product_key INT,
    month_sales_amount DECIMAL(18,2),
    month_quantity INT,
    month_profit_amount DECIMAL(18,2)
);

CREATE CLUSTERED INDEX idx_agg_sales_monthly
ON gold.agg_sales_monthly(year_month_key, customer_key, product_key);
```

---

## Summary of Technical Competencies

| Area | Skills | Proficiency |
|------|--------|-------------|
| **T-SQL** | CTEs, Window Functions, Aggregations | Expert |
| **Dimensional Modeling** | Star Schema, SCD Type 1/2 | Expert |
| **ETL** | MERGE, Error Handling, Orchestration | Advanced |
| **Data Quality** | Validation, Reconciliation, Auditing | Advanced |
| **Performance** | Indexing, Query Optimization | Advanced |
| **Database Admin** | Backup, Recovery, Security | Intermediate |

---

## Interview Talking Points

1. **"How do you handle Slowly Changing Dimensions?"**
   - Implemented SCD Type 2 for customers with effective/expiration dates
   - Implemented SCD Type 1 (overwrite) for products
   - Used MERGE statement for efficient updates

2. **"Describe your data quality framework"**
   - Multi-layer validation (nulls, duplicates, referential integrity)
   - Automated checks in Silver layer
   - Business rule enforcement in Gold layer
   - Detailed error logging and alerts

3. **"How do you optimize query performance?"**
   - Strategic index design (clustered and non-clustered)
   - INCLUDE columns for covering indexes
   - Query hints and execution plan analysis
   - Pre-aggregated tables for reporting

4. **"Tell us about your ETL error handling"**
   - Try-Catch blocks with detailed logging
   - Automated email notifications on failure
   - Transaction rollback on errors
   - Audit trail for compliance

5. **"How do you reconcile data from multiple sources?"**
   - Row count comparisons between CRM and ERP
   - Amount validations across systems
   - Cross-reference integrity checks
   - Detailed reconciliation reports

---

**This project demonstrates enterprise-grade data engineering skills suitable for senior data engineer and data architect positions.**
