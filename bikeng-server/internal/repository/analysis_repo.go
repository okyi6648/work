package repository

import (
	"errors"

	"github.com/nicksrepo/bikeng-server/internal/model"
	"gorm.io/gorm"
)

type AnalysisRepo struct {
	db *gorm.DB
}

func NewAnalysisRepo(db *gorm.DB) *AnalysisRepo {
	return &AnalysisRepo{db: db}
}

// CreateSession inserts a new analysis session.
func (r *AnalysisRepo) CreateSession(session *model.AnalysisSession) error {
	return r.db.Create(session).Error
}

// UpdateSession saves all fields of an analysis session.
func (r *AnalysisRepo) UpdateSession(session *model.AnalysisSession) error {
	return r.db.Save(session).Error
}

// FindSessionByID finds a session by ID. Returns (nil, nil) if not found.
func (r *AnalysisRepo) FindSessionByID(id uint64) (*model.AnalysisSession, error) {
	var session model.AnalysisSession
	result := r.db.First(&session, id)
	if result.Error != nil {
		if errors.Is(result.Error, gorm.ErrRecordNotFound) {
			return nil, nil
		}
		return nil, result.Error
	}
	return &session, nil
}

// FindSessionsByUser retrieves analysis sessions for a user with pagination.
func (r *AnalysisRepo) FindSessionsByUser(userID uint64, page, pageSize int) ([]model.AnalysisSession, int64, error) {
	var sessions []model.AnalysisSession
	var total int64

	query := r.db.Model(&model.AnalysisSession{}).Where("user_id = ?", userID)

	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}

	offset := (page - 1) * pageSize
	if err := query.Offset(offset).Limit(pageSize).Order("created_at DESC").Find(&sessions).Error; err != nil {
		return nil, 0, err
	}

	return sessions, total, nil
}

// CreateImages inserts multiple analysis images in a single batch.
func (r *AnalysisRepo) CreateImages(images []model.AnalysisImage) error {
	if len(images) == 0 {
		return nil
	}
	return r.db.Create(&images).Error
}

// FindImagesBySession retrieves all images for a given session.
func (r *AnalysisRepo) FindImagesBySession(sessionID uint64) ([]model.AnalysisImage, error) {
	var images []model.AnalysisImage
	err := r.db.Where("session_id = ?", sessionID).Order("id ASC").Find(&images).Error
	return images, err
}

// CreateFactors inserts multiple analysis factors in a single batch.
func (r *AnalysisRepo) CreateFactors(factors []model.AnalysisFactor) error {
	if len(factors) == 0 {
		return nil
	}
	return r.db.Create(&factors).Error
}

// FindFactorsBySession retrieves all factors for a given session.
func (r *AnalysisRepo) FindFactorsBySession(sessionID uint64) ([]model.AnalysisFactor, error) {
	var factors []model.AnalysisFactor
	err := r.db.Where("session_id = ?", sessionID).Order("score_impact DESC").Find(&factors).Error
	return factors, err
}
