class_name RuleCultureFit extends Rule
## 美国版的年龄规则：简历没有出生日期，只能看毕业年份。

## 毕业超过这么多年的不是“digital native”，刚好满这个年数仍算通过。
@export var max_years := 14


func check(c: Candidate) -> bool:
	return _years_since(c) <= max_years


func shape(c: Candidate, form: Shape, rng: RandomNumberGenerator) -> void:
	var years := 0
	match form:
		Shape.PASS:
			years = rng.randi_range(2, max_years - 2)
		Shape.EDGE_PASS:
			years = max_years
		Shape.EDGE_FAIL:
			years = max_years + 1
		Shape.FAIL:
			years = rng.randi_range(max_years + 3, max_years + 12)
	var graduated := DateUtil.parse(GameState.today).x - years
	c.birth_date = "%d-%02d-%02d" % [graduated - 22, rng.randi_range(1, 12), rng.randi_range(1, 28)]


func _years_since(c: Candidate) -> int:
	return DateUtil.parse(GameState.today).x - c.graduation_year()
