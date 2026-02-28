package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"

	"github.com/nicksrepo/bikeng-server/internal/pkg/response"
	"github.com/nicksrepo/bikeng-server/internal/service"
)

// AnalysisHandler handles analysis-related HTTP requests.
type AnalysisHandler struct {
	analysisService *service.ComprehensiveAnalysisService
}

// NewAnalysisHandler creates a new AnalysisHandler with the given analysis service.
func NewAnalysisHandler(analysisService *service.ComprehensiveAnalysisService) *AnalysisHandler {
	return &AnalysisHandler{analysisService: analysisService}
}

// SubmitAnalysis handles POST /api/v1/analysis/comprehensive.
// It accepts image URLs with types and runs the comprehensive analysis pipeline.
func (h *AnalysisHandler) SubmitAnalysis(c *gin.Context) {
	var req service.AnalysisRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, http.StatusBadRequest, "invalid request: "+err.Error())
		return
	}

	userID := c.GetUint64("user_id")

	result, err := h.analysisService.RunAnalysis(userID, req)
	if err != nil {
		response.Error(c, http.StatusInternalServerError, "analysis failed: "+err.Error())
		return
	}

	response.Created(c, result)
}

// GetAnalysisResult handles GET /api/v1/analysis/:id.
// It returns the full analysis result for a given session ID.
func (h *AnalysisHandler) GetAnalysisResult(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		response.Error(c, http.StatusBadRequest, "invalid analysis ID")
		return
	}

	result, err := h.analysisService.GetAnalysisResult(id)
	if err != nil {
		response.Error(c, http.StatusNotFound, err.Error())
		return
	}

	response.Success(c, result)
}

// GetMyAnalyses handles GET /api/v1/analysis/mine.
// It returns a paginated list of analysis sessions for the authenticated user.
func (h *AnalysisHandler) GetMyAnalyses(c *gin.Context) {
	userID := c.GetUint64("user_id")
	page, pageSize := parsePagination(c)

	sessions, total, err := h.analysisService.GetMyAnalyses(userID, page, pageSize)
	if err != nil {
		response.Error(c, http.StatusInternalServerError, "failed to get analyses: "+err.Error())
		return
	}

	response.Paginated(c, sessions, total, page, pageSize)
}
