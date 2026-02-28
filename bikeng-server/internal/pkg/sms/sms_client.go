package sms

import (
	"log"

	"github.com/nicksrepo/bikeng-server/internal/config"
)

// SMSClient wraps the Aliyun SMS service for sending verification codes.
type SMSClient struct {
	accessKey    string
	secret       string
	signName     string
	templateCode string
}

// NewSMSClient creates a new SMSClient from the given SMS configuration.
func NewSMSClient(cfg config.SMSConfig) *SMSClient {
	return &SMSClient{
		accessKey:    cfg.Aliyun.AccessKey,
		secret:       cfg.Aliyun.Secret,
		signName:     cfg.Aliyun.SignName,
		templateCode: cfg.Aliyun.TemplateCode,
	}
}

// SendCode sends a verification code to the given phone number.
// This is currently a stub implementation that logs the code instead of
// making an actual API call. Wire in the real Aliyun SMS API later.
func (c *SMSClient) SendCode(phone, code string) error {
	log.Printf("SMS sent to %s: %s", phone, code)
	return nil
}
