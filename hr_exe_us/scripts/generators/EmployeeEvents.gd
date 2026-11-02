class_name EmployeeEvents
## 延迟反馈：录用的后果不在当天出现，由隐藏属性决定几天后发生什么。
## 垂直切片只有 3 天，把设计中的 3–7 天压缩为第 3 天早上结算最早的一位录用者。

const BLAME_FINE := 100
const HC_FINE := 50
const LIE_FINE := 150


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
			event.title = "%s is gone" % c.display_name
			event.body = "%s went dark on day two, along with the project petty cash.\n“You interviewed them. You signed off. Who eats this?”" % c.display_name
		"delay":
			event.title = "Project slipped"
			event.body = "%s pushed the launch back a week.\n“This is who you picked?”" % c.display_name
		"jump":
			event.title = "Quit in week one"
			event.body = "%s took a competitor's offer and didn't show up today.\n“Who pays the recruiting cost?”" % c.display_name
		"burnout":
			event.title = "Burned out"
			event.body = "%s pulled three all-nighters, cried at their desk, and resigned.\n“No grit? How did you screen for this?”" % c.display_name
		"praise":
			event.title = "Big win"
			event.body = "All-hands email: under Brad's visionary leadership, we shipped early.\nShoutout to %s. Also, thanks to HR, I guess." % c.display_name
			event.fine = 0
			event.blame = false
	var promise: String = hire.get("promise", "")
	if promise != "" and kind in ["jump", "burnout"]:
		event.body += "\nExit interview: “In my interview, HR said: %s”" % promise
	return event


static func _empty_headcount() -> Dictionary:
	return {
		"id": "no_hire", "name": "", "fine": HC_FINE, "scorecard_full": false, "blame": false,
		"title": "Headcount still open",
		"body": "Three days, zero hires.\n“Am I paying you to say no? The recruiting cost is on you.”",
	}


## 甩锅：无论选哪条，都很难完全免责。返回老板的回应。
static func resolve_blame(event: Dictionary, choice: String) -> String:
	var fine: int = event.fine
	var reply := ""
	match choice:
		"rule":
			reply = "The rules are there to guide your judgment, not replace it."
		"own":
			GameState.boss_trust += 1
			reply = "Love the ownership. Still docking you, but I noticed."
		"scorecard":
			if event.scorecard_full:
				fine = 0
				GameState.boss_promised_rule = true
				reply = "...It really is a perfect score. Fine. New policy, then."
			else:
				fine = LIE_FINE
				GameState.boss_trust -= 1
				reply = "I checked. That scorecard isn't perfect. Are you lying to me?"
	GameState.stats.event_fine += fine
	return reply
