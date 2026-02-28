package service

import (
	"fmt"
	"regexp"
	"strconv"
	"strings"

	"github.com/nicksrepo/bikeng-server/internal/model"
)

// TransferAnalysisService analyzes transfer records from OCR text.
type TransferAnalysisService struct{}

// NewTransferAnalysisService creates a new TransferAnalysisService.
func NewTransferAnalysisService() *TransferAnalysisService {
	return &TransferAnalysisService{}
}

// TransferAnalysisResult holds the result of transfer analysis.
type TransferAnalysisResult struct {
	Score   float64
	Factors []model.AnalysisFactor
}

var (
	// amountPattern matches Chinese transfer/payment amounts.
	amountPattern = regexp.MustCompile(`(?:转账|付款|金额|收款|支付|转出|汇款|打款)\s*[:：]?\s*(?:¥|￥|CNY)?\s*(\d+(?:\.\d{1,2})?)`)

	// genericAmountPattern matches standalone monetary amounts.
	genericAmountPattern = regexp.MustCompile(`[¥￥]\s*(\d+(?:\.\d{1,2})?)`)
)

// Analyze processes OCR text from transfer screenshots and returns a risk score.
func (s *TransferAnalysisService) Analyze(sessionID uint64, ocrTexts []string) TransferAnalysisResult {
	combined := strings.Join(ocrTexts, "\n")

	var amounts []float64

	// Extract amounts from transfer keywords.
	for _, match := range amountPattern.FindAllStringSubmatch(combined, -1) {
		if val, err := strconv.ParseFloat(match[1], 64); err == nil && val > 0 {
			amounts = append(amounts, val)
		}
	}

	// Extract amounts from currency symbols.
	for _, match := range genericAmountPattern.FindAllStringSubmatch(combined, -1) {
		if val, err := strconv.ParseFloat(match[1], 64); err == nil && val > 0 {
			amounts = append(amounts, val)
		}
	}

	// Deduplicate amounts (same value appearing from both patterns).
	amounts = dedup(amounts)

	if len(amounts) == 0 {
		return TransferAnalysisResult{Score: 0}
	}

	var factors []model.AnalysisFactor
	totalScore := 0.0

	// Score each amount by tier.
	maxAmount := 0.0
	totalAmount := 0.0
	for _, amt := range amounts {
		totalAmount += amt
		if amt > maxAmount {
			maxAmount = amt
		}
	}

	// Single largest amount scoring (0-40).
	amountScore := 0.0
	switch {
	case maxAmount >= 10000:
		amountScore = 40
	case maxAmount >= 5000:
		amountScore = 30
	case maxAmount >= 1000:
		amountScore = 20
	default:
		amountScore = 10
	}
	totalScore += amountScore

	severity := "low"
	switch {
	case maxAmount >= 10000:
		severity = "critical"
	case maxAmount >= 5000:
		severity = "high"
	case maxAmount >= 1000:
		severity = "medium"
	}

	factors = append(factors, model.AnalysisFactor{
		SessionID:   sessionID,
		Category:    "transfer",
		FactorType:  "转账金额",
		FactorValue: fmt.Sprintf("最大单笔: ¥%.2f, 总计: ¥%.2f", maxAmount, totalAmount),
		ScoreImpact: amountScore,
		Severity:    severity,
	})

	// Multiple transfer pattern detection (0-30).
	if len(amounts) >= 2 {
		multiScore := 0.0
		patternDesc := ""

		// Check for escalation pattern: small amounts followed by large.
		hasSmall := false
		hasLarge := false
		for _, amt := range amounts {
			if amt < 1000 {
				hasSmall = true
			}
			if amt >= 5000 {
				hasLarge = true
			}
		}

		if hasSmall && hasLarge {
			multiScore = 30
			patternDesc = "试探性小额后大额转账模式"
		} else if len(amounts) >= 3 {
			multiScore = 20
			patternDesc = fmt.Sprintf("多次转账(%d次)", len(amounts))
		} else {
			multiScore = 10
			patternDesc = "多次转账记录"
		}

		totalScore += multiScore

		mSeverity := "medium"
		if multiScore >= 25 {
			mSeverity = "high"
		}

		factors = append(factors, model.AnalysisFactor{
			SessionID:   sessionID,
			Category:    "transfer",
			FactorType:  "转账模式",
			FactorValue: patternDesc,
			ScoreImpact: multiScore,
			Severity:    mSeverity,
		})
	}

	// Total amount scoring (0-30).
	totalAmtScore := 0.0
	switch {
	case totalAmount >= 50000:
		totalAmtScore = 30
	case totalAmount >= 20000:
		totalAmtScore = 25
	case totalAmount >= 10000:
		totalAmtScore = 20
	case totalAmount >= 5000:
		totalAmtScore = 15
	case totalAmount >= 1000:
		totalAmtScore = 10
	default:
		totalAmtScore = 5
	}
	totalScore += totalAmtScore

	// Normalize to 0-100.
	if totalScore > 100 {
		totalScore = 100
	}

	return TransferAnalysisResult{
		Score:   totalScore,
		Factors: factors,
	}
}

func dedup(amounts []float64) []float64 {
	seen := make(map[string]struct{})
	var result []float64
	for _, a := range amounts {
		key := fmt.Sprintf("%.2f", a)
		if _, exists := seen[key]; !exists {
			seen[key] = struct{}{}
			result = append(result, a)
		}
	}
	return result
}
