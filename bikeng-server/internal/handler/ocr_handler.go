package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"

	"github.com/nicksrepo/bikeng-server/internal/pkg/response"
	"github.com/nicksrepo/bikeng-server/internal/service"
)

// OCRHandler handles OCR-related HTTP requests.
type OCRHandler struct {
	ocrService *service.OCRService
}

// NewOCRHandler creates a new OCRHandler with the given OCR service.
func NewOCRHandler(ocrService *service.OCRService) *OCRHandler {
	return &OCRHandler{ocrService: ocrService}
}

// extractAccountsRequest is the JSON body for the OCR extract endpoint.
type extractAccountsRequest struct {
	ImageBase64 string `json:"image_base64" binding:"required"`
}

// ExtractAccounts handles POST /api/v1/ocr/extract.
// It runs OCR on the provided base64-encoded image and returns the recognized
// text along with extracted account identifiers.
func (h *OCRHandler) ExtractAccounts(c *gin.Context) {
	var req extractAccountsRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, http.StatusBadRequest, "invalid request: "+err.Error())
		return
	}

	ocrText, accounts, err := h.ocrService.ExtractAccountsFromImage(req.ImageBase64)
	if err != nil {
		response.Error(c, http.StatusInternalServerError, "OCR processing failed: "+err.Error())
		return
	}

	response.Success(c, gin.H{
		"ocr_text": ocrText,
		"accounts": accounts,
	})
}
