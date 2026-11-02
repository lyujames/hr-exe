class_name CandidateGenerator
## 用种子随机生成路人，并调控陷阱密度：约 40% 的简历刚好卡在规则边界上。
## 这里只负责塑形；对错永远由 RuleEngine 求值。

const EDGE_DENSITY := 0.4
const MAX_JOBS := 4
const FAIL_DENSITY := 0.25

## 姓名按文化来源成组，只作暗示：选组与国籍、身份互相独立，任何规则都不读取。
const NAME_POOLS := [
	{"given": ["Emily", "Connor", "Hannah", "Greg", "Claire", "Tucker"], "surnames": ["Murphy", "Walker", "Baker", "Sullivan", "Hall"]},
	{"given": ["Imani", "Malik", "Tanisha", "Darnell", "Aaliyah", "Andre"], "surnames": ["Washington", "Jefferson", "Banks", "Booker", "Freeman"]},
	{"given": ["Elena", "Luis", "Sofia", "Mateo", "Camila", "Carlos"], "surnames": ["Garcia", "Lopez", "Rivera", "Diaz", "Morales"]},
	{"given": ["Priya", "Dev", "Meera", "Arjun", "Anjali", "Rohan"], "surnames": ["Patel", "Sharma", "Iyer", "Reddy", "Gupta"]},
	{"given": ["Mei", "Jin", "Hana", "Minh", "Yuki", "Wei"], "surnames": ["Chen", "Kim", "Nguyen", "Tanaka", "Park"]},
	{"given": ["Omar", "Layla", "Chidi", "Ngozi", "Amina", "Tunde"], "surnames": ["Hassan", "Haddad", "Okafor", "Adeyemi", "Mansour"]},
]
const POSITIONS := ["Frontend Engineer", "Ops Associate", "Product Associate", "Data Analyst"]
const SCHOOLS := ["Lakeshore State University", "Ridgeline Tech", "Harbor City University", "Prairie A&M", "Cascade College", "Mill Valley University"]
const COLLEGES := ["Lakeshore Community College", "Ridgeline Technical Institute", "Harbor City Junior College"]
const COMPANIES := ["Tradewind Labs", "Northstar Media", "BlueOak Data", "Copperline", "ShopCircle", "Vantage Soft", "Everpeak"]
const TITLES := ["Specialist", "Engineer", "Coordinator", "Project Lead", "Analyst"]
const SKILLS := ["Python", "SQL", "Excel", "JavaScript", "Figma", "Analytics", "Stakeholder Mgmt", "Growth", "Agile", "Salesforce", "React", "Tableau"]
const SELF_EVALS := [
	"Fast learner who thrives in collaborative teams.",
	"Reliable and detail-minded. I do what I say I'll do.",
	"Results-driven communicator with a bias for action.",
	"Passionate about the work and excited to grow.",
	"Curious, adaptable, and energized by new challenges.",
	"Looking for a place I can stay and build a career.",
]
const FOREIGN := ["Canada", "Mexico", "India", "China", "Philippines", "Nigeria", "Germany", "Brazil", "South Korea", "Vietnam"]
const ATTACHMENTS := ["None", "Portfolio: link expired", "Reference: former manager, on file", "Available immediately", "Currently employed, 2 weeks' notice"]


static func generate_day(cfg: DayConfig, rules: Array[Rule], day_seed: int) -> Array[Candidate]:
	var rng := RandomNumberGenerator.new()
	rng.seed = day_seed
	var result: Array[Candidate] = []
	for i in cfg.resume_count:
		result.append(_generate(rng, rules, "gen_%d_%02d" % [cfg.day, i]))
	for story in cfg.story_candidates:
		result.insert(mini(cfg.story_slot, result.size()), story)
	return result


static func _generate(rng: RandomNumberGenerator, rules: Array[Rule], id: String) -> Candidate:
	var c := _base(rng, id)
	var target: Rule = rules[rng.randi_range(0, rules.size() - 1)]
	var roll := rng.randf()
	var target_form := Rule.Shape.PASS
	if roll < EDGE_DENSITY:
		target_form = Rule.Shape.EDGE_PASS if rng.randf() < 0.5 else Rule.Shape.EDGE_FAIL
	elif roll < EDGE_DENSITY + FAIL_DENSITY:
		target_form = Rule.Shape.FAIL
	for rule in rules:
		rule.shape(c, target_form if rule == target else Rule.Shape.PASS, rng)
	if c.degree < Candidate.Degree.BACHELOR:
		c.school = COLLEGES[rng.randi_range(0, COLLEGES.size() - 1)]
	# 荒谬规则刷掉的人，往往是更好的员工
	if target.is_absurd and target_form >= Rule.Shape.EDGE_FAIL:
		c.ability = mini(c.ability + 25, 100)
		c.loyalty = mini(c.loyalty + 20, 100)
	return c


static func _base(rng: RandomNumberGenerator, id: String) -> Candidate:
	var c := Candidate.new()
	var pick := func(list: Array) -> Variant: return list[rng.randi_range(0, list.size() - 1)]
	c.id = id
	var names: Dictionary = pick.call(NAME_POOLS)
	c.display_name = pick.call(names.given) + " " + pick.call(names.surnames)
	c.applied_position = pick.call(POSITIONS)
	c.birth_date = DateUtil.years_before(GameState.today, rng.randi_range(24, 44), -rng.randi_range(0, 360))
	c.degree = Candidate.Degree.BACHELOR if rng.randf() < 0.7 else Candidate.Degree.MASTER
	c.school = pick.call(SCHOOLS)
	var skills := SKILLS.duplicate()
	for i in 4:
		c.skills.append(skills.pop_at(rng.randi_range(0, skills.size() - 1)))
	c.bonus_pct = [0, 5, 10][rng.randi_range(0, 2)]
	c.salary_k = rng.randi_range(60, 100)
	c.self_eval = pick.call(SELF_EVALS)
	c.attachment = pick.call(ATTACHMENTS)
	c.portrait_seed = rng.randi()
	_assign_status(c, rng)
	c.ability = rng.randi_range(20, 90)
	c.honesty = rng.randi_range(15, 95)
	c.loyalty = rng.randi_range(15, 90)
	c.pressure = rng.randi_range(20, 90)
	c.performance = rng.randi_range(10, 95)
	build_jobs(c, rng, rng.randi_range(0, 12))
	return c


## 默认都合法且有效；违规形态由规则的 shape() 塑造。OPT 留够天数，不误伤第 3 天的政策。
static func _assign_status(c: Candidate, rng: RandomNumberGenerator) -> void:
	var roll := rng.randf()
	if roll < 0.6:
		return
	var today := GameState.today
	c.nationality = FOREIGN[rng.randi_range(0, FOREIGN.size() - 1)]
	if roll < 0.75:
		c.work_status = Candidate.STATUS_GREEN_CARD
	elif roll < 0.85:
		c.work_status = Candidate.STATUS_H1B
		c.status_expiry = DateUtil.add_days(today, rng.randi_range(120, 700))
	elif roll < 0.95:
		c.work_status = Candidate.STATUS_OPT
		c.status_expiry = DateUtil.add_days(today, rng.randi_range(40, 300))
	else:
		c.nationality = Candidate.TN_COUNTRIES[rng.randi_range(0, 1)]
		c.work_status = Candidate.STATUS_TN
		c.status_expiry = DateUtil.add_days(today, rng.randi_range(120, 700))


## 从今天往回排工作经历，并在其中放入恰好一段 gap 个月的空窗。
static func build_jobs(c: Candidate, rng: RandomNumberGenerator, gap: int) -> void:
	var now := DateUtil.month_index(GameState.today)
	var career := maxi((c.get_age(GameState.today) - 22) * 12, 12)
	gap = mini(gap, maxi(career - 6, 0))
	var gap_before_latest := gap > 0 and career - gap >= 30 and rng.randf() < 0.5
	var cursor := now
	var earliest := now - career
	c.jobs = []
	var first := true
	while cursor - earliest >= 6 and c.jobs.size() < MAX_JOBS:
		var length := mini(rng.randi_range(14, 40), cursor - earliest)
		if first and gap > 0 and not gap_before_latest:
			cursor -= gap
			length = mini(length, maxi(cursor - earliest, 6))
		var end := "" if first and (gap == 0 or gap_before_latest) else DateUtil.month_string(cursor)
		c.jobs.append({
			"company": COMPANIES[rng.randi_range(0, COMPANIES.size() - 1)],
			"title": TITLES[rng.randi_range(0, TITLES.size() - 1)],
			"start": DateUtil.month_string(cursor - length),
			"end": end,
		})
		cursor -= length
		if first and gap_before_latest:
			cursor -= gap
		first = false
