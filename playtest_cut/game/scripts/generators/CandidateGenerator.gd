class_name CandidateGenerator
## 用种子随机生成路人，并调控陷阱密度：约 40% 的简历刚好卡在规则边界上（规则加入当天除外）。
## 这里只负责塑形；对错永远由 RuleEngine 求值。

const EDGE_DENSITY := 0.4
const MAX_JOBS := 4
const FAIL_DENSITY := 0.25
## 先教后考：规则加入当天被抽中的权重，以及当天不出边界陷阱，第二天起才出。
const NEW_RULE_WEIGHT := 3
const NEW_POSTING_WEIGHT := 2

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
const ATTACHMENTS := ["无", "作品集：见附件（未附）", "推荐人：前主管，电话已留"]
## 人群背景：按 DayConfig.candidate_mix 抽取。只定年龄段、离职状态和自我评价，
## 规则相关的字段之后仍由 shape() 改写。
const FRESH_EVALS := [
	"应届毕业，愿意从实习做起。",
	"在校期间担任学生会干部，组织能力强。",
	"做过几个课题项目，动手能力强。",
]
## 实习生：没有工作经历，看学校、专业和在校参加的项目。专业先从所投岗位的名单里抽，没有岗位时用这份。
const MAJORS := ["计算机科学与技术", "软件工程", "市场营销", "统计学"]
const PROJECTS := [
	"校园二手交易小程序", "大学生创新创业训练计划", "“挑战杯”课外学术作品赛", "全国大学生数学建模竞赛",
	"导师横向课题：社区养老调研", "学院公众号运营", "校运动会志愿者统筹", "电子商务“三创赛”",
	"毕业设计：图书推荐系统", "支教社会实践", "学生会外联部招商", "校园歌手大赛策划",
]
const PROJECT_ROLES := ["负责人", "核心成员", "成员", "队长", "志愿者"]
const CHANGER_EVALS := [
	"从教培行业转行，愿意从实习做起。",
	"原来做外贸，行业不景气，想换个方向。",
	"三十岁重新出发，不怕从零开始。",
]
## 十六七岁上班的人，最早那段工作。
const EARLY_JOBS := [["东江电子厂", "产线操作工 → 产线脚本"], ["南山星际网吧", "网管"], ["北海手机维修城", "维修学徒"], ["云岭物流园", "仓库系统录入"], ["东江印刷厂", "排版 / 机房"]]
const LAID_OFF_EVALS := [
	"前公司业务调整，整个部门被裁。",
	"希望尽快到岗，薪资可谈。",
	"什么岗位都可以先试试。",
]


## late：今天晚到，剧情人物排到最上面，来不及看的只是生成的人。
static func generate_day(cfg: DayConfig, rules: Array[Rule], day_seed: int, late := false) -> Array[Candidate]:
	var rng := RandomNumberGenerator.new()
	rng.seed = day_seed
	var result: Array[Candidate] = []
	# 猎头的人不排第一份，免得一开桌就撞上
	var broker_slots := []
	var open_slots := range(1, cfg.resume_count)
	for n in mini(cfg.broker_count, open_slots.size()):
		broker_slots.append(open_slots.pop_at(rng.randi_range(0, open_slots.size() - 1)))
	for i in cfg.resume_count:
		var background := _pick_background(rng, cfg.candidate_mix)
		var id := "gen_%d_%02d" % [cfg.day, i]
		var c := _generate_broker(rng, rules, id, background, cfg.day) if i in broker_slots else _generate(rng, rules, id, background, cfg.day)
		_seed_chief_need(c, cfg.chief_need, rng)
		_attach_docs(c, rng)
		result.append(c)
	# 倒着插，同一个位置上几个人按 story_candidates 的顺序排
	var stories := cfg.story_candidates.filter(func(story: Candidate) -> bool: return not GameState.story_skipped(story))
	stories.reverse()
	for story: Candidate in stories:
		result.insert(0 if late else mini(cfg.story_slot, result.size()), story)
	return result


## 赵主管便签上要的那种项目，往几份简历里多撒一点，免得一整叠都对不上；角色和时长照旧随机，对不对得上还得看纸。
const CHIEF_SEED_CHANCE := 0.35


static func _seed_chief_need(c: Candidate, need: Dictionary, rng: RandomNumberGenerator) -> void:
	var names: Array = need.get("seed_projects", [])
	if names.is_empty() or c.projects.is_empty() or rng.randf() >= CHIEF_SEED_CHANCE:
		return
	c.projects[rng.randi_range(0, c.projects.size() - 1)].name = names[rng.randi_range(0, names.size() - 1)]


## 发材料，再按密度埋矛盾。矛盾只改材料上写的，事实不动，所以判定和陷阱密度不受影响。
static func _attach_docs(c: Candidate, rng: RandomNumberGenerator) -> void:
	c.docs = RuleEngine.active_docs
	for d in RuleEngine.active_discrepancies:
		if d.doc in c.docs and rng.randf() < d.chance(c):
			d.shape(c, rng)


static func _pick_background(rng: RandomNumberGenerator, mix: Dictionary) -> String:
	if mix.is_empty():
		return "regular"
	var total := 0.0
	for weight in mix.values():
		total += float(weight)
	var roll := rng.randf() * total
	for key: String in mix:
		roll -= float(mix[key])
		if roll < 0.0:
			return key
	return mix.keys().back()


## 猎头推来的人：挑一条不是今天新加的规则，卡在边上不合格（16–19k、“含实习”、JavaScript……），其余都合格；
## 一眼看着像能过。能力差、不老实，但对介绍人忠心，进来了不会走，只会把活拖垮（留任期满是“项目延期”）。
## 边界形态偶尔塑不出不合格的、或者连带违反了别的条，换一条再试，最后退到明显不合格。
const BROKER_TRIES := 6


static func _generate_broker(rng: RandomNumberGenerator, rules: Array[Rule], id: String, background: String, day: int) -> Candidate:
	var c: Candidate
	for attempt in BROKER_TRIES:
		var form := Rule.Shape.EDGE_FAIL if attempt < BROKER_TRIES - 1 else Rule.Shape.FAIL
		c = _generate(rng, rules, id, "regular" if background == "fresh" else background, day, form)
		# 只卡一条：塑年限时把年龄挤过了别的线，就再来
		if RuleEngine.evaluate(c).failed.size() == 1:
			break
	c.broker = true
	c.ability = rng.randi_range(18, 36)
	c.honesty = rng.randi_range(15, 35)
	c.loyalty = rng.randi_range(55, 80)
	c.pressure = rng.randi_range(45, 75)
	c.event_override = &""
	return c


## force：猎头的人用，目标规则只从老规则里挑、形态定死。
static func _generate(rng: RandomNumberGenerator, rules: Array[Rule], id: String, background := "regular", day := 0, force := -1) -> Candidate:
	var c := _base(rng, id)
	_apply_background(c, background, rng)
	var applicable := rules.filter(func(r: Rule) -> bool: return r.applies_to(c))
	if force >= 0:
		var old := applicable.filter(func(r: Rule) -> bool: return r.day_added < day)
		var target_rule: Rule = (old if not old.is_empty() else applicable)[rng.randi_range(0, (old if not old.is_empty() else applicable).size() - 1)]
		for rule in applicable:
			rule.shape(c, force if rule == target_rule else Rule.Shape.PASS, rng)
		_finish_shape(c, rng)
		return c
	var target := _pick_target(rng, applicable, day)
	var roll := rng.randf()
	var target_form := Rule.Shape.PASS
	if roll < EDGE_DENSITY:
		var passes := rng.randf() < 0.5
		if target.day_added == day:
			target_form = Rule.Shape.PASS if passes else Rule.Shape.FAIL
		else:
			target_form = Rule.Shape.EDGE_PASS if passes else Rule.Shape.EDGE_FAIL
	elif roll < EDGE_DENSITY + FAIL_DENSITY:
		target_form = Rule.Shape.FAIL
	for rule in applicable:
		rule.shape(c, target_form if rule == target else Rule.Shape.PASS, rng)
	_finish_shape(c, rng)
	# 荒谬规则刷掉的人，往往是更好的员工
	if target.is_absurd and target_form >= Rule.Shape.EDGE_FAIL:
		c.ability = mini(c.ability + 25, 100)
		c.loyalty = mini(c.loyalty + 20, 100)
	return c


## 规则塑完形以后：对齐年龄和年限，排经历，专科换学校。
static func _finish_shape(c: Candidate, rng: RandomNumberGenerator) -> void:
	if not c.is_intern:
		_fit_age_to_experience(c, rng)
	# 年龄可能被规则改过，经历最后再排
	if c.is_intern:
		build_projects(c, rng)
	else:
		build_jobs(c, rng)
	if c.degree < Candidate.Degree.BACHELOR:
		c.school = COLLEGES[rng.randi_range(0, COLLEGES.size() - 1)]


## 今天新加的规则多抽几次，让玩家把手册上的“新”和桌上的简历对上。
static func _pick_target(rng: RandomNumberGenerator, rules: Array, day: int) -> Rule:
	var total := 0
	for rule in rules:
		total += NEW_RULE_WEIGHT if rule.day_added == day else 1
	var roll := rng.randi_range(0, total - 1)
	for rule in rules:
		roll -= NEW_RULE_WEIGHT if rule.day_added == day else 1
		if roll < 0:
			return rule
	return rules.back()


static func _base(rng: RandomNumberGenerator, id: String) -> Candidate:
	var c := Candidate.new()
	var pick := func(list: Array) -> Variant: return list[rng.randi_range(0, list.size() - 1)]
	c.id = id
	c.display_name = pick.call(SURNAMES) + pick.call(GIVEN)
	c.applied_position = _pick_position(rng)
	c.birth_date = DateUtil.years_before(GameState.today, rng.randi_range(24, 44), -rng.randi_range(0, 360))
	c.degree = Candidate.Degree.BACHELOR if rng.randf() < 0.7 else Candidate.Degree.MASTER
	c.school = pick.call(SCHOOLS)
	var posting := RuleEngine.posting_for(c.applied_position)
	var skills: Array = Array(posting.skill_pool) if posting and not posting.skill_pool.is_empty() else SKILLS.duplicate()
	for i in rng.randi_range(4, 6) if posting and not posting.skill_pool.is_empty() else 4:
		c.skills.append(skills.pop_at(rng.randi_range(0, skills.size() - 1)))
	c.salary_k = rng.randi_range(9, 26) if posting == null or posting.salary_range == Vector2i.ZERO else rng.randi_range(posting.salary_range.x, posting.salary_range.y)
	c.salary_low_k = c.salary_k - rng.randi_range(2, 4) if rng.randf() < 0.5 else 0
	c.self_eval = pick.call(SELF_EVALS)
	c.attachment = pick.call(ATTACHMENTS)
	c.left_months_ago = -1 if rng.randf() < 0.65 else rng.randi_range(1, 8)
	if c.left_months_ago >= 0 and rng.randf() < 0.4:
		c.attachment = RuleEmployed.QUIT_NOTE
	elif c.left_months_ago < 0 and rng.randf() < 0.3:
		c.attachment = RuleEmployed.NOTICE_NOTE
	if rng.randf() < 0.45:
		var notes: Array = RuleGap.PASS_NOTES + RuleGap.EDGE_PASS_NOTES + RuleGap.EDGE_FAIL_NOTES + RuleGap.FAIL_NOTES
		c.gap_months = rng.randi_range(3, 14)
		c.gap_note = notes[rng.randi_range(0, notes.size() - 1)]
	# 写在简历上的工作年限：没有规则管的时候，大致等于毕业到现在
	c.exp_months = maxi(c.get_age(GameState.today) - 23, 1) * 12 + rng.randi_range(0, 11)
	c.portrait_seed = rng.randi()
	c.ability = rng.randi_range(20, 90)
	c.honesty = rng.randi_range(15, 95)
	c.loyalty = rng.randi_range(15, 90)
	c.pressure = rng.randi_range(20, 90)
	c.performance = rng.randi_range(10, 95)
	return c


## 今天新开的岗位多投几份，让玩家翻到新的那页 JD。
static func _pick_position(rng: RandomNumberGenerator) -> String:
	var postings := RuleEngine.active_postings
	if postings.is_empty():
		return POSITIONS[rng.randi_range(0, POSITIONS.size() - 1)]
	var fresh: Array = RuleEngine.load_day(GameState.day).new_postings if GameState.day > 0 else []
	var total := 0
	for posting in postings:
		total += NEW_POSTING_WEIGHT if posting in fresh else 1
	var roll := rng.randi_range(0, total - 1)
	for posting in postings:
		roll -= NEW_POSTING_WEIGHT if posting in fresh else 1
		if roll < 0:
			return posting.title
	return postings.back().title


static func _apply_background(c: Candidate, background: String, rng: RandomNumberGenerator) -> void:
	c.background = background
	match background:
		"fresh":
			c.is_intern = true
			c.birth_date = DateUtil.years_before(GameState.today, rng.randi_range(22, 24), -rng.randi_range(0, 360))
			var posting := RuleEngine.posting_for(c.applied_position)
			var majors: Array = Array(posting.majors) if posting else MAJORS
			c.major = majors[rng.randi_range(0, majors.size() - 1)]
			c.degree = Candidate.Degree.BACHELOR
			# 绩点跟能力只是松松地挂钩：会考试不等于会干活
			c.gpa = snappedf(clampf(2.4 + c.ability / 100.0 * 1.2 + rng.randf_range(-0.4, 0.4), 2.0, 3.96), 0.01)
			c.intern_days = rng.randi_range(4, 5)
			c.intern_months = rng.randi_range(6, 12)
			c.salary_k = 0
			c.salary_low_k = 0
			c.left_months_ago = -1
			c.gap_months = 0
			c.gap_note = ""
			if c.attachment in [RuleEmployed.QUIT_NOTE, RuleEmployed.NOTICE_NOTE, "推荐人：前主管，电话已留"]:
				c.attachment = "无"
			c.self_eval = FRESH_EVALS[rng.randi_range(0, FRESH_EVALS.size() - 1)]
		"changer":
			c.birth_date = DateUtil.years_before(GameState.today, rng.randi_range(30, 40), -rng.randi_range(0, 360))
			c.self_eval = CHANGER_EVALS[rng.randi_range(0, CHANGER_EVALS.size() - 1)]
		"laid_off":
			c.left_months_ago = rng.randi_range(1, 6)
			if c.attachment == RuleEmployed.NOTICE_NOTE:
				c.attachment = "无"
			c.self_eval = LAID_OFF_EVALS[rng.randi_range(0, LAID_OFF_EVALS.size() - 1)]


## 写的工作年限比年龄还长时（22 岁毕业算起）：工作年限有规则管，就把人挪老一点，
## 挪到的年龄不会越过“90 后”那条线（年限规则最多出 9 年多，22 + 10 + 2 = 34 岁），所以不改年龄规则的对错；
## 没有规则管工作年限（年龄规则把人改年轻了），就把年限缩到跟年龄对得上。
static func _fit_age_to_experience(c: Candidate, rng: RandomNumberGenerator) -> void:
	if c.early_start:
		return
	var age := c.get_age(GameState.today)
	var need := 22 + ceili(c.exp_months / 12.0)
	if age >= need:
		return
	if RuleEngine.active_rules.any(func(r: Rule) -> bool: return r is RuleExperience and r.applies_to(c)):
		c.birth_date = DateUtil.years_before(GameState.today, need + rng.randi_range(0, 2), -rng.randi_range(0, 360))
	else:
		c.exp_months = maxi(age - 23, 1) * 12 + rng.randi_range(0, 11)


## 从今天往回排工作经历：按 left_months_ago 决定最近一段是否“至今”，
## gap_months > 0 时在两段之间放一段空窗（说明在 gap_note）。
static func build_jobs(c: Candidate, rng: RandomNumberGenerator) -> void:
	var now := DateUtil.month_index(GameState.today)
	var career := maxi((c.get_age(GameState.today) - 22) * 12, 24)
	# 简历上写了工作年限的，经历排得跟它差不多长
	if c.exp_months > 0:
		career = maxi(c.exp_months, 12)
	var left := mini(c.left_months_ago, 10)
	var gap := 0
	if c.gap_months > 0:
		gap = clampi(c.gap_months, 2, maxi(career - maxi(left, 0) - 12, 2))
	# 空窗放在第 1、2 段之间；经历够长时有时放在第 2、3 段之间
	var gap_after := 1 if career - maxi(left, 0) - gap < 60 or rng.randf() < 0.6 else 2
	var cursor := now - maxi(left, 0)
	var earliest := now - career
	# 抗压规则在的时候每段至少一年（RulePressure.shape 定 min_stint）；没有规则管就照旧，最短半年
	var floor_len := c.min_stint
	c.jobs = []
	while cursor - earliest >= floor_len and c.jobs.size() < MAX_JOBS:
		if gap > 0 and c.jobs.size() == gap_after:
			cursor -= gap
			gap = 0
			if cursor - earliest < floor_len:
				break
		var reserve := (gap + floor_len) * (gap_after - c.jobs.size()) if gap > 0 else 0
		var room := maxi(cursor - earliest - reserve, floor_len)
		var length := clampi(rng.randi_range(maxi(14, floor_len), 40), floor_len, room)
		# 剩下的不够再排一段满 floor_len 的，就并进这一段，免得最早那段被截短
		if floor_len > 6 and room - length < floor_len:
			length = room
		if c.stint_len > 0 and c.jobs.size() == c.stint_at:
			length = c.stint_len
		var posting := RuleEngine.posting_for(c.applied_position)
		var titles: Array = Array(posting.job_titles) if posting and not posting.job_titles.is_empty() else TITLES
		var title: String = titles[rng.randi_range(0, titles.size() - 1)]
		if c.jobs.is_empty() and c.recent_title != "":
			title = c.recent_title
		c.jobs.append({
			"company": COMPANIES[rng.randi_range(0, COMPANIES.size() - 1)],
			"title": title,
			"start": DateUtil.month_string(cursor - length),
			"end": "" if c.jobs.is_empty() and left < 0 else DateUtil.month_string(cursor),
		})
		cursor -= length
	# 十六七岁就上班的人：最早那段在厂里、网吧、产线上
	if c.early_start and c.jobs.size() >= 2:
		var first_job: Dictionary = c.jobs.back()
		var early: Array = EARLY_JOBS[rng.randi_range(0, EARLY_JOBS.size() - 1)]
		first_job.company = early[0]
		first_job.title = early[1]
	# 经历太短、排不到要短的那一段：把最早那段截成这么长
	if c.stint_len > 0 and c.jobs.size() <= c.stint_at and not c.jobs.is_empty():
		var oldest: Dictionary = c.jobs.back()
		var end := now if oldest.end == "" else DateUtil.month_index(oldest.end)
		oldest.start = DateUtil.month_string(end - c.stint_len)
	if not c.has_gap():
		c.gap_note = ""


## 在校项目：从今天往回排 2–3 段（RuleProjects 可改成 0 或 1 段），每段 2–8 个月，彼此可以重叠一点，不算空窗。
static func build_projects(c: Candidate, rng: RandomNumberGenerator) -> void:
	var pool := PROJECTS.duplicate()
	var cursor := DateUtil.month_index(GameState.today) - rng.randi_range(0, 4)
	c.jobs = []
	c.projects = []
	var count := c.project_count if c.project_count >= 0 else rng.randi_range(2, 3)
	for i in count:
		# 只有一段的（压线）做得也短
		var length := rng.randi_range(2, 3) if count == 1 else rng.randi_range(2, 8)
		c.projects.append({
			"name": pool.pop_at(rng.randi_range(0, pool.size() - 1)),
			"role": PROJECT_ROLES[rng.randi_range(0, PROJECT_ROLES.size() - 1)],
			"start": DateUtil.month_string(cursor - length),
			"end": DateUtil.month_string(cursor),
		})
		cursor -= length - rng.randi_range(0, 2)
