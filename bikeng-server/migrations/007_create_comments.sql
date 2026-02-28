CREATE TABLE IF NOT EXISTS comments (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    post_id         BIGINT UNSIGNED NOT NULL,
    author_id       BIGINT UNSIGNED NOT NULL,
    parent_id       BIGINT UNSIGNED NULL,
    content         TEXT NOT NULL,
    like_count      INT UNSIGNED NOT NULL DEFAULT 0,
    status          ENUM('active','hidden','deleted') NOT NULL DEFAULT 'active',
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    KEY idx_post_created (post_id, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
