class_name RuleKeywords extends Rule
## “简历关键词匹配”：技能栏要一字不差地写全 JD 上的必备技能（JavaScript 不是 Java，SQL 不是 MySQL）；
## 技能写了超过 max_skills 个，算关键词堆砌，也拒。

const FILLERS := ["Python", "Go", "Spring Boot", "Kafka", "Docker", "Linux", "Git", "Vue", "MongoDB", "Kubernetes", "Nginx", "Elasticsearch"]

@export var max_skills := 8
## 按组招的版本（第 13 天起）：技能对得上今天任何一个组就算过；放进哪个组另算（RuleEngine.folder_problem）。
@export var per_team := false


func applies_to(c: Candidate) -> bool:
	return not c.is_intern and not _posting_keywords(c).is_empty()


func check(c: Candidate) -> bool:
	if c.skills.size() > max_skills:
		return false
	if per_team and RuleEngine.folder_mode:
		return RuleEngine.folders().any(func(p: JobPosting) -> bool: return RuleEngine.skills_fit(c, p, max_skills))
	for keyword in _posting_keywords(c):
		if keyword not in c.skills:
			return false
	return true


static func _posting_keywords(c: Candidate) -> PackedStringArray:
	var posting := RuleEngine.posting_for(c.applied_position)
	return posting.keywords if posting else PackedStringArray()


static func _lookalikes(c: Candidate) -> PackedStringArray:
	var posting := RuleEngine.posting_for(c.applied_position)
	return posting.keyword_lookalikes if posting else PackedStringArray()


static func fillers() -> Array:
	return FILLERS.duplicate()


func shape(c: Candidate, form: Shape, rng: RandomNumberGenerator) -> void:
	var keywords := Array(_posting_keywords(c))
	var lookalikes_all := Array(_lookalikes(c))
	# 填充技能从这个岗位自己的技能池里抽（前端填 TypeScript、React，运维填 Kubernetes、Nginx），没有池才用通用的。
	# 不能有必备技能（少写的那两项不能又被补回来），也不能有长得像的（陷阱只由 EDGE_FAIL 放）
	var posting := RuleEngine.posting_for(c.applied_position)
	var source: Array = Array(posting.skill_pool) if posting and not posting.skill_pool.is_empty() else fillers()
	var pool := source.filter(func(s: String) -> bool: return s not in keywords and s not in lookalikes_all)
	if pool.size() < max_skills + 1 - keywords.size():
		for s: String in fillers():
			if s not in pool and s not in keywords and s not in lookalikes_all:
				pool.append(s)
	var picked: Array = keywords.duplicate()
	var total := rng.randi_range(4, 6)
	match form:
		Shape.EDGE_PASS:
			# 正好写满上限：看着像堆砌，其实没超
			total = max_skills
		Shape.EDGE_FAIL:
			if rng.randf() < 0.5:
				# 一项写成了长得像的
				var lookalikes := _lookalikes(c)
				var i := rng.randi_range(0, keywords.size() - 1)
				picked[i] = lookalikes[i % lookalikes.size()] if not lookalikes.is_empty() else pool[0]
			else:
				# 多写了一个：超过上限
				total = max_skills + 1
		Shape.FAIL:
			# 少写两项
			for i in 2:
				picked.pop_at(rng.randi_range(0, picked.size() - 1))
	while picked.size() < total and not pool.is_empty():
		var s: String = pool.pop_at(rng.randi_range(0, pool.size() - 1))
		if s not in picked:
			picked.append(s)
	# 打乱顺序，必备技能不总在前面
	for i in range(picked.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t: Variant = picked[i]
		picked[i] = picked[j]
		picked[j] = t
	c.skills = PackedStringArray(picked)
