package model

import "time"

type Evidence struct {
	ID        uint64    `gorm:"column:id;primaryKey;autoIncrement" json:"id"`
	ReportID  uint64    `gorm:"column:report_id;not null;index" json:"report_id"`
	FileType  string    `gorm:"column:file_type;type:varchar(20);not null" json:"file_type"`
	FileURL   string    `gorm:"column:file_url;type:varchar(512);not null" json:"file_url"`
	FileSize  uint      `gorm:"column:file_size;not null" json:"file_size"`
	OcrText   *string   `gorm:"column:ocr_text;type:text" json:"ocr_text"`
	SortOrder int16     `gorm:"column:sort_order;default:0;not null" json:"sort_order"`
	CreatedAt time.Time `gorm:"column:created_at;autoCreateTime" json:"created_at"`
}

func (Evidence) TableName() string {
	return "evidence"
}
