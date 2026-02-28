CREATE TABLE IF NOT EXISTS accounts (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    account_type    ENUM('qq','wechat','phone','alipay','bank_card') NOT NULL,
    account_value   VARCHAR(100) NOT NULL,
    report_count    INT UNSIGNED NOT NULL DEFAULT 0,
    risk_score      DECIMAL(5,2) NOT NULL DEFAULT 0.00,
    total_amount    DECIMAL(14,2) NOT NULL DEFAULT 0.00,
    first_reported_at DATETIME NULL,
    last_reported_at  DATETIME NULL,
    appeal_status   ENUM('none','pending','accepted','rejected') NOT NULL DEFAULT 'none',
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_type_value (account_type, account_value),
    KEY idx_account_value (account_value)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
