package model

import (
	"time"

	"gorm.io/datatypes"
)

type Post struct {
	ID           uint64         `gorm:"column:id;primaryKey;autoIncrement" json:"id"`
	AuthorID     uint64         `gorm:"column:author_id;not null;index" json:"author_id"`
	Title        string         `gorm:"column:title;type:varchar(255);not null" json:"title"`
	Content      string         `gorm:"column:content;type:text;not null" json:"content"`
	Category     string         `gorm:"column:category;type:varchar(50);not null" json:"category"`
	ImageURLs    datatypes.JSON `gorm:"column:image_urls;type:json" json:"image_urls"`
	ViewCount    uint           `gorm:"column:view_count;default:0;not null" json:"view_count"`
	LikeCount    uint           `gorm:"column:like_count;default:0;not null" json:"like_count"`
	CommentCount uint           `gorm:"column:comment_count;default:0;not null" json:"comment_count"`
	IsPinned     bool           `gorm:"column:is_pinned;default:false;not null" json:"is_pinned"`
	Status       string         `gorm:"column:status;type:varchar(20);default:'active';not null" json:"status"`
	CreatedAt    time.Time      `gorm:"column:created_at;autoCreateTime" json:"created_at"`
	UpdatedAt    time.Time      `gorm:"column:updated_at;autoUpdateTime" json:"updated_at"`
}

func (Post) TableName() string {
	return "posts"
}
