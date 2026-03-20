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

├── tests/
    ├── test_parse_xml.py
    ├── test_clean_normalize.py
    └── test_categorize.py
├── docs/
    └── erd_diagram.png
├── database/
    └── database_setup.sql
├── examples/
    └── json_schemas.json
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

# Database Documentation

**Database:** `momo_sms_db` &nbsp;|&nbsp; **Engine:** MySQL / InnoDB &nbsp;|&nbsp; **Charset:** `utf8mb4_unicode_ci`

The schema consists of six tables. Entity relationships at a glance:

- `transaction_categories` **1 ── N** `transactions`
- `users` **1 ── N** `transactions` (as sender **or** receiver)
- `transactions` **M ── N** `tags` (via `transaction_tags` junction table)
- `transactions` **1 ── N** `system_logs`

---

## Table: transaction_categories

Lookup table that classifies every transaction into a named type and direction (credit / debit).

| Column | Type | Description | Nullable | Default | Constraint |
|---|---|---|---|---|---|
| `category_id` | `INT` | PK – auto-increment | No | — | PRIMARY KEY |
| `category_name` | `VARCHAR(100)` | Human-readable label | No | — | UNIQUE |
| `category_code` | `VARCHAR(30)` | Machine-readable code (e.g. `INCOMING_TRANSFER`) | No | — | UNIQUE |
| `description` | `TEXT` | Extended description | Yes | NULL | — |
| `is_credit` | `TINYINT(1)` | `1` = money in, `0` = money out | No | `1` | CHECK (0 or 1) |
| `created_at` | `DATETIME` | Row creation timestamp | No | `NOW()` | — |
| `updated_at` | `DATETIME` | Last update timestamp (auto-refreshed) | No | `NOW()` | — |

### Seeded Categories

| Code | Name | Direction |
|---|---|---|
| `INCOMING_TRANSFER` | Incoming Transfer | Credit |
| `MERCHANT_PAYMENT` | Outgoing Payment (Merchant) | Debit |
| `P2P_TRANSFER` | Peer-to-Peer Transfer | Debit |
| `BANK_DEPOSIT` | Bank Deposit | Credit |
| `CASH_WITHDRAWAL` | Cash Withdrawal | Debit |
| `AIRTIME_PURCHASE` | Airtime Purchase | Debit |
| `UTILITY_PAYMENT` | Utility / Bill Payment | Debit |
| `DIRECT_DEBIT` | Direct Debit | Debit |
| `SYSTEM_MESSAGE` | OTP / System Message | — |

---

## Table: users

Stores every person or entity referenced in SMS messages: the primary account holder, counterparties, agents, and merchants.

| Column | Type | Description | Nullable | Default | Constraint |
|---|---|---|---|---|---|
| `user_id` | `INT` | PK – auto-increment | No | — | PRIMARY KEY |
| `full_name` | `VARCHAR(150)` | Name as it appears in SMS body | No | — | INDEX |
| `phone_number` | `VARCHAR(20)` | E.164 phone number (may be partially masked) | Yes | NULL | INDEX |
| `account_number` | `VARCHAR(20)` | MoMo wallet number if known | Yes | NULL | UNIQUE |
| `user_type` | `ENUM` | `ACCOUNT_HOLDER` \| `COUNTERPARTY` \| `AGENT` \| `MERCHANT` | No | `COUNTERPARTY` | CHECK (enum values) |
| `is_active` | `TINYINT(1)` | Soft-delete flag | No | `1` | CHECK (0 or 1) |
| `created_at` | `DATETIME` | Row creation timestamp | No | `NOW()` | — |
| `updated_at` | `DATETIME` | Last update (auto-refreshed) | No | `NOW()` | — |

### User Types

| Type | Description |
|---|---|
| `ACCOUNT_HOLDER` | The owner of the MoMo account being analysed |
| `COUNTERPARTY` | An individual who sent or received money |
| `AGENT` | A MoMo cash-in / cash-out agent |
| `MERCHANT` | A registered business (e.g. DIRECT PAYMENT LTD, MTN Cash Power) |

---

## Table: transactions

Core table — one row per financial event parsed from an SMS message. Retains `raw_sms_body` for a full audit trail and links to both the category and the two user records (sender / receiver).

| Column | Type | Description | Nullable | Default | Constraint |
|---|---|---|---|---|---|
| `transaction_id` | `BIGINT` | PK – auto-increment | No | — | PRIMARY KEY |
| `financial_tx_id` | `VARCHAR(50)` | MTN financial transaction ID from SMS | Yes | NULL | UNIQUE |
| `external_tx_id` | `VARCHAR(50)` | Third-party transaction reference | Yes | NULL | — |
| `category_id` | `INT` | FK → `transaction_categories` | No | — | INDEX, ON UPDATE CASCADE |
| `sender_id` | `INT` | FK → `users` (payer) | Yes | NULL | INDEX, ON DELETE SET NULL |
| `receiver_id` | `INT` | FK → `users` (payee) | Yes | NULL | INDEX, ON DELETE SET NULL |
| `amount` | `DECIMAL(15,2)` | Transaction amount in RWF | No | — | CHECK `amount > 0` |
| `fee` | `DECIMAL(10,2)` | Fee charged in RWF | No | `0.00` | CHECK `fee >= 0` |
| `balance_after` | `DECIMAL(15,2)` | Account balance after the transaction | Yes | NULL | — |
| `currency` | `CHAR(3)` | ISO-4217 currency code | No | `RWF` | — |
| `transaction_date` | `DATETIME` | Timestamp parsed from SMS body | No | — | INDEX |
| `sms_date` | `BIGINT` | Original Unix timestamp in ms from XML attribute | No | — | INDEX |
| `raw_sms_body` | `TEXT` | Original SMS text for audit trail | No | — | — |
| `service_center` | `VARCHAR(20)` | SMS service centre number | Yes | NULL | — |
| `status` | `ENUM` | `SUCCESS` \| `FAILED` \| `PENDING` | No | `SUCCESS` | CHECK (enum values) |
| `notes` | `TEXT` | Optional metadata or analyst notes | Yes | NULL | — |
| `created_at` | `DATETIME` | Row creation timestamp | No | `NOW()` | — |
| `updated_at` | `DATETIME` | Last update (auto-refreshed) | No | `NOW()` | — |

### Key Constraint Notes

- `financial_tx_id` is UNIQUE but nullable — bank deposit SMS messages carry no MTN transaction ID.
- `sender_id` and `receiver_id` use `ON DELETE SET NULL` so removing a counterparty never cascades to transactions.
- `amount` must be strictly positive; `fee` must be non-negative.
- `status` defaults to `SUCCESS` and is constrained to the three enum values.

---

## Table: system_logs

Audit and debug log produced by ETL scripts and background jobs. A log entry may or may not be tied to a specific transaction.

| Column | Type | Description | Nullable | Default | Constraint |
|---|---|---|---|---|---|
| `log_id` | `BIGINT` | PK – auto-increment | No | — | PRIMARY KEY |
| `log_level` | `ENUM` | `INFO` \| `WARNING` \| `ERROR` \| `DEBUG` | No | `INFO` | INDEX, CHECK (enum values) |
| `event_type` | `VARCHAR(80)` | Short event tag (e.g. `PARSE_SUCCESS`) | No | — | INDEX |
| `transaction_id` | `BIGINT` | FK → `transactions` (optional) | Yes | NULL | INDEX, ON DELETE SET NULL |
| `message` | `TEXT` | Human-readable description | No | — | — |
| `stack_trace` | `TEXT` | Error stack trace if applicable | Yes | NULL | — |
| `ip_address` | `VARCHAR(45)` | IP of the generating process (supports IPv6) | Yes | NULL | — |
| `process_name` | `VARCHAR(100)` | Script or service that wrote this log | Yes | NULL | — |
| `created_at` | `DATETIME` | Log entry timestamp | No | `NOW()` | INDEX |

### Common Event Types

| Event Type | Description |
|---|---|
| `IMPORT_START` | Beginning of an XML import run |
| `IMPORT_COMPLETE` | End of an XML import run (with totals) |
| `PARSE_SUCCESS` | A single SMS was parsed and stored successfully |
| `PARSE_FAILED` | An SMS could not be mapped to a category; skipped |
| `MISSING_TX_ID` | A transaction was inserted with a NULL `financial_tx_id` |
| `CRON_RUN` | Scheduled background job started |
| `CRON_COMPLETE` | Scheduled background job completed |
| `QUERY_SLOW` | Performance warning from the query monitor |

---

## Table: tags

Catalogue of descriptive labels that can be applied to any number of transactions.

| Column | Type | Description | Nullable | Constraint |
|---|---|---|---|---|
| `tag_id` | `INT` | PK – auto-increment | No | PRIMARY KEY |
| `tag_name` | `VARCHAR(80)` | Label (e.g. `high-value`, `recurring`) | No | UNIQUE |
| `created_at` | `DATETIME` | Row creation timestamp | No | — |

### Default Tags

| Tag | Description |
|---|---|
| `high-value` | Transaction amount above a defined threshold |
| `recurring` | Transfer from/to the same counterparty seen multiple times |
| `agent-withdrawal` | Cash-out via a MoMo agent |
| `airtime` | Mobile airtime purchase |
| `utility` | Electricity, water, or other utility bill |
| `direct-debit` | Third-party initiated debit |
| `otp` | One-time password or system notification |
| `bank-deposit` | Cash deposited from a linked bank |
| `suspected-fraud` | Flagged by an analyst or automated rule |

---

## Table: transaction_tags (junction)

Resolves the many-to-many relationship between `transactions` and `tags`. The composite primary key `(transaction_id, tag_id)` prevents duplicate assignments.

| Column | Type | Description | Nullable | Constraint |
|---|---|---|---|---|
| `transaction_id` | `BIGINT` | FK → `transactions` (part of composite PK) | No | ON DELETE CASCADE |
| `tag_id` | `INT` | FK → `tags` (part of composite PK) | No | ON DELETE CASCADE |
| `assigned_at` | `DATETIME` | When the tag was applied | No | — |
| `assigned_by` | `VARCHAR(80)` | User or process that applied the tag | Yes | — |

---

## Indexes Summary

| Table | Index | Purpose |
|---|---|---|
| `transactions` | `idx_tx_date (transaction_date)` | Date-range queries and chronological ordering |
| `transactions` | `idx_amount (amount)` | High-value and threshold filtering |
| `transactions` | `idx_category (category_id)` | Filter by transaction type |
| `transactions` | `idx_sender (sender_id)` | Counterparty lookup – outgoing |
| `transactions` | `idx_receiver (receiver_id)` | Counterparty lookup – incoming |
| `transactions` | `idx_sms_date (sms_date)` | Deduplicate by original XML timestamp |
| `system_logs` | `idx_log_level (log_level)` | Filter by severity |
| `system_logs` | `idx_event_type (event_type)` | Filter by event tag |
| `system_logs` | `idx_log_created (created_at)` | Chronological log retrieval |

---

## Useful Queries

**All successful transactions with full context:**
```sql
SELECT t.transaction_id, tc.category_name,
       u_s.full_name AS sender, u_r.full_name AS receiver,
       t.amount, t.fee, t.balance_after, t.transaction_date
FROM transactions t
JOIN transaction_categories tc ON t.category_id = tc.category_id
LEFT JOIN users u_s ON t.sender_id  = u_s.user_id
LEFT JOIN users u_r ON t.receiver_id = u_r.user_id
WHERE t.status = 'SUCCESS'
ORDER BY t.transaction_date;
```

**Monthly credit vs debit summary:**
```sql
SELECT DATE_FORMAT(transaction_date, '%Y-%m') AS month,
       SUM(CASE WHEN tc.is_credit = 1 THEN t.amount ELSE 0 END) AS total_credit,
       SUM(CASE WHEN tc.is_credit = 0 THEN t.amount ELSE 0 END) AS total_debit,
       SUM(t.fee) AS total_fees
FROM transactions t
JOIN transaction_categories tc ON t.category_id = tc.category_id
GROUP BY month ORDER BY month;
```

**Transactions carrying the `high-value` tag:**
```sql
SELECT t.transaction_id, t.amount, t.transaction_date,
       GROUP_CONCAT(tg.tag_name SEPARATOR ', ') AS tags
FROM transactions t
JOIN transaction_tags tt ON t.transaction_id = tt.transaction_id
JOIN tags tg             ON tt.tag_id = tg.tag_id
GROUP BY t.transaction_id
HAVING FIND_IN_SET('high-value', GROUP_CONCAT(tg.tag_name));
```

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