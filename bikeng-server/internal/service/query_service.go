package service

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/nicksrepo/bikeng-server/internal/model"
	"github.com/nicksrepo/bikeng-server/internal/repository"
	"github.com/redis/go-redis/v9"
)

// QueryResult contains the full query result for a single account.
type QueryResult struct {
	Account       *model.Account  `json:"account"`
	ReportCount   uint            `json:"report_count"`
	RiskScore     float64         `json:"risk_score"`
	RiskLevel     string          `json:"risk_level"`
	RecentReports []model.Report  `json:"recent_reports"`
}

// QueryRequest represents a single account query in a batch request.
type QueryRequest struct {
	AccountType  string `json:"account_type" binding:"required"`
	AccountValue string `json:"account_value" binding:"required"`
}

// QueryService handles account queries with Redis caching.
type QueryService struct {
	accountRepo *repository.AccountRepo
	reportRepo  *repository.ReportRepo
	rdb         *redis.Client
}

// NewQueryService creates a new QueryService with the required dependencies.
func NewQueryService(
	accountRepo *repository.AccountRepo,
	reportRepo *repository.ReportRepo,
	rdb *redis.Client,
) *QueryService {
	return &QueryService{
		accountRepo: accountRepo,
		reportRepo:  reportRepo,
		rdb:         rdb,
	}
}

// QueryAccount queries a single account by type and value.
// Results are cached in Redis for 5 minutes to reduce database load.
func (s *QueryService) QueryAccount(accountType, accountValue string) (*QueryResult, error) {
	ctx := context.Background()
	cacheKey := fmt.Sprintf("query:cache:%s:%s", accountType, accountValue)

	// Try to get from cache first.
	cached, err := s.rdb.Get(ctx, cacheKey).Bytes()
	if err == nil {
		var result QueryResult
		if json.Unmarshal(cached, &result) == nil {
			return &result, nil
		}
	}

	// Cache miss: query from database.
	account, err := s.accountRepo.FindByTypeAndValue(accountType, accountValue)
	if err != nil {
		return nil, fmt.Errorf("failed to query account: %w", err)
	}

	// Account not found - return a safe result.
	if account == nil {
		result := &QueryResult{
			Account:       nil,
			ReportCount:   0,
			RiskScore:     0,
			RiskLevel:     riskLevel(0),
			RecentReports: []model.Report{},
		}
		// Cache the safe result too to prevent repeated DB lookups.
		if data, err := json.Marshal(result); err == nil {
			s.rdb.Set(ctx, cacheKey, data, 5*time.Minute)
		}
		return result, nil
	}

	// Get recent reports for this account.
	reports, err := s.reportRepo.FindByAccount(account.ID)
	if err != nil {
		return nil, fmt.Errorf("failed to get reports: %w", err)
	}

	// Limit to the 10 most recent reports for the response.
	recentReports := reports
	if len(recentReports) > 10 {
		recentReports = recentReports[:10]
	}

	result := &QueryResult{
		Account:       account,
		ReportCount:   account.ReportCount,
		RiskScore:     account.RiskScore,
		RiskLevel:     riskLevel(account.RiskScore),
		RecentReports: recentReports,
	}

	// Cache the result.
	if data, err := json.Marshal(result); err == nil {
		s.rdb.Set(ctx, cacheKey, data, 5*time.Minute)
	}

	return result, nil
}

// QueryBatch queries multiple accounts in one call.
func (s *QueryService) QueryBatch(queries []QueryRequest) ([]QueryResult, error) {
	results := make([]QueryResult, 0, len(queries))
	for _, q := range queries {
		result, err := s.QueryAccount(q.AccountType, q.AccountValue)
		if err != nil {
			return nil, fmt.Errorf("failed to query account %s:%s: %w", q.AccountType, q.AccountValue, err)
		}
		results = append(results, *result)
	}
	return results, nil
}

// riskLevel converts a numeric risk score to a human-readable level string.
func riskLevel(score float64) string {
	switch {
	case score == 0:
		return "safe"
	case score < 30:
		return "low"
	case score < 60:
		return "medium"
	default:
		return "high"
	}
}
