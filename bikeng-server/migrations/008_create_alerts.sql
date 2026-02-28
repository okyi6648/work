CREATE TABLE IF NOT EXISTS alerts (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    title           VARCHAR(200) NOT NULL,
    content         TEXT NOT NULL,
    severity        ENUM('info','warning','critical') NOT NULL DEFAULT 'info',
    is_pushed       TINYINT(1) NOT NULL DEFAULT 0,
    pushed_at       DATETIME NULL,
    created_by      BIGINT UNSIGNED NOT NULL,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    KEY idx_severity_created (severity, created_at DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
