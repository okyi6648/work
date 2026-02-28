package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"

	"github.com/nicksrepo/bikeng-server/internal/pkg/response"
	"github.com/nicksrepo/bikeng-server/internal/service"
)

// AlertHandler handles alert/warning HTTP requests.
type AlertHandler struct {
	alertService *service.AlertService
}

// NewAlertHandler creates a new AlertHandler with the given alert service.
func NewAlertHandler(alertService *service.AlertService) *AlertHandler {
	return &AlertHandler{alertService: alertService}
}

// GetAlertList handles GET /api/v1/alerts.
// It returns a paginated list of alerts.
func (h *AlertHandler) GetAlertList(c *gin.Context) {
	page, pageSize := parsePagination(c)

	alerts, total, err := h.alertService.GetAlertList(page, pageSize)
	if err != nil {
		response.Error(c, http.StatusInternalServerError, "failed to get alerts: "+err.Error())
		return
	}

	response.Paginated(c, alerts, total, page, pageSize)
}

// GetLatestAlerts handles GET /api/v1/alerts/latest.
// It returns the most recent alerts up to the given limit (default 5).
func (h *AlertHandler) GetLatestAlerts(c *gin.Context) {
	limit := 5
	if l := c.Query("limit"); l != "" {
		if parsed, err := strconv.Atoi(l); err == nil && parsed > 0 {
			limit = parsed
		}
	}

	alerts, err := h.alertService.GetLatestAlerts(limit)
	if err != nil {
		response.Error(c, http.StatusInternalServerError, "failed to get latest alerts: "+err.Error())
		return
	}

	response.Success(c, alerts)
}

// createAlertRequest is the JSON body for creating a new alert.
type createAlertRequest struct {
	Title    string `json:"title" binding:"required"`
	Content  string `json:"content" binding:"required"`
	Severity string `json:"severity" binding:"required"`
}

// CreateAlert handles POST /api/v1/admin/alerts.
// It creates a new alert (admin only).
func (h *AlertHandler) CreateAlert(c *gin.Context) {
	var req createAlertRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, http.StatusBadRequest, "invalid request: "+err.Error())
		return
	}

	userID := c.GetUint64("user_id")

	alert, err := h.alertService.CreateAlert(userID, req.Title, req.Content, req.Severity)
	if err != nil {
		response.Error(c, http.StatusInternalServerError, "failed to create alert: "+err.Error())
		return
	}

	response.Created(c, alert)
}
