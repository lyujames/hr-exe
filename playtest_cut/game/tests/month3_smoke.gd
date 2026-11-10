extends Node
## 无界面冒烟测试：从第三个月开局，一天一天过（生成简历、按规则判、实例化每一屏、日结、下一天）。
## 用法：Godot --headless --path . res://tests/Smoke.tscn

var screens := ["res://scenes/MailScreen.tscn", "res://scenes/Desk.tscn", "res://scenes/ExitTalk.tscn", "res://scenes/DayReport.tscn", "res://scenes/Newspaper.tscn", "res://scenes/HomeScreen.tscn"]


func _ready() -> void:
	var root := get_tree().root
	await get_tree().process_frame
	var gs = root.get_node("GameState")
	var re = root.get_node("RuleEngine")
	var variants := [
		{"chenmo": true, "table": "fudge", "broker": true, "card": true, "poor": true},
		{"chenmo": false, "table": "true", "broker": false, "card": false, "poor": false},
	]
	for opts: Dictionary in variants:
		print("==== 开局 ", opts)
		gs.new_game_month3(opts, 12345)
		gs.family["h19_wife"] = "full"
		for d in range(17, 24):
			var pile: Array = CandidateGenerator.generate_day(gs.config, re.active_rules, gs.day_seed())
			var ok := 0
			var bot_right := 0
			var names := []
			for c: Candidate in pile:
				var r: Dictionary = re.evaluate(c)
				if r.pass:
					ok += 1
				if gs.config.hirebot > 0 and HireBot.says_pass(HireBot.label(c)) == r.pass:
					bot_right += 1
				if r.pass and d == 23:
					print("    第 23 天合格？", c.display_name, " 学历 ", c.degree, " ", c.school, " / ", c.degree_note, " 出生 ", c.fact("birth_date", "id_card"), " 年限 ", c.exp_months, c.exp_note, " 岗位 ", c.applied_position)
				if c.is_story:
					names.append("%s:%s" % [c.display_name, "过" if r.pass else "拒(" + ",".join(r.failed.map(func(x): return x.title_key)) + ")"])
			print("第 %d 天 %s 简历 %d（今日 %d）合格 %d HireBot 对 %d 剧情 %s 指标 %d" % [d, gs.today, pile.size(), gs.resume_count_today(), ok, bot_right, names, gs.quota_today()])
			# 判一半：合格的放，不合格的拒；剧情人物都放（看回响）
			for c: Candidate in pile:
				var r: Dictionary = re.evaluate(c)
				var verdict := "pass" if r.pass or c.is_story else "reject"
				gs.record_decision(c, verdict, &"generic" if verdict == "reject" else &"", Desk.GENERIC_REASON if verdict == "reject" else "")
				gs.record_pace(480 + gs.stats.processed * 9)
			if d == 18:
				gs.add_hire(pile[0], {"狼性": 3, "格局": 3, "稳定性": 3, "颜值": 3})
			for path: String in screens:
				if path.ends_with("ExitTalk.tscn") and gs.next_talk_index() < 0:
					continue
				if path.ends_with("HomeScreen.tscn") and (gs.config.home_scene.is_empty() or gs.is_month_end()):
					continue
				var node: Control = load(path).instantiate()
				root.add_child(node)
				await get_tree().process_frame
				await get_tree().process_frame
				if node is ExitTalk:
					# 每一问都选第一个选项
					while true:
						var talk: ExitTalk = node
						talk._ask()
						await get_tree().process_frame
						if talk._options.is_empty():
							break
						talk._options[talk._options.size() - 1].emit_signal("pressed")
						await get_tree().process_frame
					print("  谈话：", gs.stats.talks)
				if node is DayReport:
					for r in gs.config.rescue_options:
						if gs.family_matches(r.get("when", "")):
							node.rescue[r.id] = r.id == "dad_envelope"
					node.confirm()
				node.queue_free()
				await get_tree().process_frame
			print("  存款 %d 感情 %d 信任 %d 良心 %d 诉讼 %d 证据 %s 违规 %d 迟到到家 %s" % [gs.savings, gs.marriage, gs.boss_trust, gs.conscience, gs.lawsuit_risk, gs.evidence, gs.stats.wrong, gs.clock_text(gs.home_minutes())])
			if gs.day >= gs.LAST_DAY:
				gs.savings = maxi(gs.savings, 100)
				var end: Control = load("res://scenes/SliceEnd.tscn").instantiate()
				root.add_child(end)
				await get_tree().process_frame
				end._show_home()
				await get_tree().process_frame
				end._show_summary()
				await get_tree().process_frame
				end.queue_free()
				break
			gs.advance_day()
	# 面试室：邵东第二次（出生那行删了）、破格的沈雯单独面
	gs.new_game_month3({}, 777)
	gs.day = 23
	gs.begin_day()
	var sd2: Candidate = load("res://data/story/candidate_shaodong_2.tres")
	var sw: Candidate = load("res://data/story/candidate_shenwen.tres")
	gs.interviewees.assign([sd2])
	gs.vouched.assign([sw])
	for i in 2:
		var room: Control = load("res://scenes/InterviewRoom.tscn").instantiate()
		root.add_child(room)
		for f in 3:
			await get_tree().process_frame
		print("  面试室 ", room.candidate.display_name, " solo=", room.solo)
		room.queue_free()
		await get_tree().process_frame
	# 桌上弹出来的事、HireBot 预筛、推翻
	gs.day = 22
	gs.family["w16_table"] = "fudge"
	gs.decision_log.append({"day": 20, "candidate_id": "story_shenwen", "candidate_name": "沈雯", "verdict": "pass", "reason_rule": "", "reason_text": "", "expected": "reject", "failed_rules": [], "violated_rule": true})
	gs.begin_day()
	var desk: Desk = load("res://scenes/Desk.tscn").instantiate()
	root.add_child(desk)
	for f in 5:
		await get_tree().process_frame
	desk.elapsed = 60.0
	for f in 5:
		await get_tree().process_frame
	print("  弹窗：", desk._memo != null)
	var guard := 0
	while desk._memo and guard < 10:
		guard += 1
		var b: Button = null
		for child in desk._memo.get_children():
			if child is Button:
				b = child
				break
		b.emit_signal("pressed")
		await get_tree().process_frame
		for child in desk._memo.get_children():
			if child is Button and child.text == "接着干活":
				child.emit_signal("pressed")
		await get_tree().process_frame
		await get_tree().process_frame
		desk._process(0.0)
		await get_tree().process_frame
	print("  弹窗处理完：", gs.family.get("m22_rule"), " ", gs.family.get("m22_wife"), " ", gs.family.get("m22_table"), " 作废 ", gs.voided, " 信任 ", gs.boss_trust)
	# 推翻 HireBot：对它推荐的人盖拒绝
	var c := desk.doc.candidate
	print("  当前简历 ", c.display_name, " HireBot ", HireBot.label(c))
	desk._maybe_override("reject" if HireBot.label(c) == HireBot.RECOMMEND else "pass", func() -> void: print("  推翻后盖章"))
	await get_tree().process_frame
	print("  推翻框：", desk._override != null)
	if desk._override:
		for child in desk._override.get_children():
			if child is Button:
				child.emit_signal("pressed")
				break
	await get_tree().process_frame
	print("  推翻记录：", gs.stats.overrides)
	var cheat = root.get_node_or_null("Cheat")
	if cheat:
		cheat.stamp_all()
		await get_tree().process_frame
		print("  修改器全部盖对：处理 ", gs.stats.processed, " 错 ", gs.stats.wrong)
		print(cheat._status_text())
	desk.queue_free()
	await get_tree().process_frame
	# 第二个月底接着进第三个月：规则、岗位换没换
	gs.new_game_month2(false, "try", 99)
	gs.day = 16
	gs.begin_day()
	gs.advance_day()
	print("  第二个月底之后：第 %d 天 第 %d 个月 规则 %s 岗位 %s" % [gs.day, gs.month(), re.active_rules.map(func(r): return String(r.id)), re.active_postings.map(func(p): return p.title)])
	# Main 的流程：第 18 天面试完接离职谈话
	var main: Control = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await get_tree().process_frame
	gs.new_game_month3({}, 5)
	gs.day = 18
	gs.begin_day()
	main._after_interviews()
	await get_tree().process_frame
	print("  Main 面试后：", main.current.get_script().resource_path.get_file())
	main.queue_free()
	await get_tree().process_frame
	# 标题页的第三个月入口
	var title: Control = load("res://scenes/Title.tscn").instantiate()
	root.add_child(title)
	await get_tree().process_frame
	title.start_month3()
	await get_tree().process_frame
	print("SMOKE DONE")
	get_tree().quit()
