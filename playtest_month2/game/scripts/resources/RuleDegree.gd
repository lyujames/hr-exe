class_name RuleDegree extends Rule
## 社招：本科及以上。实习生：本科、硕士在读都要，大专不要。

@export var min_degree: Candidate.Degree = Candidate.Degree.BACHELOR
## 合格的实习生里硕士占多少。
@export var grad_share := 0.25


func check(c: Candidate) -> bool:
	if c.is_intern:
		return c.degree == Candidate.Degree.BACHELOR or c.degree == Candidate.Degree.MASTER
	return c.degree >= min_degree


func shape(c: Candidate, form: Shape, rng: RandomNumberGenerator) -> void:
	c.degree_note = ""
	if c.is_intern:
		_shape_intern(c, form, rng)
		return
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


## 实习生都在读，看的是现在读的层次：专升本读上了的算，拿了录取还没入学的不算；硕士在读也要。
func _shape_intern(c: Candidate, form: Shape, rng: RandomNumberGenerator) -> void:
	c.undergrad_school = ""
	match form:
		Shape.PASS:
			if rng.randf() < grad_share:
				_make_grad(c, rng)
			else:
				c.degree = Candidate.Degree.BACHELOR
		Shape.EDGE_PASS:
			if rng.randf() < 0.5:
				c.degree = Candidate.Degree.BACHELOR
				c.degree_note = "专升本，本科在读"
			else:
				_make_grad(c, rng)
				c.degree_note = "推免，研一"
		Shape.EDGE_FAIL:
			c.degree = Candidate.Degree.COLLEGE
			c.degree_note = "大专在读，已拿到专升本录取，九月入学"
		Shape.FAIL:
			c.degree = Candidate.Degree.COLLEGE


## 硕士比本科生大一两岁，本科那行写着第一学历的学校。
func _make_grad(c: Candidate, rng: RandomNumberGenerator) -> void:
	c.degree = Candidate.Degree.MASTER
	c.undergrad_school = c.school
	c.birth_date = DateUtil.years_before(GameState.today, rng.randi_range(23, 26), -rng.randi_range(0, 360))
