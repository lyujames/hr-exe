extends Node
## 天数、存款、隐藏数值、已录用员工、决策日志。

const START_DATE := "2026-03-02"
const START_SAVINGS := 100
const LAST_DAY := 3
const CURRENCY := "$"
const BASE_PAY := 150
const PIECE_PAY := 2
const VIOLATION_FINE := 25
const FREE_WARNINGS := 2
const STREAK_LENGTH := 5
const STREAK_BONUS := 5
const MORTGAGE := 90
## 诉讼风险到线就和解，一局只赔一次；主管问的也算你的。
const LAWSUIT_LIMIT := 2
const LAWSUIT_SETTLEMENT := 150

var run_seed := 0
var day := 1
var today := START_DATE
var config: DayConfig
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
var lawsuit_settled := false
## 玩家回答候选人反问的原话，终章由 HireBot 原样复述。
var reply_log: Array = []

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
	lawsuit_settled = false
	reply_log = []
	begin_day()


func begin_day() -> void:
	today = DateUtil.add_days(START_DATE, day - 1)
	config = RuleEngine.load_day(day)
	RuleEngine.set_day(day)
	stats = {"processed": 0, "correct": 0, "wrong": 0, "unprocessed": 0, "errors": [], "bonus": 0, "event_fine": 0, "legal_flags": []}
	passed_today = []
	event_today = {}


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
		var why: String = "should reject: " + result.failed[0].title_key if verdict == "pass" else "should pass: broke no rule"
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


## 问了不该问的：当晚法务才告诉你，到线才赔。
func add_lawsuit_risk(card: QuestionCard) -> void:
	if card.lawsuit_risk > 0:
		lawsuit_risk += card.lawsuit_risk
		stats.legal_flags.append(card.text_key)


func legal_fine() -> int:
	return LAWSUIT_SETTLEMENT if lawsuit_risk >= LAWSUIT_LIMIT and not lawsuit_settled else 0


func fines() -> int:
	return maxi(0, stats.wrong - FREE_WARNINGS) * VIOLATION_FINE


## 第 1–2 次违规只警告；未处理的简历只是没有计件。
func income() -> int:
	return BASE_PAY + stats.processed * PIECE_PAY + stats.bonus - fines() - stats.event_fine - legal_fine()


func settle(paid_bills: Array) -> int:
	var net := income() - MORTGAGE
	for bill: Dictionary in config.bills:
		if bill.id in paid_bills:
			net -= int(bill.amount)
		else:
			family_state -= 1
	savings += net
	lawsuit_settled = lawsuit_settled or lawsuit_risk >= LAWSUIT_LIMIT
	EventBus.day_ended.emit(day)
	return net


func is_bankrupt() -> bool:
	return savings < 0


func to_dict() -> Dictionary:
	return {
		"run_seed": run_seed, "day": day, "savings": savings, "conscience": conscience,
		"boss_trust": boss_trust, "family_state": family_state, "streak": streak,
		"decision_log": decision_log, "hires": hires, "boss_promised_rule": boss_promised_rule,
		"lawsuit_risk": lawsuit_risk, "lawsuit_settled": lawsuit_settled, "reply_log": reply_log,
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
	lawsuit_settled = data.get("lawsuit_settled", false)
	reply_log = data.get("reply_log", [])
	begin_day()
