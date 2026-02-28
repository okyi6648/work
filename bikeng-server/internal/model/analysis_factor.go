package model

import "time"

type AnalysisFactor struct {
	ID          uint64    `gorm:"column:id;primaryKey;autoIncrement" json:"id"`
	SessionID   uint64    `gorm:"column:session_id;not null;index" json:"session_id"`
	Category    string    `gorm:"column:category;type:varchar(50);not null" json:"category"`
	FactorType  string    `gorm:"column:factor_type;type:varchar(100);not null" json:"factor_type"`
	FactorValue string    `gorm:"column:factor_value;type:varchar(512);not null" json:"factor_value"`
	ScoreImpact float64   `gorm:"column:score_impact;default:0;not null" json:"score_impact"`
	Severity    string    `gorm:"column:severity;type:varchar(20);default:'low';not null" json:"severity"`
	CreatedAt   time.Time `gorm:"column:created_at;autoCreateTime" json:"created_at"`
}

func (AnalysisFactor) TableName() string {
	return "analysis_factors"
}
