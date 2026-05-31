# Enterprise Data Warehouse Project
**A Production-Grade SQL Data Warehouse Built with SQL Server**

![Data Warehouse](https://img.shields.io/badge/SQL%20Server-Data%20Warehouse-blue?style=flat-square)
![Architecture](https://img.shields.io/badge/Architecture-Medallion-green?style=flat-square)
![Status](https://img.shields.io/badge/Status-Production%20Ready-brightgreen?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-yellow?style=flat-square)

---

## 📋 Table of Contents

- [Project Overview](#project-overview)
- [Business Problem](#business-problem)
- [Architecture](#architecture)
- [Repository Structure](#repository-structure)
- [Data Warehouse Design](#data-warehouse-design)
- [Getting Started](#getting-started)
- [Skills Demonstrated](#skills-demonstrated)
- [Business Impact](#business-impact)
- [Documentation](#documentation)
- [Contributing](#contributing)
- [License](#license)

---

## 🎯 Project Overview

This enterprise-grade Data Warehouse project demonstrates a comprehensive end-to-end data engineering solution built with **SQL Server**. The project consolidates data from multiple source systems (ERP and CRM), applies rigorous data quality transformations, and delivers business-ready analytics through a dimensional star schema.

**Key Highlights:**
- ✅ **Medallion Architecture**: Bronze → Silver → Gold layers with clear data lineage
- ✅ **Star Schema Design**: Optimized for analytical queries and reporting
- ✅ **Data Quality Framework**: Comprehensive cleaning and validation processes
- ✅ **Production-Ready Code**: Industry best practices with comprehensive documentation
- ✅ **Dimensional Modeling**: Fact and dimension tables for enterprise analytics

---

## 💼 Business Problem

### Objective
Organizations face challenges in:
1. **Data Silos**: Sales data fragmented across ERP and CRM systems
2. **Data Quality**: Inconsistent, incomplete, and duplicate records
3. **Analytical Gaps**: Difficulty answering business questions without manual data manipulation
4. **Decision-Making**: Lack of real-time insights into customer behavior, product performance, and sales trends

### Solution
This Data Warehouse consolidates multi-source data into a unified, high-quality analytical platform that enables:
- **360-degree customer view** with demographic enrichment
- **Product performance analysis** across categories and subcategories
- **Sales trend analysis** with temporal dimensions
- **Real-time dashboarding** and business intelligence

---

## 🏗️ Architecture

### Medallion Architecture Pattern

```
┌─────────────────────────────────────────────────────────────┐
│                    DATA WAREHOUSE LAYERS                    │
└─────────────────────────────────────────────────────────────┘

SOURCE SYSTEMS
    ↓
    ├─────────────────────────────────────────────────────────┐
    │ BRONZE LAYER (Raw/Landing)                              │
    │ ├─ crm_customer_info (Raw customer data from CRM)       │
    │ ├─ crm_order_details (Raw orders from CRM)              │
    │ ├─ erp_products (Raw products from ERP)                 │
    │ └─ erp_sales_transactions (Raw sales from ERP)          │
    └─────────────────────────────────────────────────────────┘
    ↓
    ├─────────────────────────────────────────────────────────┐
    │ SILVER LAYER (Cleansed/Standardized)                    │
    │ ├─ crm_customers (Deduplicated, validated)              │
    │ ├─ crm_orders (Data quality rules applied)              │
    │ ├─ erp_products (Standardized attributes)               │
    │ └─ erp_sales (Reconciled transactions)                  │
    └─────────────────────────────────────────────────────────┘
    ↓
    ├─────────────────────────────────────────────────────────┐
    │ GOLD LAYER (Business-Ready/Analytical)                  │
    │ ├─ DIMENSION TABLES:                                    │
    │ │  ├─ dim_customers (Customer master with SCD Type 2)   │
    │ │  ├─ dim_products (Product catalog)                    │
    │ │  ├─ dim_date (Temporal dimension)                     │
    │ │  └─ dim_geography (Location dimension)                │
    │ │                                                        │
    │ ├─ FACT TABLES:                                         │
    │ │  ├─ fact_sales (Sales transactions)                   │
    │ │  └─ fact_orders (Order metrics)                       │
    │ │                                                        │
    │ └─ AGGREGATE TABLES:                                    │
    │    ├─ agg_sales_monthly (Pre-aggregated for performance)│
    │    └─ agg_customer_summary (Customer KPIs)              │
    └─────────────────────────────────────────────────────────┘
    ↓
    ANALYTICS & REPORTING
    (Power BI / Tableau / Custom Dashboards)
```

### Layer Descriptions

#### 🔴 BRONZE LAYER (Landing Zone)
- **Purpose**: Captures raw data from source systems with minimal transformation
- **Characteristics**: One-to-one mapping with source tables, historical preservation
- **Key Tables**: `crm_*`, `erp_*`
- **Data Quality**: None (raw data acceptance)
- **Retention**: Full history maintained for audit trail

#### 🟡 SILVER LAYER (Cleansing & Standardization)
- **Purpose**: Applies data quality rules, deduplication, and standardization
- **Characteristics**: Business logic applied, data validation implemented
- **Key Tables**: Cleansed versions of bronze tables
- **Data Quality**: Applied rules for nulls, duplicates, referential integrity
- **Retention**: Latest snapshot with audit columns

#### 🟢 GOLD LAYER (Business-Ready Analytics)
- **Purpose**: Dimensional models optimized for analytical queries
- **Characteristics**: Star schema with dimensions and facts, denormalized for performance
- **Key Tables**: `dim_*`, `fact_*`, `agg_*`
- **Data Quality**: Fully validated with surrogate keys and relationships
- **Retention**: Aggregated and summarized for reporting

---

## 📂 Repository Structure

```
data-warehouse-project/
│
├── 📄 README.md                          # Project overview (this file)
├── 📄 LICENSE                            # MIT License
├── 📄 .gitignore                         # Git ignore rules
│
├── docs/                                 # 📚 Comprehensive Documentation
│   ├── 01_ARCHITECTURE.md               # Architecture overview and decisions
│   ├── 02_DATA_DICTIONARY.md            # Complete data catalog
│   ├── 03_NAMING_CONVENTIONS.md         # Naming standards and guidelines
│   ├── 04_ETL_PROCESS.md                # ETL workflow documentation
│   ├── 05_BUSINESS_LOGIC.md             # Business rules and calculations
│   ├── 06_DEPLOYMENT_GUIDE.md           # Step-by-step deployment instructions
│   ├── 07_TROUBLESHOOTING.md            # Common issues and solutions
│   ├── ARCHITECTURE_DIAGRAM.md          # Visual diagrams (Mermaid)
│   ├── ERD.md                           # Entity Relationship Diagrams
│   └── SKILLS_MAPPING.md                # Skills demonstrated in project
│
├── datasets/                             # 📊 Sample Data Sources
│   ├── crm_customer_info.csv            # CRM customer data
│   ├── crm_order_details.csv            # CRM order data
│   ├── erp_products.csv                 # ERP product catalog
│   └── erp_sales_transactions.csv       # ERP sales transactions
│
├── scripts/                              # 🔧 SQL Implementation Scripts
│
│   ├── 00_setup/                        # Database and Schema Setup
│   │   ├── 01_create_database.sql       # Database initialization
│   │   ├── 02_create_schemas.sql        # Schema creation (bronze, silver, gold)
│   │   └── 03_create_file_formats.sql   # External file format definitions
│   │
│   ├── 01_bronze_layer/                 # 🔴 Raw Data Landing
│   │   ├── 01_bronze_create_tables.sql  # Create raw data tables
│   │   ├── 02_bronze_load_crm.sql       # Load CRM data
│   │   ├── 03_bronze_load_erp.sql       # Load ERP data
│   │   └── PROCESS_LOG.sql              # Audit and monitoring procedures
│   │
│   ├── 02_silver_layer/                 # 🟡 Data Cleansing
│   │   ├── 01_silver_create_tables.sql  # Create cleansed tables
│   │   ├── 02_silver_customers_clean.sql # Customer deduplication & validation
│   │   ├── 03_silver_orders_clean.sql    # Order data cleaning
│   │   ├── 04_silver_products_clean.sql  # Product standardization
│   │   ├── 05_silver_reconciliation.sql  # Cross-system reconciliation
│   │   └── QUALITY_CHECKS.sql            # Data quality validation procedures
│   │
│   ├── 03_gold_layer/                   # 🟢 Business-Ready Analytics
│   │   ├── 01_gold_dimension_tables.sql  # All dimension table creation
│   │   ├── 02_gold_fact_tables.sql       # All fact table creation
│   │   ├── 03_gold_scd_type2.sql         # Slowly Changing Dimensions logic
│   │   ├── 04_gold_aggregates.sql        # Pre-aggregated tables
│   │   └── 05_gold_indexes.sql           # Performance indexes
│   │
│   ├── 04_queries/                      # 📈 Analytical Queries
│   │   ├── 01_customer_analytics.sql    # Customer insights
│   │   ├── 02_product_analytics.sql     # Product performance
│   │   ├── 03_sales_analytics.sql       # Sales trends and forecasting
│   │   └── 04_business_reports.sql      # Executive reporting queries
│   │
│   ├── 05_procedures/                   # ⚙️ Stored Procedures
│   │   ├── 01_load_bronze.sql           # Orchestrates bronze layer load
│   │   ├── 02_load_silver.sql           # Orchestrates silver layer load
│   │   ├── 03_load_gold.sql             # Orchestrates gold layer load
│   │   ├── 04_refresh_dimensions.sql    # Dimension table refresh logic
│   │   └── 05_audit_procedures.sql      # Audit trail logging
│   │
│   ├── 06_utilities/                    # 🛠️ Utility Scripts
│   │   ├── 01_drop_all_objects.sql      # Clean slate script
│   │   ├── 02_create_backups.sql        # Backup procedures
│   │   ├── 03_performance_stats.sql     # Performance monitoring
│   │   └── 04_data_validation.sql       # Validation framework
│   │
│   └── RUN_PIPELINE.sql                 # 🚀 Master orchestration script
│
├── tests/                                # ✅ Testing & Validation
│   ├── 01_data_quality_tests.sql        # DQC validation rules
│   ├── 02_integrity_tests.sql           # Referential integrity checks
│   ├── 03_reconciliation_tests.sql      # Source vs warehouse validation
│   ├── test_results/                    # Test execution logs
│   └── TEST_SUITE.sql                   # Master test orchestration
│
├── config/                               # ⚙️ Configuration Files
│   ├── database_config.json              # Database connection parameters
│   ├── transformation_rules.json         # Business rule definitions
│   └── alerts_thresholds.json            # Data quality thresholds
│
├── 🎯 QUICK_START.md                    # Fast setup guide for impatient developers
└── 📝 DEPLOYMENT_CHECKLIST.md            # Pre-production deployment steps

```

---

## 🗄️ Data Warehouse Design

### Dimensional Model (Star Schema)

```
                    ╔═══════════════╗
                    ║ dim_date      ║
                    ║───────────────║
                    ║ date_key (PK) ║
                    ║ full_date     ║
                    ║ month         ║
                    ║ quarter       ║
                    ║ year          ║
                    ║ day_of_week   ║
                    ╚═══════════════╝
                           ▲
                           │ fk_date_key
                           │
        ╔══════════════╗   │   ╔═════════════════╗
        ║ dim_products ║   │   ║ fact_sales      ║
        ║──────────────║ ◄─┼──►║─────────────────║
        ║ product_key  ║◄──┼──►║ product_key(FK) ║
        ║ product_id   ║   │   ║ customer_key(FK)║
        ║ product_name ║   │   ║ date_key(FK)    ║
        ║ category     ║   │   ║ order_date      ║
        ║ subcategory  ║   │   ║ sales_amount    ║
        ║ price        ║   │   ║ quantity        ║
        ║ cost         ║   │   ║ profit          ║
        ╚══════════════╝   │   ╚═════════════════╝
                           │ fk_customer_key
                           │
                    ╔═══════════════╗
                    ║ dim_customers ║
                    ║───────────────║
                    ║ customer_key  ║
                    ║ customer_id   ║
                    ║ first_name    ║
                    ║ last_name     ║
                    ║ email         ║
                    ║ country       ║
                    ║ marital_status║
                    ╚═══════════════╝
```

### Fact Tables

| Fact Table | Grain | Measures | Dimensions |
|-----------|-------|----------|-----------|
| **fact_sales** | One row per sales transaction | sales_amount, quantity, discount, tax, profit | customer, product, date, geography |
| **fact_orders** | One row per order | order_amount, items_count, shipping_cost, lead_time | customer, date, status, region |

### Dimension Tables

| Dimension | Type | Key Attributes | Use Case |
|-----------|------|----------------|----------|
| **dim_customers** | SCD Type 2 | customer_id, name, email, country, marital_status | Customer segmentation, loyalty analysis |
| **dim_products** | SCD Type 1 | product_id, name, category, subcategory, price, cost | Product performance, inventory analysis |
| **dim_date** | Conformed | date, month, quarter, year, day_of_week, holidays | Time-based analysis, trend detection |
| **dim_geography** | Reference | country, state, city, region, postal_code | Geographic analysis, market segmentation |

---

## 🚀 Getting Started

### Prerequisites

- **SQL Server 2019 or later** (SQL Server Express supported)
- **SQL Server Management Studio (SSMS)** 18.0+
- **Sample Datasets** (CSV files in `/datasets`)
- **Git** for version control

### Setup Instructions

#### **Step 1: Setup Database and Schemas**
```sql
-- Run this first to create the database structure
EXECUTE master.dbo.sp_executesql N'CREATE DATABASE DataWarehouse'
GO
USE DataWarehouse
GO

-- Create schemas
CREATE SCHEMA bronze;
GO
CREATE SCHEMA silver;
GO
CREATE SCHEMA gold;
GO
```

#### **Step 2: Load Bronze Layer**
```sql
-- Execute bronze layer setup
EXEC scripts.load_bronze;
-- This loads raw data from CSV files into bronze tables
```

#### **Step 3: Transform to Silver Layer**
```sql
-- Execute silver layer transformations
EXEC scripts.load_silver;
-- This applies data quality rules and deduplication
```

#### **Step 4: Load Gold Layer**
```sql
-- Execute gold layer dimensional models
EXEC scripts.load_gold;
-- This creates dimensions and fact tables for analytics
```

#### **Step 5: Run Analytical Queries**
```sql
-- Explore business insights
SELECT TOP 10 * FROM gold.fact_sales
ORDER BY order_date DESC;

SELECT * FROM gold.dim_customers
WHERE country = 'Australia';
```

### Quick Start Script

For immediate setup, execute the master orchestration script:

```sql
-- Single-step pipeline execution (creates all layers)
EXEC master.RUN_PIPELINE;
```

### Deployment Checklist

Before deploying to production, ensure:
- ✅ All data quality tests pass (see `/tests`)
- ✅ Referential integrity validated
- ✅ Performance indexes created
- ✅ Backup strategy configured
- ✅ User permissions granted
- ✅ Monitoring and alerts configured

---

## 🎓 Skills Demonstrated

This project showcases enterprise-level data engineering competencies:

### **Core SQL Competencies**
- ✅ **Complex Joins & Aggregations**: Multi-table joins, window functions, CTEs
- ✅ **Data Transformation**: CASE statements, string manipulation, date calculations
- ✅ **Performance Optimization**: Index strategies, query optimization, execution plans
- ✅ **Advanced SQL**: Window functions, recursive CTEs, set operations
- ✅ **Stored Procedures**: Parameterized scripts, error handling, transactions

### **Data Warehousing**
- ✅ **Medallion Architecture**: Bronze-Silver-Gold layer implementation
- ✅ **Dimensional Modeling**: Star schema, fact/dimension tables, surrogate keys
- ✅ **Slowly Changing Dimensions (SCD)**: Type 1, Type 2 implementations
- ✅ **Data Lineage**: Complete tracking from source to analytics
- ✅ **Conformed Dimensions**: Shared dimension tables across fact tables

### **ETL Development**
- ✅ **Data Integration**: Multi-source system consolidation
- ✅ **Incremental Loading**: Delta detection and processing
- ✅ **Error Handling**: Robust exception management and logging
- ✅ **Orchestration**: Master scripts coordinating layer execution
- ✅ **Idempotency**: Re-runnable pipelines without duplication

### **Data Quality & Governance**
- ✅ **Validation Frameworks**: Comprehensive data quality checks
- ✅ **Anomaly Detection**: Statistical validation and thresholds
- ✅ **Audit Logging**: Complete change tracking and accountability
- ✅ **Reconciliation**: Source vs warehouse validation
- ✅ **Deduplication**: Identifying and resolving duplicate records

### **Business Intelligence**
- ✅ **Analytical Queries**: Customer, product, and sales analytics
- ✅ **Business Metrics**: KPI calculations and trend analysis
- ✅ **Report Generation**: Executive-level dashboarding queries
- ✅ **Predictive Insights**: Time-series analysis and forecasting
- ✅ **Segmentation**: Customer clustering and RFM analysis

### **Database Administration**
- ✅ **Schema Design**: Logical and physical data modeling
- ✅ **Indexing Strategy**: Clustered and non-clustered indexes
- ✅ **Performance Tuning**: Query optimization and statistics
- ✅ **Backup & Recovery**: Business continuity planning
- ✅ **Security**: Row-level security, encryption, access control

---

## 💡 Business Impact

### Key Business Questions Answered

| Question | Data Source | Business Value |
|----------|-------------|-----------------|
| Which customers generate the highest revenue? | fact_sales + dim_customers | Revenue optimization, account management |
| What are the top-performing products? | fact_sales + dim_products | Inventory planning, marketing focus |
| Which regions underperform? | fact_sales + dim_geography | Market expansion strategy |
| What are customer purchase patterns? | fact_sales + dim_date | Personalization, retention strategy |
| Which product categories have highest margins? | fact_sales + dim_products | Pricing strategy, profitability |
| What is customer lifetime value? | fact_sales (historical) | Customer segmentation, lifetime acquisition cost |

### Analytics Capabilities

**Customer Analytics**
- 360-degree customer view with demographic data
- Purchase history and lifetime value calculation
- Customer segmentation and churn prediction
- Geographic distribution and regional analysis

**Product Analytics**
- Product performance by category and subcategory
- Profit margin analysis and pricing optimization
- Product lifecycle tracking and obsolescence
- Cross-sell and upsell opportunities

**Sales Analytics**
- Monthly/quarterly/yearly sales trends
- Seasonal patterns and anomaly detection
- Sales pipeline and lead time analysis
- Promotional effectiveness measurement

---

## 📚 Documentation

### Core Documentation
- **[Architecture Overview](docs/01_ARCHITECTURE.md)** - System design and layer descriptions
- **[Data Dictionary](docs/02_DATA_DICTIONARY.md)** - Complete table and column documentation
- **[Naming Conventions](docs/03_NAMING_CONVENTIONS.md)** - Standardized naming guidelines
- **[ETL Process](docs/04_ETL_PROCESS.md)** - Detailed ETL workflow documentation
- **[Business Logic](docs/05_BUSINESS_LOGIC.md)** - Business rule implementations
- **[Deployment Guide](docs/06_DEPLOYMENT_GUIDE.md)** - Production deployment steps
- **[Troubleshooting](docs/07_TROUBLESHOOTING.md)** - Common issues and solutions
- **[Architecture Diagrams](docs/ARCHITECTURE_DIAGRAM.md)** - Visual system diagrams
- **[Skills Mapping](docs/SKILLS_MAPPING.md)** - Detailed skills documentation

### Quick References
- **[Quick Start Guide](QUICK_START.md)** - 5-minute setup
- **[Deployment Checklist](DEPLOYMENT_CHECKLIST.md)** - Pre-deployment verification

---

## 🔧 Technology Stack

| Component | Technology | Version |
|-----------|-----------|---------|
| **Database Engine** | SQL Server | 2019+ |
| **Query Language** | T-SQL | Latest |
| **Scripting** | SQL Server Management Studio | 18.0+ |
| **Version Control** | Git | Latest |
| **Development** | VS Code / SSMS | Any |
| **Documentation** | Markdown + Mermaid | Latest |

---

## 📈 Performance Metrics

### Expected Query Performance

| Query Type | Expected Time | Row Count |
|-----------|---------------|-----------|
| Customer summary | < 100ms | 5,000+ |
| Monthly sales report | < 500ms | 50,000+ |
| Product performance | < 300ms | 10,000+ |
| Full fact table scan | < 2s | 1M+ |

*Performance depends on server specifications and data volume*

---

## 🤝 Contributing

Contributions are welcome! Please follow these guidelines:

1. **Create a feature branch**: `git checkout -b feature/your-feature`
2. **Follow naming conventions**: Use established standards from `docs/03_NAMING_CONVENTIONS.md`
3. **Write documentation**: Every script should have purpose, parameters, and examples
4. **Add tests**: Include validation queries for new features
5. **Commit with clear messages**: Describe what and why in commit messages
6. **Submit pull request**: Reference related issues and provide context

---

## 📜 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

You are free to use this project for:
- ✅ Personal learning and portfolio building
- ✅ Commercial applications
- ✅ Educational purposes
- ✅ Open-source contributions

**Attribution requested but not required.**

---

## 👨‍💼 About

**Author**: Mahendra Kumar Ravi  
**Role**: Data Engineer / M.Tech Data Engineering Student  
**Focus**: Data Warehousing, ETL Development, Data Quality, and Analytics  

### Connect With Me

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Profile-blue?style=flat-square&logo=linkedin)](https://www.linkedin.com/in/mahendra-kumar-ravi-055b3121b/)
[![GitHub](https://img.shields.io/badge/GitHub-Profile-black?style=flat-square&logo=github)](https://github.com/mahendra-kumar-ravi)

---

## 📝 Project Timeline

- **Phase 1** ✅: Database setup and Bronze layer implementation
- **Phase 2** ✅: Silver layer data quality and transformation
- **Phase 3** ✅: Gold layer dimensional modeling
- **Phase 4** ✅: Analytical queries and business intelligence
- **Phase 5** ✅: Documentation and production hardening

---

## ❓ FAQ

**Q: Can I use this project for production?**  
A: Yes! This project follows enterprise best practices. Review the deployment guide and perform appropriate testing for your environment.

**Q: What SQL Server editions are supported?**  
A: SQL Server 2019+, including Express, Standard, and Enterprise editions.

**Q: How do I handle incremental updates?**  
A: Check `scripts/05_procedures/02_load_silver.sql` for delta handling patterns.

**Q: Can I modify the schema?**  
A: Yes! Follow the naming conventions and update the documentation accordingly.

**Q: Is there sample data?**  
A: Yes! Check the `/datasets` folder for CSV files with realistic sample data.

---

## 🎓 Learning Resources

- [Microsoft SQL Server Documentation](https://docs.microsoft.com/en-us/sql/)
- [Kimball Dimensional Modeling](https://en.wikipedia.org/wiki/Dimensional_modeling)
- [Data Warehouse Best Practices](https://docs.microsoft.com/en-us/sql/relational-databases/data-warehousing)
- [T-SQL Tutorial](https://www.tutorialspoint.com/t_sql/)

---

**Last Updated**: May 2026  
**Version**: 2.0 (Production-Ready)  
**Status**: ✅ Active Development

---

**⭐ If this project helped you, please consider giving it a star! Thank you!**
