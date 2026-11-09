class_name RuleEmployed extends Rule
## “不要裸辞的”：最近一段写“至今”，且附注没自称已离职。

const QUIT_NOTE := "已离职，可随时到岗"
const NOTICE_NOTE := "在职，需一个月交接"


func check(c: Candidate) -> bool:
	return not c.jobs.is_empty() and c.jobs[0].end == "" and not c.attachment.contains("已离职")


func shape(c: Candidate, form: Shape, rng: RandomNumberGenerator) -> void:
	match form:
		Shape.PASS:
			c.left_months_ago = -1
			if c.attachment.contains("已离职"):
				c.attachment = "无"
		Shape.EDGE_PASS:
			c.left_months_ago = -1
			c.attachment = NOTICE_NOTE
		Shape.EDGE_FAIL:
			# 要么这个月刚离职（写的是月份不是“至今”），要么写着至今、附注却说已离职
			if rng.randf() < 0.5:
				c.left_months_ago = 0
			else:
				c.left_months_ago = -1
				c.attachment = QUIT_NOTE
		Shape.FAIL:
			c.left_months_ago = rng.randi_range(2, 10)
			if rng.randf() < 0.5:
				c.attachment = QUIT_NOTE
