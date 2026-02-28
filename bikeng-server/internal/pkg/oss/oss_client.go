package oss

import (
	"crypto/hmac"
	"crypto/sha1"
	"encoding/base64"
	"fmt"
	"net/url"
	"strconv"
	"time"

	"github.com/nicksrepo/bikeng-server/internal/config"
)

// OSSClient provides presigned URL generation for Alibaba Cloud OSS.
type OSSClient struct {
	endpoint    string
	accessKey   string
	accessSecret string
	bucket      string
}

// NewOSSClient creates a new OSSClient from the given OSS configuration.
func NewOSSClient(cfg config.OSSConfig) *OSSClient {
	return &OSSClient{
		endpoint:     cfg.Aliyun.Endpoint,
		accessKey:    cfg.Aliyun.AccessKey,
		accessSecret: cfg.Aliyun.Secret,
		bucket:       cfg.Aliyun.Bucket,
	}
}

// GeneratePresignedURL creates a presigned PUT URL for direct upload to OSS.
// It uses the Alibaba OSS v1 signature specification (HMAC-SHA1).
// The returned URL is valid for expireSec seconds.
func (c *OSSClient) GeneratePresignedURL(objectKey string, expireSec int64) (string, error) {
	expiration := time.Now().Unix() + expireSec

	// Build the string to sign per OSS v1 signature spec:
	// HTTP-Verb + "\n" + Content-MD5 + "\n" + Content-Type + "\n" + Expires + "\n" + CanonicalizedResource
	canonicalizedResource := fmt.Sprintf("/%s/%s", c.bucket, objectKey)
	stringToSign := fmt.Sprintf("PUT\n\n\n%d\n%s", expiration, canonicalizedResource)

	// Compute HMAC-SHA1 signature.
	mac := hmac.New(sha1.New, []byte(c.accessSecret))
	mac.Write([]byte(stringToSign))
	signature := base64.StdEncoding.EncodeToString(mac.Sum(nil))

	// Build the presigned URL.
	presignedURL := fmt.Sprintf("https://%s.%s/%s?OSSAccessKeyId=%s&Expires=%s&Signature=%s",
		c.bucket,
		c.endpoint,
		objectKey,
		url.QueryEscape(c.accessKey),
		strconv.FormatInt(expiration, 10),
		url.QueryEscape(signature),
	)

	return presignedURL, nil
}

// GetPublicURL returns the public access URL for an uploaded object.
func (c *OSSClient) GetPublicURL(objectKey string) string {
	return fmt.Sprintf("https://%s.%s/%s", c.bucket, c.endpoint, objectKey)
}
