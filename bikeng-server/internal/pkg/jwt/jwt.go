package jwt

import (
	"errors"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"github.com/nicksrepo/bikeng-server/internal/config"
)

// Claims represents the custom JWT claims used for authentication.
type Claims struct {
	jwt.RegisteredClaims
	UserID uint64 `json:"user_id"`
	Role   string `json:"role"`
}

// GenerateTokenPair creates an access token and a refresh token for the given user.
// The access token expires after 2 hours and the refresh token after 168 hours (7 days)
// by default, but these durations can be overridden through config.
func GenerateTokenPair(userID uint64, role string) (accessToken, refreshToken string, err error) {
	cfg := config.GetConfig()
	if cfg == nil {
		return "", "", errors.New("config not loaded")
	}

	secret := []byte(cfg.JWT.Secret)

	accessTTL := cfg.JWT.AccessTTL
	if accessTTL == 0 {
		accessTTL = 2 * time.Hour
	}
	refreshTTL := cfg.JWT.RefreshTTL
	if refreshTTL == 0 {
		refreshTTL = 168 * time.Hour
	}

	now := time.Now()

	// Generate access token.
	accessClaims := Claims{
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(now.Add(accessTTL)),
			IssuedAt:  jwt.NewNumericDate(now),
			Issuer:    "huoyanjinjing",
			ID:        uuid.New().String(),
		},
		UserID: userID,
		Role:   role,
	}
	accessToken, err = jwt.NewWithClaims(jwt.SigningMethodHS256, accessClaims).SignedString(secret)
	if err != nil {
		return "", "", err
	}

	// Generate refresh token.
	refreshClaims := Claims{
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(now.Add(refreshTTL)),
			IssuedAt:  jwt.NewNumericDate(now),
			Issuer:    "huoyanjinjing",
			ID:        uuid.New().String(),
		},
		UserID: userID,
		Role:   role,
	}
	refreshToken, err = jwt.NewWithClaims(jwt.SigningMethodHS256, refreshClaims).SignedString(secret)
	if err != nil {
		return "", "", err
	}

	return accessToken, refreshToken, nil
}

// ParseToken validates the given JWT token string and returns the parsed claims.
func ParseToken(tokenString string) (*Claims, error) {
	cfg := config.GetConfig()
	if cfg == nil {
		return nil, errors.New("config not loaded")
	}

	secret := []byte(cfg.JWT.Secret)

	token, err := jwt.ParseWithClaims(tokenString, &Claims{}, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, errors.New("unexpected signing method")
		}
		return secret, nil
	})
	if err != nil {
		return nil, err
	}

	claims, ok := token.Claims.(*Claims)
	if !ok || !token.Valid {
		return nil, errors.New("invalid token")
	}

	return claims, nil
}
