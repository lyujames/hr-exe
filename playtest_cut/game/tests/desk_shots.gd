extends Control
## 桌面美术接进来以后的截图：第 3 天的桌面、盖章那一下、违规单、抽屉、离职谈话的协议书。
## Godot --path . res://tests/DeskShots.tscn（要开窗口）。截图存到 user://shots/desk_*.png。

const OUT := "user://shots/"


func _ready() -> void:
	theme = UI.theme()
	DirAccess.make_dir_recursive_absolute(OUT)
	var gs = get_node("/root/GameState")
	gs.new_game(4242, 1)
	gs.day = 3
	gs.begin_day()
	var desk: Control = load("res://scenes/Desk.tscn").instantiate()
	add_child(desk)
	await _wait(0.6)
	await _shot("desk_3")
	desk._home_phone.set_lit(true, "10:42")
	desk._print_slip("郭磊", "盖错章：这份不该过")
	await _wait(0.8)
	await _shot("desk_slip")
	# 三种章印盖在同一张简历上，中间那下截在“压下去”那一刻
	var c: Candidate = desk.doc.candidate
	desk.queue_free()
	var sheet := ResumeDoc.new()
	sheet.position = Vector2(200, 40)
	add_child(sheet)
	sheet.setup(c)
	gs.stats.processed = 0
	sheet.stamp("pass", Vector2(70, 60))
	gs.stats.processed = 30
	sheet.stamp("exception", Vector2(170, 130))
	sheet.stamp("reject", Vector2(110, 210))
	sheet._thump("reject")
	await _wait(0.075)
	await _shot("desk_thump")
	await _wait(0.5)
	await _shot("desk_marks")
	sheet.queue_free()
	# 第三个月末的抽屉
	gs.new_game(4242, 1)
	gs.day = 22
	gs.begin_day()
	gs.evidence = ["mail_19", "zhou_book", "voice_22"]
	gs.kickbacks = [{"day": 7, "from": "李哲的爸爸", "amount": 300, "taken": true}, {"day": 14, "from": "x", "amount": 100, "taken": true}]
	desk = load("res://scenes/Desk.tscn").instantiate()
	add_child(desk)
	await _wait(0.5)
	desk._open_drawer()
	await _wait(0.2)
	await _shot("desk_drawer")
	desk.queue_free()
	gs.day = 18
	gs.begin_day()
	var talk: Control = load("res://scenes/ExitTalk.tscn").instantiate()
	add_child(talk)
	await _wait(0.4)
	await _shot("desk_exit_talk")
	print("SHOTS DONE ", ProjectSettings.globalize_path(OUT))
	get_tree().quit()


func _wait(t: float) -> void:
	await get_tree().create_timer(t).timeout


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT + name + ".png")
