class_name RuleFullTime extends Rule
## 第 23 天：HireBot 规则 #001“第一学历须为全日制本科”。看学历栏的小字：成人教育、自考、网络教育、开放大学、专升本都不算。
## 跟第 17 天那两条放在一起，合格的人数是零（空集日）：放谁都违反一条。

const NOT_FULL_TIME := ["成人", "自考", "业余", "网络教育", "非全日制", "专升本", "开放大学", "广播电视", "继续教育", "第一学历"]
const EDGE_PASS_NOTES := ["全日制统招本科", "统招本科，辅修计算机"]
const EDGE_FAIL_NOTES := ["专升本（全日制），2019 年毕业", "第一学历 东江职业技术学院（大专）；全日制专升本"]


func applies_to(c: Candidate) -> bool:
	return not c.is_intern


func check(c: Candidate) -> bool:
	if c.degree < Candidate.Degree.BACHELOR:
		return false
	for word: String in NOT_FULL_TIME:
		if c.degree_note.contains(word) or c.school.contains(word) or c.first_school().contains(word):
			return false
	return true


## 合格的不动（跟年限那条撞上就撞上，那正是这一天）；不合格的往小字里塞一句。
func shape(c: Candidate, form: Shape, rng: RandomNumberGenerator) -> void:
	if c.early_start:
		return
	match form:
		Shape.EDGE_PASS:
			if c.degree >= Candidate.Degree.BACHELOR and c.degree_note == "":
				c.degree_note = EDGE_PASS_NOTES[rng.randi_range(0, EDGE_PASS_NOTES.size() - 1)]
		Shape.EDGE_FAIL, Shape.FAIL:
			if c.degree >= Candidate.Degree.BACHELOR:
				c.degree_note = EDGE_FAIL_NOTES[rng.randi_range(0, EDGE_FAIL_NOTES.size() - 1)]
