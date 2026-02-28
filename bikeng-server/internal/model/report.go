package model

import "time"

type Report struct {
	ID              uint64     `gorm:"column:id;primaryKey;autoIncrement" json:"id"`
	ReporterID      uint64     `gorm:"column:reporter_id;not null;index" json:"reporter_id"`
	AccountID       uint64     `gorm:"column:account_id;not null;index" json:"account_id"`
	ScamType        string     `gorm:"column:scam_type;type:varchar(50);not null" json:"scam_type"`
	Description     string     `gorm:"column:description;type:text;not null" json:"description"`
	LossAmount      float64    `gorm:"column:loss_amount;default:0;not null" json:"loss_amount"`
	ContactMethod   string     `gorm:"column:contact_method;type:varchar(50)" json:"contact_method"`
	IncidentDate    *time.Time `gorm:"column:incident_date;type:date" json:"incident_date"`
	Status          string     `gorm:"column:status;type:varchar(20);default:'pending';not null" json:"status"`
	LiabilityAgreed bool       `gorm:"column:liability_agreed;default:false;not null" json:"liability_agreed"`
	ReviewerID      *uint64    `gorm:"column:reviewer_id" json:"reviewer_id"`
	ReviewedAt      *time.Time `gorm:"column:reviewed_at" json:"reviewed_at"`
	RejectReason    string     `gorm:"column:reject_reason;type:varchar(512)" json:"reject_reason"`
	CreatedAt       time.Time  `gorm:"column:created_at;autoCreateTime" json:"created_at"`
	UpdatedAt       time.Time  `gorm:"column:updated_at;autoUpdateTime" json:"updated_at"`
}

func (Report) TableName() string {
	return "reports"
}
