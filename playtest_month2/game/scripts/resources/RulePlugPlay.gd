class_name RulePlugPlay extends Rule
## “即插即用”：只看简历第二页最上面那段（最近一段）的职位名，带“后端”“服务端”或“Java”才算。
## 一字一字地比：JavaScript 不是 Java，“软件工程师”再像写后端也不算；以前做过后端、最近一段转了别的，也不算。

const WORDS := ["后端", "服务端", "Java"]
const PASS_TITLES := ["后端开发", "Java 开发工程师", "服务端开发", "高级后端开发"]
## 看着不像，字面上算
const EDGE_PASS_TITLES := ["Java 讲师", "外包驻场 Java 开发", "后端测试工程师", "服务端运维"]
## 看着像，字面上不算
const EDGE_FAIL_TITLES := ["软件工程师", "外包驻场开发", "全栈工程师", "JavaScript 开发", "研发工程师"]
const FAIL_TITLES := ["测试工程师", "运维工程师", "前端开发", "实施工程师", "产品经理", "技术支持"]


## 只管投后端的社招：按组招以后有前端、运维的组，那天起这条收起来（第 13 天 retire）。
func applies_to(c: Candidate) -> bool:
	if c.is_intern:
		return false
	var posting := RuleEngine.posting_for(c.applied_position)
	return posting != null and posting.role == "后端"


func check(c: Candidate) -> bool:
	return not c.jobs.is_empty() and fits(c.jobs[0].title)


static func fits(title: String) -> bool:
	var plain := title.replace("JavaScript", "")
	return WORDS.any(func(w: String) -> bool: return plain.contains(w))


func shape(c: Candidate, form: Shape, rng: RandomNumberGenerator) -> void:
	var titles: Array = PASS_TITLES
	match form:
		Shape.EDGE_PASS:
			titles = EDGE_PASS_TITLES
		Shape.EDGE_FAIL:
			titles = EDGE_FAIL_TITLES
		Shape.FAIL:
			titles = FAIL_TITLES
	c.recent_title = titles[rng.randi_range(0, titles.size() - 1)]
