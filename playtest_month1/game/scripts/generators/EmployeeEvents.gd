class_name EmployeeEvents
## 延迟反馈：录用的后果不在当天出现，由隐藏属性决定几天后发生什么。
## 每个人在留任期满那天早上结算一次：走了的没有留任奖金，还在的记进 stats.retained。

const BLAME_FINE := 200
const LIE_FINE := 300
## 由重到轻；同一天几个人满期，老板只叫最重的那个，其余的只在日结里一行带过。
const SEVERITY := ["embezzle", "jump", "burnout", "delay", "praise"]
const LEAVES := ["embezzle", "jump", "burnout"]
## 评分表上哪一项对的是哪个隐藏属性：抗压的人不会加班加到哭，留得住的人不跳槽，干得了的人不拖排期。
## 颜值没有对应的属性，改了也对不上账。
const EDIT_TRUTH := {"狼性": "pressure", "稳定性": "loyalty", "格局": "ability"}
## 出了哪种事，对的是评分表哪一项。
const EVENT_ITEM := {"burnout": "狼性", "jump": "稳定性", "delay": "格局"}


static func due_event() -> Dictionary:
	settle_rejects()
	var events: Array = []
	for hire: Dictionary in GameState.hires:
		if not hire.event_resolved and GameState.retention_due(hire) <= GameState.day:
			hire.event_resolved = true
			var event := _for_hire(hire)
			var days := GameState.retention_due(hire) - int(hire.day_hired)
			var entry := {"name": event.name, "days": days, "left": event.id in LEAVES, "title": event.title}
			GameState.stats.retained.append(entry)
			settle_edit(hire)
			_settle_vouch(hire, event)
			events.append(event)
	if events.is_empty():
		return _empty_headcount() if _no_hires_this_month() else {}
	events.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return SEVERITY.find(a.id) < SEVERITY.find(b.id))
	return events[0]


## 月初录用的人本该满期的那天，这个月还一个人都没招。
static func _no_hires_this_month() -> bool:
	var month_start := GameState.day - (GameState.day - 1) % GameState.DAYS_PER_MONTH
	if GameState.day != month_start + int(GameState.pay.retention_days):
		return false
	return not GameState.hires.any(func(h: Dictionary) -> bool: return int(h.day_hired) >= month_start)


## 这个人进来会怎样：剧情人物写死，其余按隐藏属性。录用和拒绝共用一套。
static func fate(c: Candidate) -> String:
	var kind := String(c.event_override)
	if kind != "":
		return kind
	if c.ability < 40:
		return "delay"
	if c.loyalty < 35:
		return "jump"
	if c.pressure < 35:
		return "burnout"
	return "praise"


## 被拒的人在别家的下场：拒对了有证据发识人奖，拒掉好人记错失（GameState.reject_bonus / reject_cost）。
const ELSEWHERE := {
	"embezzle": "%s去了别家，带着备用金失联了。",
	"jump": "%s去了别家，试用期没过就跳了。",
	"burnout": "%s去了别家，加班加到辞职了。",
	"delay": "%s去了别家，把项目拖黄了。",
	"praise": "%s去了竞对，干得很好。",
}


static func settle_rejects() -> void:
	for r: Dictionary in GameState.rejects:
		if r.resolved or int(r.due) > GameState.day:
			continue
		r.resolved = true
		var c := Candidate.from_dict(r.candidate)
		var kind := fate(c)
		var good := kind == "praise"
		var evidence := GameState.has_evidence(r.get("evidence", {}))
		var text: String = ELSEWHERE[kind] % c.display_name
		if good:
			text += "“我要的人你也拒？”" if r.get("chief_pick", false) else "你拒掉了一个好人。"
		else:
			text += "你拒对了。" if evidence else "拒对了，但你说不出为什么。"
		GameState.stats.rejects.append({"name": c.display_name, "good": good, "evidence": evidence, "text": text})


static func _for_hire(hire: Dictionary) -> Dictionary:
	var c := Candidate.from_dict(hire.candidate)
	var kind := fate(c)
	var scorecard_full: bool = hire.scorecard.values().all(func(v: Variant) -> bool: return int(v) == 5)
	var event := {"id": kind, "name": c.display_name, "fine": BLAME_FINE, "scorecard_full": scorecard_full, "blame": true}
	var term := "实习期" if c.is_intern else "试用期"
	match kind:
		"embezzle":
			event.title = "%s 不见了" % c.display_name
			event.body = "你录用的 %s %s还没满，带着项目备用金失联了。\n“你面试的，你签的字。这钱算谁的？”" % [c.display_name, term]
		"delay":
			event.title = "项目延期"
			event.body = "你录用的 %s 把排期拖了一周。\n“这就是你挑的人？”" % c.display_name
		"jump":
			event.title = term + "跳槽"
			event.body = "你录用的 %s 拿了竞对的 offer，今早直接没来。\n“招聘成本谁出？”" % c.display_name
		"burnout":
			event.title = "加班后离职"
			event.body = "%s 连续加了三天班，在工位上哭了，然后辞职了。\n“抗压都不行，你怎么面的？”" % c.display_name
		"praise":
			event.title = "项目大捷"
			event.body = "全员邮件：在王总的英明领导下，项目提前上线。\n其中 %s 贡献突出。顺便感谢 HR 同事。" % c.display_name
			event.fine = 0
			event.blame = false
	if not GameState.fines_on():
		event.fine = 0
	if hire.get("chief_pick", false):
		var who: String = hire.get("picked_by", "赵主管")
		event.body += "\n%s在旁边：“%s”" % [who, "我带得好。" if kind == "praise" else "人是你面的。"]
	# 破格进来的人：你单独面、你签的字。出事扣担保金（第一个月也扣），干得好老板记你一笔。
	if hire.get("vouched", false):
		event.vouched = true
		if kind == "praise":
			event.body += "\n王总批注：“破格那个是你保的？眼光可以。”"
		else:
			event.body += "\n“规则不让进，是你破格放进来的。担保金 ¥%d，自己出。”" % GameState.VOUCH_FINE
	var edit: Dictionary = hire.get("hr_edit", {})
	if not edit.is_empty() and EVENT_ITEM.get(kind, "") == edit.item:
		# 一行写完，别把老板的回话挤出纸
		var to := int(edit.to)
		var said := "看出来了还招？" if to <= 2 else ("这一项是你签的字。" if to >= 4 else "改成个 3 分，有什么用？")
		event.body += "\n评分表上你改了%s %d→%d：“%s”" % [edit.item, int(edit.from), to, said]
	# 面试里查实了还录：第一个月也扣（GameState.knowing_fine）
	if kind != "praise" and not hire.get("evidence", {}).get("found", []).is_empty():
		event.body += "\n“面试记录上你自己写着查实。你还招？”"
		GameState.boss_trust -= 1
		GameState.stats.knowing.append(c.display_name)
	var promise: String = hire.get("promise", "")
	if promise != "" and kind in ["jump", "burnout"]:
		event.body += "\n离职记录：“面试时 HR 说：%s”" % promise
	return event


## 破格担保对账：出事（含跳槽、项目延期）扣担保金，甩锅也甩不掉；干得好老板记你一笔。日结单上单列一行。
static func _settle_vouch(hire: Dictionary, event: Dictionary) -> void:
	if not hire.get("vouched", false):
		return
	var good: bool = event.id == "praise"
	GameState.boss_trust += 1 if good else -1
	if not good:
		GameState.stats.event_fine += GameState.VOUCH_FINE
	GameState.stats.vouch.append({"name": hire.candidate.display_name, "good": good})


## 属性 0–100 折成评分表的 1–5：0–19 是 1，80 以上是 5。
static func true_score(attribute: int) -> int:
	return clampi(1 + attribute / 20, 1, 5)


## 留任期满对账：你改的那一处，比主管原来填的离真实情况近就是“准”，远就是“看走眼”，一样远算“白改”。
## 结果记进 stats.edits，日结单上一行一个，准的发识人奖（GameState.edit_bonus）。
static func settle_edit(hire: Dictionary) -> void:
	var edit: Dictionary = hire.get("hr_edit", {})
	if edit.is_empty():
		return
	var entry := {"name": hire.candidate.display_name, "item": edit.item, "from": int(edit.from), "to": int(edit.to), "truth": 0, "verdict": "blank"}
	var attribute: String = EDIT_TRUTH.get(edit.item, "")
	if attribute != "":
		var truth := true_score(int(hire.candidate.get(attribute, 50)))
		var mine := absi(entry.to - truth)
		var chief := absi(entry.from - truth)
		entry.truth = truth
		entry.verdict = "right" if mine < chief else ("wrong" if mine > chief else "even")
	GameState.stats.edits.append(entry)


static func _empty_headcount() -> Dictionary:
	return {
		"id": "no_hire", "name": "", "fine": 0, "scorecard_full": false, "blame": false,
		"title": "HC 空着",
		"body": "这几天，一个人都没招进来。\n“我养你是让你拒人的吗？”",
	}


## 甩锅：无论选哪条，都很难完全免责。返回老板的回应。
static func resolve_blame(event: Dictionary, choice: String) -> String:
	var fine: int = event.fine
	var reply := ""
	match choice:
		"rule":
			reply = "规则是让你判断的，不是让你不动脑子。"
		"own":
			GameState.boss_trust += 1
			reply = "嗯，敢担责任。钱照扣，但我记住了。" if GameState.fines_on() else "嗯，敢担责任。这次先不扣你钱，我记住了。"
		"scorecard":
			if event.scorecard_full:
				fine = 0
				GameState.boss_promised_rule = true
				reply = "……满分确实是满分。行，那以后加一条规矩。"
			else:
				fine = LIE_FINE if GameState.fines_on() else 0
				GameState.boss_trust -= 1
				reply = "评分表我看了，根本不是满分。还学会撒谎了？"
	GameState.stats.event_fine += fine
	return reply
