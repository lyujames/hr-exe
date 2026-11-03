class_name RuleGap extends Rule
## 不数月份，只看空窗说明：涉及家庭、生育、身体的拒绝，没写说明的也拒绝。

const PASS_NOTES := ["进修考证", "脱产读研", "创业"]
const EDGE_PASS_NOTES := ["备考公务员", "出国游学", "自由职业"]
const EDGE_FAIL_NOTES := ["家中有事", "陪父亲住院", "产后休整", "术后休养"]
const FAIL_NOTES := ["照顾家人", "备孕", "身体原因", ""]


func check(c: Candidate) -> bool:
	if not c.has_gap():
		return true
	return c.gap_note != "" and not (c.gap_note in EDGE_FAIL_NOTES or c.gap_note in FAIL_NOTES)


func shape(c: Candidate, form: Shape, rng: RandomNumberGenerator) -> void:
	var notes: Array = PASS_NOTES
	match form:
		Shape.PASS:
			if rng.randf() < 0.5:
				c.gap_months = 0
				c.gap_note = ""
				return
		Shape.EDGE_PASS:
			notes = EDGE_PASS_NOTES
		Shape.EDGE_FAIL:
			notes = EDGE_FAIL_NOTES
		Shape.FAIL:
			notes = FAIL_NOTES
	c.gap_months = rng.randi_range(3, 14)
	c.gap_note = notes[rng.randi_range(0, notes.size() - 1)]
