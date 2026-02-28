package repository

import (
	"errors"
	"time"

	"github.com/nicksrepo/bikeng-server/internal/model"
	"gorm.io/gorm"
)

type SmsCodeRepo struct {
	db *gorm.DB
}

func NewSmsCodeRepo(db *gorm.DB) *SmsCodeRepo {
	return &SmsCodeRepo{db: db}
}

// Create inserts a new SMS code record.
func (r *SmsCodeRepo) Create(code *model.SmsCode) error {
	return r.db.Create(code).Error
}

// FindLatestValid finds the latest unused SMS code for the given phone and purpose
// that has not yet expired. Returns (nil, nil) if not found.
func (r *SmsCodeRepo) FindLatestValid(phone, purpose string) (*model.SmsCode, error) {
	var code model.SmsCode
	result := r.db.Where("phone = ? AND purpose = ? AND is_used = ? AND expires_at > ?",
		phone, purpose, false, time.Now()).
		Order("created_at DESC").
		First(&code)
	if result.Error != nil {
		if errors.Is(result.Error, gorm.ErrRecordNotFound) {
			return nil, nil
		}
		return nil, result.Error
	}
	return &code, nil
}

// MarkUsed sets is_used to true for the given SMS code.
func (r *SmsCodeRepo) MarkUsed(id uint64) error {
	return r.db.Model(&model.SmsCode{}).Where("id = ?", id).Update("is_used", true).Error
}
