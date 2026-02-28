package service

import (
	"math"
	"time"

	"github.com/nicksrepo/bikeng-server/internal/model"
	"github.com/nicksrepo/bikeng-server/internal/repository"
)

// AccountAnalysisService analyzes account risk by querying the community report database.
type AccountAnalysisService struct {
	accountRepo *repository.AccountRepo
	reportRepo  *repository.ReportRepo
}

// NewAccountAnalysisService creates a new AccountAnalysisService.
func NewAccountAnalysisService(
	accountRepo *repository.AccountRepo,
	reportRepo *repository.ReportRepo,
) *AccountAnalysisService {
	return &AccountAnalysisService{
		accountRepo: accountRepo,
		reportRepo:  reportRepo,
	}
}

// AccountAnalysisResult holds the result of account analysis.
type AccountAnalysisResult struct {
	Score   float64
	Factors []model.AnalysisFactor
}

// Analyze checks the community report database for the given accounts and returns a risk score.
func (s *AccountAnalysisService) Analyze(sessionID uint64, accounts []extractedAccountInfo) AccountAnalysisResult {
	if len(accounts) == 0 {
		return AccountAnalysisResult{Score: 0}
	}

	var factors []model.AnalysisFactor
	highestScore := 0.0

	for _, acc := range accounts {
		account, err := s.accountRepo.FindByTypeAndValue(acc.Type, acc.Value)
		if err != nil || account == nil {
			continue
		}

		if account.ReportCount == 0 {
			continue
		}

		// Base score from report count: min(log2(count+1)*15, 40)
		countScore := math.Min(math.Log2(float64(account.ReportCount)+1)*15, 40)

		// Existing risk score contribution (0-30)
		riskContribution := account.RiskScore * 0.3

		// Recency bonus (0-20)
		recencyBonus := 0.0
		if account.LastReportedAt != nil {
			daysSince := time.Since(*account.LastReportedAt).Hours() / 24
			switch {
			case daysSince <= 7:
				recencyBonus = 20
			case daysSince <= 30:
				recencyBonus = 15
			case daysSince <= 90:
				recencyBonus = 10
			case daysSince <= 365:
				recencyBonus = 5
			}
		}

		// Multi-type bonus (0-10)
		scamTypes, _ := s.reportRepo.CountByScamType(account.ID)
		typeBonus := math.Min(float64(scamTypes)*3, 10)

		accountScore := countScore + riskContribution + recencyBonus + typeBonus
		if accountScore > 100 {
			accountScore = 100
		}

		severity := "low"
		switch {
		case accountScore >= 70:
			severity = "critical"
		case accountScore >= 50:
			severity = "high"
		case accountScore >= 30:
			severity = "medium"
		}

		factors = append(factors, model.AnalysisFactor{
			SessionID:   sessionID,
			Category:    "account",
			FactorType:  "社区举报记录",
			FactorValue: acc.Type + ": " + acc.Value + " (举报" + itoa(int(account.ReportCount)) + "次)",
			ScoreImpact: accountScore,
			Severity:    severity,
		})

		if accountScore > highestScore {
			highestScore = accountScore
		}
	}

	return AccountAnalysisResult{
		Score:   highestScore,
		Factors: factors,
	}
}

// extractedAccountInfo is a simple struct for passing extracted account info between services.
type extractedAccountInfo struct {
	Type  string
	Value string
}

func itoa(n int) string {
	if n == 0 {
		return "0"
	}
	s := ""
	for n > 0 {
		s = string(rune('0'+n%10)) + s
		n /= 10
	}
	return s
}
