package repository

import (
	"errors"

	"github.com/nicksrepo/bikeng-server/internal/model"
	"gorm.io/gorm"
)

type PostRepo struct {
	db *gorm.DB
}

func NewPostRepo(db *gorm.DB) *PostRepo {
	return &PostRepo{db: db}
}

// Create inserts a new post record.
func (r *PostRepo) Create(post *model.Post) error {
	return r.db.Create(post).Error
}

// FindByID finds a post by ID. Returns (nil, nil) if not found.
func (r *PostRepo) FindByID(id uint64) (*model.Post, error) {
	var post model.Post
	result := r.db.First(&post, id)
	if result.Error != nil {
		if errors.Is(result.Error, gorm.ErrRecordNotFound) {
			return nil, nil
		}
		return nil, result.Error
	}
	return &post, nil
}

// List retrieves posts with optional category filter and pagination.
// Posts are ordered by is_pinned DESC, created_at DESC.
// Returns matched posts, total count, and error.
func (r *PostRepo) List(category string, page, pageSize int) ([]model.Post, int64, error) {
	var posts []model.Post
	var total int64

	query := r.db.Model(&model.Post{})
	if category != "" {
		query = query.Where("category = ?", category)
	}

	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}

	offset := (page - 1) * pageSize
	if err := query.Offset(offset).Limit(pageSize).
		Order("is_pinned DESC, created_at DESC").
		Find(&posts).Error; err != nil {
		return nil, 0, err
	}

	return posts, total, nil
}

// IncrementViewCount increments the view_count of a post by 1.
func (r *PostRepo) IncrementViewCount(id uint64) error {
	return r.db.Model(&model.Post{}).Where("id = ?", id).
		Update("view_count", gorm.Expr("view_count + 1")).Error
}

// IncrementLikeCount adjusts the like_count of a post by delta (+1 or -1).
func (r *PostRepo) IncrementLikeCount(id uint64, delta int) error {
	return r.db.Model(&model.Post{}).Where("id = ?", id).
		Update("like_count", gorm.Expr("like_count + ?", delta)).Error
}

// IncrementCommentCount increments the comment_count of a post by 1.
func (r *PostRepo) IncrementCommentCount(id uint64) error {
	return r.db.Model(&model.Post{}).Where("id = ?", id).
		Update("comment_count", gorm.Expr("comment_count + 1")).Error
}

// UpdateStatus updates the status of a post.
func (r *PostRepo) UpdateStatus(id uint64, status string) error {
	return r.db.Model(&model.Post{}).Where("id = ?", id).Update("status", status).Error
}
