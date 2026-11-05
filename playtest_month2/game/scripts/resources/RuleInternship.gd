class_name RuleInternship extends Rule
## “实习生要能长期干”：每周到岗天数和可实习月数两条都要够，只管实习生。
## 不让玩家算日期：简历上直接写“每周 X 天，N 个月”，陷阱是一条很好看、另一条刚好差一点。

@export var min_days := 4
@export var min_months := 6


func applies_to(c: Candidate) -> bool:
	return c.is_intern


func check(c: Candidate) -> bool:
	return c.intern_days >= min_days and c.intern_months >= min_months


func shape(c: Candidate, form: Shape, rng: RandomNumberGenerator) -> void:
	match form:
		Shape.PASS:
			c.intern_days = rng.randi_range(min_days, 5)
			c.intern_months = rng.randi_range(min_months, 12)
		Shape.EDGE_PASS:
			# 至少一条正好压线
			c.intern_days = min_days
			c.intern_months = min_months if rng.randf() < 0.5 else rng.randi_range(min_months, 12)
		Shape.EDGE_FAIL:
			# 一条很漂亮，另一条差一点
			if rng.randf() < 0.5:
				c.intern_days = 5
				c.intern_months = min_months - 1
			else:
				c.intern_days = min_days - 1
				c.intern_months = 12
		Shape.FAIL:
			c.intern_days = rng.randi_range(2, min_days - 1)
			c.intern_months = rng.randi_range(2, min_months - 2)
