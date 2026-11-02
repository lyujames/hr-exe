class_name RuleAgeLimit extends Rule

## 允许的最大周岁。“35 岁以下”即 34，满 35 周岁当天起拒绝。
@export var max_age := 34


func check(c: Candidate) -> bool:
	return c.get_age(GameState.today) <= max_age


func shape(c: Candidate, form: Shape, rng: RandomNumberGenerator) -> void:
	var today := GameState.today
	match form:
		Shape.PASS:
			c.birth_date = DateUtil.years_before(today, rng.randi_range(max_age - 10, max_age - 2), -rng.randi_range(0, 300))
		Shape.EDGE_PASS:
			c.birth_date = DateUtil.years_before(today, max_age + 1, rng.randi_range(1, 30))
		Shape.EDGE_FAIL:
			c.birth_date = DateUtil.years_before(today, max_age + 1, -rng.randi_range(0, 30))
		Shape.FAIL:
			c.birth_date = DateUtil.years_before(today, rng.randi_range(max_age + 3, max_age + 12), -rng.randi_range(0, 300))
