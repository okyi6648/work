package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"

	"github.com/nicksrepo/bikeng-server/internal/pkg/response"
	"github.com/nicksrepo/bikeng-server/internal/service"
)

// AppealHandler handles appeal-related HTTP requests.
type AppealHandler struct {
	appealService *service.AppealService
}

// NewAppealHandler creates a new AppealHandler with the given appeal service.
func NewAppealHandler(appealService *service.AppealService) *AppealHandler {
	return &AppealHandler{appealService: appealService}
}

// SubmitAppeal handles POST /api/v1/appeals.
// It creates a new appeal for an account.
func (h *AppealHandler) SubmitAppeal(c *gin.Context) {
	var req service.SubmitAppealRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, http.StatusBadRequest, "invalid request: "+err.Error())
		return
	}

	appeal, err := h.appealService.SubmitAppeal(req)
	if err != nil {
		response.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	response.Created(c, appeal)
}

// GetAppealStatus handles GET /api/v1/appeals/:id.
// It retrieves the current status of an appeal.
func (h *AppealHandler) GetAppealStatus(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		response.Error(c, http.StatusBadRequest, "invalid appeal ID")
		return
	}

	appeal, err := h.appealService.GetAppealStatus(id)
	if err != nil {
		response.Error(c, http.StatusNotFound, err.Error())
		return
	}

	response.Success(c, appeal)
}
