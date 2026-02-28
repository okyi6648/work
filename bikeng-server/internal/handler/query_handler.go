package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"

	"github.com/nicksrepo/bikeng-server/internal/pkg/response"
	"github.com/nicksrepo/bikeng-server/internal/service"
)

// QueryHandler handles account query HTTP requests.
type QueryHandler struct {
	queryService *service.QueryService
}

// NewQueryHandler creates a new QueryHandler with the given query service.
func NewQueryHandler(queryService *service.QueryService) *QueryHandler {
	return &QueryHandler{queryService: queryService}
}

// QueryAccount handles GET /api/v1/query.
// It queries a single account by type and value provided as query parameters.
func (h *QueryHandler) QueryAccount(c *gin.Context) {
	accountType := c.Query("account_type")
	accountValue := c.Query("account_value")

	if accountType == "" || accountValue == "" {
		response.Error(c, http.StatusBadRequest, "account_type and account_value are required")
		return
	}

	result, err := h.queryService.QueryAccount(accountType, accountValue)
	if err != nil {
		response.Error(c, http.StatusInternalServerError, "query failed: "+err.Error())
		return
	}

	response.Success(c, result)
}

// batchQueryRequest is the JSON body for the batch query endpoint.
type batchQueryRequest struct {
	Queries []service.QueryRequest `json:"queries" binding:"required"`
}

// QueryBatch handles GET /api/v1/query/batch.
// It queries multiple accounts in a single request.
func (h *QueryHandler) QueryBatch(c *gin.Context) {
	var req batchQueryRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, http.StatusBadRequest, "invalid request: "+err.Error())
		return
	}

	if len(req.Queries) == 0 {
		response.Error(c, http.StatusBadRequest, "queries list cannot be empty")
		return
	}

	results, err := h.queryService.QueryBatch(req.Queries)
	if err != nil {
		response.Error(c, http.StatusInternalServerError, "batch query failed: "+err.Error())
		return
	}

	response.Success(c, results)
}
