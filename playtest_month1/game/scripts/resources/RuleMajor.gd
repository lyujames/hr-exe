class_name RuleMajor extends Rule
## “专业对口”：实习生的主修专业要在 TA 应聘的那个岗位的名单上（见 JobPosting.majors）。
## 辅修、双学位不算；转专业转进来的算；研究生看现在读的专业，本科专业写在小字里也不算。
## 陷阱：名字沾边的专业（JobPosting.lookalikes），以及在别的岗位名单上、却投错了岗位的专业。

## 不在任何岗位名单上的专业。
const OTHER_MAJORS := ["汉语言文学", "金融学", "英语", "哲学", "历史学", "数字媒体艺术", "法学", "会计学"]

## 简历上的岗位对不上任何开着的岗位时（只在测试里），退回这份名单。
@export var majors := PackedStringArray(["计算机科学与技术", "软件工程", "统计学", "市场营销"])


func applies_to(c: Candidate) -> bool:
	return c.is_intern


func check(c: Candidate) -> bool:
	return c.major in listed_for(c)


static func listed_for(c: Candidate) -> PackedStringArray:
	var posting := RuleEngine.posting_for(c.applied_position)
	if posting:
		return posting.majors
	var rule: RuleMajor = load("res://data/rules/rule_major.tres")
	return rule.majors


func shape(c: Candidate, form: Shape, rng: RandomNumberGenerator) -> void:
	var listed := listed_for(c)
	var pick := func(list: Array) -> String: return list[rng.randi_range(0, list.size() - 1)]
	var off := _off_list(c, listed)
	c.major_note = ""
	match form:
		Shape.PASS:
			if c.major not in listed:
				c.major = pick.call(Array(listed))
		Shape.EDGE_PASS:
			# 在名单上，但小字看着像不对口
			c.major = pick.call(Array(listed))
			var other: String = pick.call(off)
			match rng.randi_range(0, 2 if c.is_grad() else 1):
				0:
					c.major_note = "大二从%s转入" % other
				1:
					c.major_note = "辅修%s" % other
				2:
					c.major_note = "本科专业：%s" % other
		Shape.EDGE_FAIL:
			var posting := RuleEngine.posting_for(c.applied_position)
			var roll := rng.randf()
			var elsewhere := _other_postings_majors(c, listed)
			if roll < 0.4 and not elsewhere.is_empty():
				# 专业在别的岗位名单上，投的却是这个岗位
				c.major = pick.call(elsewhere)
			elif roll < 0.75 and posting and not posting.lookalikes.is_empty():
				c.major = pick.call(Array(posting.lookalikes))
			else:
				# 名单上的专业写在小字里：辅修，或者研究生的本科
				c.major = pick.call(off)
				c.major_note = ("本科专业：" if c.is_grad() else "辅修") + pick.call(Array(listed))
		Shape.FAIL:
			c.major = pick.call(off)


## 不在这个岗位名单上的专业：其他岗位的专业也算，让同一个专业在不同岗位上有不同结果。
func _off_list(c: Candidate, listed: PackedStringArray) -> Array:
	var result := OTHER_MAJORS.filter(func(m: String) -> bool: return m not in listed)
	return result + _other_postings_majors(c, listed)


func _other_postings_majors(c: Candidate, listed: PackedStringArray) -> Array:
	var result := []
	for posting in RuleEngine.active_postings:
		if posting.title == c.applied_position:
			continue
		for m in posting.majors:
			if m not in listed and m not in result:
				result.append(m)
	return result
