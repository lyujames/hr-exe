class_name RuleVisaPolicy extends Rule
## 手册不写的规则：H-1B 来自前一晚的报纸，OPT 期限来自法务通知。

@export var blocked: PackedStringArray
@export var opt_min_days := 30


func check(c: Candidate) -> bool:
	if c.work_status in blocked:
		return false
	return c.work_status != Candidate.STATUS_OPT or DateUtil.days_between(GameState.today, c.status_expiry) >= opt_min_days


func shape(c: Candidate, form: Shape, rng: RandomNumberGenerator) -> void:
	var today := GameState.today
	match form:
		Shape.PASS:
			# 已经违反工作授权的人留给那条规则，别在这里洗白
			if c.authorized_on(today) and not check(c):
				c.nationality = "United States"
				c.work_status = Candidate.STATUS_CITIZEN
				c.status_expiry = ""
		Shape.EDGE_PASS:
			_set_status(c, rng, Candidate.STATUS_OPT, DateUtil.add_days(today, opt_min_days))
		Shape.EDGE_FAIL:
			_set_status(c, rng, Candidate.STATUS_OPT, DateUtil.add_days(today, opt_min_days - 1))
		Shape.FAIL:
			_set_status(c, rng, blocked[0], DateUtil.add_days(today, rng.randi_range(200, 700)))


func _set_status(c: Candidate, rng: RandomNumberGenerator, status: String, expiry: String) -> void:
	var foreign := CandidateGenerator.FOREIGN
	c.nationality = foreign[rng.randi_range(0, foreign.size() - 1)]
	c.work_status = status
	c.status_expiry = expiry
