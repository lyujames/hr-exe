class_name RuleAiResume extends Rule
## 第 20 天：“AI 写的简历不要”。HireBot 在简历右上角标“AI 生成概率”，超过 50% 拒；正好 50% 不算。
## 它判得不准：写得规整的人被标高，机器写的带两个错别字就标低。规则只看那个数。

@export var max_prob := 50


func applies_to(c: Candidate) -> bool:
	return not c.is_intern


func check(c: Candidate) -> bool:
	return c.ai_prob <= max_prob


func shape(c: Candidate, form: Shape, rng: RandomNumberGenerator) -> void:
	match form:
		Shape.PASS:
			c.ai_prob = rng.randi_range(4, 41)
		Shape.EDGE_PASS:
			c.ai_prob = max_prob if rng.randf() < 0.5 else rng.randi_range(max_prob - 6, max_prob - 1)
		Shape.EDGE_FAIL:
			c.ai_prob = rng.randi_range(max_prob + 1, max_prob + 7)
		Shape.FAIL:
			c.ai_prob = rng.randi_range(66, 97)
