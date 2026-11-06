extends Node
## 天数、存款、隐藏数值、已录用员工、决策日志。

const START_DATE := "2026-03-02"
const START_SAVINGS := 200
const LAST_DAY := 7
const VIOLATION_FINE := 50
const FREE_WARNINGS := 2
## 破格：从第 3 天起，每天能给一份不合规的简历盖一次破格章，第二天 14:00 你单独面 TA（赵主管不在），录用了算你担保。
## 担保的人留任期满出事，不管这个月扣不扣钱，都扣 VOUCH_FINE；干得好，老板记你一笔。
const EXCEPTION_DAY := 3
const VOUCH_FINE := 100
## 晚到：每晚一小时扣多少（底薪按 8 小时折）。这是考勤，不是违规罚款，第一个月也扣。
const LATE_PER_HOUR := 20
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
## 已录用员工 {candidate, day_hired, scorecard, promise, event_resolved, retention_due, chief_pick, hr_edit}
## hr_edit：评分表上你用红笔改的那一处 {item, from, to}，空表示没改；留任期满那天对账（见 EmployeeEvents.settle_edit）。
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
## 昨天破格放进来、今天你单独面的人；不进赵主管那场。
var vouched: Array[Candidate] = []
## 今天已经面过的人（display_name）：剧情候选人那场面完，有奇葩的日子再加一场（见 InterviewRoom.second_candidate）。
var interviewed_today: PackedStringArray = []
## 夹在简历里的信封 {day, from, amount, candidate_id, taken}：第一个月只收不追，下个月有人来“惦记”。
var kickbacks: Array = []
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

# 当日数据，只在一天内有效
var stats := {}
var passed_today: Array[Candidate] = []
var vouched_today: Array[Candidate] = []
var event_today := {}


func new_game(game_seed := 0) -> void:
	run_seed = game_seed if game_seed != 0 else randi()
	day = 1
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
	vouched = []
	kickbacks = []
	exposed = []
	late_next = {}
	late_today = {}
	late_count = 0
	late_ps = ""
	begin_day()


## 今天通过的人约到明天面试。
func advance_day() -> void:
	interviewees = passed_today.duplicate()
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
	stats = {"processed": 0, "correct": 0, "wrong": 0, "unprocessed": 0, "errors": [], "retained": [], "event_fine": 0, "reason_ok": 0, "reason_off": [], "chief_picks": [], "gray": 0, "paid_bills": [], "left_early": false, "texts": [], "called": false, "edits": [], "exception": "", "solo_done": [], "vouch": []}
	passed_today = []
	vouched_today = []
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


## 今天还能不能盖破格章：第 3 天起，一天一次。
func can_vouch() -> bool:
	return day >= EXCEPTION_DAY and stats.exception == ""


## 破格：明知不合规，你签字放进来。不算违规、不出违规单，但也没有判断奖金；计件照算。
## 决策日志记 verdict pass、exception true，回响和月底回顾按“pass”对得上。TA 明天单独面。
func record_exception(c: Candidate) -> void:
	var result := RuleEngine.evaluate(c)
	var failed_ids: Array = result.failed.map(func(r: Rule) -> String: return String(r.id))
	decision_log.append({
		"day": day, "candidate_id": String(c.id), "candidate_name": c.display_name,
		"verdict": "pass", "reason_rule": "", "reason_text": "", "expected": "reject",
		"failed_rules": failed_ids, "violated_rule": true, "exception": true,
	})
	stats.processed += 1
	stats.exception = c.display_name
	vouched_today.append(c)
	EventBus.stamp_applied.emit(c, "pass")


## 今天还没单独面的破格的人，没有返回 null。
func expose(c: Candidate) -> void:
	if String(c.id) not in exposed:
		exposed.append(String(c.id))


func next_vouched() -> Candidate:
	for c in vouched:
		if c.display_name not in stats.solo_done:
			return c
	return null


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


## 手写人物的去向：hired（录用了）、pass、reject，没见过为空串。reason 是拒绝时选的那句（原样，带句号）。
func story_outcome(id: String) -> Dictionary:
	var result := {"verdict": "", "reason": "", "chief_pick": false, "picked_by": "", "exception": false}
	for entry: Dictionary in decision_log:
		if entry.candidate_id == id:
			result = {"verdict": entry.verdict, "reason": entry.reason_text, "chief_pick": false, "picked_by": "", "exception": entry.get("exception", false)}
	for h: Dictionary in hires:
		if String(h.candidate.id) == id:
			result.verdict = "hired"
			result.chief_pick = h.get("chief_pick", false)
			result.picked_by = h.get("picked_by", "赵主管")
	return result


## when 写成“id:pass”时录用了的也算 pass；“id:exception”是破格放进来的；
## “id:exposed”是面试被你问穿、最后没录用；前面加“!”是反过来。
func echo_matches(when: String) -> bool:
	if when.begins_with("!"):
		return not echo_matches(when.substr(1))
	var parts := when.split(":")
	if parts[1] == "exception":
		return story_outcome(parts[0]).exception
	if parts[1] == "exposed":
		return parts[0] in exposed and story_outcome(parts[0]).verdict != "hired"
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
## 也可以写“marriage>=N”“marriage<N”，看夫妻感情；“kickback”是抽屉里收了信封。空串总是对上。
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
	if when.begins_with("marriage>="):
		return marriage >= int(when.trim_prefix("marriage>="))
	if when.begins_with("marriage<"):
		return marriage < int(when.trim_prefix("marriage<"))
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


## 这个月老婆发来的、能回的消息，回了几条。
func text_counts() -> Dictionary:
	var got := 0
	var replied := 0
	for id: String in family:
		if id.begins_with("t"):
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
func answer_home(flag: String, option: Dictionary) -> void:
	family[flag] = option.key
	marriage += int(option.get("marriage", 0))
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
	interviewees = []
	vouched = []


## loyalty_hit 只作用于入职记录：候选人资源是共享的，不能改。
## vouched：破格进来、你单独面的人，出了事算你的（EmployeeEvents）。
func add_hire(c: Candidate, scorecard: Dictionary, promise := "", loyalty_hit := 0, chief_pick := false, picked_by := "赵主管", hr_edit := {}, vouched_hire := false) -> void:
	var data := c.to_dict()
	data.loyalty = maxi(0, data.loyalty - loyalty_hit)
	hires.append({
		"candidate": data, "day_hired": day, "scorecard": scorecard, "promise": promise,
		"event_resolved": false, "retention_due": day + int(pay.retention_days), "chief_pick": chief_pick, "picked_by": picked_by,
		"hr_edit": hr_edit, "vouched": vouched_hire,
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


## 识人奖：今天满期的人里，你在评分表上改的那一处比主管填的更接近 TA 的真实情况；没写算 0。
func edit_bonus() -> int:
	return stats.edits.filter(func(e: Dictionary) -> bool: return e.verdict == "right").size() * int(pay.get("edit_bonus", 0))


## 今天满期、人还在的留任奖金；延发的月份不进今天的收入。
func retention_bonus() -> int:
	return 0 if pay.retention_deferred else retained_count() * int(pay.retention)


## 罚款开着时第 1–2 次违规只警告；未处理的简历拿不到绩效和判断奖金。
func income() -> int:
	return int(pay.base) + performance_pay() + judge_bonus() + reason_bonus() + chief_bonus() + edit_bonus() + retention_bonus() + echo_bonus() - late_fine() - fines() - stats.event_fine + stats.gray


## 第几个月，1 起。
func month() -> int:
	return (day - 1) / DAYS_PER_MONTH + 1


## 这个月第几天，1 起。
func day_in_month() -> int:
	return (day - 1) % DAYS_PER_MONTH + 1


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
		"lawsuit_risk": lawsuit_risk, "reply_log": reply_log, "kickbacks": kickbacks, "exposed": exposed,
		"late_next": late_next, "late_today": late_today, "late_count": late_count, "late_ps": late_ps,
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
	boss_promised_rule = data.boss_promised_rule
	lawsuit_risk = int(data.get("lawsuit_risk", 0))  # 旧存档没有这两项
	reply_log = data.get("reply_log", [])
	deferred_bonus = int(data.get("deferred_bonus", 0))
	kickbacks = data.get("kickbacks", [])
	exposed = data.get("exposed", [])
	late_next = data.get("late_next", {})
	late_today = data.get("late_today", {})
	late_count = int(data.get("late_count", 0))
	late_ps = data.get("late_ps", "")
	interviewees = []
	interviewed_today = []
	for c: Dictionary in data.get("interviewees", []):
		interviewees.append(Candidate.from_dict(c))
	vouched = []
	for c: Dictionary in data.get("vouched", []):
		vouched.append(Candidate.from_dict(c))
	begin_day()
