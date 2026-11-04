extends Node
## 当前生效规则；对候选人求值，返回是否通过与触发的规则。

var active_rules: Array[Rule] = []
## 简历之外桌上有的材料，以及它们之间会出现的矛盾。
var active_docs := PackedStringArray()
var active_discrepancies: Array[Discrepancy] = []


func set_day(day: int) -> void:
	active_rules.clear()
	active_docs.clear()
	active_discrepancies.clear()
	for d in range(1, day + 1):
		var cfg := load_day(d)
		active_rules.append_array(cfg.new_rules)
		active_docs.append_array(cfg.new_docs)
		active_discrepancies.append_array(cfg.discrepancies)


func load_day(day: int) -> DayConfig:
	return load("res://data/days/day_%02d.tres" % day)


## 往前找最近一次设置的职位描述。
func job_posting(day: int) -> JobPosting:
	for d in range(day, 0, -1):
		var posting := load_day(d).job_posting
		if posting:
			return posting
	return null


## 往前找最近一次设置的工资标准。
func pay(day: int) -> Dictionary:
	for d in range(day, 0, -1):
		var p := load_day(d).pay
		if not p.is_empty():
			return p
	return {}


## 规则只增不减；只要违反一条就应拒绝。
func evaluate(c: Candidate) -> Dictionary:
	var failed: Array[Rule] = []
	for rule in active_rules:
		if rule.applies_to(c) and not rule.check(c):
			failed.append(rule)
	return {"pass": failed.is_empty(), "failed": failed}
