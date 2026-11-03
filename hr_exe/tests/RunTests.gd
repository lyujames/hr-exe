extends Node
## 无界面逻辑测试：godot --headless --path . res://tests/RunTests.tscn

var failures := 0


func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: ", message)


func _ready() -> void:
	test_rule_boundaries()
	test_school_rule()
	test_id_card()
	test_calendar()
	test_generator()
	test_economy()
	test_month_end()
	test_events()
	test_save_roundtrip()
	await test_scene_branches()
	await test_interview()
	await test_pause_menu()
	print("TESTS DONE, failures=", failures)
	get_tree().quit(failures)


func _candidate() -> Candidate:
	var c := Candidate.new()
	c.birth_date = "1995-01-01"
	c.degree = Candidate.Degree.BACHELOR
	c.salary_k = 10
	c.jobs = [{"company": "a", "title": "b", "start": "2020-01", "end": ""}]
	return c


func test_rule_boundaries() -> void:
	GameState.new_game(1)
	GameState.day = 3
	GameState.begin_day()
	check(GameState.today == "2026-03-04", "day 3 date")
	check(RuleEngine.active_rules.size() == 5, "five rules on day 3")
	var c := _candidate()
	check(RuleEngine.evaluate(c).pass, "clean candidate passes")
	c.birth_date = "1990-01-01"
	check(RuleEngine.evaluate(c).pass, "born 1990 passes")
	c.birth_date = "1989-12-31"
	check(not RuleEngine.evaluate(c).pass, "born 1989 fails")
	c = _candidate()
	c.salary_k = 18
	c.salary_low_k = 15
	check(RuleEngine.evaluate(c).pass, "range topping at budget passes")
	c.salary_k = 19
	check(not RuleEngine.evaluate(c).pass, "range upper bound over budget fails")
	c = _candidate()
	c.jobs[0].end = "2026-03"
	check(not RuleEngine.evaluate(c).pass, "left this month fails")
	c = _candidate()
	c.attachment = "已离职，可随时到岗"
	check(not RuleEngine.evaluate(c).pass, "says quit in attachment fails")
	c = _candidate()
	c.jobs = [
		{"company": "a", "title": "b", "start": "2024-02", "end": ""},
		{"company": "a", "title": "b", "start": "2020-01", "end": "2023-07"},
	]
	check(c.has_gap(), "inner gap found")
	check(not RuleEngine.evaluate(c).pass, "gap without note fails")
	c.gap_note = "进修考证"
	check(RuleEngine.evaluate(c).pass, "gap for study passes")
	c.gap_note = "陪父亲住院"
	check(not RuleEngine.evaluate(c).pass, "gap for family fails")
	c.jobs[1].end = "2024-02"
	c.gap_note = ""
	check(not c.has_gap() and RuleEngine.evaluate(c).pass, "back-to-back jobs have no gap")
	c = _candidate()
	c.degree = Candidate.Degree.COLLEGE
	check(RuleEngine.evaluate(c).failed.size() == 1, "degree failure reports rule")


func test_school_rule() -> void:
	GameState.new_game(2)
	GameState.day = 4
	GameState.begin_day()
	check(RuleEngine.active_rules.size() == 6, "six rules on day 4")
	var c := _candidate()
	c.school = "东江大学"
	check(RuleEngine.evaluate(c).pass, "famous school passes")
	c.school = "东江大学科文学院"
	check(not RuleEngine.evaluate(c).pass, "branch college of a famous school fails")
	c.degree = Candidate.Degree.MASTER
	c.school = "东江大学"
	c.undergrad_school = "明湖学院"
	check(not RuleEngine.evaluate(c).pass, "famous master over plain bachelor fails")
	c.school = "明湖学院"
	c.undergrad_school = "南山理工大学"
	check(RuleEngine.evaluate(c).pass, "plain master over famous bachelor passes")
	var restored := Candidate.from_dict(c.to_dict())
	check(restored.undergrad_school == "南山理工大学", "undergrad school saved")


func test_id_card() -> void:
	GameState.new_game(14)
	GameState.day = 2
	GameState.begin_day()
	check(RuleEngine.active_docs.is_empty(), "no ID card before day 3")
	GameState.day = 3
	GameState.begin_day()
	check(RuleEngine.active_docs == PackedStringArray(["id_card"]), "ID card from day 3")
	# 简历写 1990，身份证是 1989：看简历能过，其实不过
	var c := _candidate()
	c.birth_date = "1989-11-05"
	c.override("resume", "birth_date", "1990-03-05")
	check(c.fact("birth_date") == "1990-03-05", "resume shows the claim")
	check(RuleEngine.evaluate(c).pass, "without an ID card the resume counts")
	c.docs = PackedStringArray(["id_card"])
	check(c.fact("birth_date", "id_card") == "1989-11-05", "ID card shows the fact")
	check(not RuleEngine.evaluate(c).pass, "ID card born 1989 fails though resume says 1990")
	var number := c.id_number()
	check(number.length() == 18 and number.substr(6, 8) == "19891105", "ID number carries the ID birth date")
	var restored := Candidate.from_dict(JSON.parse_string(JSON.stringify(c.to_dict())))
	check(restored.docs == c.docs and restored.fact("birth_date") == "1990-03-05", "docs and overrides survive JSON")
	check(restored.id_number() == number, "ID number stable after reload")

	# 生成器：第 3 天起人人带身份证，一部分简历年份改过；改的只是简历，判定按事实不变
	var planted := 0
	var liars := 0
	for game_seed in range(1, 30):
		GameState.new_game(game_seed)
		for day in [3, 4, 5]:
			GameState.day = day
			GameState.begin_day()
			for g in CandidateGenerator.generate_day(GameState.config, RuleEngine.active_rules, GameState.day_seed()):
				check(g.is_story or "id_card" in g.docs, "generated candidate carries an ID card")
				if g.doc_overrides.is_empty():
					continue
				planted += 1
				var claimed := DateUtil.parse(g.fact("birth_date")).x
				var real := DateUtil.parse(g.birth_date).x
				check(claimed != real, "planted birth year differs")
				if real < 1990 and claimed >= 1990:
					liars += 1
					check(g.honesty <= DiscrepancyBirth.LIAR_HONESTY, "claiming to be younger lowers honesty")
				var plain := Candidate.from_dict(g.to_dict())
				plain.doc_overrides = {}
				check(RuleEngine.evaluate(plain).pass == RuleEngine.evaluate(g).pass, "mismatch never changes the verdict")
	var days := 29.0 * 3
	print("birth mismatches/day=", planted / days, " younger claims/day=", liars / days)
	check(liars / days > 0.7 and liars / days < 1.5, "about one 'claims to be 90s' trap a day")
	check(planted / days < 3.5, "mismatches stay a minority of the pile")


func test_calendar() -> void:
	GameState.new_game(3)
	var expected := ["2026-03-02", "2026-03-03", "2026-03-04", "2026-03-18", "2026-03-31"]
	for day in range(1, GameState.LAST_DAY + 1):
		GameState.day = day
		GameState.begin_day()
		check(GameState.today == expected[day - 1], "date of day %d" % day)
		check(GameState.config.morning_push != "", "morning push on day %d" % day)
		check(GameState.job_posting != null and GameState.job_posting.title == "管培生（实习）", "job posting carries over to day %d" % day)
		check(GameState.days_to_mortgage() == GameState.LAST_DAY - day, "days to mortgage on day %d" % day)
		check(GameState.is_month_end() == (day == 5), "month end only on day 5")
	var batch := CandidateGenerator.generate_day(GameState.config, RuleEngine.active_rules, GameState.day_seed())
	check(batch.all(func(c: Candidate) -> bool: return c.applied_position == "管培生（实习）"), "everyone applies for the posted job")


func test_generator() -> void:
	var total := 0
	var rejected := 0
	var edge := 0
	var late_total := 0
	var late_rejected := 0
	for game_seed in range(1, 40):
		GameState.new_game(game_seed)
		for day in range(1, GameState.LAST_DAY + 1):
			GameState.day = day
			GameState.begin_day()
			var batch := CandidateGenerator.generate_day(GameState.config, RuleEngine.active_rules, GameState.day_seed())
			check(batch.size() == GameState.config.resume_count + GameState.config.story_candidates.size(), "batch size")
			for c in batch:
				total += 1
				var result := RuleEngine.evaluate(c)
				if c.is_story:
					check(result.pass, "story candidate satisfies every rule")
				else:
					rejected += 0 if result.pass else 1
					edge += 1 if _is_edge(c) else 0
					if day >= 3:
						late_total += 1
						late_rejected += 0 if result.pass else 1
				check(not c.jobs.is_empty(), "has jobs")
				for i in c.jobs.size():
					check(c.jobs[i].start < (c.jobs[i].end if c.jobs[i].end != "" else "9999"), "job order")
	var reject_rate := float(rejected) / total
	print("reject_rate=", reject_rate, " edge_rate=", float(edge) / total, " day3-5_reject_rate=", float(late_rejected) / late_total)
	check(reject_rate > 0.3 and reject_rate < 0.6, "reject rate in range")
	var slice_total := 0
	for day in range(1, GameState.LAST_DAY + 1):
		var config := RuleEngine.load_day(day)
		slice_total += config.resume_count + config.story_candidates.size()
	check(slice_total == 37, "first month: 5 on day 1 (story included), then 8 a day")


func _is_edge(c: Candidate) -> bool:
	if c.degree_note != "":
		return true
	if absi(c.salary_k - 18) <= 1 and GameState.day >= 2:
		return true
	if c.attachment.contains("在职") or c.attachment.contains("已离职"):
		return true
	var year := DateUtil.parse(c.birth_date).x
	return GameState.day >= 3 and (year == 1989 or year == 1990 or c.has_gap())


func test_economy() -> void:
	GameState.new_game(5)
	var good := _candidate()
	var bad := _candidate()
	bad.degree = Candidate.Degree.COLLEGE
	for i in 3:
		GameState.record_decision(bad, "pass", &"", "")  # 3 次违规：2 警告 + 1 罚款
	GameState.record_decision(good, "pass", &"", "")
	check(GameState.stats.wrong == 3, "three violations")
	check(GameState.fines() == 50, "first two are warnings")
	check(GameState.performance_pay() == 4 * 5, "every processed resume pays performance")
	check(GameState.judge_bonus() == 3, "only correct verdicts pay the judging bonus")
	check(GameState.income() == 300 + 20 + 3 - 50, "income")
	check(GameState.conscience == 0, "degree is not absurd")
	var before := GameState.savings
	GameState.settle([])
	check(GameState.savings == before + 273, "unpaid bill not charged, no mortgage mid-month")
	check(GameState.family_state == -1, "unpaid bill hurts family")

	GameState.new_game(6)
	GameState.day = 3
	GameState.begin_day()
	var old := _candidate()
	old.birth_date = "1980-01-01"
	GameState.record_decision(old, "pass", &"", "")
	check(GameState.conscience == 1, "letting an absurd-rule victim through raises conscience")
	check(GameState.decision_log[0].violated_rule, "log marks violation")
	GameState.record_decision(old, "reject", &"rule_age", "您的年龄不符合团队活力要求。")
	check(GameState.decision_log[1].reason_text == "您的年龄不符合团队活力要求。", "reason kept verbatim")


func test_month_end() -> void:
	GameState.new_game(4)
	GameState.day = 5
	GameState.begin_day()
	GameState.savings = 1000
	GameState.settle(["tutoring"])
	check(GameState.savings == 1000 + 300 - 1250 - 60, "mortgage charged on month end")
	check(GameState.is_bankrupt(), "short on mortgage is bankrupt")

	# 第 2 天录用的人第 5 天满期；延期的人还在，留任奖金照发
	GameState.new_game(5)
	var lazy := _candidate()
	lazy.ability = 20
	GameState.day = 2
	GameState.begin_day()
	GameState.add_hire(lazy, {"狼性": 3})
	check(GameState.hires[0].retention_due == 5, "retention period from hire day")
	GameState.day = 4
	GameState.begin_day()
	check(EmployeeEvents.due_event().is_empty(), "not due yet")
	GameState.day = 5
	GameState.begin_day()
	check(EmployeeEvents.due_event().id == "delay", "day 5 settles the day 2 hire")
	check(GameState.retention_bonus() == 150, "delayed hire still earns retention")

	# 延发的月份：留任奖金不进存款，记在 deferred_bonus
	GameState.pay = GameState.pay.duplicate()
	GameState.pay.retention_deferred = true
	check(GameState.retention_bonus() == 0, "deferred retention not paid today")
	GameState.savings = 5000
	GameState.settle([])
	check(GameState.deferred_bonus == 150, "deferred retention recorded")


func test_events() -> void:
	var perfect: Candidate = load("res://data/story/candidate_perfect.tres")
	var full := {"狼性": 5, "格局": 5, "稳定性": 5, "颜值": 5}
	GameState.new_game(7)
	GameState.add_hire(perfect, full)
	check(EmployeeEvents.due_event().is_empty(), "no event before retention ends")
	GameState.day = 4
	GameState.begin_day()
	var event := EmployeeEvents.due_event()
	check(event.id == "embezzle", "story override fires")
	check(GameState.retention_bonus() == 0 and GameState.stats.retained[0].left, "leaver earns no retention")
	check(EmployeeEvents.due_event().is_empty(), "event resolved once")
	EmployeeEvents.resolve_blame(event, "scorecard")
	check(GameState.stats.event_fine == 0, "full scorecard avoids fine")
	check(GameState.boss_promised_rule, "but boss adds a rule")

	GameState.new_game(8)
	GameState.add_hire(perfect, {"狼性": 5, "格局": 3, "稳定性": 5, "颜值": 5})
	GameState.day = 4
	GameState.begin_day()
	event = EmployeeEvents.due_event()
	EmployeeEvents.resolve_blame(event, "scorecard")
	check(GameState.stats.event_fine == EmployeeEvents.LIE_FINE, "lying is punished")

	GameState.new_game(9)
	GameState.add_hire(perfect, full)
	GameState.day = 4
	GameState.begin_day()
	EmployeeEvents.resolve_blame(EmployeeEvents.due_event(), "own")
	check(GameState.boss_trust == 1 and GameState.stats.event_fine == EmployeeEvents.BLAME_FINE, "owning it costs money, earns trust")

	GameState.new_game(10)
	GameState.day = 4
	GameState.begin_day()
	var empty := EmployeeEvents.due_event()
	check(empty.id == "no_hire" and empty.fine == 0, "no hires: boss mail, no fine")
	GameState.day = 3
	GameState.begin_day()
	check(EmployeeEvents.due_event().is_empty(), "headcount mail only on the first due day")

	# 同一天两个人满期：老板叫最重的那个，两个都记进日结
	GameState.new_game(13)
	var stays := _candidate()
	stays.ability = 80
	stays.loyalty = 80
	stays.pressure = 80
	var leaves := _candidate()
	leaves.ability = 80
	leaves.loyalty = 20
	leaves.pressure = 80
	GameState.add_hire(stays, {"狼性": 3})
	GameState.add_hire(leaves, {"狼性": 3})
	GameState.day = 4
	GameState.begin_day()
	check(EmployeeEvents.due_event().id == "jump", "worst event goes to the boss")
	check(GameState.stats.retained.size() == 2 and GameState.retention_bonus() == 150, "only the stayer pays")

	for attrs: Array in [[30, 80, 80, "delay"], [80, 20, 80, "jump"], [80, 80, 20, "burnout"], [80, 80, 80, "praise"]]:
		GameState.new_game(11)
		var c := _candidate()
		c.ability = attrs[0]
		c.loyalty = attrs[1]
		c.pressure = attrs[2]
		GameState.add_hire(c, {"狼性": 3})
		GameState.day = 4
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
	check(GameState.stats.unprocessed == 5, "all five resumes unprocessed")
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
	check(GameState.stats.unprocessed == 4, "rest unprocessed")

	# 第 3 天：身份证跟着简历来，跟着简历走
	main.queue_free()
	main = _main(3)
	main.show_desk()
	desk = main.current
	await get_tree().process_frame
	check(desk.id_card != null and desk.id_card.candidate == desk.doc.candidate, "ID card arrives with its resume")
	var first := desk.id_card
	desk.commit("pass", &"", "")
	check(desk.id_card != first and desk.id_card.candidate == desk.doc.candidate, "next resume brings its own ID card")

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
	report._toggle_bill(false, "tutoring")
	check(report.paid_ids().is_empty(), "bill can be unpaid")
	report.confirm()
	await get_tree().process_frame
	check(GameState.is_bankrupt(), "negative savings is bankrupt")
	check(main.current.has_method("_ready") and main.current.name.begins_with("Newspaper"), "news after report")
	main.next_day()
	await get_tree().process_frame
	check(main.current is SliceEnd, "bankruptcy ends the run early")

	# 存档 → 继续：JSON 读回后第 4 天（留任期满）事件仍能结算
	main.queue_free()
	main = _main(1)
	GameState.add_hire(load("res://data/story/candidate_perfect.tres"), {"狼性": 5, "格局": 5, "稳定性": 5, "颜值": 5})
	GameState.day = 3
	main.next_day()
	check(GameState.day == 4, "advance to day 4")
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
	room.chief_ask()
	room.ask(_card(room, &"q_weakness"))


func test_interview() -> void:
	for path in InterviewRoom.QUESTION_PATHS:
		var card: QuestionCard = load("res://data/questions/%s.tres" % path)
		check(card.always_truthful or card.chief_item in InterviewRoom.SCORE_ITEMS, "chief item valid: " + path)
		check(card.chief_honest != "", "chief reaction: " + path)
	for day in range(1, GameState.LAST_DAY + 1):
		var config := RuleEngine.load_day(day)
		check(config.chief_question.lawsuit_risk == 0 or day == 3, "only day 3 chief question is illegal")
		check(config.chief_opener != "" and config.chief_question != null and config.candidate_ask != null, "chief data day %d" % day)

	# 表演者加分、说实话减分；主管占掉一问，上限 5
	var performer := _candidate()
	performer.performance = 90
	var room := _room(1, performer)
	room.ask(_card(room, &"q_overtime"))
	check(room.scorecard["狼性"] == 4, "standard answer raises score")
	check(room.asked == 1 and _button(room, "让主管问") != null, "chief cuts in after first card")
	room.chief_ask()
	check(room.asked == 2, "chief uses a question")
	check(GameState.lawsuit_risk == 0, "ordinary chief question is legal")
	room.scorecard["狼性"] = 5
	room.ask(_card(room, &"q_friday"))
	check(room.scorecard["狼性"] == 5, "score capped")
	room.queue_free()

	var honest := _candidate()
	honest.performance = 10
	honest.honesty = 80
	room = _room(1, honest)
	room.ask(_card(room, &"q_weakness"))
	check(room.scorecard["格局"] == 2, "honest answer lowers score")
	room.queue_free()

	# 现场测试只说话不打分
	room = _room(1, honest)
	var before := room.scorecard.duplicate()
	room.ask(_card(room, &"q_test"))
	check(room.scorecard == before, "test card leaves scorecard alone")
	room.queue_free()

	# 违法提问累积诉讼风险
	room = _room(3, performer)
	room.ask(_card(room, &"q_overtime"))
	room.chief_ask()
	check(GameState.lawsuit_risk == 1, "illegal chief question adds risk")
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
	GameState.day = 4
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
	check(_button(room, "录用") == null and _button(room, "送客") != null, "able candidate walks out")
	room.queue_free()

	var stuck := _candidate()
	stuck.ability = 30
	room = _room(1, stuck)
	_ask_until_candidate(room)
	room.answer_candidate("truth")
	check(_button(room, "录用") != null, "candidate without options stays")
	await get_tree().process_frame
	room.queue_free()


func test_save_roundtrip() -> void:
	GameState.new_game(12)
	GameState.lawsuit_risk = 2
	GameState.reply_log = [{"answer": "x"}]
	GameState.savings = 123
	GameState.conscience = 2
	var perfect: Candidate = load("res://data/story/candidate_perfect.tres")
	GameState.add_hire(perfect, {"狼性": 5})
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
	GameState.load_dict(old_save)
	check(GameState.lawsuit_risk == 0 and GameState.reply_log.is_empty(), "old saves still load")
	var restored := Candidate.from_dict(GameState.hires[0].candidate)
	check(restored.display_name == "顾全" and restored.event_override == &"embezzle", "hire restored")
	check(restored.skills.size() == 4, "skills restored")
	SaveManager.clear()
	check(not SaveManager.has_save(), "cleared")


func test_pause_menu() -> void:
	# 第 2 天筛到一半：暂停 → 存档（存的是早上）→ 退出 → 继续，回到第 2 天早上
	SaveManager.clear()
	var main := _main(2)
	var morning_savings := GameState.savings
	main.show_desk()
	await get_tree().process_frame
	main.open_menu()
	check(get_tree().paused, "menu pauses the desk clock")
	GameState.record_decision(_candidate(), "pass", &"", "")
	GameState.savings += 77
	main.menu.save()
	check(SaveManager.saved_day() == 2, "checkpoint is today")
	main.menu._confirm_quit()
	main.menu.quit()
	await get_tree().process_frame
	check(not get_tree().paused, "unpaused after quit")
	check(not main._menu_button.visible, "no menu on title")
	check(main.current.has_method("start_saved"), "back to title")
	main.current.start_saved()
	await get_tree().process_frame
	check(GameState.day == 2 and GameState.savings == morning_savings, "resume from this morning")
	check(GameState.decision_log.is_empty(), "half-done day not saved")
	check(main.current.scene_file_path.ends_with("MailScreen.tscn"), "resume at morning mail")
	check(main._menu_button.visible, "menu during play")

	# 别的局的存档不算这一局的
	GameState.new_game(5)
	check(SaveManager.saved_day() == 0, "other run's save not counted")
	main.queue_free()
	SaveManager.clear()
