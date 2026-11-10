extends Node
## 砍减版截图走查（要开窗口）：和 CutWalk 走法一样，每一屏截一张 user://shots/tour/DD_屏.png。
## 用法：Godot --path . res://tests/CutTour.tscn
## 原注释：砍减版无界面走查：从第 1 天走到第 23 天，按 Main 的顺序把每一屏实例化一遍。
## 判对所有简历；有人面试就录用；谈话每问选最后一项；回家每个问话选第一项。
## 用法：Godot --headless --path . res://tests/CutWalk.tscn

var _errors: Array[String] = []
## 和 Main 一样挂主题（字体、行距），截出来的排版才对。
var _stage: Control
const OUT := "user://shots/tour/"


func _ready() -> void:
	var root := get_tree().root
	_stage = Control.new()
	_stage.theme = UI.theme()
	_stage.size = Vector2(640, 360)
	root.add_child.call_deferred(_stage)
	await get_tree().process_frame
	var gs = root.get_node("GameState")
	var re = root.get_node("RuleEngine")
	gs.new_game(4242, 1)
	DirAccess.make_dir_recursive_absolute(OUT)
	while true:
		var d: int = gs.day
		# 早上：昨天的晚报在不在
		var mail: Control = load("res://scenes/MailScreen.tscn").instantiate()
		_stage.add_child(mail)
		await _frames(2)
		await _shot(d, "1mail")
		var paper_ok: bool = gs.paper.is_empty() or gs.paper.get("date", "") != gs.today
		mail.queue_free()
		var desk: Desk = load("res://scenes/Desk.tscn").instantiate()
		_stage.add_child(desk)
		await _frames(3)
		await _wait(0.4)
		await _shot(d, "2desk")
		if RuleEngine.folder_mode:
			_errors.append("第 %d 天还是文件夹模式" % d)
		if gs.config.intake:
			_errors.append("第 %d 天还有入职登记表" % d)
		var notes := 0
		if desk.doc:
			for child in desk.doc.get_children():
				if child is Control and child.get_child_count() == 2 and child.get_child(1) is Label and String(child.get_child(1).text).begins_with("附言"):
					notes += 1
		desk.queue_free()
		await _frames(1)
		var pile: Array = CandidateGenerator.generate_day(gs.config, re.active_rules, gs.day_seed())
		var ok := 0
		var story := []
		for c: Candidate in pile:
			var r: Dictionary = re.evaluate(c)
			if r.pass:
				ok += 1
			if c.is_story:
				story.append("%s:%s" % [c.display_name, "过" if r.pass else "拒"])
			var verdict := "pass" if r.pass else "reject"
			var rule: StringName = r.failed[0].id if not r.pass else &""
			var why: String = gs.record_decision(c, verdict, rule, Desk.GENERIC_REASON if verdict == "reject" else "")
			if why != "":
				_errors.append("第 %d 天按规则判还违规：%s %s" % [d, c.display_name, why])
		# 傍晚：和 Main.show_interview 一样的判断
		var interviewed := ""
		if gs.next_vouched():
			interviewed += await _interview(root, gs) + "(破格) "
		if not gs.interviewees.is_empty() and not gs.skip_plain_interview():
			interviewed += await _interview(root, gs)
		var talks := 0
		while gs.next_talk_index() >= 0:
			talks += 1
			var talk: ExitTalk = load("res://scenes/ExitTalk.tscn").instantiate()
			_stage.add_child(talk)
			await _frames(2)
			await _shot(d, "4talk")
			var guard := 0
			while guard < 20:
				guard += 1
				talk._ask()
				await _frames(1)
				if talk._options.is_empty():
					break
				talk._options[talk._options.size() - 1].emit_signal("pressed")
				await _frames(1)
			await _shot(d, "4talk_end")
			talk.queue_free()
			await _frames(1)
			if talks > 4:
				_errors.append("第 %d 天谈话停不下来" % d)
				break
		var report: DayReport = load("res://scenes/DayReport.tscn").instantiate()
		_stage.add_child(report)
		await _frames(2)
		await _shot(d, "5report")
		report.confirm()
		report.queue_free()
		await _frames(1)
		# 回家（含短信）
		gs.store_paper()
		var home_beats := 0
		if not gs.is_bankrupt() and HomeScreen.has_content():
			var home: HomeScreen = load("res://scenes/HomeScreen.tscn").instantiate()
			_stage.add_child(home)
			await _frames(2)
			await _shot(d, "6home")
			var guard := 0
			while guard < 60:
				guard += 1
				if not home._options.is_empty():
					home._options[0].emit_signal("pressed")
				elif home._next.text in ["睡觉", "继续"]:
					break
				else:
					home._advance()
				home_beats += 1
				await _frames(1)
			await _shot(d, "6home_end")
			home.queue_free()
			await _frames(1)
		print("第 %2d 天 %s 简历 %2d 合格 %2d 剧情 %s 附言 %d 面试 %s 谈话 %d 回家 %d 拍 早报 %s 存款 %d 感情 %d 信任 %d" % [d, gs.today, pile.size(), ok, story, notes, interviewed if interviewed != "" else "-", talks, home_beats, "ok" if paper_ok else "旧", gs.savings, gs.marriage, gs.boss_trust])
		if gs.is_bankrupt():
			print("  破产，补 ¥2000 接着走")
			gs.savings += 2000
		if gs.day >= gs.LAST_DAY:
			break
		gs.advance_day()
		if gs.interviewees.size() > 1:
			_errors.append("第 %d 天约了 %d 个人" % [gs.day, gs.interviewees.size()])
	print("ERRORS: ", _errors.size())
	for e in _errors:
		print("  ", e)
	print("CUT WALK DONE")
	get_tree().quit()


func _interview(_root: Node, gs: Node) -> String:
	var room: InterviewRoom = load("res://scenes/InterviewRoom.tscn").instantiate()
	_stage.add_child(room)
	await _frames(3)
	await _wait(0.3)
	await _shot(gs.day, "3room")
	var who: String = room.candidate.display_name
	room._show_scorecard()
	await _frames(1)
	await _shot(gs.day, "3room_card")
	room.decide(true)
	room.queue_free()
	await _frames(1)
	return who


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _wait(t: float) -> void:
	await get_tree().create_timer(t).timeout


func _shot(d: int, name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT + "%02d_%s.png" % [d, name])
