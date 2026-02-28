package service

import (
	"fmt"

	"github.com/nicksrepo/bikeng-server/internal/model"
	"github.com/nicksrepo/bikeng-server/internal/repository"
)

// AlertService handles alert/warning management operations.
type AlertService struct {
	alertRepo *repository.AlertRepo
}

// NewAlertService creates a new AlertService with the required dependencies.
func NewAlertService(alertRepo *repository.AlertRepo) *AlertService {
	return &AlertService{
		alertRepo: alertRepo,
	}
}

// CreateAlert creates a new alert/warning notification.
func (s *AlertService) CreateAlert(createdBy uint64, title, content, severity string) (*model.Alert, error) {
	alert := &model.Alert{
		Title:     title,
		Content:   content,
		Severity:  severity,
		CreatedBy: createdBy,
	}
	if err := s.alertRepo.Create(alert); err != nil {
		return nil, fmt.Errorf("failed to create alert: %w", err)
	}
	return alert, nil
}

// GetAlertList retrieves a paginated list of alerts.
func (s *AlertService) GetAlertList(page, pageSize int) ([]model.Alert, int64, error) {
	return s.alertRepo.List(page, pageSize)
}

// GetLatestAlerts retrieves the most recent alerts up to the given limit.
func (s *AlertService) GetLatestAlerts(limit int) ([]model.Alert, error) {
	return s.alertRepo.GetLatest(limit)
}
