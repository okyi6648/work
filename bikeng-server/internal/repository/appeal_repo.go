package repository

import (
	"errors"
	"time"

	"github.com/nicksrepo/bikeng-server/internal/model"
	"gorm.io/gorm"
)

type AppealRepo struct {
	db *gorm.DB
}

func NewAppealRepo(db *gorm.DB) *AppealRepo {
	return &AppealRepo{db: db}
}

// Create inserts a new appeal record.
func (r *AppealRepo) Create(appeal *model.Appeal) error {
	return r.db.Create(appeal).Error
}

// FindByID finds an appeal by ID. Returns (nil, nil) if not found.
func (r *AppealRepo) FindByID(id uint64) (*model.Appeal, error) {
	var appeal model.Appeal
	result := r.db.First(&appeal, id)
	if result.Error != nil {
		if errors.Is(result.Error, gorm.ErrRecordNotFound) {
			return nil, nil
		}
		return nil, result.Error
	}
	return &appeal, nil
}

// FindByAccount retrieves all appeals for a given account.
func (r *AppealRepo) FindByAccount(accountID uint64) ([]model.Appeal, error) {
	var appeals []model.Appeal
	err := r.db.Where("account_id = ?", accountID).Order("created_at DESC").Find(&appeals).Error
	return appeals, err
}

// UpdateStatus updates the review status of an appeal.
func (r *AppealRepo) UpdateStatus(id uint64, status string, reviewerID uint64, reviewNote string) error {
	now := time.Now()
	return r.db.Model(&model.Appeal{}).Where("id = ?", id).
		Updates(map[string]interface{}{
			"status":      status,
			"reviewer_id": reviewerID,
			"review_note": reviewNote,
			"resolved_at": now,
		}).Error
}

// GetPendingAppeals retrieves appeals with pending status for admin review.
// Returns matched appeals, total count, and error.
func (r *AppealRepo) GetPendingAppeals(page, pageSize int) ([]model.Appeal, int64, error) {
	var appeals []model.Appeal
	var total int64

	query := r.db.Model(&model.Appeal{}).Where("status = ?", "pending")

	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}

	offset := (page - 1) * pageSize
	if err := query.Offset(offset).Limit(pageSize).Order("created_at ASC").Find(&appeals).Error; err != nil {
		return nil, 0, err
	}

	return appeals, total, nil
}
