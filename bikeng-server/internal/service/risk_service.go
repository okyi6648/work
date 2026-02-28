package service

import (
	"fmt"
	"log"
	"math"
	"time"

	"github.com/nicksrepo/bikeng-server/internal/repository"
)

// RiskService handles risk score calculation for reported accounts.
type RiskService struct {
	accountRepo *repository.AccountRepo
	reportRepo  *repository.ReportRepo
}

// NewRiskService creates a new RiskService with the required dependencies.
func NewRiskService(
	accountRepo *repository.AccountRepo,
	reportRepo *repository.ReportRepo,
) *RiskService {
	return &RiskService{
		accountRepo: accountRepo,
		reportRepo:  reportRepo,
	}
}

// CalculateRiskScore computes the risk score for the given account using
// a weighted multi-factor algorithm:
//   - Count score (30%): min(log2(report_count+1)*10, 30)
//   - Amount score (25%): tiered by total loss amount
//   - Reporter score (20%): min(unique_reporters*5, 20)
//   - Recency score (15%): based on last_reported_at
//   - Diversity score (10%): min(scam_type_count*3, 10)
//
// If the account has an accepted appeal, the final score is halved.
// The returned score is capped at 100.
func (s *RiskService) CalculateRiskScore(accountID uint64) (float64, error) {
	account, err := s.accountRepo.FindByID(accountID)
	if err != nil {
		return 0, fmt.Errorf("failed to find account: %w", err)
	}
	if account == nil {
		return 0, fmt.Errorf("account %d not found", accountID)
	}

	// 1. Count score (30% weight): min(log2(report_count+1)*10, 30)
	countScore := math.Min(math.Log2(float64(account.ReportCount)+1)*10, 30)

	// 2. Amount score (25% weight): tiered by total loss amount
	amountScore := calculateAmountScore(account.TotalAmount)

	// 3. Reporter score (20% weight): min(unique_reporters*5, 20)
	uniqueReporters, err := s.reportRepo.CountUniqueReporters(accountID)
	if err != nil {
		return 0, fmt.Errorf("failed to count unique reporters: %w", err)
	}
	reporterScore := math.Min(float64(uniqueReporters)*5, 20)

	// 4. Recency score (15% weight): based on last_reported_at
	recencyScore := calculateRecencyScore(account.LastReportedAt)

	// 5. Diversity score (10% weight): min(scam_type_count*3, 10)
	scamTypeCount, err := s.reportRepo.CountByScamType(accountID)
	if err != nil {
		return 0, fmt.Errorf("failed to count scam types: %w", err)
	}
	diversityScore := math.Min(float64(scamTypeCount)*3, 10)

	// Sum all weighted scores.
	totalScore := countScore + amountScore + reporterScore + recencyScore + diversityScore

	// If appeal accepted, reduce score by 50%.
	if account.AppealStatus == "accepted" {
		totalScore *= 0.5
	}

	// Cap at 100.
	totalScore = math.Min(totalScore, 100)

	return totalScore, nil
}

// RecalculateAll recalculates risk scores for all accounts that have reports.
// It processes accounts in batches to avoid memory issues.
func (s *RiskService) RecalculateAll() error {
	batchSize := 100
	offset := 0

	for {
		accounts, err := s.accountRepo.GetAllWithReports(batchSize, offset)
		if err != nil {
			return fmt.Errorf("failed to get accounts batch at offset %d: %w", offset, err)
		}
		if len(accounts) == 0 {
			break
		}

		for _, account := range accounts {
			score, err := s.CalculateRiskScore(account.ID)
			if err != nil {
				log.Printf("failed to recalculate risk for account %d: %v", account.ID, err)
				continue
			}
			if err := s.accountRepo.UpdateRiskScore(account.ID, score); err != nil {
				log.Printf("failed to update risk score for account %d: %v", account.ID, err)
				continue
			}
		}

		offset += batchSize
	}

	return nil
}

// calculateAmountScore returns the amount tier score based on the total loss amount.
// Tiers: <100 => 5, 100-1000 => 12.5, 1000-10000 => 18.75, 10000+ => 22.5
// Maximum contribution is 25 (the weight for the amount factor).
func calculateAmountScore(totalAmount float64) float64 {
	switch {
	case totalAmount >= 10000:
		return 25
	case totalAmount >= 1000:
		return 18.75
	case totalAmount >= 100:
		return 12.5
	case totalAmount > 0:
		return 5
	default:
		return 0
	}
}

// calculateRecencyScore returns a score based on how recently the account was reported.
// Within 7 days: 15, 30 days: 12, 90 days: 9, 1 year: 4.5, older: 0.
func calculateRecencyScore(lastReportedAt *time.Time) float64 {
	if lastReportedAt == nil {
		return 0
	}

	daysSince := time.Since(*lastReportedAt).Hours() / 24

	switch {
	case daysSince <= 7:
		return 15
	case daysSince <= 30:
		return 12
	case daysSince <= 90:
		return 9
	case daysSince <= 365:
		return 4.5
	default:
		return 0
	}
}
