-- ============================================================
-- MoMo SMS Data Processing System - Database Setup Script
-- ============================================================

CREATE DATABASE IF NOT EXISTS momo_sms_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE momo_sms_db;

-- ============================================================
-- TABLE: transaction_categories
-- Stores the different types of MoMo transactions observed
-- ============================================================
CREATE TABLE IF NOT EXISTS transaction_categories (
    category_id     INT             NOT NULL AUTO_INCREMENT  COMMENT 'Unique category identifier',
    category_name   VARCHAR(100)    NOT NULL                 COMMENT 'Human-readable category name (e.g. Incoming Transfer)',
    category_code   VARCHAR(30)     NOT NULL                 COMMENT 'Short code used to tag transactions (e.g. INCOMING_TRANSFER)',
    description     TEXT                                     COMMENT 'Detailed description of this transaction type',
    is_credit       TINYINT(1)      NOT NULL DEFAULT 1       COMMENT '1 = money coming in, 0 = money going out',
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (category_id),
    UNIQUE KEY uq_category_code (category_code),
    CONSTRAINT chk_is_credit CHECK (is_credit IN (0, 1))
) ENGINE=InnoDB COMMENT='Lookup table for MoMo transaction categories';


-- ============================================================
-- TABLE: users
-- Stores account holders and counterparties extracted from SMS
-- ============================================================
CREATE TABLE IF NOT EXISTS users (
    user_id         INT             NOT NULL AUTO_INCREMENT  COMMENT 'Unique user identifier',
    full_name       VARCHAR(150)    NOT NULL                 COMMENT 'Full name as it appears in SMS messages',
    phone_number    VARCHAR(20)                              COMMENT 'Phone number (may be partially masked)',
    account_number  VARCHAR(20)                              COMMENT 'MoMo account/wallet number if known',
    user_type       ENUM('ACCOUNT_HOLDER','COUNTERPARTY','AGENT','MERCHANT') NOT NULL DEFAULT 'COUNTERPARTY'
                                                             COMMENT 'Role of this user in the system',
    is_active       TINYINT(1)      NOT NULL DEFAULT 1       COMMENT '1 = active, 0 = deactivated',
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (user_id),
    UNIQUE KEY uq_account_number (account_number),
    INDEX idx_full_name (full_name),
    INDEX idx_phone_number (phone_number),
    CONSTRAINT chk_user_type CHECK (user_type IN ('ACCOUNT_HOLDER','COUNTERPARTY','AGENT','MERCHANT'))
) ENGINE=InnoDB COMMENT='Users and counterparties referenced in MoMo SMS messages';


-- ============================================================
-- TABLE: transactions
-- Core table: one row per financial transaction parsed from SMS
-- ============================================================
CREATE TABLE IF NOT EXISTS transactions (
    transaction_id          BIGINT          NOT NULL AUTO_INCREMENT  COMMENT 'Internal auto-increment PK',
    financial_tx_id         VARCHAR(50)                              COMMENT 'MTN Financial Transaction Id from SMS',
    external_tx_id          VARCHAR(50)                              COMMENT 'External Transaction Id (for direct payment etc.)',
    category_id             INT             NOT NULL                 COMMENT 'FK → transaction_categories',
    sender_id               INT                                      COMMENT 'FK → users (who sent the money)',
    receiver_id             INT                                      COMMENT 'FK → users (who received the money)',
    amount                  DECIMAL(15,2)   NOT NULL                 COMMENT 'Transaction amount in RWF',
    fee                     DECIMAL(10,2)   NOT NULL DEFAULT 0.00    COMMENT 'Transaction fee charged in RWF',
    balance_after           DECIMAL(15,2)                            COMMENT 'Account holder balance after the transaction',
    currency                CHAR(3)         NOT NULL DEFAULT 'RWF'   COMMENT 'ISO currency code',
    transaction_date        DATETIME        NOT NULL                 COMMENT 'Timestamp of transaction as parsed from SMS body',
    sms_date                BIGINT          NOT NULL                 COMMENT 'Original Unix timestamp (ms) from XML date attribute',
    raw_sms_body            TEXT            NOT NULL                 COMMENT 'Original raw SMS body for auditing',
    service_center          VARCHAR(20)                              COMMENT 'SMS service centre number',
    status                  ENUM('SUCCESS','FAILED','PENDING') NOT NULL DEFAULT 'SUCCESS'
                                                                     COMMENT 'Derived transaction status',
    notes                   TEXT                                     COMMENT 'Optional notes or extra parsed metadata',
    created_at              DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at              DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (transaction_id),
    UNIQUE KEY uq_financial_tx_id (financial_tx_id),
    INDEX idx_category   (category_id),
    INDEX idx_sender     (sender_id),
    INDEX idx_receiver   (receiver_id),
    INDEX idx_tx_date    (transaction_date),
    INDEX idx_amount     (amount),
    INDEX idx_sms_date   (sms_date),

    CONSTRAINT fk_tx_category FOREIGN KEY (category_id)
        REFERENCES transaction_categories(category_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_tx_sender FOREIGN KEY (sender_id)
        REFERENCES users(user_id)
        ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT fk_tx_receiver FOREIGN KEY (receiver_id)
        REFERENCES users(user_id)
        ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT chk_amount_positive CHECK (amount > 0),
    CONSTRAINT chk_fee_non_negative CHECK (fee >= 0),
    CONSTRAINT chk_status CHECK (status IN ('SUCCESS','FAILED','PENDING'))
) ENGINE=InnoDB COMMENT='Core MoMo financial transactions parsed from SMS messages';


-- ============================================================
-- TABLE: system_logs
-- Tracks all data-processing events for auditing & debugging
-- ============================================================
CREATE TABLE IF NOT EXISTS system_logs (
    log_id          BIGINT          NOT NULL AUTO_INCREMENT  COMMENT 'Auto-increment log identifier',
    log_level       ENUM('INFO','WARNING','ERROR','DEBUG') NOT NULL DEFAULT 'INFO'
                                                             COMMENT 'Severity level of the log entry',
    event_type      VARCHAR(80)     NOT NULL                 COMMENT 'Short event tag (e.g. PARSE_SUCCESS, IMPORT_FAILED)',
    transaction_id  BIGINT                                   COMMENT 'FK → transactions (nullable – not all logs relate to a tx)',
    message         TEXT            NOT NULL                 COMMENT 'Human-readable log message',
    stack_trace     TEXT                                     COMMENT 'Stack trace or raw error detail if applicable',
    ip_address      VARCHAR(45)                              COMMENT 'IP of the process that generated this log',
    process_name    VARCHAR(100)                             COMMENT 'Name of the script / service that wrote this log',
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (log_id),
    INDEX idx_log_level      (log_level),
    INDEX idx_event_type     (event_type),
    INDEX idx_log_tx         (transaction_id),
    INDEX idx_log_created    (created_at),

    CONSTRAINT fk_log_transaction FOREIGN KEY (transaction_id)
        REFERENCES transactions(transaction_id)
        ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT chk_log_level CHECK (log_level IN ('INFO','WARNING','ERROR','DEBUG'))
) ENGINE=InnoDB COMMENT='System processing logs for audit trail and debugging';