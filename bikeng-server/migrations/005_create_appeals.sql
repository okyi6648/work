CREATE TABLE IF NOT EXISTS appeals (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    account_id      BIGINT UNSIGNED NOT NULL,
    appellant_phone VARCHAR(20) NOT NULL,
    reason          TEXT NOT NULL,
    evidence_urls   JSON NOT NULL,
    status          ENUM('pending','under_review','accepted','rejected') NOT NULL DEFAULT 'pending',
    reviewer_id     BIGINT UNSIGNED NULL,
    review_note     TEXT NULL,
    resolved_at     DATETIME NULL,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    KEY idx_account (account_id),
    KEY idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
