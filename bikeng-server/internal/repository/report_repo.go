package repository

import (
	"errors"
	"time"

	"github.com/nicksrepo/bikeng-server/internal/model"
	"gorm.io/gorm"
)

type ReportRepo struct {
	db *gorm.DB
}

func NewReportRepo(db *gorm.DB) *ReportRepo {
	return &ReportRepo{db: db}
}

// Create inserts a new report record.
func (r *ReportRepo) Create(report *model.Report) error {
	return r.db.Create(report).Error
}

// FindByID finds a report by ID. Returns (nil, nil) if not found.
func (r *ReportRepo) FindByID(id uint64) (*model.Report, error) {
	var report model.Report
	result := r.db.First(&report, id)
	if result.Error != nil {
		if errors.Is(result.Error, gorm.ErrRecordNotFound) {
			return nil, nil
		}
		return nil, result.Error
	}
	return &report, nil
}

// FindByReporter retrieves reports filed by a specific reporter with pagination.
// Returns matched reports, total count, and error.
func (r *ReportRepo) FindByReporter(reporterID uint64, page, pageSize int) ([]model.Report, int64, error) {
	var reports []model.Report
	var total int64

	query := r.db.Model(&model.Report{}).Where("reporter_id = ?", reporterID)

	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}

	offset := (page - 1) * pageSize
	if err := query.Offset(offset).Limit(pageSize).Order("created_at DESC").Find(&reports).Error; err != nil {
		return nil, 0, err
	}

	return reports, total, nil
}

// FindByAccount retrieves all reports for a given account.
func (r *ReportRepo) FindByAccount(accountID uint64) ([]model.Report, error) {
	var reports []model.Report
	err := r.db.Where("account_id = ?", accountID).Order("created_at DESC").Find(&reports).Error
	return reports, err
}

// UpdateStatus updates the review status of a report (admin review).
func (r *ReportRepo) UpdateStatus(id uint64, status string, reviewerID uint64, rejectReason string) error {
	now := time.Now()
	return r.db.Model(&model.Report{}).Where("id = ?", id).
		Updates(map[string]interface{}{
			"status":        status,
			"reviewer_id":   reviewerID,
			"reviewed_at":   now,
			"reject_reason": rejectReason,
		}).Error
}

// CountUniqueReporters counts the number of distinct reporters for an account.
func (r *ReportRepo) CountUniqueReporters(accountID uint64) (int64, error) {
	var count int64
	err := r.db.Model(&model.Report{}).
		Where("account_id = ?", accountID).
		Distinct("reporter_id").
		Count(&count).Error
	return count, err
}

// CountByScamType counts the number of distinct scam types reported for an account.
func (r *ReportRepo) CountByScamType(accountID uint64) (int64, error) {
	var count int64
	err := r.db.Model(&model.Report{}).
		Where("account_id = ?", accountID).
		Distinct("scam_type").
		Count(&count).Error
	return count, err
}

// GetPendingReports retrieves reports with pending_review status for admin review.
// Returns matched reports, total count, and error.
func (r *ReportRepo) GetPendingReports(page, pageSize int) ([]model.Report, int64, error) {
	var reports []model.Report
	var total int64

	query := r.db.Model(&model.Report{}).Where("status = ?", "pending_review")

	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}

	offset := (page - 1) * pageSize
	if err := query.Offset(offset).Limit(pageSize).Order("created_at ASC").Find(&reports).Error; err != nil {
		return nil, 0, err
	}

	return reports, total, nil
}
