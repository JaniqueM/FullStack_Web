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