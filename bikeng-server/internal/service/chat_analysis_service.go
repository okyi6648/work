package service

import (
	"regexp"
	"strings"

	"github.com/nicksrepo/bikeng-server/internal/model"
)

// ChatAnalysisService analyzes chat text for scam patterns using a rule engine.
type ChatAnalysisService struct{}

// NewChatAnalysisService creates a new ChatAnalysisService.
func NewChatAnalysisService() *ChatAnalysisService {
	return &ChatAnalysisService{}
}

// ChatAnalysisResult holds the result of chat text analysis.
type ChatAnalysisResult struct {
	Score   float64
	Factors []model.AnalysisFactor
}

// scamPattern defines a single scam detection pattern category.
type scamPattern struct {
	Category string
	Weight   float64
	Keywords []string
	Regexps  []*regexp.Regexp
}

var scamPatterns = []scamPattern{
	{
		Category: "催促紧迫",
		Weight:   15,
		Keywords: []string{
			"马上", "立刻", "紧急", "最后机会", "赶紧", "抓紧", "立即",
			"快点", "别犹豫", "不要犹豫", "现在就", "错过就没了", "仅此一次",
			"倒计时", "截止", "到期", "过期", "来不及",
		},
	},
	{
		Category: "金钱投资",
		Weight:   20,
		Keywords: []string{
			"转账", "投资", "收益", "回报", "提现", "入金", "出金",
			"本金", "利润", "分红", "理财", "基金", "股票", "期货",
			"虚拟币", "比特币", "数字货币", "佣金", "手续费", "充值",
			"打款", "汇款", "付款", "银行卡", "账户",
		},
	},
	{
		Category: "身份冒充",
		Weight:   20,
		Keywords: []string{
			"我是你", "公检法", "客服", "不要告诉别人", "别告诉别人",
			"保密", "官方", "工作人员", "银行客服", "平台客服",
			"公安", "检察院", "法院", "税务", "社保",
			"领导", "老板", "经理", "主任",
		},
	},
	{
		Category: "虚假承诺",
		Weight:   20,
		Keywords: []string{
			"保证", "稳赚不赔", "高回报", "零风险", "百分百",
			"包赚", "躺赚", "日赚", "月入", "年入",
			"保本", "无风险", "稳定收益", "翻倍", "翻番",
			"一定能", "肯定能", "保你", "担保",
		},
	},
	{
		Category: "施压逼迫",
		Weight:   15,
		Keywords: []string{
			"名额有限", "错过后悔", "限时", "仅剩", "最后几个",
			"不买就亏", "再不买就", "过了这村", "机不可失",
			"今天必须", "马上决定", "不要错过", "赶上末班车",
		},
	},
	{
		Category: "可疑链接",
		Weight:   10,
		Keywords: []string{
			"扫码", "二维码", "点击链接", "打开链接", "复制链接",
			"下载APP", "安装APP", "注册链接",
		},
		Regexps: []*regexp.Regexp{
			regexp.MustCompile(`https?://[^\s]+`),
			regexp.MustCompile(`[a-zA-Z0-9][-a-zA-Z0-9]*\.[a-z]{2,}\S*`),
		},
	},
}

// Analyze processes OCR text from chat screenshots and returns a scam risk score
// with matched factors.
func (s *ChatAnalysisService) Analyze(sessionID uint64, ocrTexts []string) ChatAnalysisResult {
	combined := strings.Join(ocrTexts, "\n")
	lower := strings.ToLower(combined)

	var factors []model.AnalysisFactor
	totalScore := 0.0

	for _, pattern := range scamPatterns {
		matchCount := 0
		var matched []string

		// Check keywords.
		for _, kw := range pattern.Keywords {
			if strings.Contains(lower, strings.ToLower(kw)) {
				matchCount++
				matched = append(matched, kw)
			}
		}

		// Check regexps.
		for _, re := range pattern.Regexps {
			if finds := re.FindAllString(combined, -1); len(finds) > 0 {
				matchCount += len(finds)
				for _, f := range finds {
					if len(f) > 100 {
						f = f[:100]
					}
					matched = append(matched, f)
				}
			}
		}

		if matchCount == 0 {
			continue
		}

		// Calculate category score: more matches = higher score, capped at category weight.
		categoryScore := pattern.Weight * min(float64(matchCount)/3.0, 1.0)
		totalScore += categoryScore

		severity := "low"
		switch {
		case categoryScore >= pattern.Weight*0.8:
			severity = "critical"
		case categoryScore >= pattern.Weight*0.5:
			severity = "high"
		case categoryScore >= pattern.Weight*0.3:
			severity = "medium"
		}

		factors = append(factors, model.AnalysisFactor{
			SessionID:   sessionID,
			Category:    "chat",
			FactorType:  pattern.Category,
			FactorValue: strings.Join(matched, ", "),
			ScoreImpact: categoryScore,
			Severity:    severity,
		})
	}

	// Normalize to 0-100.
	maxPossible := 0.0
	for _, p := range scamPatterns {
		maxPossible += p.Weight
	}
	score := (totalScore / maxPossible) * 100
	if score > 100 {
		score = 100
	}

	return ChatAnalysisResult{
		Score:   score,
		Factors: factors,
	}
}

func min(a, b float64) float64 {
	if a < b {
		return a
	}
	return b
}
