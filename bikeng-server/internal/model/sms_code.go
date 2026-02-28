package model

import "time"

type SmsCode struct {
	ID        uint64    `gorm:"column:id;primaryKey;autoIncrement" json:"id"`
	Phone     string    `gorm:"column:phone;type:varchar(20);not null;index" json:"phone"`
	Code      string    `gorm:"column:code;type:varchar(10);not null" json:"code"`
	Purpose   string    `gorm:"column:purpose;type:varchar(30);not null" json:"purpose"`
	IsUsed    bool      `gorm:"column:is_used;default:false;not null" json:"is_used"`
	ExpiresAt time.Time `gorm:"column:expires_at;not null" json:"expires_at"`
	CreatedAt time.Time `gorm:"column:created_at;autoCreateTime" json:"created_at"`
}

func (SmsCode) TableName() string {
	return "sms_codes"
}
