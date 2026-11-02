extends Node
## 无界面逻辑测试：godot --headless --path . res://tests/RunTests.tscn

var failures := 0


func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: ", message)


func _ready() -> void:
	test_rule_boundaries()
	test_generator()
	test_economy()
	test_events()
	test_save_roundtrip()
	await test_scene_branches()
	await test_interview()
	print("TESTS DONE, failures=", failures)
	get_tree().quit(failures)


func _candidate() -> Candidate:
	var c := Candidate.new()
	c.birth_date = "1995-01-01"
	c.degree = Candidate.Degree.BACHELOR
	c.salary_k = 80
	c.bonus_pct = 0
	c.performance = 50
	c.jobs = [{"company": "a", "title": "b", "start": "2020-01", "end": ""}]
	return c


func test_rule_boundaries() -> void:
	GameState.new_game(1)
	GameState.day = 3
	GameState.begin_day()
	check(GameState.today == "2026-03-04", "day 3 date")
	check(RuleEngine.active_rules.size() == 6, "six rules on day 3")
	check(RuleEngine.handbook_rules().size() == 5, "visa policy stays out of the handbook")
	var c := _candidate()
	check(RuleEngine.evaluate(c).pass, "clean candidate passes")
	c.birth_date = "1990-06-01"  # 2012 届，刚好 14 年
	check(c.graduation_year() == 2012 and RuleEngine.evaluate(c).pass, "14 years since graduation passes")
	c.birth_date = "1989-06-01"
	check(not RuleEngine.evaluate(c).pass, "15 years since graduation fails")
	c = _candidate()
	c.salary_k = 100
	c.bonus_pct = 10
	check(c.annual_salary() == 110000 and RuleEngine.evaluate(c).pass, "exact budget passes")
	c.bonus_pct = 15
	check(not RuleEngine.evaluate(c).pass, "over budget fails")
	c = _candidate()
	c.jobs = [{"company": "a", "title": "b", "start": "2020-01", "end": "2025-09"}]
	check(c.max_gap_months(GameState.today) == 6, "gap counts to today")
	check(RuleEngine.evaluate(c).pass, "six-month gap passes")
	c.jobs[0].end = "2025-08"
	check(not RuleEngine.evaluate(c).pass, "seven-month gap fails")
	c = _candidate()
	c.jobs = [
		{"company": "a", "title": "b", "start": "2024-02", "end": ""},
		{"company": "a", "title": "b", "start": "2020-01", "end": "2023-07"},
	]
	check(c.max_gap_months(GameState.today) == 7, "inner gap counted")
	c = _candidate()
	c.degree = Candidate.Degree.COLLEGE
	check(RuleEngine.evaluate(c).failed.size() == 1, "degree failure reports rule")
	test_work_status()


func _status(status: String, nationality: String, expiry: String) -> Candidate:
	var c := _candidate()
	c.work_status = status
	c.nationality = nationality
	c.status_expiry = expiry
	return c


func test_work_status() -> void:
	check(RuleEngine.evaluate(_status("TN", "Canada", "2026-03-04")).pass, "status valid on expiry day")
	check(not RuleEngine.evaluate(_status("TN", "Canada", "2026-03-03")).pass, "expired yesterday fails")
	check(not RuleEngine.evaluate(_status("TN", "India", "2027-01-01")).pass, "TN needs a treaty nationality")
	check(not RuleEngine.evaluate(_status("H-1B", "India", "2027-01-01")).pass, "H-1B blocked after the news")
	check(RuleEngine.evaluate(_status("F-1 OPT", "India", "2026-04-03")).pass, "OPT with exactly 30 days passes")
	check(not RuleEngine.evaluate(_status("F-1 OPT", "India", "2026-04-02")).pass, "OPT with 29 days fails")
	check(RuleEngine.evaluate(_status("Permanent Resident", "India", "")).pass, "green card passes")
	GameState.day = 2
	GameState.begin_day()
	check(RuleEngine.evaluate(_status("H-1B", "India", "2027-01-01")).pass, "H-1B fine before the fee")
	GameState.day = 3
	GameState.begin_day()
	check(RuleEngine.notices_until(1).is_empty() and RuleEngine.notices_until(3).size() == 2, "notices accumulate")


func test_generator() -> void:
	var total := 0
	var by_pool := {}
	var rejected := 0
	var edge := 0
	for game_seed in range(1, 40):
		GameState.new_game(game_seed)
		for day in range(1, 4):
			GameState.day = day
			GameState.begin_day()
			var batch := CandidateGenerator.generate_day(GameState.config, RuleEngine.active_rules, GameState.day_seed())
			check(batch.size() == GameState.config.resume_count + GameState.config.story_candidates.size(), "batch size")
			for c in batch:
				total += 1
				var result := RuleEngine.evaluate(c)
				if not c.is_story:
					_tally_name(by_pool, c, result.pass)
				if c.is_story:
					check(result.pass, "story candidate satisfies every rule")
				else:
					rejected += 0 if result.pass else 1
					edge += 1 if _is_edge(c) else 0
				check(not c.jobs.is_empty(), "has jobs")
				for i in c.jobs.size():
					check(c.jobs[i].start < (c.jobs[i].end if c.jobs[i].end != "" else "9999"), "job order")
	check(by_pool.size() == CandidateGenerator.NAME_POOLS.size(), "every name pool appears")
	for key: int in by_pool:
		var pool: Dictionary = by_pool[key]
		check(absf(float(pool.citizens) / pool.total - 0.5) < 0.2, "names don't predict citizenship: %s" % pool)
		check(absf(float(pool.passed) / pool.total - 0.55) < 0.2, "names don't predict the verdict: %s" % pool)
	var reject_rate := float(rejected) / total
	print("reject_rate=", reject_rate, " edge_rate=", float(edge) / total)
	check(reject_rate > 0.3 and reject_rate < 0.6, "reject rate in range")
	var slice_total: int = 8 + 10 + 12 + 1
	check(slice_total == 31, "about 30 resumes plus story")


func _tally_name(by_pool: Dictionary, c: Candidate, passed: bool) -> void:
	var surname := c.display_name.get_slice(" ", 1)
	for i in CandidateGenerator.NAME_POOLS.size():
		if surname in CandidateGenerator.NAME_POOLS[i].surnames:
			var pool: Dictionary = by_pool.get_or_add(i, {"total": 0, "citizens": 0, "passed": 0})
			pool.total += 1
			pool.citizens += 1 if c.work_status == Candidate.STATUS_CITIZEN else 0
			pool.passed += 1 if passed else 0
			return
	check(false, "surname not in any pool: " + c.display_name)


func _is_edge(c: Candidate) -> bool:
	if c.degree_note != "":
		return true
	if absi(c.annual_salary() - 110000) < 3000:
		return true
	return GameState.day >= 3 and absi(2026 - c.graduation_year() - 14) <= 1


func test_economy() -> void:
	GameState.new_game(5)
	var good := _candidate()
	var bad := _candidate()
	bad.degree = Candidate.Degree.COLLEGE
	for i in 3:
		GameState.record_decision(bad, "pass", &"", "")  # 3 次违规：2 警告 + 1 罚款
	GameState.record_decision(good, "pass", &"", "")
	check(GameState.stats.wrong == 3, "three violations")
	check(GameState.fines() == 25, "first two are warnings")
	check(GameState.income() == 150 + 8 - 25, "income")
	check(GameState.conscience == 0, "degree is not absurd")
	var before := GameState.savings
	GameState.settle([])
	check(GameState.savings == before + 133 - 90, "unpaid bill not charged")
	check(GameState.family_state == -1, "unpaid bill hurts family")

	GameState.new_game(6)
	GameState.day = 3
	GameState.begin_day()
	var old := _candidate()
	old.birth_date = "1980-01-01"
	GameState.record_decision(old, "pass", &"", "")
	check(GameState.conscience == 1, "letting an absurd-rule victim through raises conscience")
	check(GameState.decision_log[0].violated_rule, "log marks violation")
	GameState.record_decision(old, "reject", &"rule_culture_fit", "We're looking for someone with more energy.")
	check(GameState.decision_log[1].reason_text == "We're looking for someone with more energy.", "reason kept verbatim")

	GameState.new_game(13)
	GameState.lawsuit_risk = 2
	check(GameState.legal_fine() == 150, "settlement due at the limit")
	var saved := GameState.savings
	GameState.settle([])
	check(GameState.savings == saved + 150 - 150 - 90, "settlement charged")
	check(GameState.legal_fine() == 0, "settlement charged once")


func test_events() -> void:
	var perfect: Candidate = load("res://data/story/candidate_perfect.tres")
	var full := {"Culture Fit": 5, "Grit": 5, "Presence": 5, "Vibe": 5}
	GameState.new_game(7)
	GameState.add_hire(perfect, full)
	check(EmployeeEvents.due_event().is_empty(), "no event before day 3")
	GameState.day = 3
	GameState.begin_day()
	var event := EmployeeEvents.due_event()
	check(event.id == "embezzle", "story override fires")
	check(EmployeeEvents.due_event().id == "no_hire" or GameState.hires[0].event_resolved, "event resolved once")
	EmployeeEvents.resolve_blame(event, "scorecard")
	check(GameState.stats.event_fine == 0, "full scorecard avoids fine")
	check(GameState.boss_promised_rule, "but boss adds a rule")

	GameState.new_game(8)
	GameState.add_hire(perfect, {"Culture Fit": 5, "Grit": 3, "Presence": 5, "Vibe": 5})
	GameState.day = 3
	GameState.begin_day()
	event = EmployeeEvents.due_event()
	EmployeeEvents.resolve_blame(event, "scorecard")
	check(GameState.stats.event_fine == EmployeeEvents.LIE_FINE, "lying is punished")

	GameState.new_game(9)
	GameState.add_hire(perfect, full)
	GameState.day = 3
	GameState.begin_day()
	EmployeeEvents.resolve_blame(EmployeeEvents.due_event(), "own")
	check(GameState.boss_trust == 1 and GameState.stats.event_fine == 100, "owning it costs money, earns trust")

	GameState.new_game(10)
	GameState.day = 3
	GameState.begin_day()
	check(EmployeeEvents.due_event().id == "no_hire", "no hires triggers headcount event")

	for attrs: Array in [[30, 80, 80, "delay"], [80, 20, 80, "jump"], [80, 80, 20, "burnout"], [80, 80, 80, "praise"]]:
		GameState.new_game(11)
		var c := _candidate()
		c.ability = attrs[0]
		c.loyalty = attrs[1]
		c.pressure = attrs[2]
		GameState.add_hire(c, {"Grit": 3})
		GameState.day = 3
		GameState.begin_day()
		check(EmployeeEvents.due_event().id == attrs[3], "event for " + str(attrs))


func _main(day: int) -> Control:
	GameState.new_game(20 + day)
	GameState.day = day
	GameState.begin_day()
	var main: Control = load("res://scenes/Main.tscn").instantiate()
	add_child(main)
	return main


func test_scene_branches() -> void:
	# 超时下班：未处理的简历不计件
	var main := _main(1)
	main.show_desk()
	var desk: Desk = main.current
	await get_tree().process_frame
	desk.elapsed = 9999.0
	await get_tree().process_frame
	await get_tree().process_frame
	check(desk.closing, "day closes on timeout")
	check(GameState.stats.unprocessed == 9, "all nine resumes unprocessed")
	check(GameState.stats.processed == 0, "nothing processed")

	# 超时时拒绝理由还开着：等选完再下班，这份不丢
	main.queue_free()
	main = _main(1)
	main.show_desk()
	desk = main.current
	await get_tree().process_frame
	desk.doc.stamp("reject", Vector2(100, 100))
	desk.elapsed = 9999.0
	await get_tree().process_frame
	await get_tree().process_frame
	check(GameState.stats.processed == 0, "picker holds the day open")
	desk.commit("reject", &"generic", Desk.GENERIC_REASON)
	check(GameState.stats.processed == 1, "open decision still recorded")
	check(GameState.stats.unprocessed == 8, "rest unprocessed")

	# 法务通知不主动弹出，第 1 天没有
	main.queue_free()
	main = _main(1)
	main.show_desk()
	await get_tree().process_frame
	check(_button(main.current, "Legal +1") == null, "no notices on day 1")
	main.queue_free()
	main = _main(2)
	main.show_desk()
	await get_tree().process_frame
	check(not main.current._notices.visible, "notices stay closed until opened")
	check(_button(main.current, "Legal +1").size.x <= 92.0, "tray button fits")
	_button(main.current, "Legal +1").pressed.emit()
	check(main.current._notices.visible, "tray opens")

	# 全部拒绝：没有可面试的人，直接日结
	main.queue_free()
	main = _main(1)
	main.show_interview()
	check(main.current is DayReport, "no passes skips interview")

	# 不付账单与破产
	main.queue_free()
	main = _main(2)
	GameState.savings = 100
	main.show_report()
	var report: DayReport = main.current
	await get_tree().process_frame
	GameState.stats.event_fine = 600
	report._toggle_bill(false, "student_loan")
	check(report.paid_ids().is_empty(), "bill can be unpaid")
	report.confirm()
	await get_tree().process_frame
	check(GameState.is_bankrupt(), "negative savings is bankrupt")
	check(main.current.has_method("_ready") and main.current.name.begins_with("Newspaper"), "news after report")
	main.next_day()
	await get_tree().process_frame
	check(main.current is SliceEnd, "bankruptcy ends the run early")

	# 存档 → 继续：JSON 读回后第 3 天事件仍能结算
	main.queue_free()
	main = _main(1)
	GameState.add_hire(load("res://data/story/candidate_perfect.tres"), {"Culture Fit": 5, "Grit": 5, "Presence": 5, "Vibe": 5})
	GameState.day = 2
	main.next_day()
	check(GameState.day == 3, "advance to day 3")
	check(SaveManager.has_save(), "autosaved")
	await get_tree().process_frame
	GameState.new_game(1)
	check(SaveManager.load_game(), "reload")
	main._after_mail()
	await get_tree().process_frame
	check(main.current is BossOffice, "event fires after reload")
	check(main.current.event.scorecard_full, "scorecard survives JSON")
	main.queue_free()
	SaveManager.clear()


func _room(day: int, c: Candidate) -> InterviewRoom:
	GameState.new_game(30 + day)
	GameState.day = day
	GameState.begin_day()
	GameState.passed_today.append(c)
	var room: InterviewRoom = load("res://scenes/InterviewRoom.tscn").instantiate()
	add_child(room)
	return room


func _card(room: InterviewRoom, id: StringName) -> QuestionCard:
	for card in room.cards:
		if card.id == id:
			return card
	return null


func _button(node: Node, text: String) -> Button:
	if node is Button and node.text == text and not node.is_queued_for_deletion():
		return node
	for child in node.get_children():
		var found := _button(child, text)
		if found:
			return found
	return null


func _ask_until_candidate(room: InterviewRoom) -> void:
	room.ask(_card(room, &"q_overtime"))
	room.ask(_card(room, &"q_weakness"))
	room.ask(_card(room, &"q_salary"))
	room.chief_ask()


func test_interview() -> void:
	for path in InterviewRoom.QUESTION_PATHS:
		var card: QuestionCard = load("res://data/questions/%s.tres" % path)
		check(card.always_truthful or card.chief_item in InterviewRoom.SCORE_ITEMS, "chief item valid: " + path)
		check(card.chief_honest != "", "chief reaction: " + path)
		check(card.concept != &"" and card.bare_text != "", "concept: " + path)
	for day in range(1, 4):
		var config := RuleEngine.load_day(day)
		check(config.chief_opener != "" and config.chief_question != null and config.candidate_ask != null, "chief data day %d" % day)

	# 表演者加分、说实话减分；上限 5；Tyler 不占名额
	var performer := _candidate()
	performer.performance = 90
	var room := _room(1, performer)
	room.ask(_card(room, &"q_overtime"))
	check(room.scorecard["Grit"] == 4, "standard answer raises score")
	check(_button(room, "Let Tyler ask") == null, "player gets all three cards first")
	room.scorecard["Grit"] = 5
	room.ask(_card(room, &"q_equity"))
	check(room.scorecard["Grit"] == 5, "score capped")
	room.ask(_card(room, &"q_salary"))
	check(_button(room, "Let Tyler ask") != null, "Tyler cuts in after the third card")
	room.chief_ask()
	check(room.asked == 3, "Tyler uses no card slot")
	check(GameState.lawsuit_risk == 0, "ordinary chief question is legal")
	room.queue_free()

	var honest := _candidate()
	honest.performance = 10
	honest.honesty = 80
	room = _room(1, honest)
	room.ask(_card(room, &"q_weakness"))
	check(room.scorecard["Presence"] == 2, "honest answer lowers score")
	room.queue_free()

	# 现场测试只说话不打分
	room = _room(1, honest)
	var before := room.scorecard.duplicate()
	room.ask(_card(room, &"q_test"))
	check(room.scorecard == before, "test card leaves scorecard alone")
	room.queue_free()

	# 违法提问累积诉讼风险
	room = _room(3, performer)
	room.ask(_card(room, &"q_kids"))
	check(GameState.lawsuit_risk == 1 and GameState.stats.legal_flags.size() == 1, "player's risky card adds risk")
	room.ask(_card(room, &"q_overtime"))
	room.ask(_card(room, &"q_weakness"))
	room.chief_ask()
	check(GameState.lawsuit_risk == 2, "Tyler's risky question lands on HR too")
	check(GameState.legal_fine() == 150, "one card plus Tyler triggers settlement")
	room.queue_free()

	# Culture fit：表演低，满分也被否决；硬顶要拿信任换
	var quiet := _candidate()
	quiet.performance = 20
	room = _room(1, quiet)
	_ask_until_candidate(room)
	room.answer_candidate("safe")
	for item in InterviewRoom.SCORE_ITEMS:
		room.scorecard[item] = 5
	room.decide(true)
	check(GameState.hires.is_empty() and _button(room, "“Understood.”") != null, "veto stops the hire")
	room.overrule_veto()
	check(GameState.hires.size() == 1 and GameState.boss_trust == -1, "overruling hires at a trust cost")
	room.queue_free()

	# 话术：录用后忠诚下降，共享资源不被改，跳槽时原话回来
	var loyal := _candidate()
	loyal.ability = 80
	loyal.loyalty = 50
	loyal.pressure = 80
	room = _room(1, loyal)
	_ask_until_candidate(room)
	room.answer_candidate("lie")
	room.decide(true)
	var ask: CandidateAsk = GameState.config.candidate_ask
	check(GameState.hires[0].candidate.loyalty == 25, "lie costs loyalty")
	check(loyal.loyalty == 50, "resource untouched")
	check(GameState.reply_log[0].answer == ask.lie, "reply kept verbatim")
	GameState.day = 3
	GameState.begin_day()
	var event := EmployeeEvents.due_event()
	check(event.id == "jump" and ask.lie in event.body, "lie returns at exit")
	room.queue_free()

	room = _room(1, loyal)
	_ask_until_candidate(room)
	room.answer_candidate("safe")
	room.decide(true)
	check(GameState.hires[0].candidate.loyalty == 40 and GameState.hires[0].promise == "", "safe answer costs less, promises nothing")
	room.queue_free()

	# 实话：能人走，主管记一笔；没退路的留下
	room = _room(1, loyal)
	_ask_until_candidate(room)
	room.answer_candidate("truth")
	check(GameState.boss_trust == -1, "truth costs trust")
	check(_button(room, "Hire") == null and _button(room, "See them out") != null, "able candidate walks out")
	room.queue_free()

	var stuck := _candidate()
	stuck.ability = 30
	room = _room(1, stuck)
	_ask_until_candidate(room)
	room.answer_candidate("truth")
	check(_button(room, "Hire") != null, "candidate without options stays")
	await get_tree().process_frame
	room.queue_free()


func test_save_roundtrip() -> void:
	GameState.new_game(12)
	GameState.lawsuit_risk = 2
	GameState.reply_log = [{"answer": "x"}]
	GameState.savings = 123
	GameState.conscience = 2
	var perfect: Candidate = load("res://data/story/candidate_perfect.tres")
	GameState.add_hire(perfect, {"Grit": 5})
	GameState.record_decision(_candidate(), "pass", &"", "")
	GameState.day = 2
	SaveManager.save_game()
	GameState.new_game(99)
	check(SaveManager.load_game(), "load")
	check(GameState.day == 2 and GameState.savings == 123 and GameState.conscience == 2, "scalars restored")
	check(GameState.decision_log.size() == 1, "log restored")
	check(GameState.lawsuit_risk == 2 and GameState.reply_log.size() == 1, "interview state restored")
	var old_save := GameState.to_dict()
	old_save.erase("lawsuit_risk")
	old_save.erase("reply_log")
	old_save.erase("lawsuit_settled")
	GameState.load_dict(old_save)
	check(GameState.lawsuit_risk == 0 and GameState.reply_log.is_empty(), "old saves still load")
	var restored := Candidate.from_dict(GameState.hires[0].candidate)
	check(restored.display_name == "Chase Sterling" and restored.event_override == &"embezzle", "hire restored")
	check(restored.skills.size() == 4, "skills restored")
	SaveManager.clear()
	check(not SaveManager.has_save(), "cleared")
