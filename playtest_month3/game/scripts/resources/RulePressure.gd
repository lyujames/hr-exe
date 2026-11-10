class_name RulePressure extends Rule
## “抗压能力强”：简历第二页每段工作都得待满 12 个月，写“至今”的那段算到今天。
## 简历上不写为什么走：公司倒闭、整个部门被裁，在这条规则眼里都是“扛不住”。

@export var min_months := 12


func applies_to(c: Candidate) -> bool:
	return not c.is_intern


func check(c: Candidate) -> bool:
	var now := DateUtil.month_index(GameState.today)
	for job: Dictionary in c.jobs:
		var end := now if job.end == "" else DateUtil.month_index(job.end)
		if end - DateUtil.month_index(job.start) < min_months:
			return false
	return true


func shape(c: Candidate, form: Shape, rng: RandomNumberGenerator) -> void:
	c.min_stint = min_months
	c.stint_at = -1
	c.stint_len = 0
	match form:
		Shape.EDGE_PASS:
			# 正好一年：2023.03 – 2024.03 算满
			c.stint_at = rng.randi_range(0, 2)
			c.stint_len = min_months
		Shape.EDGE_FAIL:
			# 差一个月；或者最近一段写着“至今”，可刚跳过去不到一年
			if rng.randf() < 0.5:
				c.stint_at = rng.randi_range(1, 2)
			else:
				c.stint_at = 0
				c.left_months_ago = -1
			c.stint_len = min_months - 1
		Shape.FAIL:
			c.stint_at = rng.randi_range(0, 2)
			c.stint_len = rng.randi_range(3, 8)
