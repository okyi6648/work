package repository

import (
	"github.com/nicksrepo/bikeng-server/internal/model"
	"gorm.io/gorm"
)

type EvidenceRepo struct {
	db *gorm.DB
}

func NewEvidenceRepo(db *gorm.DB) *EvidenceRepo {
	return &EvidenceRepo{db: db}
}

// Create inserts a new evidence record.
func (r *EvidenceRepo) Create(evidence *model.Evidence) error {
	return r.db.Create(evidence).Error
}

// CreateBatch inserts multiple evidence records in a single batch.
func (r *EvidenceRepo) CreateBatch(evidences []model.Evidence) error {
	if len(evidences) == 0 {
		return nil
	}
	return r.db.Create(&evidences).Error
}

// FindByReport retrieves all evidence for a given report, ordered by sort_order.
func (r *EvidenceRepo) FindByReport(reportID uint64) ([]model.Evidence, error) {
	var evidences []model.Evidence
	err := r.db.Where("report_id = ?", reportID).Order("sort_order ASC").Find(&evidences).Error
	return evidences, err
}
