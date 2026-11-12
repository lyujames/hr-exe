extends Node
## 破格章走查：第 1 天走到第 23 天。每天的“被卡住的人”（BlockedTalent）份数对、只卡一条门槛规则、真假属性对得上；
## HC 硬指标那天投那个岗位、规则内的普通人一个都没有。能破格就破格第一个真的，其余按规则判；
## 破格的人单独面时问自评那一行，录用；满期那天日结单有担保奖，面试那天有补贴；拒掉的过两天有回响；月底有破格那一句。
## 用法：Godot --headless --path . res://tests/ExceptionCheck.tscn

var _errors: Array[String] = []
var _seen := {"bonus": 0, "solo": 0, "echo_ps": 0, "fake_note": 0, "push_days": 0, "real": 0, "fake": 0, "fake_tell": 0, "cracked": 0}


func _ready() -> void:
	var root := get_tree().root
	await get_tree().process_frame
	var gs = root.get_node("GameState")
	var re = root.get_node("RuleEngine")
	gs.new_game(4242, 1)
	while true:
		var d: int = gs.day
		var ps: String = gs.blocked_echo_ps()
		if ps != "":
			_seen.echo_ps += 1
			print("  邮件附言：", ps.replace("\n", " / "))
		EmployeeEvents.due_event()
		var mail: Control = load("res://scenes/MailScreen.tscn").instantiate()
		root.add_child(mail)
		await _frames(2)
		mail.queue_free()
		var pile: Array = CandidateGenerator.generate_day(gs.config, re.active_rules, gs.day_seed())
		var push: String = gs.config.hc_push.get("posting", "")
		var blocked := pile.filter(func(c: Candidate) -> bool: return c.blocked != "")
		var want := BlockedTalent.count_for(gs.config)
		if blocked.size() != want:
			_errors.append("第 %d 天被卡住的人 %d 份，应为 %d" % [d, blocked.size(), want])
		var desc := []
		for c: Candidate in blocked:
			var r: Dictionary = re.evaluate(c)
			_seen[c.blocked] += 1
			if "未附" in c.attachment or "打不开" in c.attachment or "私有" in c.attachment or "下架" in c.attachment or "丢了" in c.attachment or "老家" in c.attachment or "登不上" in c.attachment or "不方便" in c.attachment:
				_seen.fake_tell += 1
				if c.blocked == "real":
					_errors.append("第 %d 天真的那份附件露馅了：%s" % [d, c.attachment])
			if r.failed.size() != 1 and d != gs.LAST_DAY:
				_errors.append("第 %d 天 %s 卡了 %d 条" % [d, c.display_name, r.failed.size()])
			elif not BlockedTalent.credential(r.failed[0]):
				print("  （第 %d 天 %s 卡的不是门槛规则：%s）" % [d, c.display_name, r.failed[0].title_key])
			if push != "" and c.applied_position != push:
				_errors.append("第 %d 天 HC 硬指标那天，被卡住的人投的是 %s" % [d, c.applied_position])
			var fate := EmployeeEvents.fate(c)
			if (c.blocked == "real") != (fate == "praise"):
				_errors.append("第 %d 天 %s（%s）结局是 %s" % [d, c.display_name, c.blocked, fate])
			if c.blocked == "fake" and c.crack_lines.size() != 2:
				_errors.append("第 %d 天吹的 %s 没有两句说漏嘴" % [d, c.display_name])
			desc.append("%s%s[%s]" % [c.display_name, "真" if c.blocked == "real" else "假", r.failed[0].title_key if not r.failed.is_empty() else "合规"])
		if push != "":
			_seen.push_days += 1
			var fits := pile.filter(func(c: Candidate) -> bool: return not c.is_story and c.blocked == "" and c.applied_position == push and re.evaluate(c).pass)
			if not fits.is_empty():
				_errors.append("第 %d 天 HC 硬指标 %s，规则内还有 %d 个普通人" % [d, push, fits.size()])
		# 能破格就破格第一个真的，其余照规则判
		var vouched := ""
		for c: Candidate in pile:
			if c.blocked == ("fake" if d % 3 == 0 else "real") and vouched == "" and gs.can_vouch():
				var folder: JobPosting = null
				if RuleEngine.folder_mode:
					for p: JobPosting in RuleEngine.active_postings:
						if p.team != "" and not gs.folder_full(p):
							folder = p
							break
				gs.record_exception(c, folder)
				vouched = c.display_name
				continue
			var r: Dictionary = re.evaluate(c)
			var verdict := "pass" if r.pass else "reject"
			var folder: JobPosting = null
			if r.pass and RuleEngine.folder_mode:
				var fitting: Array = RuleEngine.fitting_folders(c).filter(func(p: JobPosting) -> bool: return not gs.folder_full(p))
				if fitting.is_empty():
					verdict = "reject"
				else:
					folder = fitting[0]
			gs.record_decision(c, verdict, r.failed[0].id if not r.pass else &"", Desk.GENERIC_REASON if verdict == "reject" else "", {}, folder)
		var solo := ""
		if gs.next_vouched():
			var room: InterviewRoom = load("res://scenes/InterviewRoom.tscn").instantiate()
			root.add_child(room)
			await _frames(3)
			if not room.solo:
				_errors.append("第 %d 天破格那场不是单独面" % d)
			var cand: Candidate = room.candidate
			solo = cand.display_name
			if cand.blocked != "":
				for line: Dictionary in ResumeQuestions.lines(cand):
					if line.key == "self_eval":
						room.ask_line(line)
						await _frames(1)
						# 追问一次只能接着上一问；问穿要追两次：自评追一次，再换一行问、再追一次
						room.follow_up()
						await _frames(1)
						if cand.blocked == "fake":
							for other: Dictionary in ResumeQuestions.lines(cand):
								if other.kind != "" and other.key != "self_eval":
									room.ask_line(other)
									await _frames(1)
									room.follow_up()
									await _frames(1)
									break
							if String(cand.id) in gs.exposed:
								_seen.cracked += 1
							else:
								_errors.append("第 %d 天吹的 %s 追问两次没问穿" % [d, cand.display_name])
						break
			room._show_scorecard()
			await _frames(1)
			room.decide(cand.blocked != "fake")
			room.queue_free()
			await _frames(1)
		var report: DayReport = load("res://scenes/DayReport.tscn").instantiate()
		root.add_child(report)
		await _frames(2)
		if gs.vouch_bonus() > 0:
			_seen.bonus += 1
		if gs.solo_pay() > 0:
			_seen.solo += 1
		if not gs.blocked_echoes("fake").is_empty():
			_seen.fake_note += 1
		var push_note := ""
		if push != "":
			push_note = " HC[%s 放了 %d 扣 %d]" % [push, gs.hc_push_placed(), gs.hc_push_fine()]
		print("第 %2d 天 卡住的 %s 破格 %s 单独面 %s 担保奖 %d 补贴 %d%s 存款 %d 信任 %d" % [d, desc, vouched if vouched != "" else "-", solo if solo != "" else "-", gs.vouch_bonus(), gs.solo_pay(), push_note, gs.savings, gs.boss_trust])
		report.confirm()
		report.queue_free()
		await _frames(1)
		gs.store_paper()
		if gs.is_month_end():
			var se := SliceEnd.new()
			se._month = gs.month()
			for n: String in se._exception_notes():
				print("  月底：", n)
			se.free()
		if gs.is_bankrupt():
			gs.savings += 2000
		if gs.day >= gs.LAST_DAY:
			break
		gs.advance_day()
	print("SEEN: ", _seen)
	for key in ["bonus", "solo", "echo_ps", "fake_note", "push_days", "real", "fake", "cracked"]:
		if int(_seen[key]) == 0:
			_errors.append("一次都没见到：%s" % key)
	print("ERRORS: ", _errors.size())
	for e in _errors:
		print("  ", e)
	print("EXCEPTION CHECK DONE")
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
