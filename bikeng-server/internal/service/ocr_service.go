package service

import (
	"fmt"

	"github.com/nicksrepo/bikeng-server/internal/pkg/ocr"
	"github.com/nicksrepo/bikeng-server/internal/pkg/regex"
)

// OCRService handles OCR processing and account extraction from images.
type OCRService struct {
	ocrClient *ocr.OCRClient
}

// NewOCRService creates a new OCRService with the given OCR client.
func NewOCRService(ocrClient *ocr.OCRClient) *OCRService {
	return &OCRService{
		ocrClient: ocrClient,
	}
}

// ExtractAccountsFromImage runs OCR on the base64-encoded image, then extracts
// account identifiers (QQ, WeChat, phone, Alipay) from the recognized text.
// Returns the raw OCR text, extracted accounts, and any error.
func (s *OCRService) ExtractAccountsFromImage(imageBase64 string) (ocrText string, accounts []regex.ExtractedAccount, err error) {
	ocrText, err = s.ocrClient.RecognizeText(imageBase64)
	if err != nil {
		return "", nil, fmt.Errorf("OCR recognition failed: %w", err)
	}

	accounts = regex.ExtractAccounts(ocrText)

	return ocrText, accounts, nil
}
