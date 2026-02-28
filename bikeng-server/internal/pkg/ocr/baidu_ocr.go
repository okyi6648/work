package ocr

import (
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"
	"sync"
	"time"

	"github.com/nicksrepo/bikeng-server/internal/config"
)

// OCRClient provides access to the Baidu OCR API for text recognition.
type OCRClient struct {
	apiKey      string
	secretKey   string
	accessToken string
	tokenExpiry time.Time
	mu          sync.Mutex
	httpClient  *http.Client
}

// tokenResponse represents the response from Baidu's OAuth token endpoint.
type tokenResponse struct {
	AccessToken string `json:"access_token"`
	ExpiresIn   int    `json:"expires_in"`
	Error       string `json:"error,omitempty"`
	ErrorDesc   string `json:"error_description,omitempty"`
}

// ocrResponse represents the response from Baidu's general OCR endpoint.
type ocrResponse struct {
	WordsResult []struct {
		Words string `json:"words"`
	} `json:"words_result"`
	ErrorCode int    `json:"error_code,omitempty"`
	ErrorMsg  string `json:"error_msg,omitempty"`
}

// NewOCRClient creates a new OCRClient from the given OCR configuration.
func NewOCRClient(cfg config.OCRConfig) *OCRClient {
	return &OCRClient{
		apiKey:    cfg.Baidu.APIKey,
		secretKey: cfg.Baidu.SecretKey,
		httpClient: &http.Client{
			Timeout: 30 * time.Second,
		},
	}
}

// getAccessToken retrieves and caches a Baidu OAuth access token using
// the client_credentials grant type.
func (c *OCRClient) getAccessToken() (string, error) {
	c.mu.Lock()
	defer c.mu.Unlock()

	// Return cached token if still valid (with a 5-minute safety margin).
	if c.accessToken != "" && time.Now().Before(c.tokenExpiry.Add(-5*time.Minute)) {
		return c.accessToken, nil
	}

	tokenURL := fmt.Sprintf(
		"https://aip.baidubce.com/oauth/2.0/token?grant_type=client_credentials&client_id=%s&client_secret=%s",
		url.QueryEscape(c.apiKey),
		url.QueryEscape(c.secretKey),
	)

	resp, err := c.httpClient.Post(tokenURL, "application/x-www-form-urlencoded", nil)
	if err != nil {
		return "", fmt.Errorf("failed to request access token: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", fmt.Errorf("failed to read token response: %w", err)
	}

	var tokenResp tokenResponse
	if err := json.Unmarshal(body, &tokenResp); err != nil {
		return "", fmt.Errorf("failed to parse token response: %w", err)
	}

	if tokenResp.Error != "" {
		return "", fmt.Errorf("token error: %s - %s", tokenResp.Error, tokenResp.ErrorDesc)
	}

	if tokenResp.AccessToken == "" {
		return "", errors.New("empty access token in response")
	}

	c.accessToken = tokenResp.AccessToken
	c.tokenExpiry = time.Now().Add(time.Duration(tokenResp.ExpiresIn) * time.Second)

	return c.accessToken, nil
}

// RecognizeText sends a base64-encoded image to the Baidu general OCR API
// and returns the concatenated recognized text.
func (c *OCRClient) RecognizeText(imageBase64 string) (string, error) {
	token, err := c.getAccessToken()
	if err != nil {
		return "", fmt.Errorf("failed to get access token: %w", err)
	}

	ocrURL := fmt.Sprintf(
		"https://aip.baidubce.com/rest/2.0/ocr/v1/general_basic?access_token=%s",
		url.QueryEscape(token),
	)

	formData := url.Values{}
	formData.Set("image", imageBase64)

	resp, err := c.httpClient.Post(ocrURL, "application/x-www-form-urlencoded", strings.NewReader(formData.Encode()))
	if err != nil {
		return "", fmt.Errorf("failed to call OCR API: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", fmt.Errorf("failed to read OCR response: %w", err)
	}

	var ocrResp ocrResponse
	if err := json.Unmarshal(body, &ocrResp); err != nil {
		return "", fmt.Errorf("failed to parse OCR response: %w", err)
	}

	if ocrResp.ErrorCode != 0 {
		return "", fmt.Errorf("OCR error %d: %s", ocrResp.ErrorCode, ocrResp.ErrorMsg)
	}

	var lines []string
	for _, item := range ocrResp.WordsResult {
		lines = append(lines, item.Words)
	}

	return strings.Join(lines, "\n"), nil
}
