class_name CandidateGenerator
## 用种子随机生成路人，并调控陷阱密度：约 40% 的简历刚好卡在规则边界上。
## 这里只负责塑形；对错永远由 RuleEngine 求值。

const EDGE_DENSITY := 0.4
const MAX_JOBS := 4
const FAIL_DENSITY := 0.25

const SURNAMES := ["李", "王", "张", "刘", "陈", "杨", "赵", "黄", "周", "吴", "徐", "孙", "马", "朱", "胡", "林", "郭", "何", "高", "罗"]
const GIVEN := ["伟", "芳", "娜", "敏", "静", "强", "磊", "洋", "勇", "杰", "娟", "涛", "明", "超", "秀英", "晓东", "雅婷", "子轩", "思远", "浩然", "欣怡", "建国", "文博", "梦瑶"]
const POSITIONS := ["前端工程师", "运营专员", "产品助理", "数据分析师"]
const SCHOOLS := ["东江大学", "南山理工大学", "北海师范大学", "西川财经大学", "云岭大学", "明湖学院"]
const COLLEGES := ["东江职业技术学院", "南山城市学院", "北海商务专科学校"]
const COMPANIES := ["拓鼎科技", "星河互动", "蓝海传媒", "云帆数据", "优品电商", "万象网络", "恒远软件"]
const TITLES := ["专员", "工程师", "主管助理", "项目协调", "分析师"]
const SKILLS := ["Python", "SQL", "Excel", "JavaScript", "Figma", "数据分析", "沟通协调", "用户运营", "项目管理", "英语六级", "React", "Tableau"]
const SELF_EVALS := [
	"性格开朗，学习能力强，能快速融入团队。",
	"做事踏实，有责任心，抗压能力强。",
	"结果导向，善于沟通，有较强的执行力。",
	"热爱本职工作，愿与公司共同成长。",
	"注重细节，乐于接受新挑战。",
	"希望找一份能长期做下去的工作。",
]
const ATTACHMENTS := ["无", "作品集：见附件（未附）", "推荐人：前主管，电话已留", "已离职，可随时到岗", "在职，需一个月交接"]


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
	c.display_name = pick.call(SURNAMES) + pick.call(GIVEN)
	c.applied_position = pick.call(POSITIONS)
	c.birth_date = DateUtil.years_before(GameState.today, rng.randi_range(24, 44), -rng.randi_range(0, 360))
	c.degree = Candidate.Degree.BACHELOR if rng.randf() < 0.7 else Candidate.Degree.MASTER
	c.school = pick.call(SCHOOLS)
	var skills := SKILLS.duplicate()
	for i in 4:
		c.skills.append(skills.pop_at(rng.randi_range(0, skills.size() - 1)))
	c.salary_months = [12, 13, 14][rng.randi_range(0, 2)]
	c.salary_k = rng.randi_range(9, 26)
	c.self_eval = pick.call(SELF_EVALS)
	c.attachment = pick.call(ATTACHMENTS)
	c.portrait_seed = rng.randi()
	c.ability = rng.randi_range(20, 90)
	c.honesty = rng.randi_range(15, 95)
	c.loyalty = rng.randi_range(15, 90)
	c.pressure = rng.randi_range(20, 90)
	c.performance = rng.randi_range(10, 95)
	build_jobs(c, rng, rng.randi_range(0, 12))
	return c


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
