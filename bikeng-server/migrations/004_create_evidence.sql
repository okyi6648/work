CREATE TABLE IF NOT EXISTS evidence (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    report_id       BIGINT UNSIGNED NOT NULL,
    file_type       ENUM('image','video','document') NOT NULL DEFAULT 'image',
    file_url        VARCHAR(1024) NOT NULL,
    file_size       INT UNSIGNED NOT NULL DEFAULT 0,
    ocr_text        TEXT NULL,
    sort_order      SMALLINT NOT NULL DEFAULT 0,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    KEY idx_report (report_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
