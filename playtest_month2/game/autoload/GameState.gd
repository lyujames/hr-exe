extends Node
## 天数、存款、隐藏数值、已录用员工、决策日志。

const START_DATE := "2026-03-02"
const START_SAVINGS := 200
const LAST_DAY := 14
## 第二个月从第几天开始（标题页可以直接从这里开）。
const MONTH2_START := 8
const VIOLATION_FINE := 50
const FREE_WARNINGS := 2
## 每 7 个工作日算一个月，月底一次扣月供。
const DAYS_PER_MONTH := 7
const MORTGAGE := 1750

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
## 已录用员工 {candidate, day_hired, scorecard, promise, event_resolved, retention_due, chief_pick}
## chief_pick：赵主管要的人（拿了主管推荐奖），出了事他说“人是你面的”。
var hires: Array = []
## 延发月份没进存款的留任奖金，最终“在离职补偿中抵扣”。
var deferred_bonus := 0
var boss_promised_rule := false
## 违法提问累积的诉讼风险，风险爆发时公司被告。
var lawsuit_risk := 0
## 玩家回答候选人反问的原话，终章由 HireBot 原样复述。
var reply_log: Array = []
## 昨天筛简历通过、今天来面试的人：当天通过的人第二天才面试。
var interviewees: Array[Candidate] = []
## 今天已经面过的人（display_name）：剧情候选人那场面完，有奇葩的日子再加一场（见 InterviewRoom.second_candidate）。
var interviewed_today: PackedStringArray = []
## 夹在简历里的信封 {day, from, amount, candidate_id, taken}：第一个月只收不追，下个月有人来“惦记”。
var kickbacks: Array = []
## 当天清晨的状态快照：手动存档存的是它，今天做到一半的进度不进存档。
var morning := {}

# 当日数据，只在一天内有效
var stats := {}
var passed_today: Array[Candidate] = []
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
	deferred_bonus = 0
	boss_promised_rule = false
	lawsuit_risk = 0
	reply_log = []
	interviewees = []
	kickbacks = []
	begin_day()


## 直接从第二个月开始：没玩第一个月的人，按一个“还过得去”的第一个月补上家底。
## kickback：上个月第 6 天李哲他爸的信封收了没有；xiaoliu：你爸说小刘的事，你是让他投（try）还是说不上话（hard）。
const MONTH2_SAVINGS := 240
const MONTH2_MARRIAGE := 6
## [id, 名字, 岗位, 录用那天]
const MONTH2_CARRYOVER := [["carry_1", "林晓雨", "产品运营实习生", 6], ["carry_2", "高子涵", "内容运营实习生", 7]]


func new_game_month2(kickback: bool, xiaoliu: String, game_seed := 0) -> void:
	new_game(game_seed, MONTH2_START)
	savings = MONTH2_SAVINGS
	marriage = MONTH2_MARRIAGE
	family = {"h5_dad": xiaoliu, "d4_left": "yes"}
	kickbacks = [{"day": 6, "from": "李哲的爸爸", "amount": 300, "candidate_id": "story_headhunter", "taken": kickback}]
	# 上个月月底录用的两个实习生，留任期跨到这个月：奖金还在路上
	for h: Array in MONTH2_CARRYOVER:
		var c := Candidate.new()
		c.id = StringName(h[0])
		c.display_name = h[1]
		c.applied_position = h[2]
		c.is_intern = true
		c.portrait_seed = hash(h[0])
		c.ability = 70
		c.loyalty = 70
		c.pressure = 65
		hires.append({"candidate": c.to_dict(), "day_hired": h[3], "scorecard": {"狼性": 3, "格局": 3, "稳定性": 3, "颜值": 3}, "promise": "",
			"event_resolved": false, "retention_due": h[3] + 3, "chief_pick": false})
	begin_day()


## 第几个月（每 DAYS_PER_MONTH 天一个月）。
func month() -> int:
	return (day - 1) / DAYS_PER_MONTH + 1


## 这个月第几天，1 起。
func day_in_month() -> int:
	return (day - 1) % DAYS_PER_MONTH + 1


## 今天通过的人约到明天面试；月底通过的人不跨月（下个月换岗位了）。
func advance_day() -> void:
	if is_month_end():
		interviewees.clear()
	else:
		interviewees = passed_today.duplicate()
	day += 1
	begin_day()


func begin_day() -> void:
	config = RuleEngine.load_day(day)
	today = config.date if config.date != "" else DateUtil.add_days(START_DATE, day - 1)
	pay = RuleEngine.pay(day)
	RuleEngine.set_day(day)
	# retained：今天满期、人还在的 {name, day_hired, days}
	stats = {"processed": 0, "correct": 0, "wrong": 0, "unprocessed": 0, "errors": [], "retained": [], "event_fine": 0, "reason_ok": 0, "reason_off": [], "chief_picks": [], "gray": 0, "paid_bills": [], "left_early": false, "texts": [], "called": false}
	passed_today = []
	interviewed_today = []
	event_today = {}
	morning = to_dict().duplicate(true)


func day_seed() -> int:
	return hash([run_seed, day])


## 返回违规原因，判对时为空串。
func record_decision(c: Candidate, verdict: String, reason_rule: StringName, reason_text: String, extra := {}) -> String:
	var result := RuleEngine.evaluate(c)
	var expected := "pass" if result.pass else "reject"
	var violated: bool = verdict != expected
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
	decision_log.append(entry)
	stats.processed += 1
	var why := ""
	if violated:
		stats.wrong += 1
		why = "应拒绝：" + result.failed[0].title_key if verdict == "pass" else "不应拒绝：未违反任何规则"
		stats.errors.append({"name": c.display_name, "why": why})
		if verdict == "pass" and all_absurd:
			conscience += 1
	else:
		stats.correct += 1
		if verdict == "reject" and reason_rule != &"generic":
			if reason_hits(reason_rule, failed_ids, extra.get("flagged", [])):
				stats.reason_ok += 1
				entry.reason_ok = true
			else:
				var titles: Array = result.failed.map(func(r: Rule) -> String: return r.title_key)
				stats.reason_off.append({"name": c.display_name, "why": "理由不准，应为：" + "、".join(PackedStringArray(titles))})
	if verdict == "pass":
		passed_today.append(c)
	EventBus.stamp_applied.emit(c, verdict)
	return why


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


func took_kickback() -> bool:
	return kickbacks.any(func(k: Dictionary) -> bool: return k.taken)


## 某个月收下或退回的信封和东西。
func kickbacks_in(in_month: int) -> Array:
	return kickbacks.filter(func(k: Dictionary) -> bool: return (int(k.day) - 1) / DAYS_PER_MONTH + 1 == in_month)


## 手写人物的去向：hired（录用了）、pass、reject，没见过为空串。reason 是拒绝时选的那句（原样，带句号）。
func story_outcome(id: String) -> Dictionary:
	var result := {"verdict": "", "reason": "", "chief_pick": false}
	for entry: Dictionary in decision_log:
		if entry.candidate_id == id:
			result = {"verdict": entry.verdict, "reason": entry.reason_text, "chief_pick": false}
	for h: Dictionary in hires:
		if String(h.candidate.id) == id:
			result.verdict = "hired"
			result.chief_pick = h.get("chief_pick", false)
	return result


## when 写成“id:pass”时录用了的也算 pass。
func echo_matches(when: String) -> bool:
	var parts := when.split(":")
	var verdict: String = story_outcome(parts[0]).verdict
	return verdict == parts[1] or (parts[1] == "pass" and verdict == "hired")


## 今天对上的回响叠在一起：头条取第一条对上的，邮件附言和短信一条条接着写。“{reason}”已换好。
func story_echo() -> Dictionary:
	var merged := {}
	for echo: Dictionary in config.story_echoes:
		if not echo_matches(echo.when):
			continue
		var reason: String = story_outcome(echo.when.split(":")[0]).reason.trim_suffix("。")
		if echo.get("headline", "") != "" and not merged.has("headline"):
			merged.headline = echo.headline.replace("{reason}", reason)
			merged.body = echo.get("body", "").replace("{reason}", reason)
		for key: String in ["mail_ps", "sms"]:
			if echo.get(key, "") != "":
				var text: String = echo[key].replace("{reason}", reason)
				merged[key] = text if not merged.has(key) else merged[key] + "\n" + text
	return merged


## 家里的事。when 写成“标记:选项”，比如“d2_dad:weekend”；“标记:”表示还没回过。
## 也可以写“marriage>=N”“marriage<N”，看夫妻感情；“savings<N”看存款；“unpaid:账单 id”是今天那张账单没付；
## “kickback”是收过信封，“took:候选人 id”是收了那个人的；“story:候选人 id:pass/reject/hired”看手写人物的去向（同 story_echoes）。空串总是对上。
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


## 下班结算：收到了没回的算不回。来了电话没走，也算一次。
func settle_family() -> void:
	for entry: Dictionary in stats.texts:
		if entry.has("replies") and not text_replied(entry.id):
			family[entry.id] = "ignored"
			marriage += int(entry.get("ignored", -1))
	if stats.called and not stats.left_early:
		marriage += int(config.midday_call.get("stayed", -1))


## 这个月老婆发来的、能回的消息，回了几条。消息 id 写成“t天_序号”，按天归到月份。
func text_counts(in_month := month()) -> Dictionary:
	var got := 0
	var replied := 0
	for id: String in family:
		var d := int(id.substr(1).get_slice("_", 0)) if id.begins_with("t") else 0
		if d > 0 and (d - 1) / DAYS_PER_MONTH + 1 == in_month:
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


## 第 4 天上午家里来电，玩家提前下班：剩下的简历和今天的面试都不做了。
func leave_early() -> void:
	stats.left_early = true
	family[config.midday_call.get("flag", "d%d_left" % day)] = "yes"
	marriage += int(config.midday_call.get("left", 2))
	interviewees = []


## loyalty_hit 只作用于入职记录：候选人资源是共享的，不能改。
func add_hire(c: Candidate, scorecard: Dictionary, promise := "", loyalty_hit := 0, chief_pick := false) -> void:
	var data := c.to_dict()
	data.loyalty = maxi(0, data.loyalty - loyalty_hit)
	hires.append({
		"candidate": data, "day_hired": day, "scorecard": scorecard, "promise": promise,
		"event_resolved": false, "retention_due": day + int(pay.retention_days), "chief_pick": chief_pick,
	})


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


## 教学期：盖错章当场出违规单，不等日结。
func instant_notice() -> bool:
	return pay.get("instant_notice", false)


func fines() -> int:
	if not fines_on():
		return 0
	return maxi(0, stats.wrong - FREE_WARNINGS) * VIOLATION_FINE


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


## 今天满期、人还在的留任奖金；延发的月份不进今天的收入。
func retention_bonus() -> int:
	return 0 if pay.retention_deferred else retained_count() * int(pay.retention)


## 罚款开着时第 1–2 次违规只警告；未处理的简历拿不到绩效和判断奖金。
func income() -> int:
	return int(pay.base) + performance_pay() + judge_bonus() + reason_bonus() + chief_bonus() + retention_bonus() - fines() - stats.event_fine + stats.gray


func is_month_end() -> bool:
	return day % DAYS_PER_MONTH == 0


## 距月底还房贷还有几个工作日；今天就是还款日时为 0。
func days_to_mortgage() -> int:
	return (DAYS_PER_MONTH - day % DAYS_PER_MONTH) % DAYS_PER_MONTH


func mortgage_today() -> int:
	return MORTGAGE if is_month_end() else 0


func settle(paid_bills: Array) -> int:
	stats.paid_bills = paid_bills.duplicate()
	settle_family()
	var net := income() - mortgage_today()
	for bill: Dictionary in config.bills:
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
		"decision_log": decision_log, "hires": hires, "boss_promised_rule": boss_promised_rule,
		"lawsuit_risk": lawsuit_risk, "reply_log": reply_log, "kickbacks": kickbacks,
		"interviewees": interviewees.map(func(c: Candidate) -> Dictionary: return c.to_dict()),
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
	boss_promised_rule = data.boss_promised_rule
	lawsuit_risk = int(data.get("lawsuit_risk", 0))  # 旧存档没有这两项
	reply_log = data.get("reply_log", [])
	deferred_bonus = int(data.get("deferred_bonus", 0))
	kickbacks = data.get("kickbacks", [])
	interviewees = []
	interviewed_today = []
	for c: Dictionary in data.get("interviewees", []):
		interviewees.append(Candidate.from_dict(c))
	begin_day()
