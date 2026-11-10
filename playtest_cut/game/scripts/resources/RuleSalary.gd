class_name RuleSalary extends Rule

## 期望月薪上限（k）。写区间的按上限算。
@export var max_monthly_k := 18
## 按组招的版本：上限看组（JobPosting.salary_cap_k）。技能对得上的组里，有一个上限够就算过；
## 哪个组的技能都对不上的，看所有组里最高的上限（这时候它挂在关键词那条上，这条不再重复记）。
@export var per_team := false


func applies_to(c: Candidate) -> bool:
	return not c.is_intern and for_position(c)


func check(c: Candidate) -> bool:
	# 砍减版：没有文件夹了，按组招的日子看简历投的那个组那页 JD 的上限
	if per_team and not RuleEngine.folder_mode:
		return c.salary_k <= _cap(c)
	if per_team and RuleEngine.folder_mode:
		var folders := RuleEngine.folders()
		if folders.is_empty():
			return c.salary_k <= max_monthly_k
		var skilled := folders.filter(func(p: JobPosting) -> bool: return RuleEngine.skills_fit(c, p))
		var pool: Array = skilled if not skilled.is_empty() else folders
		return pool.any(func(p: JobPosting) -> bool: return c.salary_k <= p.salary_cap_k)
	return c.salary_k <= max_monthly_k


## 塑形用的上限：按组招时用 TA 投的那个组的。
func _cap(c: Candidate) -> int:
	if per_team:
		var posting := RuleEngine.posting_for(c.applied_position)
		if posting and posting.team != "":
			return posting.salary_cap_k
	return max_monthly_k


func shape(c: Candidate, form: Shape, rng: RandomNumberGenerator) -> void:
	var cap := _cap(c)
	var as_range := rng.randf() < 0.5
	match form:
		Shape.PASS:
			c.salary_k = rng.randi_range(cap - 8, cap - 2)
		Shape.EDGE_PASS:
			c.salary_k = cap
		Shape.EDGE_FAIL:
			# 下限在预算内、上限刚超：看着像能要
			c.salary_k = cap + rng.randi_range(1, 2)
			as_range = true
		Shape.FAIL:
			c.salary_k = rng.randi_range(cap + 4, cap + 12)
	c.salary_low_k = c.salary_k - rng.randi_range(2, 4) if as_range else 0
