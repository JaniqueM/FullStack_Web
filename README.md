# Mobile Money Transaction Processing System

![Project Status](https://img.shields.io/badge/status-active-success)
![Python](https://img.shields.io/badge/python-3.8+-blue)
![Database](https://img.shields.io/badge/database-SQLite-lightgrey)

---

## Team Name
Green

## Team Members
- Janique Maduray
- Kevin Ikuzwe
- Andrea Christian Memba
- Immaculata Emmanuel Effiong

---

# Project Overview

This project focuses on building an **enterprise-style full-stack data processing system** that analyzes **Mobile Money (MoMo) SMS data stored in XML format**.

The system extracts raw transaction data, cleans and normalizes it, categorizes transactions, stores them in a **relational SQLite database**, and provides a **frontend dashboard for analysis and visualization**.

The goal of the project is to demonstrate practical skills in:

- Backend data processing (ETL pipelines)
- Database design and management
- Frontend visualization
- Full-stack system architecture
- Agile project collaboration

The project processes XML transaction data and transforms it into structured insights that can be analyzed through a dashboard interface.

---

# System Architecture

High-level system architecture diagram:

[View System Architecture Diagram](https://drive.google.com/file/d/1zbDJro7yCchEiaIArRTuYlpWlfGy4-iR/view?usp=sharing)

The architecture includes the following components:

### 1. XML Data Source
- Raw MoMo SMS transaction data in XML format.

### 2. ETL Processing Layer
Responsible for transforming raw data into structured information.

Tasks include:
- Parsing XML files
- Cleaning and normalizing transaction data
- Categorizing transactions (payments, transfers, deposits, etc.)
- Loading processed data into the database

### 3. SQLite Database
- Stores structured transaction records
- Enables efficient querying and analytics

### 4. API Layer
- Provides endpoints for accessing transactions and analytics

### 5. Frontend Dashboard
- Displays analytics, charts, and transaction insights

### Data Flow

```
MoMo XML Data
      ↓
ETL Processing Scripts
      ↓
SQLite Database
      ↓
API Layer
      ↓
Frontend Dashboard
```

---

# Scrum Board

Project task management is organized using a Scrum board.

[View Scrum Board](https://github.com/users/JaniqueM/projects/1)

The Scrum board contains the following workflow columns:

- **To Do**
- **In Progress**
- **Done**

Initial tasks include:

- Repository setup
- System architecture design
- ETL pipeline research
- Database schema design
- Frontend dashboard planning

---

# Project Structure

```
.
├── .env.example
├── requirements.txt
├── index.html

├── web/
│   ├── styles.css
│   ├── chart_handler.js
│   └── assets/

├── data/
│   ├── raw/
│   │   └── momo.xml
│   ├── processed/
│   │   └── dashboard.json
│   ├── db.sqlite3
│   └── logs/
│       ├── etl.log
│       └── dead_letter/

├── etl/
│   ├── __init__.py
│   ├── config.py
│   ├── parse_xml.py
│   ├── clean_normalize.py
│   ├── categorize.py
│   ├── load_db.py
│   └── run.py

├── api/
│   ├── __init__.py
│   ├── app.py
│   ├── db.py
│   └── schemas.py

├── scripts/
│   ├── run_etl.sh
│   ├── export_json.sh
│   └── serve_frontend.sh

└── tests/
    ├── test_parse_xml.py
    ├── test_clean_normalize.py
    └── test_categorize.py
```

---

# Setup Instructions

## 1. Install Python

Ensure Python **3.8 or higher** is installed.

Check your Python version:

```
python --version
```

---

## 2. Clone the Repository

```
git clone <repository-link>
cd <repository-folder>
```

---

## 3. Install Dependencies

Install required libraries using:

```
pip install -r requirements.txt
```

Dependencies may include:

- lxml / ElementTree
- python-dateutil
- FastAPI
- SQLite3

---

## 4. Prepare the Data

Place the XML transaction file inside the raw data directory:

```
data/raw/momo.xml
```

---

## 5. Run the ETL Pipeline

Execute the ETL process to extract, clean, categorize, and store transactions.

```
python etl/run.py --xml data/raw/momo.xml
```

This process will:

1. Parse the XML file
2. Clean and normalize the data
3. Categorize transactions
4. Store the data in the SQLite database
5. Generate aggregated dashboard data

---

## 6. Generate Dashboard Data

```
bash scripts/export_json.sh
```

This generates:

```
data/processed/dashboard.json
```

This file contains processed analytics used by the frontend dashboard.

---

## 7. Run the Frontend Dashboard

```
bash scripts/serve_frontend.sh
```

Then open your browser and navigate to:

```
http://localhost:8000
```

---

# Logging

All ETL operations are logged in:

```
data/logs/etl.log
```

Invalid or unparsed XML snippets are stored in:

```
data/logs/dead_letter/
```

These logs help monitor the ETL process and debug data issues.

---

# Technologies Used

- Python
- XML Processing (ElementTree / lxml)
- SQLite
- HTML
- CSS
- JavaScript
- FastAPI
- Git & GitHub
- Agile Scrum Workflow

---

# Future Improvements

Possible enhancements include:

- Advanced analytics and financial insights
- Authentication and user management
- Real-time transaction processing
- Migration to PostgreSQL or a cloud database
- Improved dashboard visualizations

---

# Conclusion

This project demonstrates a **full-stack data engineering workflow**, transforming raw Mobile Money transaction data into structured insights through an ETL pipeline, database storage, API access, and an interactive frontend dashboard.