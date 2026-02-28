package repository

import (
	"errors"
	"time"

	"github.com/nicksrepo/bikeng-server/internal/model"
	"gorm.io/gorm"
)

type UserRepo struct {
	db *gorm.DB
}

func NewUserRepo(db *gorm.DB) *UserRepo {
	return &UserRepo{db: db}
}

// FindByPhone finds a user by phone number. Returns (nil, nil) if not found.
func (r *UserRepo) FindByPhone(phone string) (*model.User, error) {
	var user model.User
	result := r.db.Where("phone = ?", phone).First(&user)
	if result.Error != nil {
		if errors.Is(result.Error, gorm.ErrRecordNotFound) {
			return nil, nil
		}
		return nil, result.Error
	}
	return &user, nil
}

// FindByID finds a user by ID. Returns (nil, nil) if not found.
func (r *UserRepo) FindByID(id uint64) (*model.User, error) {
	var user model.User
	result := r.db.First(&user, id)
	if result.Error != nil {
		if errors.Is(result.Error, gorm.ErrRecordNotFound) {
			return nil, nil
		}
		return nil, result.Error
	}
	return &user, nil
}

// Create inserts a new user record.
func (r *UserRepo) Create(user *model.User) error {
	return r.db.Create(user).Error
}

// Update saves all fields of the user record.
func (r *UserRepo) Update(user *model.User) error {
	return r.db.Save(user).Error
}

// UpdateLastLogin sets last_login_at to the current time.
func (r *UserRepo) UpdateLastLogin(id uint64) error {
	now := time.Now()
	return r.db.Model(&model.User{}).Where("id = ?", id).Update("last_login_at", now).Error
}
