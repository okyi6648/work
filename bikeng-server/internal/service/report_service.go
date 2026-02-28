package service

import (
	"errors"
	"fmt"
	"time"

	"github.com/nicksrepo/bikeng-server/internal/model"
	"github.com/nicksrepo/bikeng-server/internal/repository"
)

// SubmitReportRequest contains the data required to submit a new report.
type SubmitReportRequest struct {
	AccountType     string    `json:"account_type" binding:"required"`
	AccountValue    string    `json:"account_value" binding:"required"`
	ScamType        string    `json:"scam_type" binding:"required"`
	Description     string    `json:"description" binding:"required"`
	LossAmount      float64   `json:"loss_amount"`
	ContactMethod   string    `json:"contact_method"`
	IncidentDate    *time.Time `json:"incident_date"`
	LiabilityAgreed bool      `json:"liability_agreed"`
	EvidenceURLs    []string  `json:"evidence_urls"`
}

// ReportService handles report submission and management.
type ReportService struct {
	reportRepo   *repository.ReportRepo
	accountRepo  *repository.AccountRepo
	evidenceRepo *repository.EvidenceRepo
	riskService  *RiskService
}

// NewReportService creates a new ReportService with the required dependencies.
func NewReportService(
	reportRepo *repository.ReportRepo,
	accountRepo *repository.AccountRepo,
	evidenceRepo *repository.EvidenceRepo,
	riskService *RiskService,
) *ReportService {
	return &ReportService{
		reportRepo:   reportRepo,
		accountRepo:  accountRepo,
		evidenceRepo: evidenceRepo,
		riskService:  riskService,
	}
}

// SubmitReport creates a new report against the specified account.
// It finds or creates the account, creates the report and evidence records,
// increments the account's report count, and recalculates the risk score.
func (s *ReportService) SubmitReport(reporterID uint64, req SubmitReportRequest) (*model.Report, error) {
	if !req.LiabilityAgreed {
		return nil, errors.New("必须同意免责声明")
	}

	// Find or create the account being reported.
	account, err := s.accountRepo.FindOrCreate(req.AccountType, req.AccountValue)
	if err != nil {
		return nil, fmt.Errorf("failed to find or create account: %w", err)
	}

	// Set first_reported_at if this is the account's first report.
	if account.FirstReportedAt == nil {
		now := time.Now()
		account.FirstReportedAt = &now
		if err := s.accountRepo.Update(account); err != nil {
			return nil, fmt.Errorf("failed to update account first_reported_at: %w", err)
		}
	}

	// Create the report record.
	report := &model.Report{
		ReporterID:      reporterID,
		AccountID:       account.ID,
		ScamType:        req.ScamType,
		Description:     req.Description,
		LossAmount:      req.LossAmount,
		ContactMethod:   req.ContactMethod,
		IncidentDate:    req.IncidentDate,
		Status:          "pending",
		LiabilityAgreed: req.LiabilityAgreed,
	}
	if err := s.reportRepo.Create(report); err != nil {
		return nil, fmt.Errorf("failed to create report: %w", err)
	}

	// Create evidence records for each URL.
	if len(req.EvidenceURLs) > 0 {
		evidences := make([]model.Evidence, 0, len(req.EvidenceURLs))
		for i, url := range req.EvidenceURLs {
			evidences = append(evidences, model.Evidence{
				ReportID:  report.ID,
				FileType:  "image",
				FileURL:   url,
				FileSize:  0,
				SortOrder: int16(i),
			})
		}
		if err := s.evidenceRepo.CreateBatch(evidences); err != nil {
			return nil, fmt.Errorf("failed to create evidence records: %w", err)
		}
	}

	// Increment the account's report count and total amount.
	if err := s.accountRepo.IncrementReportCount(account.ID, req.LossAmount); err != nil {
		return nil, fmt.Errorf("failed to increment report count: %w", err)
	}

	// Recalculate the account's risk score.
	newScore, err := s.riskService.CalculateRiskScore(account.ID)
	if err != nil {
		// Log but do not fail the report submission for risk score errors.
		return report, nil
	}
	_ = s.accountRepo.UpdateRiskScore(account.ID, newScore)

	return report, nil
}

// GetMyReports retrieves paginated reports submitted by the given user.
func (s *ReportService) GetMyReports(userID uint64, page, pageSize int) ([]model.Report, int64, error) {
	return s.reportRepo.FindByReporter(userID, page, pageSize)
}

// GetReportDetail retrieves a report and its associated evidence by report ID.
func (s *ReportService) GetReportDetail(id uint64) (*model.Report, []model.Evidence, error) {
	report, err := s.reportRepo.FindByID(id)
	if err != nil {
		return nil, nil, fmt.Errorf("failed to find report: %w", err)
	}
	if report == nil {
		return nil, nil, errors.New("举报记录不存在")
	}

	evidences, err := s.evidenceRepo.FindByReport(report.ID)
	if err != nil {
		return nil, nil, fmt.Errorf("failed to find evidence: %w", err)
	}

	return report, evidences, nil
}

// ReviewReport allows an admin to approve or reject a pending report.
func (s *ReportService) ReviewReport(id, reviewerID uint64, approved bool, rejectReason string) error {
	report, err := s.reportRepo.FindByID(id)
	if err != nil {
		return fmt.Errorf("failed to find report: %w", err)
	}
	if report == nil {
		return errors.New("举报记录不存在")
	}
	if report.Status != "pending" {
		return errors.New("该举报已被处理")
	}

	status := "approved"
	if !approved {
		status = "rejected"
	}

	if err := s.reportRepo.UpdateStatus(id, status, reviewerID, rejectReason); err != nil {
		return fmt.Errorf("failed to update report status: %w", err)
	}

	// Recalculate risk score after review.
	newScore, err := s.riskService.CalculateRiskScore(report.AccountID)
	if err == nil {
		_ = s.accountRepo.UpdateRiskScore(report.AccountID, newScore)
	}

	return nil
}
