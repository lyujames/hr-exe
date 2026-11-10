class_name RuleSenior extends Rule
## 第 17 天：“工作满 10 年，且 1996 年及以后出生”。年限看第一页的“工作年限”（小字“含实习”“含兼职”的不算），年龄看身份证。
## 两条同时成立的只有一种人：十六七岁就上班、后来拿了成人教育 / 自考本科证的（第 10 天的规则：成人教育拿到证的算）。
## 王总以为自己要的是“年轻的老手”，门开成了陈默的形状。真合格的大约八份里一份，第一页看着都“差”。

const BAD_NOTES := ["含实习", "含兼职"]
const INTERN_NOTES := ["含实习 1 年", "含在校兼职 2 年", "含兼职"]
const EARLY_SCHOOLS := ["中专", "职高", "技校", "大专"]
const ADULT_SCHOOLS := ["东江开放大学", "南山广播电视大学", "北海师范大学继续教育学院", "西川财经大学网络教育学院"]
const ADULT_NOTES := ["成教本科，%d 年拿证", "自考本科，%d 年拿证", "网络教育本科，%d 年毕业"]

@export var min_months := 120
@export var min_birth_year := 1996
## 生成的人里，本来该过的有多少真过得去（门开成了这个形状，大多数人连边都摸不到）。其余的塑成“看着很好”的不合格。
@export_range(0.0, 1.0) var pass_rate := 0.3


func applies_to(c: Candidate) -> bool:
	return not c.is_intern and for_position(c)


func check(c: Candidate) -> bool:
	if c.exp_months < min_months:
		return false
	for word in BAD_NOTES:
		if c.exp_note.contains(word):
			return false
	return DateUtil.parse(c.fact("birth_date", "id_card")).x >= min_birth_year


func shape(c: Candidate, form: Shape, rng: RandomNumberGenerator) -> void:
	c.exp_note = ""
	if form == Shape.PASS and rng.randf() >= pass_rate:
		form = Shape.FAIL
	match form:
		Shape.PASS:
			_make_early(c, rng, rng.randi_range(1996, 1998), rng.randi_range(0, 14))
		Shape.EDGE_PASS:
			# 正好 1996 年初，或者正好 10 年
			if rng.randf() < 0.5:
				_make_early(c, rng, min_birth_year, rng.randi_range(0, 10), rng.randi_range(1, 3))
			else:
				_make_early(c, rng, rng.randi_range(1996, 1998), 0)
				c.exp_months = min_months
		Shape.EDGE_FAIL:
			if rng.randf() < 0.5:
				# 凑够十年是把实习、兼职也算进去了
				_make_early(c, rng, rng.randi_range(1997, 1999), 0)
				c.exp_months = min_months + rng.randi_range(0, 10)
				c.exp_note = INTERN_NOTES[rng.randi_range(0, INTERN_NOTES.size() - 1)]
			else:
				# 身份证是 1995 年底的，简历上写成 1996
				_make_early(c, rng, min_birth_year - 1, rng.randi_range(14, 24), rng.randi_range(10, 12))
				var b := DateUtil.parse(c.birth_date)
				c.override("resume", "birth_date", DateUtil.format(Vector3i(min_birth_year, rng.randi_range(1, 6), b.z)))
				c.honesty = mini(c.honesty, 35)
		Shape.FAIL:
			c.early_start = false
			if rng.randf() < 0.5:
				# 老手：本科统招，十几年经验，可是 80 后、90 后
				c.birth_date = DateUtil.format(Vector3i(rng.randi_range(1984, 1994), rng.randi_range(1, 12), rng.randi_range(1, 28)))
				var age := c.get_age(GameState.today)
				c.exp_months = maxi(age - 22, 11) * 12 + rng.randi_range(0, 11)
			else:
				# 年轻人：统招本科，三到八年
				c.birth_date = DateUtil.format(Vector3i(rng.randi_range(1997, 2001), rng.randi_range(1, 12), rng.randi_range(1, 28)))
				c.exp_months = rng.randi_range(3, 8) * 12 + rng.randi_range(0, 11)
			c.salary_k = rng.randi_range(28, 44)
			c.salary_low_k = 0


## 十六七岁上班：中专、职高、大专起步，后来拿了成教本科证。年限从十六七岁算起。
func _make_early(c: Candidate, rng: RandomNumberGenerator, year: int, extra_months: int, month := 0) -> void:
	c.early_start = true
	c.birth_date = DateUtil.format(Vector3i(year, month if month > 0 else rng.randi_range(1, 12), rng.randi_range(1, 28)))
	var age := c.get_age(GameState.today)
	var start := rng.randi_range(16, 17)
	c.exp_months = maxi(min_months, (age - start) * 12) + extra_months
	# 学历那条规则塑成了大专、高中的，就留着（照样是这种人，只是证还没拿）
	if c.degree >= Candidate.Degree.BACHELOR:
		c.degree = Candidate.Degree.BACHELOR
		c.undergrad_school = ""
		c.school = ADULT_SCHOOLS[rng.randi_range(0, ADULT_SCHOOLS.size() - 1)]
		var note: String = ADULT_NOTES[rng.randi_range(0, ADULT_NOTES.size() - 1)]
		c.degree_note = "第一学历：%s；%s" % [EARLY_SCHOOLS[rng.randi_range(0, EARLY_SCHOOLS.size() - 1)], note % rng.randi_range(2019, 2024)]
	c.salary_k = rng.randi_range(22, 34)
	c.salary_low_k = 0
	c.ability = mini(c.ability + 20, 100)
	c.loyalty = mini(c.loyalty + 15, 100)
