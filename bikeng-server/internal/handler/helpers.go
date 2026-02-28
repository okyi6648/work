package handler

import (
	"strconv"

	"github.com/gin-gonic/gin"
)

// parsePagination extracts page and page_size query parameters from the request.
// It returns sensible defaults (page=1, pageSize=20) when the parameters are
// missing or invalid.
func parsePagination(c *gin.Context) (page, pageSize int) {
	page = 1
	pageSize = 20

	if p := c.Query("page"); p != "" {
		if parsed, err := strconv.Atoi(p); err == nil && parsed > 0 {
			page = parsed
		}
	}

	if ps := c.Query("page_size"); ps != "" {
		if parsed, err := strconv.Atoi(ps); err == nil && parsed > 0 {
			if parsed > 100 {
				parsed = 100
			}
			pageSize = parsed
		}
	}

	return page, pageSize
}
