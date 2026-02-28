package service

import (
	"fmt"
	"strings"

	"github.com/nicksrepo/bikeng-server/internal/model"
	"github.com/nicksrepo/bikeng-server/internal/pkg/regex"
	"github.com/nicksrepo/bikeng-server/internal/repository"
)

// ComprehensiveAnalysisService orchestrates the full analysis pipeline.
type ComprehensiveAnalysisService struct {
	analysisRepo    *repository.AnalysisRepo
	chatService     *ChatAnalysisService
	accountService  *AccountAnalysisService
	transferService *TransferAnalysisService
	ocrService      *OCRService
}

// NewComprehensiveAnalysisService creates a new ComprehensiveAnalysisService.
func NewComprehensiveAnalysisService(
	analysisRepo *repository.AnalysisRepo,
	chatService *ChatAnalysisService,
	accountService *AccountAnalysisService,
	transferService *TransferAnalysisService,
	ocrService *OCRService,
) *ComprehensiveAnalysisService {
	return &ComprehensiveAnalysisService{
		analysisRepo:    analysisRepo,
		chatService:     chatService,
		accountService:  accountService,
		transferService: transferService,
		ocrService:      ocrService,
	}
}

// AnalysisRequest contains the data required to start a comprehensive analysis.
type AnalysisRequest struct {
	Images []AnalysisImageInput `json:"images" binding:"required,min=1"`
}

// AnalysisImageInput represents a single image in the analysis request.
type AnalysisImageInput struct {
	ImageURL  string `json:"image_url" binding:"required"`
	ImageType string `json:"image_type" binding:"required,oneof=chat account_info transfer"`
}

// AnalysisResponse contains the full result of a comprehensive analysis.
type AnalysisResponse struct {
	Session *model.AnalysisSession  `json:"session"`
	Images  []model.AnalysisImage   `json:"images"`
	Factors []model.AnalysisFactor  `json:"factors"`
}

// RunAnalysis executes the full comprehensive analysis pipeline.
func (s *ComprehensiveAnalysisService) RunAnalysis(userID uint64, req AnalysisRequest) (*AnalysisResponse, error) {
	// 1. Create session.
	session := &model.AnalysisSession{
		UserID: userID,
		Status: "processing",
	}
	if err := s.analysisRepo.CreateSession(session); err != nil {
		return nil, fmt.Errorf("failed to create analysis session: %w", err)
	}

	// 2. OCR each image and store.
	var chatTexts []string
	var transferTexts []string
	var allAccounts []extractedAccountInfo
	var images []model.AnalysisImage

	for _, img := range req.Images {
		ocrText, accounts, err := s.ocrService.ExtractAccountsFromImage(img.ImageURL)
		if err != nil {
			ocrText = ""
		}

		images = append(images, model.AnalysisImage{
			SessionID: session.ID,
			ImageURL:  img.ImageURL,
			ImageType: img.ImageType,
			OcrText:   ocrText,
		})

		// Collect extracted accounts.
		for _, acc := range accounts {
			allAccounts = append(allAccounts, extractedAccountInfo{
				Type:  acc.Type,
				Value: acc.Value,
			})
		}

		// Route text by image type.
		switch img.ImageType {
		case "chat":
			chatTexts = append(chatTexts, ocrText)
		case "transfer":
			transferTexts = append(transferTexts, ocrText)
		case "account_info":
			// Also extract accounts from account info screenshots.
			chatTexts = append(chatTexts, ocrText)
			extraAccounts := regex.ExtractAccounts(ocrText)
			for _, acc := range extraAccounts {
				allAccounts = append(allAccounts, extractedAccountInfo{
					Type:  acc.Type,
					Value: acc.Value,
				})
			}
		}
	}

	if err := s.analysisRepo.CreateImages(images); err != nil {
		return nil, fmt.Errorf("failed to save analysis images: %w", err)
	}

	// 3. Run sub-analyses.
	chatResult := s.chatService.Analyze(session.ID, chatTexts)
	accountResult := s.accountService.Analyze(session.ID, allAccounts)
	transferResult := s.transferService.Analyze(session.ID, transferTexts)

	// 4. Calculate weighted overall score.
	// Weights: chat 35%, account 25%, transfer 20%, community 20%
	// Community score = account score (from community report DB).
	communityScore := accountResult.Score
	overallScore := chatResult.Score*0.35 +
		accountResult.Score*0.25 +
		transferResult.Score*0.20 +
		communityScore*0.20

	if overallScore > 100 {
		overallScore = 100
	}

	// 5. Calculate confidence based on evidence coverage.
	confidence := calculateConfidence(req.Images, chatResult, transferResult, accountResult)

	// 6. Generate summary.
	summary := generateSummary(overallScore, chatResult.Score, accountResult.Score, transferResult.Score, communityScore, confidence)

	// 7. Collect all factors.
	var allFactors []model.AnalysisFactor
	allFactors = append(allFactors, chatResult.Factors...)
	allFactors = append(allFactors, accountResult.Factors...)
	allFactors = append(allFactors, transferResult.Factors...)

	if len(allFactors) > 0 {
		if err := s.analysisRepo.CreateFactors(allFactors); err != nil {
			return nil, fmt.Errorf("failed to save analysis factors: %w", err)
		}
	}

	// 8. Update session.
	session.Status = "completed"
	session.OverallScore = overallScore
	session.ChatScore = chatResult.Score
	session.AccountScore = accountResult.Score
	session.TransferScore = transferResult.Score
	session.CommunityScore = communityScore
	session.Confidence = confidence
	session.Summary = summary

	if err := s.analysisRepo.UpdateSession(session); err != nil {
		return nil, fmt.Errorf("failed to update analysis session: %w", err)
	}

	return &AnalysisResponse{
		Session: session,
		Images:  images,
		Factors: allFactors,
	}, nil
}

// GetAnalysisResult retrieves a completed analysis result by session ID.
func (s *ComprehensiveAnalysisService) GetAnalysisResult(sessionID uint64) (*AnalysisResponse, error) {
	session, err := s.analysisRepo.FindSessionByID(sessionID)
	if err != nil {
		return nil, fmt.Errorf("failed to find session: %w", err)
	}
	if session == nil {
		return nil, fmt.Errorf("分析记录不存在")
	}

	images, err := s.analysisRepo.FindImagesBySession(sessionID)
	if err != nil {
		return nil, fmt.Errorf("failed to find images: %w", err)
	}

	factors, err := s.analysisRepo.FindFactorsBySession(sessionID)
	if err != nil {
		return nil, fmt.Errorf("failed to find factors: %w", err)
	}

	return &AnalysisResponse{
		Session: session,
		Images:  images,
		Factors: factors,
	}, nil
}

// GetMyAnalyses retrieves paginated analysis history for a user.
func (s *ComprehensiveAnalysisService) GetMyAnalyses(userID uint64, page, pageSize int) ([]model.AnalysisSession, int64, error) {
	return s.analysisRepo.FindSessionsByUser(userID, page, pageSize)
}

func calculateConfidence(images []AnalysisImageInput, chat ChatAnalysisResult, transfer TransferAnalysisResult, account AccountAnalysisResult) float64 {
	confidence := 0.0

	// Type coverage bonus.
	typesSeen := make(map[string]bool)
	for _, img := range images {
		typesSeen[img.ImageType] = true
	}
	coverage := float64(len(typesSeen)) / 3.0
	confidence += coverage * 40

	// Evidence quantity bonus (more images = higher confidence, up to 30).
	imgCount := float64(len(images))
	if imgCount > 10 {
		imgCount = 10
	}
	confidence += (imgCount / 10.0) * 30

	// Factor density bonus (more matched factors = more confident, up to 30).
	factorCount := float64(len(chat.Factors) + len(transfer.Factors) + len(account.Factors))
	if factorCount > 10 {
		factorCount = 10
	}
	confidence += (factorCount / 10.0) * 30

	if confidence > 100 {
		confidence = 100
	}
	return confidence
}

func generateSummary(overall, chat, account, transfer, community, confidence float64) string {
	var parts []string

	riskLevel := "低"
	switch {
	case overall >= 70:
		riskLevel = "高"
	case overall >= 40:
		riskLevel = "中"
	}

	parts = append(parts, fmt.Sprintf("综合风险评级: %s风险 (%.0f分)", riskLevel, overall))

	if chat > 0 {
		parts = append(parts, fmt.Sprintf("聊天话术分析: %.0f分", chat))
	}
	if account > 0 {
		parts = append(parts, fmt.Sprintf("账号风险分析: %.0f分", account))
	}
	if transfer > 0 {
		parts = append(parts, fmt.Sprintf("转账行为分析: %.0f分", transfer))
	}
	if community > 0 {
		parts = append(parts, fmt.Sprintf("社区举报评分: %.0f分", community))
	}

	confidenceLevel := "低"
	switch {
	case confidence >= 70:
		confidenceLevel = "高"
	case confidence >= 40:
		confidenceLevel = "中"
	}
	parts = append(parts, fmt.Sprintf("分析置信度: %s (%.0f%%)", confidenceLevel, confidence))

	if overall >= 70 {
		parts = append(parts, "建议: 高度警惕，该交互存在较多诈骗特征，请勿轻信对方信息，避免转账。")
	} else if overall >= 40 {
		parts = append(parts, "建议: 存在一定风险特征，请保持警惕，核实对方身份后再做决定。")
	} else {
		parts = append(parts, "建议: 暂未发现明显诈骗特征，但仍建议保持基本警惕。")
	}

	return strings.Join(parts, "\n")
}
