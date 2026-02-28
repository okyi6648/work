package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"

	"github.com/nicksrepo/bikeng-server/internal/pkg/response"
	"github.com/nicksrepo/bikeng-server/internal/service"
)

// PostHandler handles community post and comment HTTP requests.
type PostHandler struct {
	postService *service.PostService
}

// NewPostHandler creates a new PostHandler with the given post service.
func NewPostHandler(postService *service.PostService) *PostHandler {
	return &PostHandler{postService: postService}
}

// CreatePost handles POST /api/v1/posts.
// It creates a new community post by the authenticated user.
func (h *PostHandler) CreatePost(c *gin.Context) {
	var req service.CreatePostRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, http.StatusBadRequest, "invalid request: "+err.Error())
		return
	}

	authorID := c.GetUint64("user_id")

	post, err := h.postService.CreatePost(authorID, req)
	if err != nil {
		response.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	response.Created(c, post)
}

// GetPostList handles GET /api/v1/posts.
// It returns a paginated list of posts, optionally filtered by category.
func (h *PostHandler) GetPostList(c *gin.Context) {
	category := c.Query("category")
	page, pageSize := parsePagination(c)

	posts, total, err := h.postService.GetPostList(category, page, pageSize)
	if err != nil {
		response.Error(c, http.StatusInternalServerError, "failed to get posts: "+err.Error())
		return
	}

	response.Paginated(c, posts, total, page, pageSize)
}

// GetPostDetail handles GET /api/v1/posts/:id.
// It returns a single post and increments its view count.
func (h *PostHandler) GetPostDetail(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		response.Error(c, http.StatusBadRequest, "invalid post ID")
		return
	}

	post, err := h.postService.GetPostDetail(id)
	if err != nil {
		response.Error(c, http.StatusNotFound, err.Error())
		return
	}

	response.Success(c, post)
}

// addCommentRequest is the JSON body for adding a comment to a post.
type addCommentRequest struct {
	Content  string  `json:"content" binding:"required"`
	ParentID *uint64 `json:"parent_id"`
}

// AddComment handles POST /api/v1/posts/:id/comments.
// It adds a comment to the specified post.
func (h *PostHandler) AddComment(c *gin.Context) {
	postID, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		response.Error(c, http.StatusBadRequest, "invalid post ID")
		return
	}

	var req addCommentRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, http.StatusBadRequest, "invalid request: "+err.Error())
		return
	}

	authorID := c.GetUint64("user_id")

	comment, err := h.postService.AddComment(postID, authorID, req.ParentID, req.Content)
	if err != nil {
		response.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	response.Created(c, comment)
}

// GetComments handles GET /api/v1/posts/:id/comments.
// It returns a paginated list of comments for the specified post.
func (h *PostHandler) GetComments(c *gin.Context) {
	postID, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		response.Error(c, http.StatusBadRequest, "invalid post ID")
		return
	}

	page, pageSize := parsePagination(c)

	comments, total, err := h.postService.GetComments(postID, page, pageSize)
	if err != nil {
		response.Error(c, http.StatusInternalServerError, "failed to get comments: "+err.Error())
		return
	}

	response.Paginated(c, comments, total, page, pageSize)
}

// LikePost handles POST /api/v1/posts/:id/like.
// It increments the like count of the specified post.
func (h *PostHandler) LikePost(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		response.Error(c, http.StatusBadRequest, "invalid post ID")
		return
	}

	if err := h.postService.LikePost(id); err != nil {
		response.Error(c, http.StatusInternalServerError, "failed to like post: "+err.Error())
		return
	}

	response.Success(c, nil)
}

// UnlikePost handles DELETE /api/v1/posts/:id/like.
// It decrements the like count of the specified post.
func (h *PostHandler) UnlikePost(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		response.Error(c, http.StatusBadRequest, "invalid post ID")
		return
	}

	if err := h.postService.UnlikePost(id); err != nil {
		response.Error(c, http.StatusInternalServerError, "failed to unlike post: "+err.Error())
		return
	}

	response.Success(c, nil)
}
