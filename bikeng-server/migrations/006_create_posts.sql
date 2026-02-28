CREATE TABLE IF NOT EXISTS posts (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    author_id       BIGINT UNSIGNED NOT NULL,
    title           VARCHAR(200) NOT NULL,
    content         TEXT NOT NULL,
    category        ENUM('experience','warning','tip','question','other') NOT NULL DEFAULT 'other',
    image_urls      JSON NULL,
    view_count      INT UNSIGNED NOT NULL DEFAULT 0,
    like_count      INT UNSIGNED NOT NULL DEFAULT 0,
    comment_count   INT UNSIGNED NOT NULL DEFAULT 0,
    is_pinned       TINYINT(1) NOT NULL DEFAULT 0,
    status          ENUM('active','hidden','deleted') NOT NULL DEFAULT 'active',
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    KEY idx_author (author_id),
    KEY idx_category_created (category, created_at DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
