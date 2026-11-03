extends Node
## 天数、存款、隐藏数值、已录用员工、决策日志。

const START_DATE := "2026-03-02"
const START_SAVINGS := 200
const LAST_DAY := 5
const BASE_PAY := 300
const PIECE_PAY := 5
const VIOLATION_FINE := 50
const FREE_WARNINGS := 2
const STREAK_LENGTH := 5
const STREAK_BONUS := 10
## 每 5 个工作日算一个月，月底一次扣月供。
const DAYS_PER_MONTH := 5
const MORTGAGE := 1250

var run_seed := 0
var day := 1
var today := START_DATE
var config: DayConfig
## 本月的职位描述，月初的那天设置，之后沿用。
var job_posting: JobPosting
var savings := START_SAVINGS
var conscience := 0
var boss_trust := 0
var family_state := 0
var streak := 0
## 决策日志：从第一天起完整记录，为终章服务。
var decision_log: Array = []
## 已录用员工 {candidate, day_hired, scorecard, event_resolved}
var hires: Array = []
var boss_promised_rule := false
## 违法提问累积的诉讼风险，风险爆发时公司被告。
var lawsuit_risk := 0
## 玩家回答候选人反问的原话，终章由 HireBot 原样复述。
var reply_log: Array = []
## 当天清晨的状态快照：手动存档存的是它，今天做到一半的进度不进存档。
var morning := {}

# 当日数据，只在一天内有效
var stats := {}
var passed_today: Array[Candidate] = []
var event_today := {}


func new_game(game_seed := 0) -> void:
	run_seed = game_seed if game_seed != 0 else randi()
	day = 1
	savings = START_SAVINGS
	conscience = 0
	boss_trust = 0
	family_state = 0
	streak = 0
	decision_log = []
	hires = []
	boss_promised_rule = false
	lawsuit_risk = 0
	reply_log = []
	begin_day()


func begin_day() -> void:
	config = RuleEngine.load_day(day)
	today = config.date if config.date != "" else DateUtil.add_days(START_DATE, day - 1)
	job_posting = RuleEngine.job_posting(day)
	RuleEngine.set_day(day)
	stats = {"processed": 0, "correct": 0, "wrong": 0, "unprocessed": 0, "errors": [], "bonus": 0, "event_fine": 0}
	passed_today = []
	event_today = {}
	morning = to_dict().duplicate(true)


func day_seed() -> int:
	return hash([run_seed, day])


func record_decision(c: Candidate, verdict: String, reason_rule: StringName, reason_text: String) -> void:
	var result := RuleEngine.evaluate(c)
	var expected := "pass" if result.pass else "reject"
	var violated: bool = verdict != expected
	var failed_ids: Array = []
	var all_absurd: bool = not result.pass
	for rule: Rule in result.failed:
		failed_ids.append(String(rule.id))
		all_absurd = all_absurd and rule.is_absurd
	decision_log.append({
		"day": day, "candidate_id": String(c.id), "candidate_name": c.display_name,
		"verdict": verdict, "reason_rule": String(reason_rule), "reason_text": reason_text,
		"expected": expected, "failed_rules": failed_ids, "violated_rule": violated,
	})
	stats.processed += 1
	if violated:
		stats.wrong += 1
		streak = 0
		var why: String = "应拒绝：" + result.failed[0].title_key if verdict == "pass" else "不应拒绝：未违反任何规则"
		stats.errors.append({"name": c.display_name, "why": why})
		if verdict == "pass" and all_absurd:
			conscience += 1
	else:
		stats.correct += 1
		streak += 1
		if streak % STREAK_LENGTH == 0:
			stats.bonus += STREAK_BONUS
	if verdict == "pass":
		passed_today.append(c)
	EventBus.stamp_applied.emit(c, verdict)


## loyalty_hit 只作用于入职记录：候选人资源是共享的，不能改。
func add_hire(c: Candidate, scorecard: Dictionary, promise := "", loyalty_hit := 0) -> void:
	var data := c.to_dict()
	data.loyalty = maxi(0, data.loyalty - loyalty_hit)
	hires.append({"candidate": data, "day_hired": day, "scorecard": scorecard, "promise": promise, "event_resolved": false})


func record_reply(c: Candidate, ask: CandidateAsk, choice: String, text: String) -> void:
	reply_log.append({"day": day, "candidate_name": c.display_name, "question": ask.question, "choice": choice, "answer": text})


func fines() -> int:
	return maxi(0, stats.wrong - FREE_WARNINGS) * VIOLATION_FINE


## 第 1–2 次违规只警告；未处理的简历只是没有计件。
func income() -> int:
	return BASE_PAY + stats.processed * PIECE_PAY + stats.bonus - fines() - stats.event_fine


func is_month_end() -> bool:
	return day % DAYS_PER_MONTH == 0


## 距月底还房贷还有几个工作日；今天就是还款日时为 0。
func days_to_mortgage() -> int:
	return (DAYS_PER_MONTH - day % DAYS_PER_MONTH) % DAYS_PER_MONTH


func mortgage_today() -> int:
	return MORTGAGE if is_month_end() else 0


func settle(paid_bills: Array) -> int:
	var net := income() - mortgage_today()
	for bill: Dictionary in config.bills:
		if bill.id in paid_bills:
			net -= int(bill.amount)
		else:
			family_state -= 1
	savings += net
	EventBus.day_ended.emit(day)
	return net


func is_bankrupt() -> bool:
	return savings < 0


func to_dict() -> Dictionary:
	return {
		"run_seed": run_seed, "day": day, "savings": savings, "conscience": conscience,
		"boss_trust": boss_trust, "family_state": family_state, "streak": streak,
		"decision_log": decision_log, "hires": hires, "boss_promised_rule": boss_promised_rule,
		"lawsuit_risk": lawsuit_risk, "reply_log": reply_log,
	}


func load_dict(data: Dictionary) -> void:
	run_seed = int(data.run_seed)
	day = int(data.day)
	savings = int(data.savings)
	conscience = int(data.conscience)
	boss_trust = int(data.boss_trust)
	family_state = int(data.family_state)
	streak = int(data.streak)
	decision_log = data.decision_log
	hires = data.hires
	boss_promised_rule = data.boss_promised_rule
	lawsuit_risk = int(data.get("lawsuit_risk", 0))  # 旧存档没有这两项
	reply_log = data.get("reply_log", [])
	begin_day()
