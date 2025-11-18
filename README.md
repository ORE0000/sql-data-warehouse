SQL Data Warehouse (Medallion Architecture)

A SQL Server-based end-to-end data warehouse built using the Medallion Architecture (Bronze → Silver → Gold), handling ETL, data modeling, and analytical dataset creation for BI and self-service analytics.

🚀 Overview

This project demonstrates a production-style modern data warehouse using:

SQL Server

Stored Procedure–driven ETL

Bronze / Silver / Gold layer separation

Modular SQL scripts

Star Schema (Fact + Dimension Tables)

Power BI consumption layer (Gold views)

ERP + CRM source integration

<img src="https://img.shields.io/badge/Architecture-Medallion-blue" /> <img src="https://img.shields.io/badge/ETL-SQL%20Stored%20Procedures-green" /> <img src="https://img.shields.io/badge/Model-StarSchema-orange" />
📂 Project Structure
sql-data-warehouse/
│
├── datasets/                          # Raw input datasets (ERP, CRM, etc)
│
├── docs/                              # Architecture and metadata documentation
│   ├── etl.drawio
│   ├── data_architecture.drawio
│   ├── data_catalog.md
│   ├── data_flow.drawio
│   ├── data_models.drawio
│   └── naming-conventions.md
│
├── scripts/
│   ├── bronze/                        # Raw ingestion / staging scripts
│   ├── silver/                        # Cleansing / transformations
│   └── gold/                          # Data marts / fact & dimension models
│
├── tests/                             # Validation, QA, unit tests, data checks
│
├── LICENSE
├── .gitignore
├── requirements.txt
└── README.md

⚙️ Tech Stack
Component	Technology
Warehouse	SQL Server
ETL	T-SQL Stored Procedures
Architecture	Medallion
Data Modeling	Star Schema
BI / Analytics	Power BI
Scheduling (optional)	SQL Agent / Task Scheduler
🧱 Medallion Layers
Layer	Purpose
Bronze	Raw ingestion (ERP + CRM extracts)
Silver	Cleansed and conformed data
Gold	Metrics, KPIs, dashboards, analytical models
🔧 ETL Highlights

Stored procedure based execution

Idempotent, re-runnable ETL pipelines

Layered schema-based design

Run control & metadata logging (optional)

Modular file-based SQL with execution order control

📊 Data Modeling

Fact & dimension tables (star schema)

Surrogate keys & slowly changing attributes

View-based semantic layer for BI

KPI ready datasets for Power BI dashboards

🧪 Testing & Validation

Row count checks

Data quality validation

Referential integrity

Transformation verification

📝 Setup & Usage
1. Clone Repository
git clone https://github.com/ORE0000/sql-data-warehouse.git
cd sql-data-warehouse

2. Run Scripts in Sequence

Bronze → Silver → Gold folder
(or execute orchestrator script if provided)

📌 Future Enhancements

dbt or Azure Data Factory orchestration

Data quality automation

Incremental loading & CDC

Logging and monitoring layer

Metadata-driven ETL

📄 License

This project is open-source under the MIT License.

🧑‍💻 Author

Ashutosh Pant
📧 ashutoshpant.855@gmail.com

🔗 Portfolio: https://ashutoshpant.netlify.app

🔗 GitHub: https://github.com/ORE0000

🔗 LinkedIn: https://linkedin.com/in/ashutosh-pant1

⭐ If this project helped you:

Leave a star ⭐ on the repo!