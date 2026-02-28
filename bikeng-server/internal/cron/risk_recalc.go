package cron

import (
	"log"
	"time"

	"github.com/nicksrepo/bikeng-server/internal/service"
)

// StartRiskRecalculation starts a background goroutine that periodically
// recalculates risk scores for all accounts with reports.
func StartRiskRecalculation(riskService *service.RiskService, interval time.Duration) {
	ticker := time.NewTicker(interval)
	go func() {
		for range ticker.C {
			log.Println("[CRON] Starting risk score recalculation...")
			if err := riskService.RecalculateAll(); err != nil {
				log.Printf("[CRON] Risk recalculation failed: %v", err)
			} else {
				log.Println("[CRON] Risk recalculation completed")
			}
		}
	}()
}
