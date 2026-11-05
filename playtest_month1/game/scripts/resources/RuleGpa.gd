class_name RuleGpa extends Rule
## “绩点太低的不要”：只管实习生。一眼能判，陷阱是压线附近的 2.9x 和 3.0x。
## 绩点跟能力只松松地挂钩，所以这条会刷掉一些能干的人。

@export var min_gpa := 3.0


func applies_to(c: Candidate) -> bool:
	return c.is_intern


func check(c: Candidate) -> bool:
	return c.gpa >= min_gpa - 0.0001


func shape(c: Candidate, form: Shape, rng: RandomNumberGenerator) -> void:
	match form:
		Shape.PASS:
			# 生成时按能力算的绩点够线就留着，不够才往上抬
			if not check(c):
				c.gpa = snappedf(rng.randf_range(min_gpa + 0.1, 3.9), 0.01)
		Shape.EDGE_PASS:
			c.gpa = snappedf(min_gpa + rng.randi_range(0, 5) * 0.01, 0.01)
		Shape.EDGE_FAIL:
			c.gpa = snappedf(min_gpa - rng.randi_range(1, 6) * 0.01, 0.01)
		Shape.FAIL:
			c.gpa = snappedf(rng.randf_range(2.0, min_gpa - 0.3), 0.01)
