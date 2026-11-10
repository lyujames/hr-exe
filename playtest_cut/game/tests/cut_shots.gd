extends Control
## 砍减版几张截图：附言纸条、早上的报纸、回家（短信 + 状态两句）、面试评分表、第 14 天没有文件夹的桌面。
## Godot --path . res://tests/CutShots.tscn（要开窗口）。截图存到 user://shots/cut_*.png。

const OUT := "user://shots/"


func _ready() -> void:
	theme = UI.theme()
	DirAccess.make_dir_recursive_absolute(OUT)
	var gs = get_node("/root/GameState")
	gs.new_game(4242, 1)
	# 第 3 天：桌上一份生成的简历，底下夹着附言
	gs.day = 3
	gs.begin_day()
	var desk: Control = load("res://scenes/Desk.tscn").instantiate()
	add_child(desk)
	await _wait(0.6)
	var cheat = get_node_or_null("/root/Cheat")
	for i in 4:
		if desk.doc and not desk.doc.candidate.is_story:
			break
		var e: Dictionary = cheat._expected(desk.doc.candidate)
		desk.commit(e.verdict, e.rule, e.reason)
		await _wait(0.3)
	await _shot("cut_desk_3")
	desk.queue_free()
	# 第 14 天：按组招，但没有文件夹
	gs.new_game_month2(false, "try", 4242)
	gs.day = 14
	gs.begin_day()
	var desk14: Control = load("res://scenes/Desk.tscn").instantiate()
	add_child(desk14)
	await _wait(0.6)
	await _shot("cut_desk_14")
	desk14.queue_free()
	# 早上的报纸：第 2 天早上看第 1 天晚上那份
	gs.new_game(4242, 1)
	gs.store_paper()
	gs.advance_day()
	var mail: Control = load("res://scenes/MailScreen.tscn").instantiate()
	add_child(mail)
	await _wait(0.4)
	await _shot("cut_paper_2")
	mail.queue_free()
	# 回家：短信在前，最后两句状态
	var home: HomeScreen = load("res://scenes/HomeScreen.tscn").instantiate()
	add_child(home)
	await _wait(0.2)
	for i in 3:
		if not home._options.is_empty():
			home._options[0].emit_signal("pressed")
		else:
			home._advance()
		await _wait(0.1)
	await _shot("cut_home_sms_2")
	var guard := 0
	while guard < 40 and home._next.text not in ["睡觉", "继续"]:
		guard += 1
		if not home._options.is_empty():
			home._options[0].emit_signal("pressed")
		else:
			home._advance()
		await _wait(0.05)
	await _shot("cut_home_end_2")
	home.queue_free()
	# 面试评分表：锁住的表
	gs.interviewees.assign([load("res://data/story/candidate_gu_quan.tres") if ResourceLoader.exists("res://data/story/candidate_gu_quan.tres") else CandidateGenerator.generate_day(gs.config, get_node("/root/RuleEngine").active_rules, 7)[0]])
	var room: InterviewRoom = load("res://scenes/InterviewRoom.tscn").instantiate()
	add_child(room)
	await _wait(0.5)
	room._show_scorecard()
	await _wait(0.3)
	await _shot("cut_scorecard")
	room.queue_free()
	print("SHOTS DONE ", ProjectSettings.globalize_path(OUT))
	get_tree().quit()


func _wait(t: float) -> void:
	await get_tree().create_timer(t).timeout


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT + name + ".png")
