package model

import "time"

type Account struct {
	ID              uint64     `gorm:"column:id;primaryKey;autoIncrement" json:"id"`
	AccountType     string     `gorm:"column:account_type;type:varchar(30);not null" json:"account_type"`
	AccountValue    string     `gorm:"column:account_value;type:varchar(255);not null;uniqueIndex" json:"account_value"`
	ReportCount     uint       `gorm:"column:report_count;default:0;not null" json:"report_count"`
	RiskScore       float64    `gorm:"column:risk_score;default:0;not null" json:"risk_score"`
	TotalAmount     float64    `gorm:"column:total_amount;default:0;not null" json:"total_amount"`
	FirstReportedAt *time.Time `gorm:"column:first_reported_at" json:"first_reported_at"`
	LastReportedAt  *time.Time `gorm:"column:last_reported_at" json:"last_reported_at"`
	AppealStatus    string     `gorm:"column:appeal_status;type:varchar(20);default:'none';not null" json:"appeal_status"`
	CreatedAt       time.Time  `gorm:"column:created_at;autoCreateTime" json:"created_at"`
	UpdatedAt       time.Time  `gorm:"column:updated_at;autoUpdateTime" json:"updated_at"`
}

func (Account) TableName() string {
	return "accounts"
}
