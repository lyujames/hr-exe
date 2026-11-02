extends Node
## 当前生效规则；对候选人求值，返回是否通过与触发的规则。

var active_rules: Array[Rule] = []


func set_day(day: int) -> void:
	active_rules.clear()
	for d in range(1, day + 1):
		active_rules.append_array(load_day(d).new_rules)


func load_day(day: int) -> DayConfig:
	return load("res://data/days/day_%02d.tres" % day)


## 手册里看得到的规则；新闻和法务发布的不在其中。
func handbook_rules() -> Array[Rule]:
	return active_rules.filter(func(rule: Rule) -> bool: return not rule.unlisted)


## 截至今天发过的法务通知，从旧到新。
func notices_until(day: int) -> PackedStringArray:
	var notices := PackedStringArray()
	for d in range(1, day + 1):
		notices.append_array(load_day(d).legal_notices)
	return notices


## 规则只增不减；只要违反一条就应拒绝。
func evaluate(c: Candidate) -> Dictionary:
	var failed: Array[Rule] = []
	for rule in active_rules:
		if not rule.check(c):
			failed.append(rule)
	return {"pass": failed.is_empty(), "failed": failed}
