package service

import (
	"encoding/json"
	"errors"
	"fmt"

	"github.com/nicksrepo/bikeng-server/internal/model"
	"github.com/nicksrepo/bikeng-server/internal/repository"
	"gorm.io/datatypes"
)

// SubmitAppealRequest contains the data required to submit an appeal.
type SubmitAppealRequest struct {
	AccountID      uint64   `json:"account_id" binding:"required"`
	AppellantPhone string   `json:"appellant_phone" binding:"required"`
	Reason         string   `json:"reason" binding:"required"`
	EvidenceURLs   []string `json:"evidence_urls"`
}

// AppealService handles appeal submission and review processing.
type AppealService struct {
	appealRepo  *repository.AppealRepo
	accountRepo *repository.AccountRepo
	riskService *RiskService
}

// NewAppealService creates a new AppealService with the required dependencies.
func NewAppealService(
	appealRepo *repository.AppealRepo,
	accountRepo *repository.AccountRepo,
	riskService *RiskService,
) *AppealService {
	return &AppealService{
		appealRepo:  appealRepo,
		accountRepo: accountRepo,
		riskService: riskService,
	}
}

// SubmitAppeal creates a new appeal for an account and sets the account's
// appeal_status to 'pending'.
func (s *AppealService) SubmitAppeal(req SubmitAppealRequest) (*model.Appeal, error) {
	// Verify the account exists.
	account, err := s.accountRepo.FindByID(req.AccountID)
	if err != nil {
		return nil, fmt.Errorf("failed to find account: %w", err)
	}
	if account == nil {
		return nil, errors.New("账号不存在")
	}

	// Check if there is already a pending appeal for this account.
	if account.AppealStatus == "pending" {
		return nil, errors.New("该账号已有待处理的申诉")
	}

	// Marshal evidence URLs to JSON.
	var evidenceJSON datatypes.JSON
	if len(req.EvidenceURLs) > 0 {
		data, err := json.Marshal(req.EvidenceURLs)
		if err != nil {
			return nil, fmt.Errorf("failed to marshal evidence URLs: %w", err)
		}
		evidenceJSON = data
	} else {
		evidenceJSON = datatypes.JSON("[]")
	}

	// Create the appeal record.
	appeal := &model.Appeal{
		AccountID:      req.AccountID,
		AppellantPhone: req.AppellantPhone,
		Reason:         req.Reason,
		EvidenceURLs:   evidenceJSON,
		Status:         "pending",
	}
	if err := s.appealRepo.Create(appeal); err != nil {
		return nil, fmt.Errorf("failed to create appeal: %w", err)
	}

	// Update the account's appeal_status to 'pending'.
	account.AppealStatus = "pending"
	if err := s.accountRepo.Update(account); err != nil {
		return nil, fmt.Errorf("failed to update account appeal status: %w", err)
	}

	return appeal, nil
}

// GetAppealStatus retrieves an appeal by its ID.
func (s *AppealService) GetAppealStatus(id uint64) (*model.Appeal, error) {
	appeal, err := s.appealRepo.FindByID(id)
	if err != nil {
		return nil, fmt.Errorf("failed to find appeal: %w", err)
	}
	if appeal == nil {
		return nil, errors.New("申诉记录不存在")
	}
	return appeal, nil
}

// ReviewAppeal processes an admin's review of an appeal.
// If accepted, the account's appeal_status is set to 'accepted' and the risk
// score is recalculated (which will halve it). If rejected, the status is set
// to 'rejected'.
func (s *AppealService) ReviewAppeal(id, reviewerID uint64, accepted bool, reviewNote string) error {
	appeal, err := s.appealRepo.FindByID(id)
	if err != nil {
		return fmt.Errorf("failed to find appeal: %w", err)
	}
	if appeal == nil {
		return errors.New("申诉记录不存在")
	}
	if appeal.Status != "pending" {
		return errors.New("该申诉已被处理")
	}

	status := "accepted"
	if !accepted {
		status = "rejected"
	}

	// Update the appeal status.
	if err := s.appealRepo.UpdateStatus(id, status, reviewerID, reviewNote); err != nil {
		return fmt.Errorf("failed to update appeal status: %w", err)
	}

	// Update the account's appeal_status.
	account, err := s.accountRepo.FindByID(appeal.AccountID)
	if err != nil {
		return fmt.Errorf("failed to find account: %w", err)
	}
	if account != nil {
		account.AppealStatus = status
		if err := s.accountRepo.Update(account); err != nil {
			return fmt.Errorf("failed to update account appeal status: %w", err)
		}

		// Recalculate risk score if the appeal was accepted.
		if accepted {
			newScore, err := s.riskService.CalculateRiskScore(account.ID)
			if err == nil {
				_ = s.accountRepo.UpdateRiskScore(account.ID, newScore)
			}
		}
	}

	return nil
}
