package service

import (
	"log"
)

// NotificationService handles push notification delivery.
// This is currently a stub implementation; integrate with FCM or another
// push service when ready.
type NotificationService struct {
	// FCM client placeholder
}

// NewNotificationService creates a new NotificationService.
func NewNotificationService() *NotificationService {
	return &NotificationService{}
}

// SendPushNotification sends a push notification to the specified users.
// This is a stub that logs the notification and returns nil.
func (s *NotificationService) SendPushNotification(title, body string, userIDs []uint64) error {
	log.Printf("push notification stub: title=%q, body=%q, users=%v", title, body, userIDs)
	return nil
}
