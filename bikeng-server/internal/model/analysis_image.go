package model

import "time"

type AnalysisImage struct {
	ID        uint64    `gorm:"column:id;primaryKey;autoIncrement" json:"id"`
	SessionID uint64    `gorm:"column:session_id;not null;index" json:"session_id"`
	ImageURL  string    `gorm:"column:image_url;type:varchar(512);not null" json:"image_url"`
	ImageType string    `gorm:"column:image_type;type:varchar(20);default:'chat';not null" json:"image_type"`
	OcrText   string    `gorm:"column:ocr_text;type:text" json:"ocr_text"`
	CreatedAt time.Time `gorm:"column:created_at;autoCreateTime" json:"created_at"`
}

func (AnalysisImage) TableName() string {
	return "analysis_images"
}
