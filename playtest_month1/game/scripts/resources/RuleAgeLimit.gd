class_name RuleAgeLimit extends Rule

## “只要 90 后”：只看出生年份，不算周岁。带了身份证的看身份证，简历上写的不算。
@export var min_birth_year := 1990


func check(c: Candidate) -> bool:
	return DateUtil.parse(c.fact("birth_date", "id_card")).x >= min_birth_year


func shape(c: Candidate, form: Shape, rng: RandomNumberGenerator) -> void:
	var latest := DateUtil.parse(GameState.today).x - 25
	var year := 0
	var month := rng.randi_range(1, 12)
	match form:
		Shape.PASS:
			year = rng.randi_range(min_birth_year + 1, maxi(latest, min_birth_year + 1))
		Shape.EDGE_PASS:
			year = min_birth_year
			month = rng.randi_range(1, 3)
		Shape.EDGE_FAIL:
			year = min_birth_year - 1
			month = rng.randi_range(10, 12)
		Shape.FAIL:
			year = rng.randi_range(min_birth_year - 10, min_birth_year - 3)
	c.birth_date = DateUtil.format(Vector3i(year, month, rng.randi_range(1, 28)))
