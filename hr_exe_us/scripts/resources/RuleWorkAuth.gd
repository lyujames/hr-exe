class_name RuleWorkAuth extends Rule
## 身份过期，或身份与国籍对不上。


func check(c: Candidate) -> bool:
	return c.authorized_on(GameState.today)


func shape(c: Candidate, form: Shape, rng: RandomNumberGenerator) -> void:
	var today := GameState.today
	match form:
		Shape.EDGE_PASS:
			_set_tn(c, rng, Candidate.TN_COUNTRIES[rng.randi_range(0, 1)], today)
		Shape.EDGE_FAIL:
			_set_tn(c, rng, Candidate.TN_COUNTRIES[rng.randi_range(0, 1)], DateUtil.add_days(today, -1))
		Shape.FAIL:
			var others: Array = CandidateGenerator.FOREIGN.filter(func(n: String) -> bool: return not n in Candidate.TN_COUNTRIES)
			_set_tn(c, rng, others[rng.randi_range(0, others.size() - 1)], DateUtil.add_days(today, rng.randi_range(60, 300)))


func _set_tn(c: Candidate, _rng: RandomNumberGenerator, nationality: String, expiry: String) -> void:
	c.nationality = nationality
	c.work_status = Candidate.STATUS_TN
	c.status_expiry = expiry
