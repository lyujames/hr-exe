class_name RuleMarital extends Rule
## 第 19 天：“已婚未育的女同志，这个岗先不考虑”。王总只在邮件里写，不进手册（hidden），拒绝理由里也没有这一句。
## 简历多了一栏“婚育状况”，跟性别写在一行。只看“女”和“已婚未育”四个字；“未婚”“已婚已育”不在这条里，男的也不在。
## 违法（is_illegal）：照着拒了，GameState.record_decision 给诉讼风险记一笔。

const PASS_STATUS := ["未婚", "已婚已育（一孩）", "已婚已育（两孩）", "未婚", "离异"]
const EDGE_PASS_STATUS := ["已婚已育（一孩，无二胎计划）", "未婚（已有男友，暂无婚育计划）"]
const EDGE_FAIL_STATUS := ["已婚未育（三年内无生育计划，可签承诺书）", "已婚未育（丁克）"]


func applies_to(c: Candidate) -> bool:
	return not c.is_intern


func check(c: Candidate) -> bool:
	return not (c.gender == "女" and c.marital.begins_with("已婚未育"))


func shape(c: Candidate, form: Shape, rng: RandomNumberGenerator) -> void:
	if c.gender == "":
		c.gender = "女" if rng.randf() < 0.45 else "男"
	_fit_portrait(c)
	match form:
		Shape.PASS:
			c.marital = PASS_STATUS[rng.randi_range(0, PASS_STATUS.size() - 1)]
		Shape.EDGE_PASS:
			# 男的已婚未育，不在这条里
			if rng.randf() < 0.5:
				c.gender = "男"
				c.marital = "已婚未育"
			else:
				c.marital = EDGE_PASS_STATUS[rng.randi_range(0, EDGE_PASS_STATUS.size() - 1)]
		Shape.EDGE_FAIL:
			c.gender = "女"
			c.marital = EDGE_FAIL_STATUS[rng.randi_range(0, EDGE_FAIL_STATUS.size() - 1)]
		Shape.FAIL:
			c.gender = "女"
			c.marital = "已婚未育"
	_fit_portrait(c)


## 照片跟性别对上：女的长发或盘发。
func _fit_portrait(c: Candidate) -> void:
	c.portrait_seed = PortraitFactory.seed_for(c.portrait_seed, c.gender == "女")
