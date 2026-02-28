package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"

	"github.com/nicksrepo/bikeng-server/internal/pkg/response"
	"github.com/nicksrepo/bikeng-server/internal/repository"
	"github.com/nicksrepo/bikeng-server/internal/service"
)

// AdminHandler handles admin-specific HTTP requests.
type AdminHandler struct {
	reportService *service.ReportService
	appealService *service.AppealService
	accountRepo   *repository.AccountRepo
}

// NewAdminHandler creates a new AdminHandler with the required dependencies.
func NewAdminHandler(
	reportService *service.ReportService,
	appealService *service.AppealService,
	accountRepo *repository.AccountRepo,
) *AdminHandler {
	return &AdminHandler{
		reportService: reportService,
		appealService: appealService,
		accountRepo:   accountRepo,
	}
}

// reviewReportRequest is the JSON body for reviewing a report.
type reviewReportRequest struct {
	Approved     bool   `json:"approved"`
	RejectReason string `json:"reject_reason"`
}

// ReviewReport handles PUT /api/v1/admin/reports/:id/review.
// It allows an admin to approve or reject a pending report.
func (h *AdminHandler) ReviewReport(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		response.Error(c, http.StatusBadRequest, "invalid report ID")
		return
	}

	var req reviewReportRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, http.StatusBadRequest, "invalid request: "+err.Error())
		return
	}

	reviewerID := c.GetUint64("user_id")

	if err := h.reportService.ReviewReport(id, reviewerID, req.Approved, req.RejectReason); err != nil {
		response.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	response.Success(c, nil)
}

// reviewAppealRequest is the JSON body for reviewing an appeal.
type reviewAppealRequest struct {
	Accepted   bool   `json:"accepted"`
	ReviewNote string `json:"review_note"`
}

// ReviewAppeal handles PUT /api/v1/admin/appeals/:id/review.
// It allows an admin to accept or reject a pending appeal.
func (h *AdminHandler) ReviewAppeal(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		response.Error(c, http.StatusBadRequest, "invalid appeal ID")
		return
	}

	var req reviewAppealRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, http.StatusBadRequest, "invalid request: "+err.Error())
		return
	}

	reviewerID := c.GetUint64("user_id")

	if err := h.appealService.ReviewAppeal(id, reviewerID, req.Accepted, req.ReviewNote); err != nil {
		response.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	response.Success(c, nil)
}

// GetDashboard handles GET /api/v1/admin/dashboard.
// It returns basic dashboard statistics for the admin panel.
// TODO: Add actual database queries for real statistics.
func (h *AdminHandler) GetDashboard(c *gin.Context) {
	response.Success(c, gin.H{
		"total_reports":  0,
		"pending_reports": 0,
		"total_appeals":  0,
		"pending_appeals": 0,
		"total_accounts": 0,
		"total_users":    0,
	})
}
