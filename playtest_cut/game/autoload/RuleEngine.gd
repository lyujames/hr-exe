extends Node
## 当前生效规则；对候选人求值，返回是否通过与触发的规则。

var active_rules: Array[Rule] = []
## 简历之外桌上有的材料，以及它们之间会出现的矛盾。
var active_docs := PackedStringArray()
var active_discrepancies: Array[Discrepancy] = []
## 到今天为止开着的岗位，按开的先后排。
var active_postings: Array[JobPosting] = []
## 这一天是不是按组分文件夹（DayConfig.team_folders）。
var folder_mode := false


func set_day(day: int) -> void:
	active_rules.clear()
	active_docs.clear()
	active_discrepancies.clear()
	active_postings.clear()
	folder_mode = load_day(day).team_folders if day > 0 else false
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


## 今天桌上的文件夹：开着的、有组名的岗位。不是按组招的日子为空。
func folders() -> Array[JobPosting]:
	if not folder_mode:
		return []
	return active_postings.filter(func(p: JobPosting) -> bool: return p.team != "")


## 这个组的必备技能齐不齐（一字不差），技能写没写超（堆砌）。
func skills_fit(c: Candidate, p: JobPosting, max_skills := 8) -> bool:
	if c.skills.size() > max_skills:
		return false
	for keyword in p.keywords:
		if keyword not in c.skills:
			return false
	return true


## 放进这个组哪里不行；能放返回空串。
func folder_problem(c: Candidate, p: JobPosting) -> String:
	if c.skills.size() > 8:
		return "技能超过 8 项，算堆砌"
	var missing := Array(p.keywords).filter(func(k: String) -> bool: return k not in c.skills)
	if not missing.is_empty():
		return "%s要 %s，简历上没有" % [p.team, "、".join(PackedStringArray(missing))]
	if c.salary_k > p.salary_cap_k:
		return "期望 %dk，%s上限 %dk" % [c.salary_k, p.team, p.salary_cap_k]
	return ""


## 技能和薪资都对得上的组（不管满没满）。
func fitting_folders(c: Candidate) -> Array[JobPosting]:
	return folders().filter(func(p: JobPosting) -> bool: return folder_problem(c, p) == "")


## 按标题找岗位：开着的先找，找不到再往前翻每天新开的（组撤了，前一天放进去的人今天照样由那个组长面）。
func find_posting(title: String) -> JobPosting:
	var open := posting_for(title)
	if open:
		return open
	for d in range(GameState.day, 0, -1):
		for posting in load_day(d).new_postings:
			if posting.title == title:
				return posting
	return null
