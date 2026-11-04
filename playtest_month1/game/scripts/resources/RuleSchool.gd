class_name RuleSchool extends Rule
## “第一学历必须名校”：看本科学校。读了研的看本科那行；名校的独立学院不算名校。

const OTHER_SCHOOLS := ["北海师范大学", "云岭大学", "明湖学院"]
const BRANCH_SUFFIXES := ["科文学院", "城市学院"]

@export var whitelist := PackedStringArray(["东江大学", "南山理工大学", "西川财经大学"])


func check(c: Candidate) -> bool:
	return c.first_school() in whitelist


func shape(c: Candidate, form: Shape, rng: RandomNumberGenerator) -> void:
	var famous := whitelist[rng.randi_range(0, whitelist.size() - 1)]
	var other: String = OTHER_SCHOOLS[rng.randi_range(0, OTHER_SCHOOLS.size() - 1)]
	c.undergrad_school = ""
	match form:
		Shape.PASS:
			c.school = famous
		Shape.EDGE_PASS:
			# 研究生读得一般，本科是名校：看着差，其实过
			c.degree = Candidate.Degree.MASTER
			c.school = other
			c.undergrad_school = famous
		Shape.EDGE_FAIL:
			# 要么是名校名下的独立学院，要么研究生名校、本科不是
			if rng.randf() < 0.5:
				c.school = famous + BRANCH_SUFFIXES[rng.randi_range(0, BRANCH_SUFFIXES.size() - 1)]
			else:
				c.degree = Candidate.Degree.MASTER
				c.school = famous
				c.undergrad_school = other
		Shape.FAIL:
			c.school = other
