class_name RuleSalary extends Rule

## 期望月薪上限（k）。写区间的按上限算。
@export var max_monthly_k := 18


func check(c: Candidate) -> bool:
	return c.salary_k <= max_monthly_k


func shape(c: Candidate, form: Shape, rng: RandomNumberGenerator) -> void:
	var as_range := rng.randf() < 0.5
	match form:
		Shape.PASS:
			c.salary_k = rng.randi_range(max_monthly_k - 8, max_monthly_k - 2)
		Shape.EDGE_PASS:
			c.salary_k = max_monthly_k
		Shape.EDGE_FAIL:
			# 下限在预算内、上限刚超：看着像能要
			c.salary_k = max_monthly_k + rng.randi_range(1, 2)
			as_range = true
		Shape.FAIL:
			c.salary_k = rng.randi_range(max_monthly_k + 4, max_monthly_k + 12)
	c.salary_low_k = c.salary_k - rng.randi_range(2, 4) if as_range else 0
