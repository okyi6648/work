CREATE TABLE IF NOT EXISTS reports (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    reporter_id     BIGINT UNSIGNED NOT NULL,
    account_id      BIGINT UNSIGNED NOT NULL,
    scam_type       ENUM('shopping','investment','romance','impersonation','lottery','loan','other') NOT NULL DEFAULT 'other',
    description     TEXT NOT NULL,
    loss_amount     DECIMAL(14,2) NOT NULL DEFAULT 0.00,
    contact_method  VARCHAR(255) NOT NULL DEFAULT '',
    incident_date   DATE NULL,
    status          ENUM('pending_review','approved','rejected','withdrawn') NOT NULL DEFAULT 'pending_review',
    liability_agreed TINYINT(1) NOT NULL DEFAULT 0,
    reviewer_id     BIGINT UNSIGNED NULL,
    reviewed_at     DATETIME NULL,
    reject_reason   VARCHAR(500) NOT NULL DEFAULT '',
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    KEY idx_reporter (reporter_id),
    KEY idx_account (account_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
