class_name RuleDegree extends Rule

@export var min_degree: Candidate.Degree = Candidate.Degree.BACHELOR


func check(c: Candidate) -> bool:
	return c.degree >= min_degree


func shape(c: Candidate, form: Shape, rng: RandomNumberGenerator) -> void:
	c.degree_note = ""
	match form:
		Shape.PASS:
			if c.degree < min_degree:
				c.degree = min_degree
		Shape.EDGE_PASS:
			c.degree = min_degree
			c.degree_note = "成人教育，业余修读"
		Shape.EDGE_FAIL:
			c.degree = Candidate.Degree.COLLEGE
			c.degree_note = "专升本在读，尚未毕业"
		Shape.FAIL:
			c.degree = Candidate.Degree.COLLEGE if rng.randf() < 0.7 else Candidate.Degree.HIGH_SCHOOL
