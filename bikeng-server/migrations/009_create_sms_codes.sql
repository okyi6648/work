CREATE TABLE IF NOT EXISTS sms_codes (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    phone           VARCHAR(20) NOT NULL,
    code            VARCHAR(6) NOT NULL,
    purpose         ENUM('login','bind','appeal_verify') NOT NULL DEFAULT 'login',
    is_used         TINYINT(1) NOT NULL DEFAULT 0,
    expires_at      DATETIME NOT NULL,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    KEY idx_phone_purpose (phone, purpose, is_used, expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
