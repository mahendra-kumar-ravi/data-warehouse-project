# 📖 Complete Data Dictionary

**Comprehensive catalog of all tables, columns, and data definitions across all layers**

---

## Table of Contents

1. [Bronze Layer Tables](#bronze-layer-tables)
2. [Silver Layer Tables](#silver-layer-tables)
3. [Gold Layer - Dimensions](#gold-layer---dimensions)
4. [Gold Layer - Facts](#gold-layer---facts)
5. [Gold Layer - Aggregates](#gold-layer---aggregates)
6. [Data Type Reference](#data-type-reference)
7. [Audit Columns](#audit-columns)

---

## BRONZE LAYER TABLES

### 🔴 bronze.crm_customer_info

**Purpose**: Raw CRM customer data (landing zone)

**Source System**: CRM (Customer Relationship Management)

**Update Frequency**: Daily

**Retention**: Full history

| Column | Data Type | Nullable | Description |
|--------|-----------|----------|-------------|
| customer_id | INT | NO | Unique customer identifier from CRM |
| customer_number | NVARCHAR(50) | NO | Customer alphanumeric code |
| first_name | NVARCHAR(50) | YES | Customer first name |
| last_name | NVARCHAR(50) | YES | Customer last name |
| email | NVARCHAR(100) | YES | Customer email address |
| phone | NVARCHAR(20) | YES | Customer phone number |
| address | NVARCHAR(250) | YES | Street address |
| city | NVARCHAR(50) | YES | City name |
| state | NVARCHAR(50) | YES | State/Province |
| country | NVARCHAR(50) | YES | Country name (e.g., 'Australia') |
| postal_code | NVARCHAR(20) | YES | ZIP/Postal code |
| marital_status | NVARCHAR(50) | YES | Marital status (e.g., 'Married', 'Single') |
| gender | NVARCHAR(10) | YES | Gender (e.g., 'M', 'F', 'n/a') |
| birthdate | DATE | YES | Date of birth (YYYY-MM-DD) |
| create_date | DATE | YES | Record creation date in CRM |
| dwh_load_date | DATE | NO | Warehouse load date |
| dwh_load_time | TIME | NO | Warehouse load time |

**Sample Query**:
```sql
SELECT TOP 10 * FROM bronze.crm_customer_info
WHERE country = 'Australia'
ORDER BY create_date DESC;
```

---

### 🔴 bronze.crm_order_details

**Purpose**: Raw CRM order and line item data

**Source System**: CRM

**Update Frequency**: Daily

| Column | Data Type | Nullable | Description |
|--------|-----------|----------|-------------|
| order_id | INT | NO | Unique order identifier |
| order_number | NVARCHAR(50) | NO | Order alphanumeric code (e.g., 'SO54496') |
| customer_id | INT | NO | FK to customer |
| order_date | DATE | NO | Date order was placed |
| shipping_date | DATE | YES | Date order was shipped |
| due_date | DATE | YES | Payment due date |
| order_status | NVARCHAR(50) | YES | Order status (e.g., 'Pending', 'Shipped') |
| total_amount | DECIMAL(18,2) | NO | Total order amount |
| dwh_load_date | DATE | NO | Warehouse load date |

**Sample Query**:
```sql
SELECT customer_id, COUNT(*) AS order_count
FROM bronze.crm_order_details
WHERE order_date >= DATEADD(MONTH, -12, GETDATE())
GROUP BY customer_id
ORDER BY order_count DESC;
```

---

### 🔴 bronze.erp_products

**Purpose**: Raw ERP product catalog data

**Source System**: ERP (Enterprise Resource Planning)

**Update Frequency**: Daily

| Column | Data Type | Nullable | Description |
|--------|-----------|----------|-------------|
| product_id | INT | NO | Unique product identifier |
| product_number | NVARCHAR(50) | NO | Product SKU code |
| product_name | NVARCHAR(100) | NO | Product description with attributes |
| category_id | NVARCHAR(50) | NO | Product category ID |
| category | NVARCHAR(50) | NO | Product category (e.g., 'Bikes', 'Components') |
| subcategory | NVARCHAR(50) | YES | Product subcategory |
| maintenance_required | NVARCHAR(50) | YES | Maintenance requirement (e.g., 'Yes', 'No') |
| cost | DECIMAL(18,2) | NO | Product cost/COGS |
| product_line | NVARCHAR(50) | YES | Product line (e.g., 'Road', 'Mountain') |
| start_date | DATE | NO | Product availability start date |
| end_date | DATE | YES | Product end of life date (NULL if active) |
| dwh_load_date | DATE | NO | Warehouse load date |

**Sample Query**:
```sql
SELECT TOP 20 category, AVG(cost) AS avg_cost, COUNT(*) AS product_count
FROM bronze.erp_products
WHERE end_date IS NULL  -- Active products only
GROUP BY category
ORDER BY avg_cost DESC;
```

---

### 🔴 bronze.erp_sales_transactions

**Purpose**: Raw ERP sales transaction data

**Source System**: ERP

**Update Frequency**: Daily (incremental)

| Column | Data Type | Nullable | Description |
|--------|-----------|----------|-------------|
| sales_order_id | INT | NO | Unique sales order ID |
| order_number | NVARCHAR(50) | NO | Order reference number |
| product_id | INT | NO | FK to product |
| customer_id | INT | NO | FK to customer |
| order_date | DATE | NO | Order date |
| quantity | INT | NO | Units sold |
| unit_price | DECIMAL(18,2) | NO | Price per unit |
| sales_amount | DECIMAL(18,2) | NO | Total sale amount (Qty × Price) |
| discount_percent | DECIMAL(5,2) | YES | Discount percentage |
| tax_amount | DECIMAL(18,2) | YES | Tax amount |
| dwh_load_date | DATE | NO | Warehouse load date |

**Sample Query**:
```sql
SELECT TOP 100 * FROM bronze.erp_sales_transactions
WHERE order_date >= CAST(GETDATE() AS DATE)
ORDER BY sales_amount DESC;
```

---

## SILVER LAYER TABLES

### 🟡 silver.crm_customers

**Purpose**: Cleansed and deduplicated customer master

**Characteristics**:
- Duplicates removed
- Nulls standardized
- Data quality rules applied
- Surrogate key added

| Column | Data Type | Nullable | Description |
|--------|-----------|----------|-------------|
| sid_customer | INT | NO | Surrogate identifier |
| customer_id | INT | NO | Natural key from CRM |
| customer_number | NVARCHAR(50) | NO | Customer code |
| first_name | NVARCHAR(50) | NO | First name (standardized) |
| last_name | NVARCHAR(50) | NO | Last name (standardized) |
| email | NVARCHAR(100) | YES | Email (validated) |
| phone | NVARCHAR(20) | YES | Phone (standardized format) |
| address | NVARCHAR(250) | YES | Complete address |
| city | NVARCHAR(50) | YES | City |
| state | NVARCHAR(50) | YES | State |
| country | NVARCHAR(50) | YES | Country |
| postal_code | NVARCHAR(20) | YES | Postal code |
| marital_status | NVARCHAR(50) | YES | Marital status (M/S/D/W) |
| gender | NVARCHAR(10) | YES | Gender (M/F/Unknown) |
| birthdate | DATE | YES | Date of birth (validated) |
| age_years | INT | YES | Calculated age |
| is_duplicate | BIT | NO | Duplicate flag (0=unique, 1=duplicate) |
| duplicate_of_sid | INT | YES | Points to master record if duplicate |
| data_quality_score | DECIMAL(3,2) | NO | Completeness score (0.0-1.0) |
| dwh_load_date | DATE | NO | Load date |
| dwh_update_date | DATE | NO | Last update date |

**Data Quality Rules Applied**:
- ✓ Email format validation
- ✓ Phone number standardization (XXX-XXX-XXXX)
- ✓ Duplicate customer detection
- ✓ Null value standardization ('Unknown' for names)
- ✓ Age calculation validation

---

### 🟡 silver.crm_orders

**Purpose**: Cleansed order data

| Column | Data Type | Nullable | Description |
|--------|-----------|----------|-------------|
| sid_order | INT | NO | Surrogate order key |
| order_id | INT | NO | Natural order ID |
| order_number | NVARCHAR(50) | NO | Order code |
| sid_customer | INT | NO | FK to cleansed customer |
| order_date | DATE | NO | Order date (validated) |
| shipping_date | DATE | YES | Shipping date (validated ≥ order_date) |
| due_date | DATE | YES | Due date (validated ≥ order_date) |
| order_status | NVARCHAR(50) | YES | Standardized status |
| total_amount | DECIMAL(18,2) | NO | Order total (validated > 0) |
| days_to_ship | INT | YES | Calculated (shipping_date - order_date) |
| is_valid | BIT | NO | Data quality check flag |
| validation_errors | NVARCHAR(MAX) | YES | Error messages if invalid |
| dwh_load_date | DATE | NO | Load date |

**Data Quality Rules Applied**:
- ✓ shipping_date ≥ order_date
- ✓ due_date ≥ order_date
- ✓ total_amount > 0
- ✓ order_status in allowed values
- ✓ FK to customer exists

---

### 🟡 silver.erp_products

**Purpose**: Standardized product catalog

| Column | Data Type | Nullable | Description |
|--------|-----------|----------|-------------|
| sid_product | INT | NO | Surrogate product key |
| product_id | INT | NO | Natural product ID |
| product_number | NVARCHAR(50) | NO | Product SKU (standardized) |
| product_name | NVARCHAR(100) | NO | Product name (standardized) |
| category_id | NVARCHAR(50) | NO | Category ID |
| category | NVARCHAR(50) | NO | Category (standardized) |
| subcategory | NVARCHAR(50) | YES | Subcategory |
| maintenance_required | NVARCHAR(10) | YES | 'Yes' or 'No' (standardized) |
| cost | DECIMAL(18,2) | NO | Cost (validated > 0) |
| product_line | NVARCHAR(50) | YES | Product line |
| start_date | DATE | NO | Start date |
| end_date | DATE | YES | End date |
| is_active | BIT | NO | Active flag (end_date IS NULL) |
| dwh_load_date | DATE | NO | Load date |

---

### 🟡 silver.erp_sales

**Purpose**: Reconciled sales transactions

| Column | Data Type | Nullable | Description |
|--------|-----------|----------|-------------|
| sid_sales | INT | NO | Surrogate sales key |
| sales_order_id | INT | NO | Natural order ID |
| order_number | NVARCHAR(50) | NO | Order code |
| sid_product | INT | NO | FK to product |
| sid_customer | INT | NO | FK to customer |
| order_date | DATE | NO | Order date |
| quantity | INT | NO | Quantity (validated > 0) |
| unit_price | DECIMAL(18,2) | NO | Unit price (validated > 0) |
| sales_amount | DECIMAL(18,2) | NO | Sales amount |
| discount_percent | DECIMAL(5,2) | YES | Discount % (0-100) |
| discount_amount | DECIMAL(18,2) | YES | Calculated discount |
| tax_amount | DECIMAL(18,2) | YES | Tax amount |
| net_amount | DECIMAL(18,2) | NO | Final amount (sales - discount + tax) |
| cost | DECIMAL(18,2) | NO | Product cost |
| profit | DECIMAL(18,2) | NO | Calculated profit (net - cost) |
| profit_margin_percent | DECIMAL(5,2) | NO | Profit margin % |
| is_reconciled | BIT | NO | Reconciliation flag |
| dwh_load_date | DATE | NO | Load date |

**Calculations**:
- `discount_amount` = `sales_amount` × (`discount_percent` / 100)
- `net_amount` = `sales_amount` - `discount_amount` + `tax_amount`
- `profit` = `net_amount` - `cost`
- `profit_margin_percent` = (`profit` / `net_amount`) × 100

---

## GOLD LAYER - DIMENSIONS

### 🟢 gold.dim_customers

**Purpose**: Customer dimension with full attributes

**Type**: Slowly Changing Dimension (SCD Type 2 - Track History)

**Grain**: One row per customer per effective date

| Column | Data Type | Nullable | Description |
|--------|-----------|----------|-------------|
| customer_key | INT | NO | **Primary Key** - Surrogate key |
| customer_id | INT | NO | Business key from CRM |
| customer_number | NVARCHAR(50) | NO | Customer code |
| first_name | NVARCHAR(50) | NO | First name |
| last_name | NVARCHAR(50) | NO | Last name |
| email | NVARCHAR(100) | YES | Email address |
| phone | NVARCHAR(20) | YES | Phone number |
| address | NVARCHAR(250) | YES | Street address |
| city | NVARCHAR(50) | YES | City |
| state | NVARCHAR(50) | YES | State/Province |
| country | NVARCHAR(50) | YES | Country |
| postal_code | NVARCHAR(20) | YES | Postal code |
| marital_status | NVARCHAR(50) | YES | Marital status |
| gender | NVARCHAR(10) | YES | Gender |
| birthdate | DATE | YES | Date of birth |
| age_years | INT | YES | Current age |
| **effective_date** | **DATE** | **NO** | **SCD2 - Date change effective** |
| **expiration_date** | **DATE** | **NO** | **SCD2 - Date change expired** |
| **is_current** | **BIT** | **NO** | **SCD2 - Current flag (1=current)** |
| dwh_load_date | DATE | NO | Warehouse load date |

**Usage Example**:
```sql
-- Get current customer attributes
SELECT * FROM gold.dim_customers
WHERE is_current = 1;

-- Get customer history
SELECT * FROM gold.dim_customers
WHERE customer_id = 12345
ORDER BY effective_date;

-- Join to fact table
SELECT f.*, c.first_name, c.country
FROM gold.fact_sales f
JOIN gold.dim_customers c ON f.customer_key = c.customer_key;
```

---

### 🟢 gold.dim_products

**Purpose**: Product dimension

**Type**: Slowly Changing Dimension (SCD Type 1 - Overwrite)

**Grain**: One row per product

| Column | Data Type | Nullable | Description |
|--------|-----------|----------|-------------|
| product_key | INT | NO | **Primary Key** - Surrogate key |
| product_id | INT | NO | Business key from ERP |
| product_number | NVARCHAR(50) | NO | Product SKU |
| product_name | NVARCHAR(100) | NO | Product description |
| category_id | NVARCHAR(50) | NO | Category ID |
| category | NVARCHAR(50) | NO | Product category |
| subcategory | NVARCHAR(50) | YES | Product subcategory |
| maintenance_required | NVARCHAR(10) | YES | Maintenance requirement |
| cost | DECIMAL(18,2) | NO | Product cost |
| product_line | NVARCHAR(50) | YES | Product line |
| start_date | DATE | NO | Product availability start |
| end_date | DATE | YES | Product end of life |
| is_active | BIT | NO | Active product flag |
| dwh_load_date | DATE | NO | Load date |
| dwh_update_date | DATE | NO | Last update date |

---

### 🟢 gold.dim_date

**Purpose**: Calendar dimension for temporal analysis

**Type**: Conformed Dimension

**Grain**: One row per day

| Column | Data Type | Description |
|--------|-----------|-------------|
| date_key | INT | **PK** - YYYYMMDD format (e.g., 20250531) |
| full_date | DATE | Actual date |
| day_of_month | INT | Day (1-31) |
| day_of_week | INT | Day of week (1-7, Monday=1) |
| day_name | NVARCHAR(10) | Day name (e.g., 'Monday') |
| week_of_year | INT | Week number (1-53) |
| month_number | INT | Month (1-12) |
| month_name | NVARCHAR(10) | Month name (e.g., 'January') |
| quarter_number | INT | Quarter (1-4) |
| year_number | INT | Year (e.g., 2025) |
| is_weekend | BIT | Flag (1=Sat/Sun) |
| is_holiday | BIT | Flag (1=Holiday) |
| holiday_name | NVARCHAR(50) | Holiday name if applicable |
| is_workday | BIT | Flag (1=Workday) |
| day_offset | INT | Days from today (negative=past) |

**Usage Example**:
```sql
-- Sales by day of week
SELECT d.day_name, SUM(f.sales_amount) AS total_sales
FROM gold.fact_sales f
JOIN gold.dim_date d ON f.date_key = d.date_key
WHERE d.year_number = 2025
GROUP BY d.day_name
ORDER BY d.day_of_week;

-- Year-to-date analysis
SELECT SUM(f.sales_amount) AS ytd_sales
FROM gold.fact_sales f
JOIN gold.dim_date d ON f.date_key = d.date_key
WHERE d.year_number = 2025 AND d.day_offset <= 0;
```

---

### 🟢 gold.dim_geography

**Purpose**: Geographic dimension for regional analysis

**Type**: Reference Dimension

| Column | Data Type | Nullable | Description |
|--------|-----------|----------|-------------|
| geography_key | INT | NO | **Primary Key** - Surrogate |
| country | NVARCHAR(50) | NO | Country name |
| country_code | NVARCHAR(3) | NO | ISO 3166-1 alpha-3 code |
| state_province | NVARCHAR(50) | YES | State/Province name |
| city | NVARCHAR(50) | YES | City name |
| region | NVARCHAR(50) | YES | Sales/Business region |
| postal_code | NVARCHAR(20) | YES | Postal code |
| latitude | DECIMAL(10,7) | YES | Geographic latitude |
| longitude | DECIMAL(10,7) | YES | Geographic longitude |
| dwh_load_date | DATE | NO | Load date |

---

## GOLD LAYER - FACTS

### 🟢 gold.fact_sales

**Purpose**: Atomic-level sales transactions (Fact Table)

**Type**: Transactional Fact Table

**Grain**: One row per line item per order

**Update Pattern**: Append (immutable)

| Column | Data Type | Nullable | Description |
|--------|-----------|----------|-------------|
| sales_key | INT | NO | **Primary Key** - Unique identifier |
| order_number | NVARCHAR(50) | NO | **Degenerate Dimension** - Order code |
| **customer_key** | **INT** | **NO** | **FK → dim_customers** |
| **product_key** | **INT** | **NO** | **FK → dim_products** |
| **date_key** | **INT** | **NO** | **FK → dim_date** |
| **geography_key** | **INT** | **NO** | **FK → dim_geography** |
| order_date | DATE | NO | Order date (denormalized for perf) |
| shipping_date | DATE | YES | Shipping date |
| quantity | INT | NO | Units sold |
| unit_price | DECIMAL(18,2) | NO | Price per unit |
| sales_amount | DECIMAL(18,2) | NO | Revenue (Qty × Price) |
| discount_percent | DECIMAL(5,2) | YES | Discount % |
| discount_amount | DECIMAL(18,2) | YES | Discount $ |
| tax_amount | DECIMAL(18,2) | YES | Tax $ |
| net_sales_amount | DECIMAL(18,2) | NO | Net revenue |
| cost_amount | DECIMAL(18,2) | NO | Product cost |
| profit_amount | DECIMAL(18,2) | NO | Profit (net - cost) |
| profit_margin_percent | DECIMAL(5,2) | NO | Margin % |
| dwh_load_date | DATE | NO | Load date |

**Indexing**:
```sql
-- Clustered Index on Foreign Keys (for joins)
CREATE CLUSTERED INDEX idx_fact_sales_fk
ON gold.fact_sales(customer_key, product_key, date_key);

-- Non-clustered indexes on measures (for aggregations)
CREATE NONCLUSTERED INDEX idx_fact_sales_amount
ON gold.fact_sales(sales_amount DESC)
INCLUDE (customer_key, product_key);
```

---

### 🟢 gold.fact_orders

**Purpose**: Order-level aggregates (Aggregate Fact Table)

**Type**: Aggregate Fact Table

**Grain**: One row per order

| Column | Data Type | Description |
|--------|-----------|-------------|
| order_key | INT | **PK** - Unique order identifier |
| order_number | NVARCHAR(50) | Order code |
| **customer_key** | INT | **FK → dim_customers** |
| **date_key** | INT | **FK → dim_date** (order date) |
| order_date | DATE | Order date |
| shipping_date | DATE | Shipping date |
| order_line_count | INT | Number of line items |
| order_total_amount | DECIMAL(18,2) | Total order revenue |
| order_discount_amount | DECIMAL(18,2) | Total order discount |
| order_tax_amount | DECIMAL(18,2) | Total order tax |
| order_net_amount | DECIMAL(18,2) | Net order amount |
| order_cost_amount | DECIMAL(18,2) | Total cost |
| order_profit_amount | DECIMAL(18,2) | Total profit |
| days_to_ship | INT | Calculated (shipping - order date) |
| order_status | NVARCHAR(50) | Order fulfillment status |

---

## GOLD LAYER - AGGREGATES

### 🟢 gold.agg_sales_monthly

**Purpose**: Pre-aggregated monthly sales for performance

**Grain**: One row per month per customer per product

| Column | Data Type | Description |
|--------|-----------|-------------|
| year_month_key | INT | Year-Month key (YYYYMM format) |
| customer_key | INT | FK to customer |
| product_key | INT | FK to product |
| **month_sales_amount** | **DECIMAL(18,2)** | Monthly revenue |
| **month_quantity** | **INT** | Monthly units sold |
| **month_cost_amount** | **DECIMAL(18,2)** | Monthly cost |
| **month_profit_amount** | **DECIMAL(18,2)** | Monthly profit |
| order_count | INT | Orders placed |
| dwh_load_date | DATE | Load date |

**Usage**:
```sql
-- Monthly sales trend
SELECT year_month_key, SUM(month_sales_amount) AS total_sales
FROM gold.agg_sales_monthly
GROUP BY year_month_key
ORDER BY year_month_key DESC;
```

---

### 🟢 gold.agg_customer_summary

**Purpose**: Customer KPI metrics for dashboards

**Grain**: One row per customer

| Column | Data Type | Description |
|--------|-----------|-------------|
| customer_key | INT | **PK** - FK to dim_customers |
| total_lifetime_sales | DECIMAL(18,2) | Total revenue |
| total_orders | INT | Order count |
| total_units | INT | Units purchased |
| first_purchase_date | DATE | First order date |
| last_purchase_date | DATE | Most recent order |
| days_since_purchase | INT | Calculated recency |
| average_order_value | DECIMAL(18,2) | Calculated AOV |
| total_lifetime_cost | DECIMAL(18,2) | Total cost |
| total_lifetime_profit | DECIMAL(18,2) | Total profit |
| customer_profit_margin_percent | DECIMAL(5,2) | Margin % |
| dwh_load_date | DATE | Load date |

---

## Data Type Reference

### Standard Data Types Used

| Type | Usage | Example |
|------|-------|---------|
| **INT** | Whole numbers, IDs, counts | customer_id, quantity, year |
| **BIGINT** | Large numbers | transaction_id for 10M+ rows |
| **DECIMAL(18,2)** | Currency/Prices | sales_amount, cost, profit |
| **DATE** | Calendar dates | order_date, birth_date |
| **DATETIME2** | Timestamp with precision | dwh_load_time |
| **NVARCHAR(n)** | Text (Unicode) | names, addresses, descriptions |
| **BIT** | Boolean flags | is_current, is_active, is_weekend |

---

## Audit Columns

Every table includes these audit columns for tracking:

### Bronze & Silver Audit Columns

| Column | Type | Description |
|--------|------|-------------|
| **dwh_load_date** | DATE | Date record was loaded to DW |
| **dwh_load_time** | TIME | Time record was loaded |
| **dwh_source_file** | NVARCHAR(250) | Source filename |
| **dwh_row_hash** | NVARCHAR(64) | MD5 hash for change detection |

### Gold Layer Audit Columns

| Column | Type | Description |
|--------|------|-------------|
| **dwh_load_date** | DATE | Load date |
| **dwh_update_date** | DATE | Last update date |
| **dwh_load_by** | NVARCHAR(50) | Loaded by procedure/user |

### SCD Type 2 Audit Columns (Dimensions Only)

| Column | Type | Description |
|--------|------|-------------|
| **effective_date** | DATE | Date change became effective |
| **expiration_date** | DATE | Date change expired |
| **is_current** | BIT | Current record flag (1=current) |
| **dwh_version** | INT | Record version number |

---

## Key Relationships & Foreign Keys

```
FACT_SALES
├─ customer_key → dim_customers.customer_key
├─ product_key → dim_products.product_key
├─ date_key → dim_date.date_key
└─ geography_key → dim_geography.geography_key

FACT_ORDERS
├─ customer_key → dim_customers.customer_key
└─ date_key → dim_date.date_key

AGG_SALES_MONTHLY
├─ customer_key → dim_customers.customer_key
└─ product_key → dim_products.product_key

AGG_CUSTOMER_SUMMARY
└─ customer_key → dim_customers.customer_key
```

---

## Data Quality Metrics

### Expected Data Quality Scores

- **Bronze Layer**: 100% acceptance (raw data)
- **Silver Layer**: >95% quality (cleansed data)
- **Gold Layer**: 99.9% quality (business-ready)

### Validation Rules by Layer

| Layer | Rule | Threshold |
|-------|------|-----------|
| **Silver** | Null percentage | < 5% per column |
| **Silver** | Duplicate rate | < 1% of rows |
| **Silver** | FK validity | 100% match to master |
| **Gold** | Referential integrity | 100% match |
| **Gold** | Metric reasonableness | Profit margin 0-100% |

---

For implementation examples, see individual SQL scripts in `/scripts/` directory.
