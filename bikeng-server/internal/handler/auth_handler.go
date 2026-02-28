package handler

import (
	"net/http"
	"regexp"
	"strings"

	"github.com/gin-gonic/gin"

	jwtpkg "github.com/nicksrepo/bikeng-server/internal/pkg/jwt"
	"github.com/nicksrepo/bikeng-server/internal/pkg/response"
	"github.com/nicksrepo/bikeng-server/internal/service"
)

// phoneRegex validates Chinese mobile phone numbers.
var phoneRegex = regexp.MustCompile(`^1[3-9]\d{9}$`)

// AuthHandler handles authentication-related HTTP requests.
type AuthHandler struct {
	authService *service.AuthService
}

// NewAuthHandler creates a new AuthHandler with the given auth service.
func NewAuthHandler(authService *service.AuthService) *AuthHandler {
	return &AuthHandler{authService: authService}
}

// sendSmsCodeRequest is the JSON body for the SMS send endpoint.
type sendSmsCodeRequest struct {
	Phone   string `json:"phone" binding:"required"`
	Purpose string `json:"purpose" binding:"required"`
}

// SendSmsCode handles POST /api/v1/auth/sms/send.
// It validates the phone number format and delegates to the auth service.
func (h *AuthHandler) SendSmsCode(c *gin.Context) {
	var req sendSmsCodeRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, http.StatusBadRequest, "invalid request: "+err.Error())
		return
	}

	if !phoneRegex.MatchString(req.Phone) {
		response.Error(c, http.StatusBadRequest, "invalid phone number format")
		return
	}

	if err := h.authService.SendSmsCode(req.Phone, req.Purpose); err != nil {
		response.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	response.Success(c, nil)
}

// verifySmsCodeRequest is the JSON body for the SMS verify endpoint.
type verifySmsCodeRequest struct {
	Phone string `json:"phone" binding:"required"`
	Code  string `json:"code" binding:"required"`
}

// VerifySmsCode handles POST /api/v1/auth/sms/verify.
// On success it returns access and refresh tokens.
func (h *AuthHandler) VerifySmsCode(c *gin.Context) {
	var req verifySmsCodeRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, http.StatusBadRequest, "invalid request: "+err.Error())
		return
	}

	accessToken, refreshToken, err := h.authService.VerifySmsCode(req.Phone, req.Code)
	if err != nil {
		response.Error(c, http.StatusUnauthorized, err.Error())
		return
	}

	response.Success(c, gin.H{
		"access_token":  accessToken,
		"refresh_token": refreshToken,
	})
}

// refreshTokenRequest is the JSON body for the token refresh endpoint.
type refreshTokenRequest struct {
	RefreshToken string `json:"refresh_token" binding:"required"`
}

// RefreshToken handles POST /api/v1/auth/refresh.
// It exchanges a valid refresh token for a new token pair.
func (h *AuthHandler) RefreshToken(c *gin.Context) {
	var req refreshTokenRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, http.StatusBadRequest, "invalid request: "+err.Error())
		return
	}

	accessToken, refreshToken, err := h.authService.RefreshToken(req.RefreshToken)
	if err != nil {
		response.Error(c, http.StatusUnauthorized, err.Error())
		return
	}

	response.Success(c, gin.H{
		"access_token":  accessToken,
		"refresh_token": refreshToken,
	})
}

// Logout handles POST /api/v1/auth/logout.
// It parses the Authorization header to extract the token's JTI and expiry,
// then blacklists the token via the auth service.
func (h *AuthHandler) Logout(c *gin.Context) {
	authHeader := c.GetHeader("Authorization")
	if authHeader == "" {
		response.Error(c, http.StatusBadRequest, "authorization header is required")
		return
	}

	parts := strings.SplitN(authHeader, " ", 2)
	if len(parts) != 2 || !strings.EqualFold(parts[0], "Bearer") {
		response.Error(c, http.StatusBadRequest, "invalid authorization header format")
		return
	}

	claims, err := jwtpkg.ParseToken(parts[1])
	if err != nil {
		response.Error(c, http.StatusBadRequest, "invalid token: "+err.Error())
		return
	}

	if claims.ExpiresAt == nil {
		response.Error(c, http.StatusBadRequest, "token has no expiry")
		return
	}

	if err := h.authService.Logout(claims.ID, claims.ExpiresAt.Time); err != nil {
		response.Error(c, http.StatusInternalServerError, "failed to logout: "+err.Error())
		return
	}

	response.Success(c, nil)
}
