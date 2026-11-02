class_name EmployeeEvents
## 延迟反馈：录用的后果不在当天出现，由隐藏属性决定几天后发生什么。
## 垂直切片只有 3 天，把设计中的 3–7 天压缩为第 3 天早上结算最早的一位录用者。

const BLAME_FINE := 200
const HC_FINE := 100
const LIE_FINE := 300


static func due_event() -> Dictionary:
	if not GameState.config.fires_employee_event:
		return {}
	for hire: Dictionary in GameState.hires:
		if not hire.event_resolved:
			hire.event_resolved = true
			return _for_hire(hire)
	return _empty_headcount()


static func _for_hire(hire: Dictionary) -> Dictionary:
	var c := Candidate.from_dict(hire.candidate)
	var kind := String(c.event_override)
	if kind == "":
		if c.ability < 40:
			kind = "delay"
		elif c.loyalty < 35:
			kind = "jump"
		elif c.pressure < 35:
			kind = "burnout"
		else:
			kind = "praise"
	var scorecard_full: bool = hire.scorecard.values().all(func(v: Variant) -> bool: return int(v) == 5)
	var event := {"id": kind, "name": c.display_name, "fine": BLAME_FINE, "scorecard_full": scorecard_full, "blame": true}
	match kind:
		"embezzle":
			event.title = "%s 不见了" % c.display_name
			event.body = "你录用的 %s 入职第二天，带着项目备用金失联了。\n“你面试的，你签的字。这钱算谁的？”" % c.display_name
		"delay":
			event.title = "项目延期"
			event.body = "你录用的 %s 把排期拖了一周。\n“这就是你挑的人？”" % c.display_name
		"jump":
			event.title = "试用期跳槽"
			event.body = "你录用的 %s 拿了竞对的 offer，今早直接没来。\n“招聘成本谁出？”" % c.display_name
		"burnout":
			event.title = "加班后离职"
			event.body = "%s 连续加了三天班，在工位上哭了，然后辞职了。\n“抗压都不行，你怎么面的？”" % c.display_name
		"praise":
			event.title = "项目大捷"
			event.body = "全员邮件：在王总的英明领导下，项目提前上线。\n其中 %s 贡献突出。顺便感谢 HR 同事。" % c.display_name
			event.fine = 0
			event.blame = false
	var promise: String = hire.get("promise", "")
	if promise != "" and kind in ["jump", "burnout"]:
		event.body += "\n离职记录：“面试时 HR 说：%s”" % promise
	return event


static func _empty_headcount() -> Dictionary:
	return {
		"id": "no_hire", "name": "", "fine": HC_FINE, "scorecard_full": false, "blame": false,
		"title": "HC 空着",
		"body": "三天了，一个人都没招进来。\n“我养你是让你拒人的吗？这个月的招聘成本你来背。”",
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
			reply = "嗯，敢担责任。钱照扣，但我记住了。"
		"scorecard":
			if event.scorecard_full:
				fine = 0
				GameState.boss_promised_rule = true
				reply = "……满分确实是满分。行，那以后加一条规矩。"
			else:
				fine = LIE_FINE
				GameState.boss_trust -= 1
				reply = "评分表我看了，根本不是满分。还学会撒谎了？"
	GameState.stats.event_fine += fine
	return reply
