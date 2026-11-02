class_name RuleSalary extends Rule

@export var max_annual := 240000


func check(c: Candidate) -> bool:
	return c.annual_salary() <= max_annual


func shape(c: Candidate, form: Shape, rng: RandomNumberGenerator) -> void:
	var months: int = [12, 13, 14, 15, 16][rng.randi_range(0, 4)]
	var limit_k := floori(max_annual / 1000.0 / months)
	c.salary_months = months
	match form:
		Shape.PASS:
			c.salary_k = rng.randi_range(limit_k - 8, limit_k - 2)
		Shape.EDGE_PASS:
			c.salary_k = limit_k
		Shape.EDGE_FAIL:
			c.salary_k = limit_k + 1
		Shape.FAIL:
			c.salary_k = rng.randi_range(limit_k + 3, limit_k + 12)
