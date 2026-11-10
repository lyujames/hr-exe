class_name RuleAiExp extends Rule
## 第 18 天：“要有 AI 协同经验”。技能栏或工作经历里写明用过 AI 编程助手（“码力”“AI 编程助手”“大模型”）才算；
## 只在自我评价里说“关注 AI”的不算，“AI 绘图”“AIGC 运营”不是编程助手。

const WORDS := ["码力", "AI 编程助手", "大模型"]
const PASS_SKILLS := ["码力", "AI 编程助手", "大模型应用开发"]
const PASS_TITLES := ["全栈工程师（码力协同）", "大模型应用开发"]
const LOOKALIKE_SKILLS := ["AI 绘图", "AIGC 运营", "人工智能导论（选修）"]
const LOOKALIKE_EVALS := ["持续关注 AI 前沿动态。", "对 AI 有浓厚兴趣，正在学习。", "关注 AI，热爱新技术。"]


func applies_to(c: Candidate) -> bool:
	return not c.is_intern and for_position(c)


func check(c: Candidate) -> bool:
	for word: String in WORDS:
		if Array(c.skills).any(func(s: String) -> bool: return s.contains(word)):
			return true
		if c.jobs.any(func(j: Dictionary) -> bool: return String(j.title).contains(word)):
			return true
		if c.recent_title.contains(word):
			return true
	return false


func shape(c: Candidate, form: Shape, rng: RandomNumberGenerator) -> void:
	var plain := Array(c.skills).filter(func(s: String) -> bool: return not WORDS.any(func(w: String) -> bool: return s.contains(w)))
	c.skills = PackedStringArray(plain)
	match form:
		Shape.PASS:
			c.skills.append(PASS_SKILLS[rng.randi_range(0, PASS_SKILLS.size() - 1)])
		Shape.EDGE_PASS:
			# 技能栏没写，写在最近那段工作的职位里
			c.recent_title = PASS_TITLES[rng.randi_range(0, PASS_TITLES.size() - 1)]
		Shape.EDGE_FAIL:
			if rng.randf() < 0.5:
				c.skills.append(LOOKALIKE_SKILLS[rng.randi_range(0, LOOKALIKE_SKILLS.size() - 1)])
			else:
				c.self_eval = c.self_eval + LOOKALIKE_EVALS[rng.randi_range(0, LOOKALIKE_EVALS.size() - 1)]
		Shape.FAIL:
			pass
