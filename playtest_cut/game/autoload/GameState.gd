extends Node
## 天数、存款、隐藏数值、已录用员工、决策日志。

const START_DATE := "2026-03-02"
const START_SAVINGS := 200
const LAST_DAY := 23
## 第二个月从第几天开始（标题页可以直接从这里开）。
const MONTH2_START := 10
## 第三个月（5 月，寒冬）从第几天开始。
const MONTH3_START := 17
const VIOLATION_FINE := 50
const FREE_WARNINGS := 2
## 破格：从第 3 天起，每天能给一份不合规的简历盖一次破格章，第二天 14:00 你单独面 TA（主管 / 组长不在），录用了算你担保。
## 担保的人留任期满出事，不管这个月扣不扣钱，都扣 VOUCH_FINE；干得好，老板记你一笔。第二个月从第一天起就有。
const EXCEPTION_DAY := 3
const VOUCH_FINE := 100
## 担保的人满试用期干得好：日结单上单列一行，比判断奖金大得多（风险 ¥100 对回报 ¥150）。
const VOUCH_BONUS := 150
## 破格那场单独面试的补贴：补那天提前一小时收工少筛的简历。
const SOLO_PAY := 50
## HC 硬指标（DayConfig.hc_push）没放满：扣钱（罚款开着的月份），王总记一笔。
const HC_PUSH_FINE := 100
## 被规则卡住的人（BlockedTalent）筛简历时拒掉，几天后在别处有回响。
const BLOCKED_ECHO_DAYS := 2
const KNOWING_FINE := 100
const MISS_COST := 50
## 晚到：每晚一小时扣多少（底薪按 8 小时折）。这是考勤，不是违规罚款，第一个月也扣。
const LATE_PER_HOUR := 20
## 每个月几个工作日：第一个月 9 天，第二个月 7 天；月底那天扣月供。
const MONTH_LENGTHS := [9, 7, 7]
const MORTGAGE := 1750
## 猎头（李哲他爸）的价目：放进面试当晚转一笔，录用后满试用期再转一笔（人走了就没有）。
const BROKER_FROM := "李哲的爸爸"
## 手机里他的备注名。
const BROKER_FROM_THREAD := "李哲他爸"
const BROKER_PASS := 100
const BROKER_RETAIN := 200
## 按组招的日子（DayConfig.team_folders）：一天最多面几场；公司 18:00 打卡，面完才下班，路上 50 分钟。
const MAX_SESSIONS := 3
const CLOCK_OUT := 18 * 60
const COMMUTE := 50
## 到家晚过这两个点，老婆那边各扣一次感情。
const LATE_HOME := [19 * 60 + 30, 20 * 60 + 30]

var run_seed := 0
var day := 1
var today := START_DATE
var config: DayConfig
## 本月工资标准，见 DayConfig.pay。
var pay := {}
var savings := START_SAVINGS
var conscience := 0
var boss_trust := 0
var family_state := 0
## 家里的事 {标记 id: 选项 key}：晚上回的短信、回家说的话（h 开头）、第 4 天有没有提前下班。不显示数字，只改之后的短信。
var family := {}
## 夫妻感情：回老婆消息、第 4 天提前下班会加，不回会减。不显示数字，月底的结局看它。
var marriage := 0
## 回一条消息花掉的钟点（分钟）。
const REPLY_MINUTES := 2
## 决策日志：从第一天起完整记录，为终章服务。
var decision_log: Array = []
## 已录用员工 {candidate, day_hired, scorecard, promise, event_resolved, retention_due, chief_pick, hr_edit}
## hr_edit：评分表上你用红笔改的那一处 {item, from, to}，空表示没改；留任期满那天对账（见 EmployeeEvents.settle_edit）。
## chief_pick：赵主管（或当天的组长）要的人（拿了推荐奖），出了事他说“人是你面的”；picked_by 是谁要的。
var hires: Array = []
## 面试后没录的人：满期那天按 TA 的底子对账，拒对了有证据发识人奖，拒掉好人记错失（EmployeeEvents.settle_rejects）
var rejects: Array = []
## 延发月份没进存款的留任奖金，最终“在离职补偿中抵扣”。
var deferred_bonus := 0
var boss_promised_rule := false
## 违法提问累积的诉讼风险，风险爆发时公司被告。
var lawsuit_risk := 0
## 玩家回答候选人反问的原话，终章由 HireBot 原样复述。
var reply_log: Array = []
## 昨天约来、今天来面试的人：当天通过的人里，晚上约一个，第二天才面试。
var interviewees: Array[Candidate] = []
## 今晚约了明天来的人（日结单之后的约面）；通过的人不比名额多时自动全约（见 book_slots()）。
var booked_today: Array[Candidate] = []
## 筛过了、但晚上没约的人（id）：进人才库，月底回顾按“没约”写。
var unbooked: Array = []
## 昨天破格放进来、今天你单独面的人；不进主管 / 组长那场。
var vouched: Array[Candidate] = []
## 今天已经面过的人（display_name）：剧情候选人那场面完，有奇葩的日子再加一场（见 InterviewRoom.second_candidate）。
var interviewed_today: PackedStringArray = []
## 夹在简历里的信封 {day, from, amount, candidate_id, taken}：第一个月只收不追，下个月有人来“惦记”。
var kickbacks: Array = []
## 手机零钱转出去的累计：零钱 = 收下的转账 − 这个数（见 wallet()）。第一个月没有转账，零钱一直是 0；第二个月猎头的钱从这里进。
var wallet_out := 0
## 每个组（岗位标题）一共放进去几个人：名额满了组长退回（JobPosting.hc）。
var folder_filled := {}
## 今天按组排好的面试（不含破格那场）：第一场开始前排好，见 plan_sessions()。
var sessions: Array[Candidate] = []
## 面试时被你追问问穿了的手写人物 id（Candidate.crack_lines 说完最后一句）。
var exposed: Array = []
## 晚上答应了家里、明天晚到：{minutes, morning}（回家那一幕选项的 late / morning）。
var late_next := {}
## 今天晚到了多少：同上，空表示 08:00 准时到。
var late_today := {}
## 这个月迟到过几次；第二次起老板印象 −1。
var late_count := 0
## 迟到第二天早上邮件末尾老板那句，空表示没有。
var late_ps := ""
## 当天清晨的状态快照：手动存档存的是它，今天做到一半的进度不进存档。
var morning := {}
## 第三个月起：离职谈话里你说过的每一句 {day, name, question, style, text}；话术（lie）终章由 HireBot 原样念给你。
var talk_log: Array = []
## 抽屉里的证据（id）：第 19 天起文件也能放进抽屉，和信封放在同一个地方（第四个月交不交出去）。
var evidence: Array = []
## 标准耗时（第 18 天起）：你哪天最快的那一段，几分钟一份。0 表示还没量过。王总照这个排第二天的量。
var best_pace := 0.0
## 这个月里被作废的录用（HireBot 对出来的，比如沈雯）：候选人 id。
var voided: Array = []
## 筛简历时规则拒掉的“被卡住的人”[{name, kind, text, day, due}]：due 那天早上，真的进王总邮件附言，吹的进日结单。
var blocked_rejects: Array = []
## 砍减版：昨天晚上的报纸 {date, headline, body}，第二天早上在邮件之前看。空表示没有。
var paper := {}
## 意外支出（动态难度，见 Surprises）：来过的 [{day, id, cost, paid, key}]；今天要来的那条手机消息，空表示今天没事。
var surprises: Array = []
var surprise_today := {}
## 赌一把留下的后账 [{id, day, due, outcome, amount, at}]，到 due 那天手机上揭晓、自动扣钱（Surprises.reveals）。
## 当天扣完才删，所以早上的存档里还在，读档重来同一条。
var surprise_queue: Array = []
## 今天要揭晓的那几条手机消息（早上从 surprise_queue 生成）。
var reveal_today: Array = []
## 赌一把连着坏了几次（到 Surprises.PITY 下一次保底不坏）。
var luck_streak := 0
## 修改器：下一次赌一把的结果（good / mid / bad），空表示照常掷。不存档。
var luck_force := ""

# 当日数据，只在一天内有效
var stats := {}
var passed_today: Array[Candidate] = []
var vouched_today: Array[Candidate] = []
var event_today := {}


func new_game(game_seed := 0, start_day := 1) -> void:
	run_seed = game_seed if game_seed != 0 else randi()
	day = start_day
	savings = START_SAVINGS
	conscience = 0
	boss_trust = 0
	family_state = 0
	family = {}
	marriage = 0
	decision_log = []
	hires = []
	rejects = []
	deferred_bonus = 0
	boss_promised_rule = false
	lawsuit_risk = 0
	reply_log = []
	interviewees = []
	unbooked = []
	vouched = []
	blocked_rejects = []
	kickbacks = []
	folder_filled = {}
	sessions = []
	wallet_out = 0
	exposed = []
	late_next = {}
	late_today = {}
	late_count = 0
	late_ps = ""
	talk_log = []
	evidence = []
	best_pace = 0.0
	voided = []
	paper = {}
	surprises = []
	surprise_queue = []
	luck_streak = 0
	begin_day()


## 直接从第二个月开始：没玩第一个月的人，按一个“还过得去”的第一个月补上家底。
## kickback：上个月第 7 天李哲他爸的信封收了没有；xiaoliu：你爸说小刘的事，你是让他投（try）还是说不上话（hard）。
const MONTH2_SAVINGS := 240
const MONTH2_MARRIAGE := 6
## [id, 名字, 岗位, 录用那天]：第一个月最后两天录的
const MONTH2_CARRYOVER := [["carry_1", "林晓雨", "产品运营实习生", 8], ["carry_2", "高子涵", "内容运营实习生", 9]]


func new_game_month2(kickback: bool, xiaoliu: String, game_seed := 0) -> void:
	new_game(game_seed, MONTH2_START)
	savings = MONTH2_SAVINGS
	marriage = MONTH2_MARRIAGE
	family = {"h5_dad": xiaoliu, "d4_left": "yes"}
	kickbacks = [{"day": 7, "from": "李哲的爸爸", "amount": 300, "candidate_id": "story_headhunter", "taken": kickback}]
	# 上个月月底录用的两个实习生，留任期跨到这个月：奖金还在路上
	for h: Array in MONTH2_CARRYOVER:
		var c := Candidate.new()
		c.id = StringName(h[0])
		c.display_name = h[1]
		c.applied_position = h[2]
		c.is_intern = true
		c.portrait_seed = PortraitFactory.seed_for(hash(h[0]), true)
		c.ability = 70
		c.loyalty = 70
		c.pressure = 65
		hires.append({"candidate": c.to_dict(), "day_hired": h[3], "scorecard": {"狼性": 3, "格局": 3, "稳定性": 3, "颜值": 3}, "promise": "",
			"event_resolved": false, "retention_due": h[3] + 3, "chief_pick": false})
	begin_day()


## 直接从第三个月开始：标题页问五件前两个月的事，其余按“还过得去”补。
## opts: {chenmo: 录没录陈默, table: 盘点表 true/fudge/delay, broker: 收没收李哲他爸的钱, card: 小刘家的卡收没收, poor: 第二个月底存款不到 ¥300}
const MONTH3_SAVINGS := 420
const MONTH3_MARRIAGE := 14


func new_game_month3(opts: Dictionary, game_seed := 0) -> void:
	new_game(game_seed, MONTH3_START)
	savings = 180 if opts.get("poor", false) else MONTH3_SAVINGS
	marriage = MONTH3_MARRIAGE
	family = {"h5_dad": "try", "d4_left": "yes", "w16_table": str(opts.get("table", "true")), "h6_wife": "together"}
	if opts.get("poor", false):
		family["m2_late"] = "yes"
	kickbacks = [{"day": 7, "from": BROKER_FROM, "amount": 300, "candidate_id": "story_headhunter", "taken": bool(opts.get("broker", false))}]
	if opts.get("broker", false):
		kickbacks.append({"day": 14, "from": BROKER_FROM, "amount": 100, "candidate_id": "gen_14_03", "taken": true, "broker": "pass", "name": "赵磊"})
	if opts.get("card", false):
		kickbacks.append({"day": 12, "from": "小刘家", "amount": 800, "candidate_id": "story_xiaoliu", "taken": true})
		family["h12_gift"] = "take"
	# 陈默：录了就记一条第 13 天的录用（内部系统组），没录就记三次拒绝
	if opts.get("chenmo", false):
		var c := Candidate.new()
		c.id = &"story_chenmo_3"
		c.display_name = "陈默"
		c.applied_position = "后端开发工程师（内部系统组）"
		c.portrait_seed = 19960914
		c.ability = 98
		c.loyalty = 85
		hires.append({"candidate": c.to_dict(), "day_hired": 13, "scorecard": {"狼性": 3, "格局": 3, "稳定性": 3, "颜值": 3}, "promise": "",
			"event_resolved": true, "retention_due": 17, "chief_pick": false})
	else:
		for d: int in [10, 12, 13]:
			var id := "story_chenmo_%d" % [{10: 1, 12: 2, 13: 3}[d]]
			decision_log.append({"day": d, "candidate_id": id, "candidate_name": "陈默", "verdict": "reject", "reason_rule": "rule_degree_pro",
				"reason_text": "学历不符合岗位要求。", "expected": "reject", "failed_rules": ["rule_degree_pro"], "violated_rule": false})
	# 前两个月写得最多的几句拒绝理由：HireBot 的建议理由从这里取
	for i in 6:
		decision_log.append({"day": 11 + i % 5, "candidate_id": "gen_m2_%d" % i, "candidate_name": "", "verdict": "reject",
			"reason_rule": ["rule_age_90", "rule_experience", "rule_self_eval"][i % 3],
			"reason_text": ["您的年龄不符合团队活力要求。", "您的工作经验与岗位要求不符。", "综合评估后，您与岗位暂不匹配。"][i % 3],
			"expected": "reject", "failed_rules": [], "violated_rule": false})
	begin_day()


## 今晚能约几个人明天来面：第一个月一个；第二个月看明天——按组招的日子最多 MAX_SESSIONS 场，
## 不按组的日子一场，明天有奇葩再加一场（剧情人物那场之后的第二场）。
## 砍减版：一天只面一场（不再按组排三场、不再加第二场奇葩），约面那一屏也拿掉了。
func book_slots() -> int:
	return 1


## 砍减版：有离职谈话的日子，傍晚只留一场。普通人不面，剧情人物和破格的人照面。
func skip_plain_interview() -> bool:
	if config.exit_talks.is_empty():
		return false
	return not interviewees.any(func(c: Candidate) -> bool: return c.is_story)


## 砍减版：自动约面。剧情人物先约，其余按盖章的先后。
func _auto_book() -> void:
	var order: Array[Candidate] = []
	for c in passed_today:
		if c.is_story:
			order.append(c)
	for c in passed_today:
		if not c.is_story:
			order.append(c)
	booked_today = order.slice(0, book_slots())


## 今晚的报纸排好版，第二天早上看（MailScreen）。头条的优先级和原来晚报一样。
func store_paper() -> void:
	var headline := config.headline
	var body := config.news_body
	var echo := story_echo()
	if echo.get("headline", "") != "":
		headline = echo.headline
		body = echo.get("body", "")
	for variant: Dictionary in config.news_by:
		if family_matches(variant.when):
			headline = variant.headline
			body = variant.get("body", "")
			break
	var event_id: String = event_today.get("id", "")
	if config.news_by_event.has(event_id):
		headline = config.news_by_event[event_id][0]
		body = config.news_by_event[event_id][1]
	paper = {} if headline == "" else {"date": today, "headline": headline, "body": body}


## 砍减版：每晚回家最后两句，把看不见的夫妻感情和老板信任说成一句话。
func status_lines() -> Array[String]:
	var home := ""
	if marriage >= 8:
		home = "她给你留了灯，饭还温着。"
	elif marriage >= 3:
		home = "她问了一句今天累不累。"
	elif marriage >= 0:
		home = "她说了声“回来了”，没抬头。"
	elif marriage > -8:
		home = "卧室的门关着。她今晚没等你。"
	else:
		home = "沙发上给你铺好了被子。"
	var boss := ""
	if boss_trust >= 2:
		boss = "王总这两天见了你会点个头。"
	elif boss_trust >= 0:
		boss = "王总那边没什么动静。"
	elif boss_trust >= -2:
		boss = "王总今天回你的消息，只有一个“嗯”。"
	else:
		boss = "王总开始让别人抄送你的邮件了。"
	return [home, boss]


## 明天面不满两场王总要记一笔（今天、明天都按组招，见 end_day 里的 few_sessions）。
func few_sessions_noted_tomorrow() -> bool:
	return month() > 1 and day < LAST_DAY and config.team_folders and RuleEngine.load_day(day + 1).team_folders


## 今晚约的人明天来面试，没约的进人才库（这个月不会再来）；通过的人不比名额多时全约。
## 月底通过的人不跨月（下个月换岗位了）。
func advance_day() -> void:
	if booked_today.is_empty():
		_auto_book()
	interviewees = [] as Array[Candidate]
	if not is_month_end():
		interviewees = booked_today.duplicate()
		for c in passed_today:
			if c not in booked_today and String(c.id) not in unbooked:
				unbooked.append(String(c.id))
	# 破格的人跨月也来：月底那天破格的，下个月第一天 14:00 面
	vouched = vouched_today.duplicate()
	late_ps = ""
	if not late_today.is_empty():
		late_count += 1
		late_ps = "PS：听说昨天有人%s才到？" % arrival_time() if late_count == 1 else "PS：又迟到。我记下了。"
		if late_count >= 2:
			boss_trust -= 1
	late_today = late_next
	late_next = {}
	day += 1
	begin_day()


func begin_day() -> void:
	config = RuleEngine.load_day(day)
	today = config.date if config.date != "" else DateUtil.add_days(START_DATE, day - 1)
	pay = RuleEngine.pay(day)
	RuleEngine.set_day(day)
	# retained：今天满期、人还在的 {name, day_hired, days}
	stats = {"processed": 0, "correct": 0, "wrong": 0, "unprocessed": 0, "errors": [], "retained": [], "event_fine": 0, "reason_ok": 0, "reason_off": [], "chief_picks": [], "gray": 0, "broker": [], "broker_retained": [], "paid_bills": [], "left_early": false, "texts": [], "called": false, "edits": [], "rejects": [], "knowing": [], "transfers": [], "sent": [], "exception": "", "solo_done": [], "vouch": [], "ats_agree": 0, "ats_override": 0, "ats_override_ok": 0, "intake_left": [], "called_out": 0, "clock": 0, "held": 0, "late_home": 0, "few_sessions": false, "talks": [], "talk_fine": 0, "rescues": [], "paces": [], "overrides": [], "memo_money": 0, "hc_short": false}
	passed_today = []
	booked_today = []
	vouched_today = []
	interviewed_today = []
	sessions = []
	event_today = {}
	surprise_today = Surprises.pick(day, savings, surprises, run_seed)
	reveal_today = Surprises.reveals(day, surprise_queue)
	morning = to_dict().duplicate(true)


func day_seed() -> int:
	return hash([run_seed, day])


## 返回违规原因，判对时为空串。
## folder：按组招的日子放进了哪个组（通过时才有）。放进对不上的组也算违规；能进的组都满了，拒掉不算错。
func record_decision(c: Candidate, verdict: String, reason_rule: StringName, reason_text: String, extra := {}, folder: JobPosting = null) -> String:
	var result := RuleEngine.evaluate(c)
	var expected := "pass" if result.pass else "reject"
	var full_only := false
	if result.pass and RuleEngine.folder_mode:
		full_only = RuleEngine.fitting_folders(c).all(folder_full)
		if full_only:
			expected = "reject"
	var violated: bool = verdict != expected
	var folder_why := ""
	if verdict == "pass" and folder and result.pass and not full_only:
		var problem := RuleEngine.folder_problem(c, folder)
		if problem != "":
			violated = true
			folder_why = "放错组：" + problem
	var failed_ids: Array = []
	var all_absurd: bool = not result.pass
	for rule: Rule in result.failed:
		failed_ids.append(String(rule.id))
		all_absurd = all_absurd and rule.is_absurd
	var entry := {
		"day": day, "candidate_id": String(c.id), "candidate_name": c.display_name,
		"verdict": verdict, "reason_rule": String(reason_rule), "reason_text": reason_text,
		"expected": expected, "failed_rules": failed_ids, "violated_rule": violated,
	}
	entry.merge(extra)
	# 不进手册的口头规则（第 19 天“已婚未育”）：照着拒了，诉讼风险记一笔；拒绝理由里没有这条，写的是别的
	if verdict == "reject" and not violated and result.failed.any(func(r: Rule) -> bool: return r.is_illegal):
		lawsuit_risk += 1
		entry.illegal = true
	if folder:
		entry.folder = folder.team
	_tally_ats(c, verdict, violated, entry)
	decision_log.append(entry)
	stats.processed += 1
	var why := ""
	if violated:
		stats.wrong += 1
		if folder_why != "":
			why = folder_why
		elif verdict == "pass" and full_only:
			why = "应拒绝：能进的组都满了"
		else:
			why = "应拒绝：" + result.failed[0].title_key if verdict == "pass" else "不应拒绝：未违反任何规则"
		stats.errors.append({"name": c.display_name, "why": why})
		if verdict == "pass" and all_absurd:
			conscience += 1
	else:
		stats.correct += 1
		if verdict == "reject" and reason_rule != &"generic" and not full_only:
			if reason_hits(reason_rule, failed_ids, extra.get("flagged", [])):
				stats.reason_ok += 1
				entry.reason_ok = true
			else:
				var titles: Array = result.failed.map(func(r: Rule) -> String: return r.title_key)
				stats.reason_off.append({"name": c.display_name, "why": "理由不准，应为：" + "、".join(PackedStringArray(titles))})
	if verdict == "pass":
		passed_today.append(place(c, folder))
		if c.broker:
			broker_paid(c, BROKER_PASS)
	elif c.blocked != "" and c.elsewhere != "" and not result.pass:
		blocked_rejects.append({"name": c.display_name, "kind": c.blocked, "text": c.elsewhere, "day": day, "due": day + BLOCKED_ECHO_DAYS})
	EventBus.stamp_applied.emit(c, verdict)
	return why


## 今天到期的回响：kind 为“real”的（拒掉的是真有东西的人）或“fake”的。
func blocked_echoes(kind: String) -> Array:
	return blocked_rejects.filter(func(r: Dictionary) -> bool: return int(r.due) == day and r.kind == kind)


## 王总邮件附言：被你按规则筛掉的人，在竞对干得好。
func blocked_echo_ps() -> String:
	var lines := blocked_echoes("real").map(func(r: Dictionary) -> String:
		return "PS：%s（第 %d 天你筛掉的）“这种人你也筛？”" % [r.text, int(r.day)])
	return "\n".join(PackedStringArray(lines))


## 某个月盖了几次破格章。
func exceptions_in(in_month := month()) -> int:
	return decision_log.filter(func(e: Dictionary) -> bool: return e.get("exception", false) and month_of(int(e.day)) == in_month).size()


## 某个月筛简历时规则拒掉的“被卡住的人”，kind 是 real / fake。
func blocked_rejected_in(kind: String, in_month := month()) -> int:
	return blocked_rejects.filter(func(r: Dictionary) -> bool: return r.kind == kind and month_of(int(r.day)) == in_month).size()


## HC 硬指标：今天这个岗位放进了几个（通过的和破格的）。
func hc_push_placed() -> int:
	var posting: String = config.hc_push.get("posting", "")
	var placed := 0
	for c: Candidate in passed_today + vouched_today:
		if c.applied_position == posting:
			placed += 1
	return placed


func hc_push_short() -> bool:
	return not config.hc_push.is_empty() and hc_push_placed() == 0


func hc_push_fine() -> int:
	return HC_PUSH_FINE if hc_push_short() and fines_on() else 0


## 担保的人干得好：每人一笔担保奖。
func vouch_bonus() -> int:
	return stats.vouch.filter(func(v: Dictionary) -> bool: return v.good).size() * VOUCH_BONUS


## 今天面了几场破格：每场一笔补贴。
func solo_pay() -> int:
	return stats.solo_done.size() * SOLO_PAY


## 初筛系统上线的日子：跟它一致还是推翻了它，推翻的里面判对几份。老板只看前一个数。
func _tally_ats(c: Candidate, verdict: String, violated: bool, entry: Dictionary) -> void:
	if not config.ats and config.hirebot <= 0:
		return
	var tag := HireBot.label(c) if config.hirebot > 0 else Ats.label(c)
	if tag == "":
		return
	entry.ats = tag
	var says_pass := HireBot.says_pass(tag) if config.hirebot > 0 else Ats.says_pass(tag)
	if says_pass == (verdict == "pass"):
		stats.ats_agree += 1
	else:
		stats.ats_override += 1
		entry.ats_override = true
		if not violated:
			stats.ats_override_ok += 1


## 某个月推翻系统几次、判对几次（决策日志里记着）。
func ats_overrides(in_month := month()) -> Dictionary:
	var out := {"agree": 0, "override": 0, "ok": 0}
	for e: Dictionary in decision_log:
		if not e.has("ats") or month_of(int(e.day)) != in_month:
			continue
		if e.get("ats_override", false):
			out.override += 1
			if not e.violated_rule:
				out.ok += 1
		else:
			out.agree += 1
	return out


## 今天还没谈的下一场离职谈话在 config.exit_talks 里的下标；没有了返回 -1。提前下班的日子不谈。
func next_talk_index() -> int:
	if stats.get("left_early", false):
		return -1
	var done: Array = stats.talks.map(func(t: Dictionary) -> String: return t.id)
	for i in config.exit_talks.size():
		var t: Dictionary = config.exit_talks[i]
		if String(t.id) not in done and family_matches(t.get("when", "")) and not _resolve_talk(t).is_empty():
			return i
	return -1


## 下一场离职谈话（variants 换好、{hire_name} 换好）；没有返回空。
func next_talk() -> Dictionary:
	var i := next_talk_index()
	return {} if i < 0 else _resolve_talk(config.exit_talks[i])


## variants 里第一条对上的盖在上面（谈谁看你招过谁）；写了 variants 却一条都对不上，这一场就不谈。
func _resolve_talk(t: Dictionary) -> Dictionary:
	var out := t.duplicate(true)
	if t.has("variants"):
		var hit := {}
		for v: Dictionary in t.variants:
			if family_matches(v.get("when", "")):
				hit = v
				break
		if hit.is_empty():
			return {}
		out.merge(hit, true)
		out.erase("variants")
	var name := _recent_hire_name()
	for key: String in ["name", "opener", "info", "criteria", "refused", "signed"]:
		if out.has(key):
			out[key] = String(out[key]).replace("{hire_name}", name)
	return out


## 上个月你录用的、最晚的那一个（谈话名单上“你亲手招的人”）。
func _recent_hire_name() -> String:
	for i in range(hires.size() - 1, -1, -1):
		var h: Dictionary = hires[i]
		if month_of(int(h.day_hired)) == month() - 1:
			return String(h.candidate.display_name)
	return "孙立"


## 离职谈话里说的一句（ExitTalk）：话术、敷衍、实话。
func record_talk(person: String, question: String, style: String, text: String) -> void:
	talk_log.append({"day": day, "name": person, "question": question, "style": style, "text": text})


## 这个月念过几次话术。
func talk_count(style: String, in_month := month()) -> int:
	return talk_log.filter(func(t: Dictionary) -> bool: return t.style == style and month_of(int(t.day)) == in_month).size()


## 离职谈话、桌上弹出来的事、王总办公室：选项的后果（见 DayConfig.exit_talks / desk_memos）。
## lawsuit / trust / conscience / marriage / family：数值；fine：今天日结扣多少；money：今天日结多一笔（干净的）；
## gray：今天多一笔不干净的钱（记进 kickbacks，抽屉里多一个信封）；flag：{标记: 值} 记进 family；
## evidence：一件证据放进抽屉；void：作废这个人的录用（候选人 id）。
func apply_effects(effects: Dictionary) -> void:
	lawsuit_risk += int(effects.get("lawsuit", 0))
	boss_trust += int(effects.get("trust", 0))
	conscience += int(effects.get("conscience", 0))
	marriage += int(effects.get("marriage", 0))
	family_state += int(effects.get("family", 0))
	stats.talk_fine += int(effects.get("fine", 0))
	stats.memo_money += int(effects.get("money", 0))
	# 下班以后才发生的钱（回家路上买花）：直接动存款
	savings += int(effects.get("savings", 0))
	if effects.has("gray"):
		var gray: Dictionary = effects.gray
		kickbacks.append({"day": day, "from": gray.get("from", ""), "amount": int(gray.amount), "candidate_id": gray.get("candidate_id", ""), "taken": true})
		stats.gray += int(gray.amount)
	for key: String in effects.get("flag", {}):
		family[key] = effects.flag[key]
	if effects.get("evidence", "") != "":
		add_evidence(effects.evidence)
	if effects.get("void", "") != "":
		var id: String = effects.void
		if id not in voided:
			voided.append(id)
		hires = hires.filter(func(h: Dictionary) -> bool: return String(h.candidate.id) != id)


## 证据放进抽屉（重复的不算）。
func add_evidence(id: String) -> void:
	if id not in evidence:
		evidence.append(id)


## 约面：今晚约这些人明天来（不超过 book_slots()）。
func book(people: Array[Candidate]) -> void:
	booked_today = people.duplicate()


## 面试时被你问穿了：记下来，回响里用“id:exposed”。
func expose(c: Candidate) -> void:
	if String(c.id) not in exposed:
		exposed.append(String(c.id))


## 理由选中了 TA 实际违反的任一条；“材料不一致”要标出的矛盾正好牵扯到违反的那条才算。万能理由不算。
func reason_hits(reason_rule: StringName, failed_ids: Array, flagged: Array) -> bool:
	if String(reason_rule) in failed_ids:
		return true
	if reason_rule == &"mismatch":
		for d in RuleEngine.active_discrepancies:
			if d.field in flagged and Array(d.rule_ids).any(func(id: String) -> bool: return id in failed_ids):
				return true
	return false


## 信封收下或退回。收下的钱当晚进存款，不进工资条。
func answer_envelope(c: Candidate, taken: bool) -> void:
	kickbacks.append({"day": day, "from": c.envelope.get("from", ""), "amount": int(c.envelope.get("amount", 0)), "candidate_id": String(c.id), "taken": taken})
	if taken:
		stats.gray += int(c.envelope.get("amount", 0))


## 猎头的钱：WChat 转账，先在手机上挂一张“待收款”（stats.transfers），点收款才算收下、当晚进存款；
## 点退还，或者下班还没点，就退回去。收没收都记进 kickbacks（broker 标着是哪一笔，taken 是收没收）。
## 放进面试是 pass，满试用期是 retain；同一个人放两次（重投）只转一次。
func broker_paid(c: Candidate, amount: int, stage := "pass") -> void:
	var tid := "%s_%s" % [stage, c.id]
	if kickbacks.any(func(k: Dictionary) -> bool: return k.get("broker", "") == stage and k.candidate_id == String(c.id)):
		return
	if stats.transfers.any(func(t: Dictionary) -> bool: return t.id == tid):
		return
	var note := "辛苦费" if stage == "pass" else "%s 满试用期" % c.display_name
	stats.transfers.append({"id": tid, "from": BROKER_FROM_THREAD, "amount": amount, "note": note, "status": "pending",
		"broker": stage, "candidate_id": String(c.id), "name": c.display_name})


## 手机上点收款 / 退还。
func answer_transfer(t: Dictionary, taken: bool) -> void:
	if t.status != "pending":
		return
	t.status = "taken" if taken else "returned"
	kickbacks.append({"day": day, "from": BROKER_FROM, "amount": int(t.amount), "candidate_id": t.candidate_id, "taken": taken, "broker": t.broker, "name": t.name})
	if taken:
		stats.broker.append({"name": t.name, "amount": int(t.amount), "stage": t.broker})


## 手机零钱：收下的猎头转账减去转出去的。
func wallet() -> int:
	var got := 0
	for k: Dictionary in kickbacks:
		if k.get("broker", "") != "" and k.taken:
			got += int(k.amount)
	return got - wallet_out


## 从零钱转出去（回消息的选项带 transfer）：当天从存款里扣。
func send_transfer(to: String, amount: int, note: String) -> void:
	stats.sent.append({"to": to, "amount": amount, "note": note})
	wallet_out += amount


func sent_total() -> int:
	return stats.sent.reduce(func(sum: int, t: Dictionary) -> int: return sum + int(t.amount), 0)


func broker_income() -> int:
	return stats.broker.reduce(func(sum: int, b: Dictionary) -> int: return sum + int(b.amount), 0)


## 这个月放进面试的猎头的人。
func broker_passes(in_month := month()) -> Array:
	return kickbacks_in(in_month).filter(func(k: Dictionary) -> bool: return k.get("broker", "") == "pass")


## 录用了、还没满期的猎头的人：后半笔钱在路上。
func broker_pending() -> Array:
	return pending_hires().filter(func(h: Dictionary) -> bool: return h.candidate.get("broker", false))


## 今天还能不能盖破格章：第 3 天起，一天一次。
func can_vouch() -> bool:
	return day >= EXCEPTION_DAY and stats.exception == ""


## 破格：明知不合规，你签字放进来。不算违规、不出违规单，但也没有判断奖金；计件照算。
## 决策日志记 verdict pass、exception true，回响和月底回顾按“pass”对得上。TA 明天单独面。
## 猎头推来的人破格放进去，也算放进面试，他照样转钱。
func record_exception(c: Candidate, folder: JobPosting = null) -> void:
	var result := RuleEngine.evaluate(c)
	var failed_ids: Array = result.failed.map(func(r: Rule) -> String: return String(r.id))
	decision_log.append({
		"day": day, "candidate_id": String(c.id), "candidate_name": c.display_name,
		"verdict": "pass", "reason_rule": "", "reason_text": "", "expected": "reject",
		"failed_rules": failed_ids, "violated_rule": true, "exception": true,
	})
	stats.processed += 1
	stats.exception = c.display_name
	if folder:
		decision_log.back().folder = folder.team
	vouched_today.append(place(c, folder))
	if c.broker:
		broker_paid(c, BROKER_PASS)
	EventBus.stamp_applied.emit(c, "pass")


## 放进文件夹：占一个名额，复制一份记下是哪个组（候选人资源是共享的，不能直接改）。没分组原样返回。
func place(c: Candidate, folder: JobPosting) -> Candidate:
	if folder == null:
		return c
	folder_filled[folder.title] = folder_count(folder) + 1
	var placed: Candidate = c.duplicate()
	placed.folder = folder.resource_path
	return placed


func folder_count(p: JobPosting) -> int:
	return int(folder_filled.get(p.title, 0))


func folder_full(p: JobPosting) -> bool:
	return folder_count(p) >= p.hc


## 来面这个人的是哪个组：放进过文件夹的看文件夹，没分组的看简历上投的岗位（组撤了也找得到）。
func team_posting(c: Candidate) -> JobPosting:
	if c.folder != "":
		return load(c.folder)
	return RuleEngine.find_posting(c.applied_position)


## 按组招的日子：今天面谁、按什么顺序。剧情人物先面，然后每个组轮流出一个人，最多 MAX_SESSIONS 场。
## 今天有奇葩，就套在第一个普通人身上。顺序跟着这一天的种子走。
func plan_sessions() -> void:
	sessions = []
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([day_seed(), "sessions"])
	var pool := interviewees.duplicate()
	for i in range(pool.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t: Candidate = pool[i]
		pool[i] = pool[j]
		pool[j] = t
	var story := pool.filter(func(c: Candidate) -> bool: return c.is_story)
	var plain := pool.filter(func(c: Candidate) -> bool: return not c.is_story)
	for c: Candidate in story:
		if sessions.size() < MAX_SESSIONS:
			sessions.append(c)
	# 每个组轮流出一个：这一轮出过人的组先跳过，都出过了就开下一轮
	var round_teams := {}
	for c: Candidate in sessions:
		round_teams[_team_key(c)] = true
	while sessions.size() < MAX_SESSIONS and not plain.is_empty():
		var picked := -1
		for i in plain.size():
			if not round_teams.has(_team_key(plain[i])):
				picked = i
				break
		if picked < 0:
			round_teams = {}
			picked = 0
		var next: Candidate = plain.pop_at(picked)
		round_teams[_team_key(next)] = true
		sessions.append(next)
	var quirk := config.quirk
	if quirk:
		for c: Candidate in sessions:
			if not c.is_story:
				if c.quirk == &"":
					quirk.apply(c)
				break


func _team_key(c: Candidate) -> String:
	return c.folder if c.folder != "" else c.applied_position


## 下班时间跟着实际走的日子：按组招（面到几点算几点），或者有离职谈话（谈到几点算几点）。
func clocked_day() -> bool:
	return config.team_folders or not config.exit_talks.is_empty()


## 今天几点下班：没面试 18:00；按组招的日子面到几点算几点，不早于 18:00。
func off_minutes() -> int:
	return maxi(CLOCK_OUT, int(stats.get("clock", 0)))


func clock_text(minutes: int) -> String:
	return "%02d:%02d" % [minutes / 60, minutes % 60]


## 今天几点到家。
func home_minutes() -> int:
	return off_minutes() + COMMUTE


## 今天还没单独面的破格的人，没有返回 null。
func next_vouched() -> Candidate:
	for c in vouched:
		if c.display_name not in stats.solo_done:
			return c
	return null


## 手写人物这份简历今天出不出现：skip_when 对上就不出。写成“family:…”的看家里的事（GameState.family_matches），否则看手写人物的去向。
func story_skipped(c: Candidate) -> bool:
	if c.skip_when == "":
		return false
	if c.skip_when.begins_with("family:"):
		return family_matches(c.skip_when.trim_prefix("family:"))
	return echo_matches(c.skip_when)


func took_kickback() -> bool:
	return kickbacks.any(func(k: Dictionary) -> bool: return k.taken)


## 某个月收下或退回的信封和东西。
func kickbacks_in(in_month: int) -> Array:
	return kickbacks.filter(func(k: Dictionary) -> bool: return month_of(int(k.day)) == in_month)


## 手写人物的去向：hired（录用了）、pass、reject，没见过为空串。reason 是拒绝时选的那句（原样，带句号）。
## unbooked：筛过了，但那晚约的是别人。
func story_outcome(id: String) -> Dictionary:
	var result := {"verdict": "", "reason": "", "chief_pick": false, "picked_by": "", "exception": false, "unbooked": false}
	for entry: Dictionary in decision_log:
		if entry.candidate_id == id:
			result = {"verdict": entry.verdict, "reason": entry.reason_text, "chief_pick": false, "picked_by": "", "exception": entry.get("exception", false)}
	result.unbooked = id in unbooked
	for h: Dictionary in hires:
		if String(h.candidate.id) == id:
			result.verdict = "hired"
			result.chief_pick = h.get("chief_pick", false)
			result.picked_by = h.get("picked_by", "赵主管")
	return result


## when 写成“id:pass”时录用了的也算 pass；“id:exception”是破格放进来的；
## “id:exposed”是面试被你问穿、最后没录用；“id:seen”是这份简历你处理过（不管怎么判的）；
## “a|b”任一条对上，“a&b”都对上，“!a”没对上（| 比 & 松）。
func echo_matches(when: String) -> bool:
	if "|" in when:
		return Array(when.split("|")).any(echo_matches)
	if "&" in when:
		return Array(when.split("&")).all(echo_matches)
	if when.begins_with("!"):
		return not echo_matches(when.substr(1))
	var parts := when.split(":")
	if parts[1] == "exception":
		return story_outcome(parts[0]).exception
	if parts[1] == "exposed":
		return parts[0] in exposed and story_outcome(parts[0]).verdict != "hired"
	if parts[1] == "seen":
		return story_outcome(parts[0]).verdict != ""
	var verdict: String = story_outcome(parts[0]).verdict
	return verdict == parts[1] or (parts[1] == "pass" and verdict == "hired")


## 今天对上的回响叠在一起：头条取第一条对上的，邮件附言和短信一条条接着写。“{reason}”已换好。
func story_echo() -> Dictionary:
	var merged := {}
	for echo: Dictionary in config.story_echoes:
		if not echo_matches(echo.when):
			continue
		var reason: String = story_outcome(echo.when.split(":")[0].trim_prefix("!")).reason.trim_suffix("。")
		if echo.get("headline", "") != "" and not merged.has("headline"):
			merged.headline = echo.headline.replace("{reason}", reason)
			merged.body = echo.get("body", "").replace("{reason}", reason)
		for key: String in ["mail_ps", "sms"]:
			if echo.get(key, "") != "":
				var text: String = echo[key].replace("{reason}", reason)
				merged[key] = text if not merged.has(key) else merged[key] + "\n" + text
	return merged


## 今天对上的回响里老板发的钱 [{label, amount}]。
func echo_bonuses() -> Array:
	var result := []
	for echo: Dictionary in config.story_echoes:
		if echo.has("bonus") and echo_matches(echo.when):
			result.append(echo.bonus)
	return result


func echo_bonus() -> int:
	var total := 0
	for b: Dictionary in echo_bonuses():
		total += int(b.amount)
	return total


## 家里的事。when 写成“标记:选项”，比如“d2_dad:weekend”；“标记:”表示还没回过。
## 也可以写“marriage>=N”“marriage<N”，看夫妻感情；“savings<N”看存款；“unpaid:账单 id”是今天那张账单没付；
## “wallet>=N”看手机零钱；“kickback”是收过信封，“broker”是这个月放过猎头的人，“took:候选人 id”是收了那个人的；“story:候选人 id:pass/reject/hired”看手写人物的去向（同 story_echoes）。空串总是对上。
## 前面加“!”是反过来；用“&”连起几条，要全对上。
func family_matches(when: String) -> bool:
	if when == "":
		return true
	if "&" in when:
		return Array(when.split("&")).all(family_matches)
	if when.begins_with("!"):
		return not family_matches(when.substr(1))
	if when == "kickback":
		return took_kickback()
	if when.begins_with("evidence:"):
		return when.trim_prefix("evidence:") in evidence
	if when.begins_with("lawsuit>="):
		return lawsuit_risk >= int(when.trim_prefix("lawsuit>="))
	if when.begins_with("trust>="):
		return boss_trust >= int(when.trim_prefix("trust>="))
	if when.begins_with("trust<"):
		return boss_trust < int(when.trim_prefix("trust<"))
	if when.begins_with("conscience>="):
		return conscience >= int(when.trim_prefix("conscience>="))
	if when.begins_with("hired_month:"):
		var m := int(when.trim_prefix("hired_month:"))
		return hires.any(func(h: Dictionary) -> bool: return month_of(int(h.day_hired)) == m)
	if when.begins_with("hired:"):
		return hires.any(func(h: Dictionary) -> bool: return String(h.candidate.id) == when.trim_prefix("hired:")) and when.trim_prefix("hired:") not in voided
	if when == "broker":
		return not broker_passes().is_empty()
	if when.begins_with("wallet>="):
		return wallet() >= int(when.trim_prefix("wallet>="))
	if when.begins_with("took:"):
		var who := when.trim_prefix("took:")
		return kickbacks.any(func(k: Dictionary) -> bool: return k.taken and k.get("candidate_id", "") == who)
	if when.begins_with("story:"):
		return echo_matches(when.trim_prefix("story:"))
	if when.begins_with("marriage>="):
		return marriage >= int(when.trim_prefix("marriage>="))
	if when.begins_with("marriage<"):
		return marriage < int(when.trim_prefix("marriage<"))
	if when.begins_with("savings<"):
		return savings < int(when.trim_prefix("savings<"))
	if when.begins_with("unpaid:"):
		return when.trim_prefix("unpaid:") not in stats.get("paid_bills", [])
	var parts := when.split(":")
	return str(family.get(parts[0], "")) == parts[1]


## 上班时收到一条老婆的消息（DayConfig.desk_texts 的一项）。
func receive_text(entry: Dictionary) -> void:
	stats.texts.append(entry)


func text_replied(id: String) -> bool:
	return family.has(id)


## 回老婆的消息：记下回了哪句，感情按选项变，桌上的钟另扣。
func reply_text(entry: Dictionary, option: Dictionary) -> void:
	if text_replied(entry.id):
		return
	family[entry.id] = option.key
	marriage += int(option.get("marriage", 0))
	family_state += int(option.get("family", 0))
	boss_trust += int(option.get("trust", 0))
	if option.has("transfer"):
		# 意外支出走工资卡，不动猎头那笔零钱（第 15 天“我手头有”看的是零钱）
		if entry.has("surprise"):
			stats.sent.append({"to": entry.get("from", "老婆"), "amount": int(option.transfer), "note": option.get("note", "")})
		else:
			send_transfer(entry.get("from", "老婆"), int(option.transfer), option.get("note", ""))
	if option.get("evidence", "") != "":
		add_evidence(option.evidence)


## 意外支出：今天那件事收尾。消息没到（下班早）或到了没回，都按第一项（全价）办；
## 没回的再按发消息的人扣一次（老婆 −1 感情）。选了赌一把的当场掷骰，排进后账。
## 今天到期的后账（reveal_today）也在这里扣钱。重复调用没事。日结单打开时和 settle 里各调一次。
func close_surprise() -> void:
	for r: Dictionary in reveal_today:
		if not stats.texts.any(func(e: Dictionary) -> bool: return e.get("id", "") == r.id):
			receive_text(r)
		if r.id in stats.get("reveals_paid", []):
			continue
		stats["reveals_paid"] = stats.get("reveals_paid", []) + [r.id]
		if int(r.transfer) > 0:
			stats.sent.append({"to": r.from, "amount": int(r.transfer), "note": r.note})
		marriage += int(r.marriage)
		family_state += int(r.family)
		for k in r.flag:
			family[k] = r.flag[k]
		for h: Dictionary in surprises:
			if h.id == r.surprise:
				h["revealed"] = int(r.transfer)
	surprise_queue = surprise_queue.filter(func(q: Dictionary) -> bool: return int(q.due) > day)
	if surprise_today.is_empty():
		return
	var entry := surprise_today
	if not stats.texts.any(func(e: Dictionary) -> bool: return e.get("id", "") == entry.id):
		receive_text(entry)
	if not text_replied(entry.id):
		reply_text(entry, entry.replies[0])
		if entry.from == "老婆":
			marriage -= 1
		else:
			family_state -= 1
		stats["surprise_ignored"] = true
	if surprises.any(func(h: Dictionary) -> bool: return int(h.day) == day):
		return
	var key: String = family.get(entry.id, "")
	var h := {"day": day, "id": entry.surprise, "cost": int(entry.cost), "paid": 0, "key": key}
	for o: Dictionary in entry.replies:
		if o.key != key:
			continue
		h.paid = int(o.transfer)
		if o.get("gamble", false) and day < LAST_DAY:
			var extra := Surprises.surplus(day, int(morning.get("savings", savings)))
			var g := Surprises.gamble(day, entry.surprise, int(entry.cost), extra, luck_streak, run_seed, luck_force)
			luck_force = ""
			h["outcome"] = g.outcome
			h["streak"] = luck_streak
			luck_streak = luck_streak + 1 if g.outcome == "bad" else 0
			surprise_queue.append(g.item)
	surprises.append(h)


## 修改器：今天立刻来一件（不看门槛），还没发到手机上的话 Desk 下一分钟就发。
func force_surprise() -> void:
	surprise_today = Surprises.pick(day, savings, surprises, run_seed + randi(), true)
	if not surprise_today.is_empty():
		surprise_today.at = 0


## 下班结算：收到了没回的算不回。来了电话没走，也算一次。
func settle_family() -> void:
	for entry: Dictionary in stats.texts:
		if entry.has("replies") and not text_replied(entry.id):
			family[entry.id] = "ignored"
			# 只有老婆的消息不回默认扣感情，别人的写了 ignored 才算
			marriage += int(entry.get("ignored", -1 if entry.get("from", "老婆") == "老婆" else 0))
			boss_trust += int(entry.get("ignored_trust", 0))
	# 今天的 HC 没放满（第 23 天月底）：王总记一笔
	if config.hc_today > 0 and passed_today.size() + vouched_today.size() < config.hc_today:
		boss_trust -= 2
	# HC 硬指标那个岗位一个都没放进去：王总记一笔
	if hc_push_short():
		stats.hc_short = true
		boss_trust -= 1
	# 没签的入职登记表：王总记一笔
	if not stats.intake_left.is_empty():
		boss_trust -= 1
	# 下班还没点的转账，24 小时一到自动退回
	for t: Dictionary in stats.transfers:
		answer_transfer(t, false)
	if stats.called and not stats.left_early:
		marriage += int(config.midday_call.get("stayed", -1))
	# 按组招的日子：回家晚了老婆那边扣；放进去的人太少、面不满两场，王总记一笔（第 13 天的面试是第 12 天招的，不算）
	if clocked_day() and not stats.left_early:
		for at: int in LATE_HOME:
			if home_minutes() >= at:
				stats.late_home += 1
				marriage -= 1
		if config.team_folders and day > 1 and RuleEngine.load_day(day - 1).team_folders and int(stats.held) < 2:
			stats.few_sessions = true
			boss_trust -= 1


## 这个月老婆发来的、能回的消息，回了几条。消息 id 写成“t天_序号”，按天归到月份。
func text_counts(in_month := month()) -> Dictionary:
	var got := 0
	var replied := 0
	for id: String in family:
		var d := int(id.substr(1).get_slice("_", 0)) if id.begins_with("t") else 0
		if d > 0 and month_of(d) == in_month:
			got += 1
			if family[id] != "ignored":
				replied += 1
	return {"got": got, "replied": replied}


## 今晚的家人短信：对上的第一条变体盖过 family_sms。
func family_sms() -> String:
	for variant: Dictionary in config.family_sms_by:
		if family_matches(variant.when):
			return variant.sms
	return config.family_sms


## 今晚能回的话：要求付了（paid）或没付（unpaid）某张账单的选项，条件不对就不出。
func sms_options() -> Array:
	return config.sms_replies.filter(func(o: Dictionary) -> bool:
		if o.has("paid"):
			return o.paid in stats.paid_bills
		if o.has("unpaid"):
			return o.unpaid not in stats.paid_bills
		return true)


## 回短信：记下选了哪句；“不回”之类的选项带 family < 0。
func answer_sms(option: Dictionary) -> void:
	family[config.sms_flag] = option.key
	family_state += int(option.get("family", 0))
	marriage += int(option.get("marriage", 0))


## 回家时说的话（DayConfig.home_scene 里的问话）：记下选了哪句，感情按选项变。
## 选项带 gray 的是收下了别人的东西（小刘家的购物卡）：钱直接进存款，记进 kickbacks。
func answer_home(flag: String, option: Dictionary) -> void:
	family[flag] = option.key
	marriage += int(option.get("marriage", 0))
	if option.has("gray"):
		var gray: Dictionary = option.gray
		kickbacks.append({"day": day, "from": gray.get("from", ""), "amount": int(gray.amount), "candidate_id": gray.get("candidate_id", ""), "taken": bool(gray.get("taken", true))})
		if gray.get("taken", true):
			savings += int(gray.amount)
	if option.has("late"):
		late_next = {"minutes": int(option.late), "morning": option.get("morning", "")}


## 今天几点到的公司，比如“10:30”。
func arrival_time() -> String:
	var at := 8 * 60 + int(late_today.get("minutes", 0))
	return "%02d:%02d" % [at / 60, at % 60]


## 迟到扣款：按分钟折，晚 150 分钟扣 ¥50。
func late_fine() -> int:
	return int(late_today.get("minutes", 0)) * LATE_PER_HOUR / 60


## 第 4 天上午家里来电，玩家提前下班：剩下的简历和今天的面试都不做了。
func leave_early() -> void:
	stats.left_early = true
	family[config.midday_call.get("flag", "d%d_left" % day)] = "yes"
	marriage += int(config.midday_call.get("left", 2))
	boss_trust += int(config.midday_call.get("trust", 0))
	interviewees = []
	vouched = []


## loyalty_hit 只作用于入职记录：候选人资源是共享的，不能改。
## vouched：破格进来、你单独面的人，出了事算你的（EmployeeEvents）。
## evidence：面试里查出来的 {found: 查实的行, caught: 说中几次}；查实了还录、人又出事，算明知故犯（EmployeeEvents）。
func add_hire(c: Candidate, scorecard: Dictionary, promise := "", loyalty_hit := 0, chief_pick := false, picked_by := "赵主管", hr_edit := {}, vouched_hire := false, evidence := {}) -> void:
	var data := c.to_dict()
	data.loyalty = maxi(0, data.loyalty - loyalty_hit)
	hires.append({
		"candidate": data, "day_hired": day, "scorecard": scorecard, "promise": promise,
		"event_resolved": false, "retention_due": day + int(pay.retention_days), "chief_pick": chief_pick, "picked_by": picked_by,
		"hr_edit": hr_edit, "vouched": vouched_hire, "evidence": evidence,
	})


## 面试完没录：和录用的人同一天对账。chief_pick：主管当时想要这个人。
func add_reject(c: Candidate, evidence := {}, chief_pick := false) -> void:
	rejects.append({
		"candidate": c.to_dict(), "day": day, "due": day + int(pay.retention_days),
		"evidence": evidence, "chief_pick": chief_pick, "resolved": false,
	})


static func has_evidence(evidence: Dictionary) -> bool:
	return not evidence.get("found", []).is_empty() or int(evidence.get("caught", 0)) > 0


## 留任期按录用那天的标准算；旧存档没有这一项，按 3 天补。
func retention_due(hire: Dictionary) -> int:
	return int(hire.get("retention_due", int(hire.day_hired) + 3))


## 留任期还没满的人：奖金“在路上”。
func pending_hires() -> Array:
	return hires.filter(func(h: Dictionary) -> bool: return not h.event_resolved)


func record_reply(c: Candidate, ask: CandidateAsk, choice: String, text: String) -> void:
	reply_log.append({"day": day, "candidate_name": c.display_name, "question": ask.question, "choice": choice, "answer": text})


## 第一个月不扣钱：违规只是拿不到判断奖金，老板对质也不罚款。
func fines_on() -> bool:
	return pay.get("fines", true)


func fines() -> int:
	if not fines_on():
		return 0
	return maxi(0, stats.wrong - FREE_WARNINGS) * VIOLATION_FINE


## 底薪：有人效指标的日子（DayConfig.quota），处理不够数按比例扣。
func base_pay() -> int:
	var quota := quota_today()
	if quota <= 0:
		return int(pay.base)
	return int(pay.base) * mini(stats.processed, quota) / quota


## 今天的人效指标：标准耗时的日子（DayConfig.standard_time）按你最快的那一段排，
## 一天 420 分钟（08:00–15:00）除以几分钟一份，不少于当天的简历数、不多于一倍半；平时用 DayConfig.quota。
func quota_today() -> int:
	if config.standard_time and best_pace > 0.0:
		return clampi(ceili(420.0 / best_pace), config.resume_count, ceili(config.resume_count * 1.5))
	return config.quota


## 今天的简历份数：标准耗时的日子跟着指标走（王总照你最快那天排量）。
func resume_count_today() -> int:
	return maxi(config.resume_count, quota_today()) if config.standard_time else config.resume_count


## 盖一个章记一次钟点；下班时量出今天最快的那一段（连着三份的平均），比以前快就记下来。
func record_pace(minute: int) -> void:
	stats.paces.append(minute)


func _settle_pace() -> void:
	var p: Array = stats.paces
	for i in range(3, p.size()):
		var avg := (float(p[i]) - float(p[i - 3])) / 3.0
		if avg > 0.0:
			var pace := maxf(avg, 3.0)
			if best_pace <= 0.0 or pace < best_pace:
				best_pace = pace


## 昨天处理了几份（人效看板用）。
func processed_on(on_day: int) -> int:
	return decision_log.filter(func(e: Dictionary) -> bool: return int(e.day) == on_day).size()


## 昨天录用的人：今天要办入职手续。
func hired_on(on_day: int) -> Array:
	return hires.filter(func(h: Dictionary) -> bool: return int(h.day_hired) == on_day)


## 绩效：处理过的每份简历都有，对错不论。
func performance_pay() -> int:
	return stats.processed * int(pay.per_resume)


func judge_bonus() -> int:
	return stats.correct * int(pay.per_correct)


## 理由奖金：经济好的时候才有（第 1 月），之后的月份没写就是 0。
func reason_bonus() -> int:
	return stats.reason_ok * int(pay.get("per_reason", 0))


func retained_count() -> int:
	return stats.retained.filter(func(r: Dictionary) -> bool: return not r.left).size()


## 主管推荐奖：录用的人是赵主管要的（见 InterviewRoom.is_chief_pick），当天发；没写算 0。
func chief_bonus() -> int:
	return stats.chief_picks.size() * int(pay.get("chief_bonus", 0))


## 识人奖：今天满期的人里，你在评分表上改的那一处比主管填的更接近 TA 的真实情况；没写算 0。
func edit_bonus() -> int:
	return stats.edits.filter(func(e: Dictionary) -> bool: return e.verdict == "right").size() * int(pay.get("edit_bonus", 0))


## 拒对了、面试里又有证据（说中/查实）：发识人奖；没证据不发，免得“全拒最安全”。
func reject_bonus() -> int:
	return stats.rejects.filter(func(r: Dictionary) -> bool: return not r.good and r.evidence).size() * int(pay.get("edit_bonus", 0))


## 拒掉好人：招聘成本。第一个月不扣钱。
func reject_cost() -> int:
	if not fines_on():
		return 0
	return stats.rejects.filter(func(r: Dictionary) -> bool: return r.good).size() * MISS_COST


## 查实了还录、人又出事：第一个月也扣（明知故犯，和破格担保一个道理）。
func knowing_fine() -> int:
	return stats.knowing.size() * KNOWING_FINE


## 今天满期、人还在的留任奖金；延发的月份不进今天的收入。
func retention_bonus() -> int:
	return 0 if pay.retention_deferred else retained_count() * int(pay.retention)


## 罚款开着时第 1–2 次违规只警告；未处理的简历拿不到绩效和判断奖金。
func income() -> int:
	return base_pay() + performance_pay() + judge_bonus() + reason_bonus() + chief_bonus() + edit_bonus() + retention_bonus() + echo_bonus() + reject_bonus() - reject_cost() - knowing_fine() - late_fine() - fines() - stats.event_fine + stats.gray + broker_income() - sent_total() - int(stats.talk_fine) + int(stats.memo_money) + vouch_bonus() + solo_pay() - hc_push_fine()


## 第 d 天是第几个月，1 起（月份长短见 MONTH_LENGTHS；超出的按最后一个月的长度往后排）。
static func month_of(d: int) -> int:
	var m := 1
	var first := 1
	while d >= first + month_length(m):
		first += month_length(m)
		m += 1
	return m


## 第 m 个月有几个工作日。
static func month_length(m: int) -> int:
	return MONTH_LENGTHS[clampi(m - 1, 0, MONTH_LENGTHS.size() - 1)]


## 第 m 个月的第一天是第几天。
static func month_first_day(m: int) -> int:
	var first := 1
	for i in range(1, m):
		first += month_length(i)
	return first


## 第 m 个月的最后一天（月底，还房贷那天）。
static func month_last_day(m: int) -> int:
	return month_first_day(m) + month_length(m) - 1


## 第几个月，1 起。
func month() -> int:
	return month_of(day)


## 这个月第几天，1 起。
func day_in_month() -> int:
	return day - month_first_day(month()) + 1


func is_month_end() -> bool:
	return day == month_last_day(month())


## 距月底还房贷还有几个工作日；今天就是还款日时为 0。
func days_to_mortgage() -> int:
	return month_last_day(month()) - day


func mortgage_today() -> int:
	return MORTGAGE if is_month_end() else 0


## 今天的账单：带 when 的（之前选过才有的）对不上就不出。
func bills_today() -> Array:
	return config.bills.filter(func(b: Dictionary) -> bool: return family_matches(b.get("when", "")))


func settle(paid_bills: Array, rescues: Array = []) -> int:
	stats.paid_bills = paid_bills.duplicate()
	close_surprise()
	settle_family()
	_settle_pace()
	var net := income() - mortgage_today()
	# 月底补窟窿的路（DayConfig.rescue_options）：钱进来，标记记下，后果下个月算
	for r: Dictionary in config.rescue_options:
		if r.id in rescues and family_matches(r.get("when", "")):
			net += int(r.get("amount", 0))
			family["rescue_" + String(r.id)] = "yes"
			family_state += int(r.get("family", 0))
			marriage += int(r.get("marriage", 0))
			stats.rescues.append(r.id)
	for bill: Dictionary in bills_today():
		if bill.id in paid_bills:
			net -= int(bill.amount)
		else:
			family_state -= 1
	savings += net
	if pay.retention_deferred:
		deferred_bonus += retained_count() * int(pay.retention)
	EventBus.day_ended.emit(day)
	return net


func is_bankrupt() -> bool:
	return savings < 0


func to_dict() -> Dictionary:
	return {
		"run_seed": run_seed, "day": day, "savings": savings, "conscience": conscience,
		"boss_trust": boss_trust, "family_state": family_state, "family": family, "marriage": marriage, "deferred_bonus": deferred_bonus,
		"month_lengths": MONTH_LENGTHS, "decision_log": decision_log, "hires": hires, "rejects": rejects, "boss_promised_rule": boss_promised_rule,
		"lawsuit_risk": lawsuit_risk, "reply_log": reply_log, "kickbacks": kickbacks, "wallet_out": wallet_out, "exposed": exposed,
		"late_next": late_next, "late_today": late_today, "late_count": late_count, "late_ps": late_ps, "unbooked": unbooked,
		"folder_filled": folder_filled, "talk_log": talk_log, "evidence": evidence, "best_pace": best_pace, "voided": voided, "paper": paper, "blocked_rejects": blocked_rejects, "surprises": surprises, "surprise_queue": surprise_queue, "luck_streak": luck_streak,
		"interviewees": interviewees.map(func(c: Candidate) -> Dictionary: return c.to_dict()),
		"vouched": vouched.map(func(c: Candidate) -> Dictionary: return c.to_dict()),
	}


func load_dict(data: Dictionary) -> void:
	run_seed = int(data.run_seed)
	day = int(data.day)
	savings = int(data.savings)
	conscience = int(data.conscience)
	boss_trust = int(data.boss_trust)
	family_state = int(data.family_state)
	family = data.get("family", {})
	marriage = int(data.get("marriage", 0))
	decision_log = data.decision_log
	hires = data.hires
	rejects = data.get("rejects", [])
	boss_promised_rule = data.boss_promised_rule
	lawsuit_risk = int(data.get("lawsuit_risk", 0))  # 旧存档没有这两项
	reply_log = data.get("reply_log", [])
	deferred_bonus = int(data.get("deferred_bonus", 0))
	kickbacks = data.get("kickbacks", [])
	wallet_out = int(data.get("wallet_out", 0))
	folder_filled = data.get("folder_filled", {})
	exposed = data.get("exposed", [])
	late_next = data.get("late_next", {})
	late_today = data.get("late_today", {})
	late_count = int(data.get("late_count", 0))
	late_ps = data.get("late_ps", "")
	unbooked = data.get("unbooked", [])
	talk_log = data.get("talk_log", [])
	evidence = data.get("evidence", [])
	best_pace = float(data.get("best_pace", 0.0))
	voided = data.get("voided", [])
	blocked_rejects = data.get("blocked_rejects", [])
	paper = data.get("paper", {})
	surprises = data.get("surprises", [])
	surprise_queue = data.get("surprise_queue", [])
	luck_streak = int(data.get("luck_streak", 0))
	interviewees = []
	interviewed_today = []
	for c: Dictionary in data.get("interviewees", []):
		interviewees.append(Candidate.from_dict(c))
	vouched = []
	for c: Dictionary in data.get("vouched", []):
		vouched.append(Candidate.from_dict(c))
	begin_day()
