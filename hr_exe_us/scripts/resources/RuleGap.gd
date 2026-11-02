class_name RuleGap extends Rule

@export var max_months := 6


func check(c: Candidate) -> bool:
	return c.max_gap_months(GameState.today) <= max_months


func shape(c: Candidate, form: Shape, rng: RandomNumberGenerator) -> void:
	var gap := 0
	match form:
		Shape.PASS:
			gap = rng.randi_range(0, max_months - 2)
		Shape.EDGE_PASS:
			gap = max_months
		Shape.EDGE_FAIL:
			gap = max_months + 1
		Shape.FAIL:
			gap = rng.randi_range(max_months + 3, max_months + 20)
	CandidateGenerator.build_jobs(c, rng, gap)
