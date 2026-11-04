class_name RuleMajor extends Rule
## “指定专业”：实习生只看主修专业在不在名单里。辅修、双学位不算；转专业转进来的算。

const OTHER_MAJORS := ["工商管理", "汉语言文学", "金融学", "人力资源管理", "数字媒体艺术", "英语"]
## 听着沾边、其实不在名单上的专业。
const LOOKALIKES := ["数据科学与大数据技术", "网络与新媒体", "电子商务", "应用统计学"]

@export var majors := PackedStringArray(["计算机科学与技术", "软件工程", "统计学", "市场营销"])


func applies_to(c: Candidate) -> bool:
	return c.is_intern


func check(c: Candidate) -> bool:
	return c.major in majors


func shape(c: Candidate, form: Shape, rng: RandomNumberGenerator) -> void:
	var listed := majors[rng.randi_range(0, majors.size() - 1)]
	var other: String = OTHER_MAJORS[rng.randi_range(0, OTHER_MAJORS.size() - 1)]
	c.major_note = ""
	match form:
		Shape.PASS:
			c.major = listed
		Shape.EDGE_PASS:
			# 在名单上，但小字看着像不对口
			c.major = listed
			c.major_note = "大二从%s转入" % other if rng.randf() < 0.5 else "辅修%s" % other
		Shape.EDGE_FAIL:
			# 要么名字沾边，要么辅修才在名单上
			if rng.randf() < 0.5:
				c.major = LOOKALIKES[rng.randi_range(0, LOOKALIKES.size() - 1)]
			else:
				c.major = other
				c.major_note = "辅修" + listed
		Shape.FAIL:
			c.major = other
