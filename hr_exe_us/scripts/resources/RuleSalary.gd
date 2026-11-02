class_name RuleSalary extends Rule

@export var max_annual := 110000


func check(c: Candidate) -> bool:
	return c.annual_salary() <= max_annual


func shape(c: Candidate, form: Shape, rng: RandomNumberGenerator) -> void:
	var bonus: int = [0, 5, 10, 15, 20][rng.randi_range(0, 4)]
	var limit_k := floori(max_annual / 10.0 / (100 + bonus))
	c.bonus_pct = bonus
	match form:
		Shape.PASS:
			c.salary_k = rng.randi_range(limit_k - 25, limit_k - 3)
		Shape.EDGE_PASS:
			c.salary_k = limit_k
		Shape.EDGE_FAIL:
			c.salary_k = limit_k + 1
		Shape.FAIL:
			c.salary_k = rng.randi_range(limit_k + 3, limit_k + 30)
