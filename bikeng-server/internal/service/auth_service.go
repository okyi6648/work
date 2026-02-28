package service

import (
	"context"
	"crypto/rand"
	"errors"
	"fmt"
	"math/big"
	"time"

	"github.com/nicksrepo/bikeng-server/internal/model"
	jwtpkg "github.com/nicksrepo/bikeng-server/internal/pkg/jwt"
	"github.com/nicksrepo/bikeng-server/internal/pkg/sms"
	"github.com/nicksrepo/bikeng-server/internal/repository"
	"github.com/redis/go-redis/v9"
)

// AuthService handles authentication operations including SMS-based login,
// token management, and logout.
type AuthService struct {
	userRepo    *repository.UserRepo
	smsCodeRepo *repository.SmsCodeRepo
	smsClient   *sms.SMSClient
	rdb         *redis.Client
}

// NewAuthService creates a new AuthService with the required dependencies.
func NewAuthService(
	userRepo *repository.UserRepo,
	smsCodeRepo *repository.SmsCodeRepo,
	smsClient *sms.SMSClient,
	rdb *redis.Client,
) *AuthService {
	return &AuthService{
		userRepo:    userRepo,
		smsCodeRepo: smsCodeRepo,
		smsClient:   smsClient,
		rdb:         rdb,
	}
}

// SendSmsCode generates a 6-digit verification code and sends it to the given phone.
// It enforces rate limiting: at most one code per 60 seconds and 10 codes per day.
func (s *AuthService) SendSmsCode(phone, purpose string) error {
	ctx := context.Background()

	// Check per-minute rate limit.
	limitKey := fmt.Sprintf("sms:limit:%s", phone)
	exists, err := s.rdb.Exists(ctx, limitKey).Result()
	if err != nil {
		return fmt.Errorf("failed to check rate limit: %w", err)
	}
	if exists > 0 {
		return errors.New("请等待60秒后再获取验证码")
	}

	// Check daily rate limit.
	dailyKey := fmt.Sprintf("sms:daily:%s", phone)
	dailyCount, err := s.rdb.Get(ctx, dailyKey).Int()
	if err != nil && !errors.Is(err, redis.Nil) {
		return fmt.Errorf("failed to check daily limit: %w", err)
	}
	if dailyCount >= 10 {
		return errors.New("今日验证码发送次数已达上限")
	}

	// Generate a 6-digit verification code using crypto/rand.
	code, err := generateCode(6)
	if err != nil {
		return fmt.Errorf("failed to generate code: %w", err)
	}

	// Save the code to the database.
	smsCode := &model.SmsCode{
		Phone:     phone,
		Code:      code,
		Purpose:   purpose,
		IsUsed:    false,
		ExpiresAt: time.Now().Add(5 * time.Minute),
	}
	if err := s.smsCodeRepo.Create(smsCode); err != nil {
		return fmt.Errorf("failed to save sms code: %w", err)
	}

	// Send the SMS.
	if err := s.smsClient.SendCode(phone, code); err != nil {
		return fmt.Errorf("failed to send sms: %w", err)
	}

	// Set rate limit keys in Redis.
	s.rdb.Set(ctx, limitKey, 1, 60*time.Second)

	// Increment daily counter. If this is the first code today, set the key to expire at end of day.
	pipe := s.rdb.Pipeline()
	pipe.Incr(ctx, dailyKey)
	// Set TTL only if the key is new (TTL returns -2 for non-existent keys).
	ttl, _ := s.rdb.TTL(ctx, dailyKey).Result()
	if ttl < 0 {
		// Calculate seconds until midnight.
		now := time.Now()
		endOfDay := time.Date(now.Year(), now.Month(), now.Day()+1, 0, 0, 0, 0, now.Location())
		pipe.Expire(ctx, dailyKey, endOfDay.Sub(now))
	}
	if _, err := pipe.Exec(ctx); err != nil {
		// Non-fatal: the code was already sent successfully.
		return nil
	}

	return nil
}

// VerifySmsCode verifies the given SMS code for the phone number.
// On success it finds or creates a user account and returns a JWT token pair.
func (s *AuthService) VerifySmsCode(phone, code string) (accessToken, refreshToken string, err error) {
	// Find the latest valid code for this phone.
	smsCode, err := s.smsCodeRepo.FindLatestValid(phone, "login")
	if err != nil {
		return "", "", fmt.Errorf("failed to find sms code: %w", err)
	}
	if smsCode == nil {
		return "", "", errors.New("验证码不存在或已过期")
	}

	// Verify the code matches.
	if smsCode.Code != code {
		return "", "", errors.New("验证码错误")
	}

	// Mark the code as used.
	if err := s.smsCodeRepo.MarkUsed(smsCode.ID); err != nil {
		return "", "", fmt.Errorf("failed to mark code as used: %w", err)
	}

	// Find or create the user by phone number.
	user, err := s.userRepo.FindByPhone(phone)
	if err != nil {
		return "", "", fmt.Errorf("failed to find user: %w", err)
	}
	if user == nil {
		// Create a new user with a default nickname derived from phone.
		user = &model.User{
			Phone:    phone,
			Nickname: "用户" + phone[len(phone)-4:],
			Role:     "user",
			Status:   "active",
		}
		if err := s.userRepo.Create(user); err != nil {
			return "", "", fmt.Errorf("failed to create user: %w", err)
		}
	}

	// Update last login time.
	if err := s.userRepo.UpdateLastLogin(user.ID); err != nil {
		return "", "", fmt.Errorf("failed to update last login: %w", err)
	}

	// Generate JWT token pair.
	accessToken, refreshToken, err = jwtpkg.GenerateTokenPair(user.ID, user.Role)
	if err != nil {
		return "", "", fmt.Errorf("failed to generate tokens: %w", err)
	}

	return accessToken, refreshToken, nil
}

// RefreshToken validates a refresh token and returns a new token pair.
// The old refresh token is blacklisted in Redis.
func (s *AuthService) RefreshToken(refreshToken string) (newAccess, newRefresh string, err error) {
	// Parse the refresh token to extract claims.
	claims, err := jwtpkg.ParseToken(refreshToken)
	if err != nil {
		return "", "", fmt.Errorf("invalid refresh token: %w", err)
	}

	// Check if the refresh token has been blacklisted.
	ctx := context.Background()
	blacklistKey := fmt.Sprintf("token:blacklist:%s", claims.ID)
	exists, err := s.rdb.Exists(ctx, blacklistKey).Result()
	if err != nil {
		return "", "", fmt.Errorf("failed to check token blacklist: %w", err)
	}
	if exists > 0 {
		return "", "", errors.New("refresh token has been revoked")
	}

	// Generate a new token pair.
	newAccess, newRefresh, err = jwtpkg.GenerateTokenPair(claims.UserID, claims.Role)
	if err != nil {
		return "", "", fmt.Errorf("failed to generate new tokens: %w", err)
	}

	// Blacklist the old refresh token until its original expiry.
	if claims.ExpiresAt != nil {
		ttl := time.Until(claims.ExpiresAt.Time)
		if ttl > 0 {
			s.rdb.Set(ctx, blacklistKey, 1, ttl)
		}
	}

	return newAccess, newRefresh, nil
}

// Logout adds the given token JTI to the Redis blacklist so it cannot be reused.
func (s *AuthService) Logout(jti string, expiry time.Time) error {
	ctx := context.Background()
	blacklistKey := fmt.Sprintf("token:blacklist:%s", jti)
	ttl := time.Until(expiry)
	if ttl <= 0 {
		// Token already expired, nothing to blacklist.
		return nil
	}
	return s.rdb.Set(ctx, blacklistKey, 1, ttl).Err()
}

// generateCode produces a cryptographically random numeric code of the given length.
func generateCode(length int) (string, error) {
	code := ""
	for i := 0; i < length; i++ {
		n, err := rand.Int(rand.Reader, big.NewInt(10))
		if err != nil {
			return "", err
		}
		code += fmt.Sprintf("%d", n.Int64())
	}
	return code, nil
}
