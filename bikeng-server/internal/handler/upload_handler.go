package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"

	"github.com/nicksrepo/bikeng-server/internal/pkg/response"
	"github.com/nicksrepo/bikeng-server/internal/service"
)

// UploadHandler handles file upload HTTP requests.
type UploadHandler struct {
	ossService *service.OSSService
}

// NewUploadHandler creates a new UploadHandler with the given OSS service.
func NewUploadHandler(ossService *service.OSSService) *UploadHandler {
	return &UploadHandler{ossService: ossService}
}

// getPresignedURLRequest is the JSON body for the presigned URL endpoint.
type getPresignedURLRequest struct {
	FileExt string `json:"file_ext" binding:"required"`
}

// GetPresignedURL handles POST /api/v1/upload/presign.
// It generates a presigned upload URL for the client to upload a file directly
// to object storage.
func (h *UploadHandler) GetPresignedURL(c *gin.Context) {
	var req getPresignedURLRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, http.StatusBadRequest, "invalid request: "+err.Error())
		return
	}

	result, err := h.ossService.GetPresignedUploadURL(req.FileExt)
	if err != nil {
		response.Error(c, http.StatusInternalServerError, "failed to generate presigned URL: "+err.Error())
		return
	}

	response.Success(c, result)
}
