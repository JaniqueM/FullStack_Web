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