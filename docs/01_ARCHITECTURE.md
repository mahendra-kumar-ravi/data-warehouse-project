# 🏗️ Architecture Overview

This document provides a comprehensive architectural analysis of the Enterprise Data Warehouse project, detailing design decisions, layer descriptions, and implementation patterns.

---

## Table of Contents

1. [System Architecture](#system-architecture)
2. [Medallion Architecture Pattern](#medallion-architecture-pattern)
3. [Data Flow Diagram](#data-flow-diagram)
4. [Layer-by-Layer Analysis](#layer-by-layer-analysis)
5. [Schema Design](#schema-design)
6. [Performance Optimization](#performance-optimization)
7. [Security Architecture](#security-architecture)
8. [Disaster Recovery](#disaster-recovery)

---

## System Architecture

### High-Level System Design

```
┌─────────────────────────────────────────────────────────────────────┐
│                        DATA WAREHOUSE SYSTEM                        │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│ SOURCE SYSTEMS                                                      │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌──────────────────┐              ┌──────────────────────┐        │
│  │   CRM System     │              │   ERP System         │        │
│  │   (Customer      │              │   (Product &         │        │
│  │    & Orders)     │              │    Sales Data)       │        │
│  └────────┬─────────┘              └──────────┬───────────┘        │
│           │                                   │                    │
│           └───────────────┬───────────────────┘                    │
│                           │ ETL Extract                            │
└───────────────────────────┼───────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────────┐
│ BRONZE LAYER (Raw/Landing Zone)        [SQL Server - 38GB]        │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌─ crm_customer_info     (Raw CRM customer data)                 │
│  ├─ crm_order_details     (Raw CRM order data)                    │
│  ├─ erp_products          (Raw ERP product catalog)               │
│  └─ erp_sales_transactions (Raw ERP sales data)                   │
│                                                                     │
│  ✓ No transformation                                              │
│  ✓ One-to-one mapping with source                                 │
│  ✓ Full audit trail maintained                                    │
│                                                                     │
└───────────────────────────────────────────────────────────────────┘
                            │
                            │ Data Quality Rules
                            ▼
┌─────────────────────────────────────────────────────────────────────┐
│ SILVER LAYER (Cleansed/Standardized)   [SQL Server - Clean Data]  │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌─ crm_customers        (Deduplicated, validated)                │
│  ├─ crm_orders           (Quality rules applied)                   │
│  ├─ erp_products         (Standardized attributes)                │
│  └─ erp_sales            (Reconciled transactions)                │
│                                                                     │
│  ✓ Deduplication applied                                          │
│  ✓ Data quality rules enforced                                    │
│  ✓ Null values standardized                                       │
│  ✓ Referential integrity validated                                │
│                                                                     │
└───────────────────────────────────────────────────────────────────┘
                            │
                            │ Dimensional Modeling
                            ▼
┌─────────────────────────────────────────────────────────────────────┐
│ GOLD LAYER (Business-Ready Analytics)  [SQL Server - Star Schema] │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  DIMENSION TABLES:                                                │
│  ├─ dim_customers       (Customer master - SCD Type 2)           │
│  ├─ dim_products        (Product catalog - SCD Type 1)           │
│  ├─ dim_date            (Temporal dimension)                      │
│  └─ dim_geography       (Geographic dimension)                    │
│                                                                     │
│  FACT TABLES:                                                     │
│  ├─ fact_sales          (Transaction-level sales)                │
│  └─ fact_orders         (Order-level aggregates)                 │
│                                                                     │
│  AGGREGATES:                                                      │
│  ├─ agg_sales_monthly   (Pre-aggregated monthly sales)           │
│  └─ agg_customer_summary (Customer KPI metrics)                  │
│                                                                     │
│  ✓ Star schema optimized                                         │
│  ✓ Surrogate keys implemented                                    │
│  ✓ Fact/Dimension relationships established                      │
│  ✓ Query-optimized indexes created                               │
│                                                                     │
└───────────────────────────────────────────────────────────────────┘
                            │
                            │ BI Tools
                            ▼
┌─────────────────────────────────────────────────────────────────────┐
│ REPORTING & ANALYTICS                                              │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  Power BI Dashboards  │  Tableau Visualizations  │  Custom Reports│
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Medallion Architecture Pattern

The **Medallion Architecture** (also called **Lambda Architecture**) is a best-practice pattern that organizes data into three layers, each adding value to the raw data.

### Why Medallion Architecture?

| Aspect | Benefit |
|--------|---------|
| **Separation of Concerns** | Each layer has clear responsibility |
| **Data Lineage** | Easy to track data transformations |
| **Quality Control** | Issues isolated to specific layer |
| **Performance** | Each layer optimized for its purpose |
| **Reusability** | Cleansed data available for multiple uses |
| **Scalability** | Easy to add new data sources |

---

## Data Flow Diagram

### ETL Pipeline Flow

```
START: Daily Schedule @ 2:00 AM
    │
    ▼
┌──────────────────────────┐
│ EXTRACT PHASE            │
│  ├─ Connect to CRM       │
│  ├─ Query customers      │
│  ├─ Query orders         │
│  ├─ Connect to ERP       │
│  ├─ Query products       │
│  └─ Query sales          │
└──────┬───────────────────┘
       │ Success
       ▼
┌──────────────────────────┐
│ LOAD TO BRONZE           │
│  ├─ Create backup        │
│  ├─ Truncate tables      │
│  ├─ Bulk insert CRM      │
│  ├─ Bulk insert ERP      │
│  └─ Log activity         │
└──────┬───────────────────┘
       │ Success
       ▼
┌──────────────────────────┐
│ TRANSFORM TO SILVER      │
│  ├─ Deduplicate          │
│  ├─ Validate nulls       │
│  ├─ Standardize format   │
│  ├─ Cross-ref check      │
│  └─ Log errors           │
└──────┬───────────────────┘
       │ Success
       ▼
┌──────────────────────────┐
│ MODEL TO GOLD            │
│  ├─ Create dimensions    │
│  ├─ Create facts         │
│  ├─ Apply SCD logic      │
│  ├─ Build aggregates     │
│  └─ Create indexes       │
└──────┬───────────────────┘
       │ Success
       ▼
┌──────────────────────────┐
│ QUALITY CHECKS           │
│  ├─ Row count validation │
│  ├─ Referential integrity│
│  ├─ Business rules       │
│  └─ Reconciliation       │
└──────┬───────────────────┘
       │
       ├─ ✅ SUCCESS ──→ Notify Stakeholders
       │
       └─ ❌ FAILURE ──→ Alert DBA & Rollback
```

---

## Layer-by-Layer Analysis

### 🔴 BRONZE LAYER

**Purpose**: Immutable landing zone for raw data

**Characteristics**:
- One-to-one mapping with source systems
- No business logic applied
- Raw data accepted as-is
- Full change history maintained
- Retention: Full history

**Tables**:
```sql
bronze.crm_customer_info
bronze.crm_order_details
bronze.erp_products
bronze.erp_sales_transactions
```

**Key Design Decisions**:
- ✓ Preserve source data integrity
- ✓ Minimal transformations
- ✓ Audit columns added (dwh_load_date, dwh_load_time)
- ✓ No primary keys enforced
- ✓ Clustered indexes on source keys only

**Data Quality**:
- No validation (raw acceptance)
- Source format preservation
- Potential duplicates allowed

---

### 🟡 SILVER LAYER

**Purpose**: Cleansed and standardized data

**Characteristics**:
- Data quality rules enforced
- Duplicates removed
- Standardized formats
- Business logic applied
- Ready for analytics

**Tables**:
```sql
silver.crm_customers        -- Cleansed customer master
silver.crm_orders           -- Validated order data
silver.erp_products         -- Standardized products
silver.erp_sales            -- Reconciled sales data
```

**Transformations Applied**:

| Transformation | Rule | Example |
|---|---|---|
| **Deduplication** | Remove duplicate records | Keep latest by load_date |
| **Null Handling** | Standardize missing values | Replace NULL with 'Unknown' |
| **Type Casting** | Convert to correct data types | String → Date |
| **Trimming** | Remove whitespace | ' John ' → 'John' |
| **Standardization** | Consistent naming | 'M' → 'Male', 'F' → 'Female' |
| **Validation** | Check business rules | OrderDate ≤ ShipDate |

**Key Design Decisions**:
- ✓ Surrogate keys added (sid_*)
- ✓ Audit columns maintained (dwh_*, is_current)
- ✓ Primary keys enforced
- ✓ Foreign key relationships defined
- ✓ Non-clustered indexes on foreign keys

---

### 🟢 GOLD LAYER

**Purpose**: Business-ready analytical data

**Characteristics**:
- Dimensional star schema
- Optimized for queries
- Conformed dimensions
- Pre-aggregated tables
- Query-optimized indexes

**Dimension Tables**:

```sql
gold.dim_customers   -- Customer master with history
gold.dim_products    -- Product catalog
gold.dim_date        -- Calendar dimension
gold.dim_geography   -- Location hierarchy
```

**Fact Tables**:

```sql
gold.fact_sales      -- Transaction-level sales
gold.fact_orders     -- Order-level metrics
```

**Aggregate Tables**:

```sql
gold.agg_sales_monthly      -- Monthly sales summary
gold.agg_customer_summary    -- Customer KPIs
```

**Key Design Decisions**:
- ✓ Star schema structure
- ✓ Surrogate key-based relationships
- ✓ Degenerate dimensions in facts
- ✓ Clustered indexes on fact keys
- ✓ Non-clustered indexes on foreign keys

---

## Schema Design

### Dimensional Modeling Principles

```
FACT TABLE RELATIONSHIPS

                    ┌──────────────────┐
                    │  dim_customers   │
                    │  ────────────────│
                    │  customer_key(PK)│
                    └────────┬─────────┘
                             │
                             │ FK
                             │
    ┌────────────────────────┼────────────────────────┐
    │                        │                        │
    ▼                        ▼                        ▼
┌──────────────┐      ┌─────────────────┐      ┌──────────────┐
│ dim_products │      │  fact_sales     │      │  dim_date    │
│ ────────────│◄──────┤ ───────────────│─────►│ ──────────── │
│ product_key │ FK    │ product_key(FK)│  FK  │ date_key(PK) │
│      (PK)   │       │ customer_key(FK)     │            │
└──────────────┘       │ date_key(FK)   │      └──────────────┘
                       │ sales_amount   │
                       │ quantity       │
                       │ profit         │
                       └─────────────────┘
```

### Surrogate Key Strategy

**Why Surrogate Keys?**
- ✓ Stable keys independent of business changes
- ✓ Improved join performance
- ✓ Support for Slowly Changing Dimensions
- ✓ Easier to manage history

**Implementation**:

```sql
-- Surrogate Key Generation
CREATE TABLE gold.dim_customers (
    customer_key INT PRIMARY KEY IDENTITY(1,1),  -- Surrogate
    customer_id INT NOT NULL,                     -- Natural key
    customer_number NVARCHAR(50) NOT NULL,        -- Natural key
    first_name NVARCHAR(50),
    last_name NVARCHAR(50),
    country NVARCHAR(50),
    -- SCD Type 2 columns
    effective_date DATE,
    expiration_date DATE,
    is_current BIT,
    dwh_load_date DATE
);
```

---

## Performance Optimization

### Indexing Strategy

| Table Type | Index Type | Strategy |
|-----------|-----------|----------|
| **Dimension** | Clustered on PK | Fast joins via surrogate key |
| **Dimension** | Non-clustered on Business Key | Support for lookups by natural key |
| **Fact** | Clustered on Foreign Keys | Fact table scans optimized |
| **Fact** | Non-clustered on Measures | Support aggregation queries |

### Query Optimization Techniques

```sql
-- 1. Use Columnar Storage for Large Fact Tables
CREATE CLUSTERED COLUMNSTORE INDEX cci_fact_sales
ON gold.fact_sales;

-- 2. Partition Large Tables by Date
CREATE PARTITION SCHEME ps_date
  AS PARTITION pf_date
  TO (fg_2024, fg_2025);

-- 3. Use Statistics for Query Optimizer
UPDATE STATISTICS gold.fact_sales;

-- 4. Materialized Views for Common Aggregations
CREATE VIEW gold.mv_sales_by_month
WITH SCHEMABINDING
AS
SELECT 
    YEAR(order_date) AS year,
    MONTH(order_date) AS month,
    SUM(sales_amount) AS total_sales
FROM gold.fact_sales
GROUP BY YEAR(order_date), MONTH(order_date);

CREATE UNIQUE CLUSTERED INDEX idx_mv_sales
ON gold.mv_sales_by_month(year, month);
```

---

## Security Architecture

### Access Control

**Role-Based Access Control (RBAC)**:

```sql
-- Bronze Layer: Restricted Access
CREATE ROLE [Bronze_Readonly]
GRANT SELECT ON SCHEMA::bronze TO [Bronze_Readonly];

-- Silver Layer: Development Access
CREATE ROLE [Silver_Developer]
GRANT SELECT, INSERT, UPDATE ON SCHEMA::silver TO [Silver_Developer];

-- Gold Layer: Analyst Access
CREATE ROLE [Gold_Analyst]
GRANT SELECT ON SCHEMA::gold TO [Gold_Analyst];

-- Database Admin: Full Access
CREATE ROLE [DW_Admin]
GRANT CONTROL ON DATABASE::DataWarehouse TO [DW_Admin];
```

### Data Encryption

```sql
-- Transparent Data Encryption (TDE)
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'StrongPassword123!';

ALTER DATABASE DataWarehouse
SET ENCRYPTION ON;

-- Column-Level Encryption (Sensitive Data)
CREATE CERTIFICATE customer_cert
WITH SUBJECT = 'Customer PII Certificate';

ALTER TABLE gold.dim_customers
ADD email_encrypted VARBINARY(256);
```

---

## Disaster Recovery

### Backup Strategy

| Backup Type | Frequency | Retention | Purpose |
|-----------|-----------|-----------|---------|
| **Full Backup** | Daily (11 PM) | 30 days | Complete database snapshot |
| **Differential** | Every 6 hours | 7 days | Faster recovery |
| **Transaction Log** | Every 15 minutes | 3 days | Point-in-time recovery |

### Recovery Time Objectives (RTO/RPO)

| Scenario | RTO | RPO | Recovery Method |
|----------|-----|-----|-----------------|
| **Data Corruption** | < 2 hours | < 15 min | Point-in-time restore |
| **Hardware Failure** | < 4 hours | < 30 min | Full restore + TLog |
| **Regional Disaster** | < 24 hours | < 1 hour | Geo-redundant backup |

---

## Conclusion

This architecture provides:
- ✅ **Scalability**: Supports growth from MB to TB+ datasets
- ✅ **Reliability**: Comprehensive backup and recovery
- ✅ **Performance**: Optimized for analytical queries
- ✅ **Maintainability**: Clear separation of concerns
- ✅ **Security**: Multi-layered access control
- ✅ **Flexibility**: Easy to add new data sources

For implementation details, see [ETL Process Documentation](04_ETL_PROCESS.md).
