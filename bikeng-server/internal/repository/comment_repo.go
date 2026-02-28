package repository

import (
	"errors"

	"github.com/nicksrepo/bikeng-server/internal/model"
	"gorm.io/gorm"
)

type CommentRepo struct {
	db *gorm.DB
}

func NewCommentRepo(db *gorm.DB) *CommentRepo {
	return &CommentRepo{db: db}
}

// Create inserts a new comment record.
func (r *CommentRepo) Create(comment *model.Comment) error {
	return r.db.Create(comment).Error
}

// FindByPost retrieves comments for a given post with pagination, ordered by created_at ASC.
// Returns matched comments, total count, and error.
func (r *CommentRepo) FindByPost(postID uint64, page, pageSize int) ([]model.Comment, int64, error) {
	var comments []model.Comment
	var total int64

	query := r.db.Model(&model.Comment{}).Where("post_id = ?", postID)

	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}

	offset := (page - 1) * pageSize
	if err := query.Offset(offset).Limit(pageSize).Order("created_at ASC").Find(&comments).Error; err != nil {
		return nil, 0, err
	}

	return comments, total, nil
}

// FindByID finds a comment by ID. Returns (nil, nil) if not found.
func (r *CommentRepo) FindByID(id uint64) (*model.Comment, error) {
	var comment model.Comment
	result := r.db.First(&comment, id)
	if result.Error != nil {
		if errors.Is(result.Error, gorm.ErrRecordNotFound) {
			return nil, nil
		}
		return nil, result.Error
	}
	return &comment, nil
}
