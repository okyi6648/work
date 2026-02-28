package model

import "time"

type AnalysisSession struct {
	ID             uint64    `gorm:"column:id;primaryKey;autoIncrement" json:"id"`
	UserID         uint64    `gorm:"column:user_id;not null;index" json:"user_id"`
	Status         string    `gorm:"column:status;type:varchar(20);default:'pending';not null" json:"status"`
	OverallScore   float64   `gorm:"column:overall_score;default:0;not null" json:"overall_score"`
	ChatScore      float64   `gorm:"column:chat_score;default:0;not null" json:"chat_score"`
	AccountScore   float64   `gorm:"column:account_score;default:0;not null" json:"account_score"`
	TransferScore  float64   `gorm:"column:transfer_score;default:0;not null" json:"transfer_score"`
	CommunityScore float64   `gorm:"column:community_score;default:0;not null" json:"community_score"`
	Confidence     float64   `gorm:"column:confidence;default:0;not null" json:"confidence"`
	Summary        string    `gorm:"column:summary;type:text" json:"summary"`
	CreatedAt      time.Time `gorm:"column:created_at;autoCreateTime" json:"created_at"`
	UpdatedAt      time.Time `gorm:"column:updated_at;autoUpdateTime" json:"updated_at"`
}

func (AnalysisSession) TableName() string {
	return "analysis_sessions"
}
