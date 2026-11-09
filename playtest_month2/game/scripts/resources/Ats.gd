class_name Ats extends RefCounted
## 关键词初筛系统（第 15 天上线）：只看技能栏，给社招简历打“匹配 / 不匹配 / 堆砌”。
## 它和规则手册不是一套：
## - 不分大小写、按包含算：JavaScript 里有 Java、Golang 里有 Go、Kafka Streams 里有 Kafka，都算写了（规则要一字不差）。
## - 技能超过 MAX_SKILLS 项就判堆砌（规则是超过 8 项）：写 7、8 项的合格简历会被它判堆砌。
## - 看不见别的规则和身份证：薪资超了、89 年的、写了“稳定”的，只要关键词齐，它都判匹配。
## 所以照着标签盖章会错，违规单上写的照样是你。

const MAX_SKILLS := 6
const MATCH := "匹配"
const MISS := "不匹配"
const STUFFED := "堆砌"


## 不归它管的简历（实习生、岗位没写必备技能）返回空串。
static func label(c: Candidate) -> String:
	if c.is_intern:
		return ""
	var keywords := RuleKeywords._posting_keywords(c)
	if keywords.is_empty():
		return ""
	if c.skills.size() > MAX_SKILLS:
		return STUFFED
	for keyword in keywords:
		if not Array(c.skills).any(func(s: String) -> bool: return keyword.to_lower() in s.to_lower()):
			return MISS
	return MATCH


## 系统的意思是放还是不放。
static func says_pass(tag: String) -> bool:
	return tag == MATCH
