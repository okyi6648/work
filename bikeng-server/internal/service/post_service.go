package service

import (
	"encoding/json"
	"errors"
	"fmt"

	"github.com/nicksrepo/bikeng-server/internal/model"
	"github.com/nicksrepo/bikeng-server/internal/repository"
	"gorm.io/datatypes"
)

// CreatePostRequest contains the data required to create a new community post.
type CreatePostRequest struct {
	Title     string   `json:"title" binding:"required"`
	Content   string   `json:"content" binding:"required"`
	Category  string   `json:"category" binding:"required"`
	ImageURLs []string `json:"image_urls"`
}

// PostService handles community post and comment operations.
type PostService struct {
	postRepo    *repository.PostRepo
	commentRepo *repository.CommentRepo
}

// NewPostService creates a new PostService with the required dependencies.
func NewPostService(
	postRepo *repository.PostRepo,
	commentRepo *repository.CommentRepo,
) *PostService {
	return &PostService{
		postRepo:    postRepo,
		commentRepo: commentRepo,
	}
}

// CreatePost creates a new community post.
func (s *PostService) CreatePost(authorID uint64, req CreatePostRequest) (*model.Post, error) {
	// Marshal image URLs to JSON.
	var imageJSON datatypes.JSON
	if len(req.ImageURLs) > 0 {
		data, err := json.Marshal(req.ImageURLs)
		if err != nil {
			return nil, fmt.Errorf("failed to marshal image URLs: %w", err)
		}
		imageJSON = data
	} else {
		imageJSON = datatypes.JSON("[]")
	}

	post := &model.Post{
		AuthorID:  authorID,
		Title:     req.Title,
		Content:   req.Content,
		Category:  req.Category,
		ImageURLs: imageJSON,
		Status:    "active",
	}
	if err := s.postRepo.Create(post); err != nil {
		return nil, fmt.Errorf("failed to create post: %w", err)
	}
	return post, nil
}

// GetPostList retrieves a paginated list of posts, optionally filtered by category.
func (s *PostService) GetPostList(category string, page, pageSize int) ([]model.Post, int64, error) {
	return s.postRepo.List(category, page, pageSize)
}

// GetPostDetail retrieves a post by ID and increments its view count.
func (s *PostService) GetPostDetail(id uint64) (*model.Post, error) {
	post, err := s.postRepo.FindByID(id)
	if err != nil {
		return nil, fmt.Errorf("failed to find post: %w", err)
	}
	if post == nil {
		return nil, errors.New("帖子不存在")
	}

	// Increment view count (fire-and-forget, error is non-critical).
	_ = s.postRepo.IncrementViewCount(id)

	return post, nil
}

// LikePost increments the like count of a post by 1.
func (s *PostService) LikePost(postID uint64) error {
	return s.postRepo.IncrementLikeCount(postID, 1)
}

// UnlikePost decrements the like count of a post by 1.
func (s *PostService) UnlikePost(postID uint64) error {
	return s.postRepo.IncrementLikeCount(postID, -1)
}

// AddComment adds a comment to a post and increments the post's comment count.
func (s *PostService) AddComment(postID, authorID uint64, parentID *uint64, content string) (*model.Comment, error) {
	// Verify the post exists.
	post, err := s.postRepo.FindByID(postID)
	if err != nil {
		return nil, fmt.Errorf("failed to find post: %w", err)
	}
	if post == nil {
		return nil, errors.New("帖子不存在")
	}

	comment := &model.Comment{
		PostID:   postID,
		AuthorID: authorID,
		ParentID: parentID,
		Content:  content,
		Status:   "active",
	}
	if err := s.commentRepo.Create(comment); err != nil {
		return nil, fmt.Errorf("failed to create comment: %w", err)
	}

	// Increment the post's comment count.
	_ = s.postRepo.IncrementCommentCount(postID)

	return comment, nil
}

// GetComments retrieves paginated comments for a post.
func (s *PostService) GetComments(postID uint64, page, pageSize int) ([]model.Comment, int64, error) {
	return s.commentRepo.FindByPost(postID, page, pageSize)
}
