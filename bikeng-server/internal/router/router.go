package router

import (
	"time"

	"github.com/gin-gonic/gin"
	"github.com/redis/go-redis/v9"
	"go.uber.org/zap"

	"github.com/nicksrepo/bikeng-server/internal/handler"
	"github.com/nicksrepo/bikeng-server/internal/middleware"
)

// SetupRouter creates and configures the Gin engine with all routes and
// middleware for the bikeng-server API.
func SetupRouter(
	authHandler *handler.AuthHandler,
	ocrHandler *handler.OCRHandler,
	reportHandler *handler.ReportHandler,
	queryHandler *handler.QueryHandler,
	appealHandler *handler.AppealHandler,
	postHandler *handler.PostHandler,
	alertHandler *handler.AlertHandler,
	uploadHandler *handler.UploadHandler,
	adminHandler *handler.AdminHandler,
	rdb *redis.Client,
	logger *zap.Logger,
) *gin.Engine {
	r := gin.New()
	r.Use(middleware.Recovery(logger), middleware.Logger(logger), middleware.CORS())

	v1 := r.Group("/api/v1")

	// ---- Public auth routes ----
	auth := v1.Group("/auth")
	auth.POST("/sms/send", middleware.RateLimit(rdb, 5, time.Minute), authHandler.SendSmsCode)
	auth.POST("/sms/verify", authHandler.VerifySmsCode)
	auth.POST("/refresh", authHandler.RefreshToken)

	// ---- Protected routes (require auth) ----
	protected := v1.Group("")
	protected.Use(middleware.AuthRequired(rdb))

	// Auth (protected)
	protected.POST("/auth/logout", authHandler.Logout)

	// OCR
	protected.POST("/ocr/extract", ocrHandler.ExtractAccounts)

	// Query
	protected.GET("/query", queryHandler.QueryAccount)
	protected.GET("/query/batch", queryHandler.QueryBatch)

	// Reports
	protected.POST("/reports", reportHandler.SubmitReport)
	protected.GET("/reports/mine", reportHandler.GetMyReports)
	protected.GET("/reports/:id", reportHandler.GetReportDetail)

	// Upload
	protected.POST("/upload/presign", uploadHandler.GetPresignedURL)

	// Appeals
	protected.POST("/appeals", appealHandler.SubmitAppeal)
	protected.GET("/appeals/:id", appealHandler.GetAppealStatus)

	// Posts
	protected.GET("/posts", postHandler.GetPostList)
	protected.POST("/posts", postHandler.CreatePost)
	protected.GET("/posts/:id", postHandler.GetPostDetail)
	protected.POST("/posts/:id/comments", postHandler.AddComment)
	protected.GET("/posts/:id/comments", postHandler.GetComments)
	protected.POST("/posts/:id/like", postHandler.LikePost)
	protected.DELETE("/posts/:id/like", postHandler.UnlikePost)

	// Alerts (read access for authenticated users)
	protected.GET("/alerts", alertHandler.GetAlertList)
	protected.GET("/alerts/latest", alertHandler.GetLatestAlerts)

	// ---- Admin routes ----
	admin := v1.Group("/admin")
	admin.Use(middleware.AuthRequired(rdb), middleware.AdminRequired())

	admin.PUT("/reports/:id/review", adminHandler.ReviewReport)
	admin.PUT("/appeals/:id/review", adminHandler.ReviewAppeal)
	admin.POST("/alerts", alertHandler.CreateAlert)
	admin.GET("/dashboard", adminHandler.GetDashboard)

	return r
}
