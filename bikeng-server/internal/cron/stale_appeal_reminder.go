package cron

import (
	"log"
	"time"
)

// StartStaleAppealReminder starts a background goroutine that periodically
// checks for appeals that have been pending for an extended period and
// sends a notification to administrators.
func StartStaleAppealReminder(interval time.Duration) {
	ticker := time.NewTicker(interval)
	go func() {
		for range ticker.C {
			log.Println("[CRON] Checking for stale appeals...")
			// TODO: Query appeals that have been pending for >7 days
			// and send notification to admin
		}
	}()
}
