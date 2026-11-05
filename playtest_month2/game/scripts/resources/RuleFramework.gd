class_name RuleFramework extends Rule
## “框架 N 年经验”：技能栏里那项框架后面括号写的年数要够（“Banyan（8 年）”）。
## 框架本身才出了几年，所以写够年数的人都在编；规则只看写的。

@export var framework := "Banyan"
@export var min_years := 8
@export var max_skills := 8


func applies_to(c: Candidate) -> bool:
	return not c.is_intern


func check(c: Candidate) -> bool:
	return claimed_years(c) >= min_years


## 技能栏里写的框架年数；没写这个框架为 -1，写了没写年数为 0。
func claimed_years(c: Candidate) -> int:
	for skill in c.skills:
		if skill.begins_with(framework):
			var digits := skill.trim_prefix(framework).replace("（", "").replace("）", "").replace("年", "").strip_edges()
			return int(digits) if digits.is_valid_int() else 0
	return -1


func shape(c: Candidate, form: Shape, rng: RandomNumberGenerator) -> void:
	var years := -1
	match form:
		Shape.PASS:
			years = rng.randi_range(min_years, min_years + 2)
		Shape.EDGE_PASS:
			years = min_years
		Shape.EDGE_FAIL:
			# 照实写：框架出来几年就写几年
			years = rng.randi_range(min_years - 5, min_years - 1)
		Shape.FAIL:
			years = -1 if rng.randf() < 0.5 else rng.randi_range(1, 2)
	var skills := Array(c.skills).filter(func(s: String) -> bool: return not s.begins_with(framework))
	if years >= 0:
		var entry := "%s（%d 年）" % [framework, years]
		var keywords := Array(RuleKeywords._posting_keywords(c))
		if skills.size() >= max_skills:
			# 顶掉一个不是必备技能的，免得把技能栏写超
			for i in range(skills.size() - 1, -1, -1):
				if skills[i] not in keywords:
					skills.remove_at(i)
					break
		skills.insert(rng.randi_range(0, skills.size()), entry)
	# 写够年数的人都在编：框架才出三年
	if years >= min_years:
		c.honesty = mini(c.honesty, 30)
	c.skills = PackedStringArray(skills)
