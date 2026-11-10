class_name RuleAgeLimit extends Rule

## “只要 00 后”：只看出生年份，不算周岁。带了身份证的看身份证，简历上写的不算。
@export var min_birth_year := 2000


func check(c: Candidate) -> bool:
	return DateUtil.parse(c.fact("birth_date", "id_card")).x >= min_birth_year


func shape(c: Candidate, form: Shape, rng: RandomNumberGenerator) -> void:
	var current := DateUtil.parse(c.birth_date).x
	var year := 0
	var month := rng.randi_range(1, 12)
	match form:
		Shape.PASS:
			# 本来就够年轻的留着，免得把研究生改成十八岁
			year = current if current > min_birth_year else rng.randi_range(min_birth_year + 1, min_birth_year + 3)
		Shape.EDGE_PASS:
			year = min_birth_year
			month = rng.randi_range(1, 3)
		Shape.EDGE_FAIL:
			year = min_birth_year - 1
			month = rng.randi_range(10, 12)
		Shape.FAIL:
			# 工作过几年又回来读书的
			year = rng.randi_range(min_birth_year - 7, min_birth_year - 3)
	c.birth_date = DateUtil.format(Vector3i(year, month, rng.randi_range(1, 28)))
