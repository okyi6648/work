package repository

import (
	"time"

	"github.com/nicksrepo/bikeng-server/internal/model"
	"gorm.io/gorm"
)

type AlertRepo struct {
	db *gorm.DB
}

func NewAlertRepo(db *gorm.DB) *AlertRepo {
	return &AlertRepo{db: db}
}

// Create inserts a new alert record.
func (r *AlertRepo) Create(alert *model.Alert) error {
	return r.db.Create(alert).Error
}

// List retrieves alerts with pagination, ordered by created_at DESC.
// Returns matched alerts, total count, and error.
func (r *AlertRepo) List(page, pageSize int) ([]model.Alert, int64, error) {
	var alerts []model.Alert
	var total int64

	if err := r.db.Model(&model.Alert{}).Count(&total).Error; err != nil {
		return nil, 0, err
	}

	offset := (page - 1) * pageSize
	if err := r.db.Offset(offset).Limit(pageSize).Order("created_at DESC").Find(&alerts).Error; err != nil {
		return nil, 0, err
	}

	return alerts, total, nil
}

// GetLatest retrieves the latest N alerts ordered by created_at DESC.
func (r *AlertRepo) GetLatest(limit int) ([]model.Alert, error) {
	var alerts []model.Alert
	err := r.db.Order("created_at DESC").Limit(limit).Find(&alerts).Error
	return alerts, err
}

// MarkPushed sets is_pushed to true and pushed_at to the current time.
func (r *AlertRepo) MarkPushed(id uint64) error {
	now := time.Now()
	return r.db.Model(&model.Alert{}).Where("id = ?", id).
		Updates(map[string]interface{}{
			"is_pushed": true,
			"pushed_at": now,
		}).Error
}
