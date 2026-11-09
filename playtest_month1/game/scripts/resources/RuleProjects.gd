class_name RuleProjects extends Rule
## “实习生要有在校项目经历”：简历第二页的“在校项目”至少写了一段。只管实习生。
## 第一页看不出来，得翻页——这条规则就是让玩家从第一天起养成翻第二页的习惯。
## 陷阱：项目栏空着，自评里却写“参与过多个项目”；压线的只有一段、两三个月。
## 项目本身由生成器最后排（CandidateGenerator.build_projects），这里只定排几段。

const CLAIM_EVALS := [
	"参与过多个校园项目，执行力强，善于团队协作。",
	"项目经验丰富，能独立推进工作。",
	"大学期间积极参与各类项目，动手能力强。",
]


func applies_to(c: Candidate) -> bool:
	return c.is_intern


func check(c: Candidate) -> bool:
	return not c.projects.is_empty()


func shape(c: Candidate, form: Shape, rng: RandomNumberGenerator) -> void:
	match form:
		Shape.PASS:
			c.project_count = -1
		Shape.EDGE_PASS:
			c.project_count = 1
		Shape.EDGE_FAIL:
			# 栏里空着，自评说得像做过很多
			c.project_count = 0
			c.self_eval = CLAIM_EVALS[rng.randi_range(0, CLAIM_EVALS.size() - 1)]
		Shape.FAIL:
			c.project_count = 0
