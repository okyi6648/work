package model

import (
	"time"

	"gorm.io/datatypes"
)

type Appeal struct {
	ID            uint64         `gorm:"column:id;primaryKey;autoIncrement" json:"id"`
	AccountID     uint64         `gorm:"column:account_id;not null;index" json:"account_id"`
	AppellantPhone string        `gorm:"column:appellant_phone;type:varchar(20);not null" json:"appellant_phone"`
	Reason        string         `gorm:"column:reason;type:text;not null" json:"reason"`
	EvidenceURLs  datatypes.JSON `gorm:"column:evidence_urls;type:json" json:"evidence_urls"`
	Status        string         `gorm:"column:status;type:varchar(20);default:'pending';not null" json:"status"`
	ReviewerID    *uint64        `gorm:"column:reviewer_id" json:"reviewer_id"`
	ReviewNote    *string        `gorm:"column:review_note;type:text" json:"review_note"`
	ResolvedAt    *time.Time     `gorm:"column:resolved_at" json:"resolved_at"`
	CreatedAt     time.Time      `gorm:"column:created_at;autoCreateTime" json:"created_at"`
	UpdatedAt     time.Time      `gorm:"column:updated_at;autoUpdateTime" json:"updated_at"`
}

func (Appeal) TableName() string {
	return "appeals"
}
