package model

import "time"

type Comment struct {
	ID        uint64    `gorm:"column:id;primaryKey;autoIncrement" json:"id"`
	PostID    uint64    `gorm:"column:post_id;not null;index" json:"post_id"`
	AuthorID  uint64    `gorm:"column:author_id;not null;index" json:"author_id"`
	ParentID  *uint64   `gorm:"column:parent_id;index" json:"parent_id"`
	Content   string    `gorm:"column:content;type:text;not null" json:"content"`
	LikeCount uint      `gorm:"column:like_count;default:0;not null" json:"like_count"`
	Status    string    `gorm:"column:status;type:varchar(20);default:'active';not null" json:"status"`
	CreatedAt time.Time `gorm:"column:created_at;autoCreateTime" json:"created_at"`
}

func (Comment) TableName() string {
	return "comments"
}
