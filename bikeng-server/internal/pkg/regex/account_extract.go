package regex

import (
	"regexp"
	"strings"
)

// ExtractedAccount represents a single account extracted from OCR text.
type ExtractedAccount struct {
	Type  string `json:"type"`
	Value string `json:"value"`
}

var (
	// qqPattern matches QQ numbers (5-11 digits) preceded by QQ-related keywords.
	qqPattern = regexp.MustCompile(`(?i)(?:QQ|qq|Qq)\s*[:：]?\s*([1-9]\d{4,10})`)

	// wechatPattern matches WeChat IDs preceded by WeChat-related keywords.
	wechatPattern = regexp.MustCompile(`(?:微信|WeChat|wechat|Wechat|wx)\s*[:：]?\s*([a-zA-Z][a-zA-Z0-9_-]{5,19})`)

	// phonePattern matches Chinese mobile phone numbers.
	phonePattern = regexp.MustCompile(`(1[3-9]\d{9})`)

	// alipayPhonePattern matches Alipay accounts that are phone numbers.
	alipayPhonePattern = regexp.MustCompile(`(?:支付宝|Alipay|alipay)\s*[:：]?\s*(1[3-9]\d{9})`)

	// alipayEmailPattern matches Alipay accounts that are email addresses.
	alipayEmailPattern = regexp.MustCompile(`(?:支付宝|Alipay|alipay)\s*[:：]?\s*([a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,})`)
)

// ExtractAccounts scans the given text for account identifiers (QQ, WeChat,
// phone numbers, Alipay) using regex patterns and returns deduplicated results.
func ExtractAccounts(text string) []ExtractedAccount {
	seen := make(map[string]struct{})
	var results []ExtractedAccount

	addUnique := func(typ, value string) {
		key := typ + ":" + value
		if _, exists := seen[key]; exists {
			return
		}
		seen[key] = struct{}{}
		results = append(results, ExtractedAccount{Type: typ, Value: value})
	}

	// Process each line to handle line-level context for keyword matching.
	lines := strings.Split(text, "\n")
	for _, line := range lines {
		// Extract QQ numbers.
		for _, match := range qqPattern.FindAllStringSubmatch(line, -1) {
			addUnique("qq", match[1])
		}

		// Extract WeChat IDs.
		for _, match := range wechatPattern.FindAllStringSubmatch(line, -1) {
			addUnique("wechat", match[1])
		}

		// Extract Alipay accounts (phone).
		for _, match := range alipayPhonePattern.FindAllStringSubmatch(line, -1) {
			addUnique("alipay", match[1])
		}

		// Extract Alipay accounts (email).
		for _, match := range alipayEmailPattern.FindAllStringSubmatch(line, -1) {
			addUnique("alipay", match[1])
		}

		// Extract standalone phone numbers.
		for _, match := range phonePattern.FindAllStringSubmatch(line, -1) {
			addUnique("phone", match[1])
		}
	}

	return results
}
