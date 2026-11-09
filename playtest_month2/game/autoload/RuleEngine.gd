extends Node
## 当前生效规则；对候选人求值，返回是否通过与触发的规则。

var active_rules: Array[Rule] = []
## 简历之外桌上有的材料，以及它们之间会出现的矛盾。
var active_docs := PackedStringArray()
var active_discrepancies: Array[Discrepancy] = []
## 到今天为止开着的岗位，按开的先后排。
var active_postings: Array[JobPosting] = []


func set_day(day: int) -> void:
	active_rules.clear()
	active_docs.clear()
	active_discrepancies.clear()
	active_postings.clear()
	for d in range(1, day + 1):
		var cfg := load_day(d)
		if not cfg.retire.is_empty():
			_retire(cfg.retire)
		for posting in cfg.new_postings:
			_open_posting(posting)
		active_rules.append_array(cfg.new_rules)
		active_docs.append_array(cfg.new_docs)
		active_discrepancies.append_array(cfg.discrepancies)


## 收起来的规则、矛盾和岗位不再生效（规则手册上也不再有）。
func _retire(ids: PackedStringArray) -> void:
	active_rules = active_rules.filter(func(r: Rule) -> bool: return String(r.id) not in ids)
	active_discrepancies = active_discrepancies.filter(func(d: Discrepancy) -> bool: return String(d.id) not in ids)
	active_postings = active_postings.filter(func(p: JobPosting) -> bool: return p.title not in ids)


## 同名岗位再开一次就是 JD 改版：替换原来那页，位置不变。
func _open_posting(posting: JobPosting) -> void:
	for i in active_postings.size():
		if active_postings[i].title == posting.title:
			active_postings[i] = posting
			return
	active_postings.append(posting)


func load_day(day: int) -> DayConfig:
	return load("res://data/days/day_%02d.tres" % day)


## 简历上“应聘”的那个岗位；对不上任何一个开着的岗位时返回 null。
func posting_for(title: String) -> JobPosting:
	for posting in active_postings:
		if posting.title == title:
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
