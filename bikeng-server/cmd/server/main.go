package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/redis/go-redis/v9"
	"go.uber.org/zap"
	"gorm.io/driver/mysql"
	"gorm.io/gorm"

	"github.com/nicksrepo/bikeng-server/internal/config"
	"github.com/nicksrepo/bikeng-server/internal/cron"
	"github.com/nicksrepo/bikeng-server/internal/handler"
	"github.com/nicksrepo/bikeng-server/internal/model"
	pkgOCR "github.com/nicksrepo/bikeng-server/internal/pkg/ocr"
	pkgOSS "github.com/nicksrepo/bikeng-server/internal/pkg/oss"
	pkgSMS "github.com/nicksrepo/bikeng-server/internal/pkg/sms"
	"github.com/nicksrepo/bikeng-server/internal/repository"
	"github.com/nicksrepo/bikeng-server/internal/router"
	"github.com/nicksrepo/bikeng-server/internal/service"
)

func main() {
	// ---- Load configuration ----
	cfg, err := config.LoadConfig("configs/config.yaml")
	if err != nil {
		log.Fatalf("failed to load config: %v", err)
	}

	// ---- Initialize zap logger ----
	logger, err := zap.NewProduction()
	if err != nil {
		log.Fatalf("failed to init logger: %v", err)
	}
	defer logger.Sync()

	// ---- Connect to MySQL ----
	dsn := fmt.Sprintf("%s:%s@tcp(%s:%d)/%s?charset=utf8mb4&parseTime=True&loc=Local",
		cfg.MySQL.User,
		cfg.MySQL.Password,
		cfg.MySQL.Host,
		cfg.MySQL.Port,
		cfg.MySQL.DBName,
	)
	db, err := gorm.Open(mysql.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Fatalf("failed to connect to MySQL: %v", err)
	}
	logger.Info("connected to MySQL")

	// ---- Auto-migrate models ----
	if err := db.AutoMigrate(
		&model.User{},
		&model.Account{},
		&model.Report{},
		&model.Evidence{},
		&model.Appeal{},
		&model.Post{},
		&model.Comment{},
		&model.Alert{},
		&model.SmsCode{},
		&model.AnalysisSession{},
		&model.AnalysisImage{},
		&model.AnalysisFactor{},
	); err != nil {
		log.Fatalf("failed to auto-migrate: %v", err)
	}
	logger.Info("database migration completed")

	// ---- Connect to Redis ----
	rdb := redis.NewClient(&redis.Options{
		Addr:     fmt.Sprintf("%s:%d", cfg.Redis.Host, cfg.Redis.Port),
		Password: cfg.Redis.Password,
		DB:       cfg.Redis.DB,
	})
	if err := rdb.Ping(context.Background()).Err(); err != nil {
		log.Fatalf("failed to connect to Redis: %v", err)
	}
	logger.Info("connected to Redis")

	// ---- Initialize external clients ----
	smsClient := pkgSMS.NewSMSClient(cfg.SMS)
	ocrClient := pkgOCR.NewOCRClient(cfg.OCR)
	ossClient := pkgOSS.NewOSSClient(cfg.OSS)

	// ---- Initialize repositories ----
	userRepo := repository.NewUserRepo(db)
	accountRepo := repository.NewAccountRepo(db)
	reportRepo := repository.NewReportRepo(db)
	evidenceRepo := repository.NewEvidenceRepo(db)
	appealRepo := repository.NewAppealRepo(db)
	postRepo := repository.NewPostRepo(db)
	commentRepo := repository.NewCommentRepo(db)
	alertRepo := repository.NewAlertRepo(db)
	smsCodeRepo := repository.NewSmsCodeRepo(db)
	analysisRepo := repository.NewAnalysisRepo(db)

	// ---- Initialize services ----
	authService := service.NewAuthService(userRepo, smsCodeRepo, smsClient, rdb)
	ocrService := service.NewOCRService(ocrClient)
	riskService := service.NewRiskService(accountRepo, reportRepo)
	reportService := service.NewReportService(reportRepo, accountRepo, evidenceRepo, riskService)
	queryService := service.NewQueryService(accountRepo, reportRepo, rdb)
	appealService := service.NewAppealService(appealRepo, accountRepo, riskService)
	postService := service.NewPostService(postRepo, commentRepo)
	alertService := service.NewAlertService(alertRepo)
	ossService := service.NewOSSService(ossClient)
	chatAnalysisService := service.NewChatAnalysisService()
	accountAnalysisService := service.NewAccountAnalysisService(accountRepo, reportRepo)
	transferAnalysisService := service.NewTransferAnalysisService()
	comprehensiveAnalysisService := service.NewComprehensiveAnalysisService(
		analysisRepo, chatAnalysisService, accountAnalysisService, transferAnalysisService, ocrService,
	)

	// ---- Initialize handlers ----
	authHandler := handler.NewAuthHandler(authService)
	ocrHandler := handler.NewOCRHandler(ocrService)
	reportHandler := handler.NewReportHandler(reportService)
	queryHandler := handler.NewQueryHandler(queryService)
	appealHandler := handler.NewAppealHandler(appealService)
	postHandler := handler.NewPostHandler(postService)
	alertHandler := handler.NewAlertHandler(alertService)
	uploadHandler := handler.NewUploadHandler(ossService)
	adminHandler := handler.NewAdminHandler(reportService, appealService, accountRepo)
	analysisHandler := handler.NewAnalysisHandler(comprehensiveAnalysisService)

	// ---- Setup router ----
	r := router.SetupRouter(
		authHandler,
		ocrHandler,
		reportHandler,
		queryHandler,
		appealHandler,
		postHandler,
		alertHandler,
		uploadHandler,
		adminHandler,
		analysisHandler,
		rdb,
		logger,
	)

	// ---- Start cron jobs ----
	cron.StartRiskRecalculation(riskService, 6*time.Hour)
	cron.StartStaleAppealReminder(24 * time.Hour)
	logger.Info("cron jobs started")

	// ---- Start HTTP server with graceful shutdown ----
	addr := fmt.Sprintf(":%d", cfg.Server.Port)
	srv := &http.Server{
		Addr:    addr,
		Handler: r,
	}

	go func() {
		logger.Info("server starting", zap.String("addr", addr))
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("server listen error: %v", err)
		}
	}()

	// Wait for interrupt signal for graceful shutdown.
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit
	logger.Info("shutting down server...")

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	if err := srv.Shutdown(ctx); err != nil {
		log.Fatalf("server forced to shutdown: %v", err)
	}

	logger.Info("server exited gracefully")
}
