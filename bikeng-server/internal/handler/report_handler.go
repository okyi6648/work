package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"

	"github.com/nicksrepo/bikeng-server/internal/pkg/response"
	"github.com/nicksrepo/bikeng-server/internal/service"
)

// ReportHandler handles report-related HTTP requests.
type ReportHandler struct {
	reportService *service.ReportService
}

// NewReportHandler creates a new ReportHandler with the given report service.
func NewReportHandler(reportService *service.ReportService) *ReportHandler {
	return &ReportHandler{reportService: reportService}
}

// SubmitReport handles POST /api/v1/reports.
// It parses the report submission request and creates a new report.
func (h *ReportHandler) SubmitReport(c *gin.Context) {
	var req service.SubmitReportRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, http.StatusBadRequest, "invalid request: "+err.Error())
		return
	}

	userID := c.GetUint64("user_id")

	report, err := h.reportService.SubmitReport(userID, req)
	if err != nil {
		response.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	response.Created(c, report)
}

// GetMyReports handles GET /api/v1/reports/mine.
// It returns a paginated list of reports submitted by the authenticated user.
func (h *ReportHandler) GetMyReports(c *gin.Context) {
	userID := c.GetUint64("user_id")
	page, pageSize := parsePagination(c)

	reports, total, err := h.reportService.GetMyReports(userID, page, pageSize)
	if err != nil {
		response.Error(c, http.StatusInternalServerError, "failed to get reports: "+err.Error())
		return
	}

	response.Paginated(c, reports, total, page, pageSize)
}

// GetReportDetail handles GET /api/v1/reports/:id.
// It returns a report along with its associated evidence.
func (h *ReportHandler) GetReportDetail(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		response.Error(c, http.StatusBadRequest, "invalid report ID")
		return
	}

	report, evidences, err := h.reportService.GetReportDetail(id)
	if err != nil {
		response.Error(c, http.StatusNotFound, err.Error())
		return
	}

	response.Success(c, gin.H{
		"report":    report,
		"evidences": evidences,
	})
}
