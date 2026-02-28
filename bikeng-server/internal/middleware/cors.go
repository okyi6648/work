package middleware

import (
	"fmt"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
)

const (
	corsMaxAge = 12 * time.Hour
)

// CORS returns a Gin middleware that sets Cross-Origin Resource Sharing headers
// on every response. Preflight OPTIONS requests are handled by returning 204
// immediately after the headers are written.
//
// Current defaults (configurable later):
//   - Allow-Origin:  *
//   - Allow-Methods: GET, POST, PUT, DELETE, OPTIONS
//   - Allow-Headers: Content-Type, Authorization
//   - Max-Age:       12 hours
func CORS() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Header("Access-Control-Allow-Origin", "*")
		c.Header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		c.Header("Access-Control-Allow-Headers", "Content-Type, Authorization")
		c.Header("Access-Control-Max-Age", fmt.Sprintf("%d", int(corsMaxAge.Seconds())))

		if c.Request.Method == http.MethodOptions {
			c.AbortWithStatus(http.StatusNoContent)
			return
		}

		c.Next()
	}
}
