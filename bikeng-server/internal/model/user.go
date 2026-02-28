package model

import "time"

type User struct {
	ID          uint64     `gorm:"column:id;primaryKey;autoIncrement" json:"id"`
	Phone       string     `gorm:"column:phone;type:varchar(20);not null;uniqueIndex" json:"phone"`
	Nickname    string     `gorm:"column:nickname;type:varchar(64);not null" json:"nickname"`
	AvatarURL   string     `gorm:"column:avatar_url;type:varchar(512)" json:"avatar_url"`
	IsVerified  bool       `gorm:"column:is_verified;default:false;not null" json:"is_verified"`
	Role        string     `gorm:"column:role;type:varchar(20);default:'user';not null" json:"role"`
	Status      string     `gorm:"column:status;type:varchar(20);default:'active';not null" json:"status"`
	LastLoginAt *time.Time `gorm:"column:last_login_at" json:"last_login_at"`
	CreatedAt   time.Time  `gorm:"column:created_at;autoCreateTime" json:"created_at"`
	UpdatedAt   time.Time  `gorm:"column:updated_at;autoUpdateTime" json:"updated_at"`
}

func (User) TableName() string {
	return "users"
}
