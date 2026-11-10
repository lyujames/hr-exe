class_name RuleExperience extends Rule
## “入门岗也要 5 年经验”：看简历上写的“工作年限”，不数经历。小字写着“含实习”的不算；外包算。

const INTERN_NOTES := ["含实习 1 年", "含在校实习"]
const OK_NOTES := ["含外包驻场 2 年", "其中外包 1 年"]

@export var min_months := 60


func applies_to(c: Candidate) -> bool:
	return not c.is_intern


func check(c: Candidate) -> bool:
	return c.exp_months >= min_months and not c.exp_note.contains("实习")


func shape(c: Candidate, form: Shape, rng: RandomNumberGenerator) -> void:
	c.exp_note = ""
	match form:
		Shape.PASS:
			c.exp_months = rng.randi_range(min_months / 12 + 1, min_months / 12 + 4) * 12 + (rng.randi_range(1, 11) if rng.randf() < 0.4 else 0)
		Shape.EDGE_PASS:
			# 正好 5 年，或者有一段外包：看着虚，其实算
			c.exp_months = min_months if rng.randf() < 0.5 else min_months + rng.randi_range(6, 30)
			if c.exp_months > min_months:
				c.exp_note = OK_NOTES[rng.randi_range(0, OK_NOTES.size() - 1)]
		Shape.EDGE_FAIL:
			# 差一两个月，或者凑够 5 年是把实习也算进去了
			if rng.randf() < 0.5:
				c.exp_months = min_months - rng.randi_range(1, 2)
			else:
				c.exp_months = min_months + rng.randi_range(0, 12)
				c.exp_note = INTERN_NOTES[rng.randi_range(0, INTERN_NOTES.size() - 1)]
		Shape.FAIL:
			c.exp_months = rng.randi_range(1, 3) * 12 + rng.randi_range(0, 8)
