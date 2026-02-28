CREATE TABLE IF NOT EXISTS analysis_sessions (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id         BIGINT UNSIGNED NOT NULL,
    status          ENUM('pending','processing','completed','failed') NOT NULL DEFAULT 'pending',
    overall_score   FLOAT NOT NULL DEFAULT 0,
    chat_score      FLOAT NOT NULL DEFAULT 0,
    account_score   FLOAT NOT NULL DEFAULT 0,
    transfer_score  FLOAT NOT NULL DEFAULT 0,
    community_score FLOAT NOT NULL DEFAULT 0,
    confidence      FLOAT NOT NULL DEFAULT 0,
    summary         TEXT NOT NULL DEFAULT '',
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    KEY idx_user (user_id),
    KEY idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS analysis_images (
    id          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    session_id  BIGINT UNSIGNED NOT NULL,
    image_url   VARCHAR(512) NOT NULL,
    image_type  ENUM('chat','account_info','transfer') NOT NULL DEFAULT 'chat',
    ocr_text    TEXT NOT NULL DEFAULT '',
    created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    KEY idx_session (session_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS analysis_factors (
    id           BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    session_id   BIGINT UNSIGNED NOT NULL,
    category     VARCHAR(50) NOT NULL DEFAULT '',
    factor_type  VARCHAR(100) NOT NULL DEFAULT '',
    factor_value VARCHAR(512) NOT NULL DEFAULT '',
    score_impact FLOAT NOT NULL DEFAULT 0,
    severity     ENUM('low','medium','high','critical') NOT NULL DEFAULT 'low',
    created_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    KEY idx_session (session_id),
    KEY idx_category (category)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
