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


-- ============================================================
-- JUNCTION TABLE: transaction_tags
-- Resolves a M:N relationship between transactions and tags
-- A single transaction can have multiple descriptive tags
-- ============================================================
CREATE TABLE IF NOT EXISTS tags (
    tag_id      INT             NOT NULL AUTO_INCREMENT  COMMENT 'Unique tag identifier',
    tag_name    VARCHAR(80)     NOT NULL                 COMMENT 'Tag label (e.g. recurring, high-value, suspected-fraud)',
    created_at  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (tag_id),
    UNIQUE KEY uq_tag_name (tag_name)
) ENGINE=InnoDB COMMENT='Descriptive tags that can be applied to transactions';


CREATE TABLE IF NOT EXISTS transaction_tags (
    transaction_id  BIGINT  NOT NULL  COMMENT 'FK → transactions',
    tag_id          INT     NOT NULL  COMMENT 'FK → tags',
    assigned_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    assigned_by     VARCHAR(80)       COMMENT 'User/process that applied this tag',

    PRIMARY KEY (transaction_id, tag_id),

    CONSTRAINT fk_tt_transaction FOREIGN KEY (transaction_id)
        REFERENCES transactions(transaction_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_tt_tag FOREIGN KEY (tag_id)
        REFERENCES tags(tag_id)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB COMMENT='Junction table resolving M:N between transactions and tags';


-- ============================================================
-- SAMPLE DATA – CATEGORIES
-- ============================================================
INSERT INTO transaction_categories (category_name, category_code, description, is_credit) VALUES
('Incoming Transfer',        'INCOMING_TRANSFER',  'Money received from another MoMo user',                           1),
('Outgoing Payment (Merchant)','MERCHANT_PAYMENT', 'Payment to a registered merchant via MoMo',                       0),
('Peer-to-Peer Transfer',    'P2P_TRANSFER',       'Direct transfer sent to another individual MoMo account',          0),
('Bank Deposit',             'BANK_DEPOSIT',       'Cash deposited from a linked bank or cash-in agent',              1),
('Cash Withdrawal',          'CASH_WITHDRAWAL',    'Cash withdrawn via a MoMo agent',                                  0),
('Airtime Purchase',         'AIRTIME_PURCHASE',   'Purchase of mobile airtime using MoMo balance',                    0),
('Utility / Bill Payment',   'UTILITY_PAYMENT',    'Payment for electricity, water, or other utility services',        0),
('Direct Debit',             'DIRECT_DEBIT',       'Debit initiated by a third-party business (e.g. Direct Payment LTD)', 0),
('OTP / System Message',     'SYSTEM_MESSAGE',     'Non-financial system notification such as OTP codes',              1);


-- ============================================================
-- SAMPLE DATA – USERS
-- ============================================================
INSERT INTO users (full_name, phone_number, account_number, user_type) VALUES
('Abebe Chala Chebudie',  '+250795963036', '36521838',     'ACCOUNT_HOLDER'),
('Jane Smith',            '+250790777777', NULL,           'COUNTERPARTY'),
('Samuel Carter',         '+250791666666', NULL,           'COUNTERPARTY'),
('Alex Doe',              '+250788999999', NULL,           'COUNTERPARTY'),
('Robert Brown',          '+250789888888', NULL,           'COUNTERPARTY'),
('Linda Green',           '+250789000000', NULL,           'COUNTERPARTY'),
('Agent Sophia',          '+250790777777', NULL,           'AGENT'),
('DIRECT PAYMENT LTD',    NULL,            NULL,           'MERCHANT'),
('MTN Cash Power',        NULL,            NULL,           'MERCHANT');


-- ============================================================
-- SAMPLE DATA – TAGS
-- ============================================================
INSERT INTO tags (tag_name) VALUES
('high-value'),
('recurring'),
('agent-withdrawal'),
('airtime'),
('utility'),
('direct-debit'),
('otp'),
('bank-deposit'),
('suspected-fraud');


-- ============================================================
-- SAMPLE DATA – TRANSACTIONS (10 representative records)
-- ============================================================
INSERT INTO transactions
  (financial_tx_id, category_id, sender_id, receiver_id, amount, fee, balance_after, transaction_date, sms_date, raw_sms_body, service_center, status)
VALUES
(
  '76662021700', 1, 2, 1, 2000.00, 0.00, 2000.00,
  '2024-05-10 16:30:51', 1715351458724,
  'You have received 2000 RWF from Jane Smith (*********013) on your mobile money account at 2024-05-10 16:30:51.',
  '+250788110381', 'SUCCESS'
),
(
  '73214484437', 2, 1, 2, 1000.00, 0.00, 1000.00,
  '2024-05-10 16:31:39', 1715351506754,
  'TxId: 73214484437. Your payment of 1,000 RWF to Jane Smith 12845 has been completed at 2024-05-10 16:31:39.',
  '+250788110381', 'SUCCESS'
),
(
  '51732411227', 2, 1, 3, 600.00, 0.00, 400.00,
  '2024-05-10 21:32:32', 1715369560245,
  'TxId: 51732411227. Your payment of 600 RWF to Samuel Carter 95464 has been completed at 2024-05-10 21:32:32.',
  '+250788110381', 'SUCCESS'
),
(
  NULL, 4, NULL, 1, 40000.00, 0.00, 40400.00,
  '2024-05-11 18:43:49', 1715445936412,
  '*113*R*A bank deposit of 40000 RWF has been added to your mobile money account at 2024-05-11 18:43:49.',
  '+250788110381', 'SUCCESS'
),
(
  NULL, 3, 1, 3, 10000.00, 100.00, 28300.00,
  '2024-05-11 20:34:47', 1715452495316,
  '*165*S*10000 RWF transferred to Samuel Carter (250791666666) from 36521838 at 2024-05-11 20:34:47.',
  '+250788110381', 'SUCCESS'
),
(
  '13913173274', 6, 1, 9, 2000.00, 0.00, 25280.00,
  '2024-05-12 11:41:28', 1715506895734,
  '*162*TxId:13913173274*S*Your payment of 2000 RWF to Airtime with token has been completed at 2024-05-12 11:41:28.',
  '+250788110381', 'SUCCESS'
),
(
  '13947831685', 8, 8, 1, 25000.00, 0.00, 4060.00,
  '2024-05-14 21:01:00', 1715713269609,
  '*164*S*A transaction of 25000 RWF by DIRECT PAYMENT LTD on your MOMO account was successfully completed at 2024-05-14 21:01:00.',
  '+250788110381', 'SUCCESS'
),
(
  '14098463509', 5, 1, 7, 20000.00, 350.00, 6400.00,
  '2024-05-26 02:10:27', 1716682234219,
  'You Abebe Chala CHEBUDIE (*********036) have via agent: Agent Sophia (250790777777), withdrawn 20000 RWF at 2024-05-26 02:10:27.',
  '+250788110381', 'SUCCESS'
),
(
  '14103506143', 7, 1, 9, 4000.00, 0.00, 800.00,
  '2024-05-26 13:31:00', 1716723067339,
  '*162*TxId:14103506143*S*Your payment of 4000 RWF to MTN Cash Power with token 72962-79980-44699-06073 has been completed.',
  '+250788110381', 'SUCCESS'
),
(
  '45738348638', 1, 6, 1, 1400.00, 0.00, 4590.00,
  '2024-05-19 01:49:09', 1716076156818,
  'You have received 1400 RWF from Linda Green (*********704) on your mobile money account at 2024-05-19 01:49:09.',
  '+250788110381', 'SUCCESS'
);


-- ============================================================
-- SAMPLE DATA – SYSTEM LOGS
-- ============================================================
INSERT INTO system_logs (log_level, event_type, transaction_id, message, process_name) VALUES
('INFO',    'IMPORT_START',    NULL, 'Started XML import of modified_sms_v2.xml (1693 messages)',  'xml_importer.py'),
('INFO',    'PARSE_SUCCESS',   1,    'Transaction 76662021700 parsed and inserted successfully',    'xml_importer.py'),
('INFO',    'PARSE_SUCCESS',   2,    'Transaction 73214484437 parsed and inserted successfully',    'xml_importer.py'),
('WARNING', 'MISSING_TX_ID',   4,    'Bank deposit SMS at 2024-05-11 18:43:49 has no financial_tx_id – inserted with NULL', 'xml_importer.py'),
('INFO',    'PARSE_SUCCESS',   5,    'P2P transfer 10000 RWF to Samuel Carter inserted',            'xml_importer.py'),
('ERROR',   'PARSE_FAILED',    NULL, 'OTP message body could not be mapped to a financial category; skipped', 'xml_importer.py'),
('INFO',    'IMPORT_COMPLETE', NULL, 'Import finished: 1693 messages processed, 1 skipped, 1692 inserted', 'xml_importer.py'),
('INFO',    'CRON_RUN',        NULL, 'Scheduled balance reconciliation job started',                 'balance_checker.py'),
('INFO',    'CRON_COMPLETE',   NULL, 'Balance reconciliation completed – no discrepancies found',   'balance_checker.py'),
('DEBUG',   'QUERY_SLOW',      NULL, 'SELECT on transactions took 1.23s – consider adding index on balance_after', 'query_monitor.py');


-- ============================================================
-- SAMPLE DATA – TRANSACTION TAGS
-- ============================================================
INSERT INTO transaction_tags (transaction_id, tag_id, assigned_by) VALUES
(5,  1, 'system'),   -- 10 000 RWF transfer → high-value
(7,  6, 'system'),   -- direct debit by DIRECT PAYMENT LTD
(7,  1, 'system'),   -- also high-value
(8,  3, 'system'),   -- cash withdrawal via agent
(8,  1, 'system'),   -- also high-value
(6,  4, 'system'),   -- airtime purchase
(9,  5, 'system'),   -- utility payment (electricity token)
(4,  8, 'system'),   -- bank deposit
(1,  2, 'system'),   -- recurring incoming transfer
(10, 2, 'system');   -- recurring incoming from Linda Green