package repository

import (
	"errors"
	"time"

	"github.com/nicksrepo/bikeng-server/internal/model"
	"gorm.io/gorm"
)

type AccountRepo struct {
	db *gorm.DB
}

func NewAccountRepo(db *gorm.DB) *AccountRepo {
	return &AccountRepo{db: db}
}

// FindByTypeAndValue finds an account by type and value. Returns (nil, nil) if not found.
func (r *AccountRepo) FindByTypeAndValue(accountType, accountValue string) (*model.Account, error) {
	var account model.Account
	result := r.db.Where("account_type = ? AND account_value = ?", accountType, accountValue).First(&account)
	if result.Error != nil {
		if errors.Is(result.Error, gorm.ErrRecordNotFound) {
			return nil, nil
		}
		return nil, result.Error
	}
	return &account, nil
}

// FindByID finds an account by ID. Returns (nil, nil) if not found.
func (r *AccountRepo) FindByID(id uint64) (*model.Account, error) {
	var account model.Account
	result := r.db.First(&account, id)
	if result.Error != nil {
		if errors.Is(result.Error, gorm.ErrRecordNotFound) {
			return nil, nil
		}
		return nil, result.Error
	}
	return &account, nil
}

// Create inserts a new account record.
func (r *AccountRepo) Create(account *model.Account) error {
	return r.db.Create(account).Error
}

// Update saves all fields of the account record.
func (r *AccountRepo) Update(account *model.Account) error {
	return r.db.Save(account).Error
}

// FindOrCreate finds an existing account by type and value, or creates a new one.
func (r *AccountRepo) FindOrCreate(accountType, accountValue string) (*model.Account, error) {
	account, err := r.FindByTypeAndValue(accountType, accountValue)
	if err != nil {
		return nil, err
	}
	if account != nil {
		return account, nil
	}

	newAccount := &model.Account{
		AccountType:  accountType,
		AccountValue: accountValue,
	}
	if err := r.db.Create(newAccount).Error; err != nil {
		return nil, err
	}
	return newAccount, nil
}

// IncrementReportCount increments report_count by 1, adds amount to total_amount, and updates last_reported_at.
func (r *AccountRepo) IncrementReportCount(id uint64, amount float64) error {
	now := time.Now()
	return r.db.Model(&model.Account{}).Where("id = ?", id).
		Updates(map[string]interface{}{
			"report_count":    gorm.Expr("report_count + 1"),
			"total_amount":    gorm.Expr("total_amount + ?", amount),
			"last_reported_at": now,
		}).Error
}

// Search searches accounts by account_value prefix match with pagination.
// Returns matched accounts, total count, and error.
func (r *AccountRepo) Search(value string, page, pageSize int) ([]model.Account, int64, error) {
	var accounts []model.Account
	var total int64

	query := r.db.Model(&model.Account{}).Where("account_value LIKE ?", value+"%")

	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}

	offset := (page - 1) * pageSize
	if err := query.Offset(offset).Limit(pageSize).Find(&accounts).Error; err != nil {
		return nil, 0, err
	}

	return accounts, total, nil
}

// UpdateRiskScore updates the risk_score for an account.
func (r *AccountRepo) UpdateRiskScore(id uint64, score float64) error {
	return r.db.Model(&model.Account{}).Where("id = ?", id).Update("risk_score", score).Error
}

// GetAllWithReports retrieves accounts that have at least one report, for batch risk score recalculation.
func (r *AccountRepo) GetAllWithReports(batchSize, offset int) ([]model.Account, error) {
	var accounts []model.Account
	err := r.db.Where("report_count > 0").
		Offset(offset).Limit(batchSize).
		Find(&accounts).Error
	return accounts, err
}
