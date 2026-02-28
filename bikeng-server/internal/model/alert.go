package model

import "time"

type Alert struct {
	ID        uint64     `gorm:"column:id;primaryKey;autoIncrement" json:"id"`
	Title     string     `gorm:"column:title;type:varchar(255);not null" json:"title"`
	Content   string     `gorm:"column:content;type:text;not null" json:"content"`
	Severity  string     `gorm:"column:severity;type:varchar(20);not null" json:"severity"`
	IsPushed  bool       `gorm:"column:is_pushed;default:false;not null" json:"is_pushed"`
	PushedAt  *time.Time `gorm:"column:pushed_at" json:"pushed_at"`
	CreatedBy uint64     `gorm:"column:created_by;not null" json:"created_by"`
	CreatedAt time.Time  `gorm:"column:created_at;autoCreateTime" json:"created_at"`
}

func (Alert) TableName() string {
	return "alerts"
}
