extends Control
## 截几张第三个月的画面看排版：Godot --path . res://tests/Shots.tscn（要开窗口，不能 headless）。
## 截图存到 user://shots/。

const OUT := "user://shots/"


func _ready() -> void:
	theme = UI.theme()
	DirAccess.make_dir_recursive_absolute(OUT)
	var gs = get_node("/root/GameState")
	gs.new_game_month3({"poor": true, "table": "fudge"}, 4242)
	for d: int in [19, 20, 23]:
		gs.day = d
		gs.begin_day()
		gs.best_pace = 9.0
		var desk: Control = load("res://scenes/Desk.tscn").instantiate()
		add_child(desk)
		await _wait(0.6)
		# 翻到剧情人物那份：一直盖对章直到它
		var cheat = get_node_or_null("/root/Cheat")
		for i in 6:
			if desk.doc and desk.doc.candidate.is_story:
				break
			if desk._memo:
				desk._memo.queue_free()
				desk._memo = null
			if desk.doc:
				var e: Dictionary = cheat._expected(desk.doc.candidate)
				desk.commit(e.verdict, e.rule, e.reason)
			await _wait(0.3)
		if desk._memo:
			desk._memo.queue_free()
			desk._memo = null
		await _wait(0.4)
		await _shot("desk_%d" % d)
		desk.queue_free()
		await _wait(0.2)
	# 第 22 天的打印件
	gs.day = 22
	gs.begin_day()
	var desk22: Control = load("res://scenes/Desk.tscn").instantiate()
	add_child(desk22)
	await _wait(0.8)
	await _shot("desk_22_memo")
	desk22.queue_free()
	# 离职谈话：韩蕾
	gs.begin_day()
	var talk: Control = load("res://scenes/ExitTalk.tscn").instantiate()
	add_child(talk)
	await _wait(0.3)
	talk._ask()
	await _wait(0.3)
	await _shot("talk_22")
	talk.queue_free()
	# 邮件（第 19 天能打印）
	gs.day = 19
	gs.begin_day()
	var mail: Control = load("res://scenes/MailScreen.tscn").instantiate()
	add_child(mail)
	await _wait(0.6)
	await _shot("mail_19")
	mail.queue_free()
	# 月底日结
	gs.day = 23
	gs.begin_day()
	var report: Control = load("res://scenes/DayReport.tscn").instantiate()
	add_child(report)
	await _wait(0.3)
	report._open_rescue(report._rescues)
	await _wait(0.3)
	await _shot("report_23")
	report.queue_free()
	var title: Control = load("res://scenes/Title.tscn").instantiate()
	add_child(title)
	await _wait(0.2)
	title.start_month3()
	await _wait(0.3)
	await _shot("title_m3")
	print("SHOTS DONE ", ProjectSettings.globalize_path(OUT))
	get_tree().quit()


func _wait(t: float) -> void:
	await get_tree().create_timer(t).timeout


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT + name + ".png")
