package service

import (
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/nicksrepo/bikeng-server/internal/pkg/oss"
)

// PresignResult contains the result of a presigned upload URL generation.
type PresignResult struct {
	UploadURL string `json:"upload_url"`
	PublicURL string `json:"public_url"`
	ObjectKey string `json:"object_key"`
}

// OSSService handles object storage operations including presigned URL generation.
type OSSService struct {
	ossClient *oss.OSSClient
}

// NewOSSService creates a new OSSService with the given OSS client.
func NewOSSService(ossClient *oss.OSSClient) *OSSService {
	return &OSSService{
		ossClient: ossClient,
	}
}

// GetPresignedUploadURL generates a presigned PUT URL for direct client upload to OSS.
// The object key follows the pattern: uploads/YYYY/MM/uuid.ext
// The presigned URL is valid for 600 seconds (10 minutes).
func (s *OSSService) GetPresignedUploadURL(fileExt string) (*PresignResult, error) {
	// Ensure the extension starts with a dot.
	if !strings.HasPrefix(fileExt, ".") {
		fileExt = "." + fileExt
	}

	// Generate a unique object key using the current date and a UUID.
	now := time.Now()
	objectKey := fmt.Sprintf("uploads/%04d/%02d/%s%s",
		now.Year(), now.Month(), uuid.New().String(), fileExt)

	// Generate the presigned upload URL (valid for 10 minutes).
	uploadURL, err := s.ossClient.GeneratePresignedURL(objectKey, 600)
	if err != nil {
		return nil, fmt.Errorf("failed to generate presigned URL: %w", err)
	}

	// Build the public access URL.
	publicURL := s.ossClient.GetPublicURL(objectKey)

	return &PresignResult{
		UploadURL: uploadURL,
		PublicURL: publicURL,
		ObjectKey: objectKey,
	}, nil
}
