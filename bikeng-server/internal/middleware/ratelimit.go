package middleware

import (
	"context"
	"fmt"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/redis/go-redis/v9"
)

// RateLimit returns a Gin middleware that enforces a sliding window rate limit
// using a Redis sorted set. Each request is scored by its Unix-nanosecond
// timestamp; entries outside the window are pruned on every call, and the
// remaining cardinality is compared against the limit.
//
// Parameters:
//   - rdb:    a connected Redis client
//   - limit:  maximum number of requests allowed within the window
//   - window: duration of the sliding window
//
// Key pattern: ratelimit:{client_ip}:{request_path}
func RateLimit(rdb *redis.Client, limit int, window time.Duration) gin.HandlerFunc {
	return func(c *gin.Context) {
		ctx := context.Background()
		key := fmt.Sprintf("ratelimit:%s:%s", c.ClientIP(), c.FullPath())
		now := time.Now()
		windowStart := now.Add(-window)

		pipe := rdb.Pipeline()

		// Remove entries outside the current sliding window.
		pipe.ZRemRangeByScore(ctx, key, "0", fmt.Sprintf("%d", windowStart.UnixNano()))

		// Add the current request with its timestamp as the score.
		pipe.ZAdd(ctx, key, redis.Z{
			Score:  float64(now.UnixNano()),
			Member: fmt.Sprintf("%d", now.UnixNano()),
		})

		// Count the number of requests in the current window.
		countCmd := pipe.ZCard(ctx, key)

		// Set an expiry on the key so it doesn't linger forever.
		pipe.Expire(ctx, key, window)

		if _, err := pipe.Exec(ctx); err != nil {
			c.AbortWithStatusJSON(http.StatusInternalServerError, gin.H{
				"error": "rate limiter error",
			})
			return
		}

		count := countCmd.Val()
		if count > int64(limit) {
			c.AbortWithStatusJSON(http.StatusTooManyRequests, gin.H{
				"error": "rate limit exceeded, please try again later",
			})
			return
		}

		c.Next()
	}
}
