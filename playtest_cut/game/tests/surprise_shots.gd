extends Control
## 意外支出截图：手机上来事（待回）、回了以后对方那句、日结单上那一行。
## Godot --path . res://tests/SurpriseShots.tscn（要开窗口）。截图存到 user://shots/surprise_*.png。

const OUT := "user://shots/"


func _ready() -> void:
	theme = UI.theme()
	DirAccess.make_dir_recursive_absolute(OUT)
	var gs = get_node("/root/GameState")
	gs.new_game(4242, 7)
	gs.surprise_today = Surprises.build(Surprises.POOL.filter(func(e: Dictionary) -> bool: return e.id == "fever")[0], 270, 0)
	var desk: Control = load("res://scenes/Desk.tscn").instantiate()
	add_child(desk)
	await _wait(0.4)
	desk._check_home(600)
	desk._clock.text = "10:05"
	desk._open_inbox()
	desk._inbox_panel._open("老婆")
	await _wait(0.2)
	await _shot("surprise_phone")
	desk._reply(gs.surprise_today, gs.surprise_today.replies[1])
	await _wait(0.2)
	await _shot("surprise_replied")
	desk.queue_free()
	var report: Control = load("res://scenes/DayReport.tscn").instantiate()
	add_child(report)
	await _wait(0.3)
	await _shot("surprise_report")
	report.queue_free()
	# 两天后揭晓：退烧药那项赌输了，手机上来一条带转账卡的消息
	gs.surprise_today = {}
	gs.reveal_today = Surprises.reveals(9, [{"id": "fever", "day": 7, "due": 9, "outcome": "bad", "amount": 400, "at": 0}])
	var desk2: Control = load("res://scenes/Desk.tscn").instantiate()
	add_child(desk2)
	await _wait(0.4)
	desk2._check_home(600)
	gs.close_surprise()
	desk2._clock.text = "10:05"
	desk2._open_inbox()
	desk2._inbox_panel._open("老婆")
	await _wait(0.2)
	await _shot("surprise_reveal")
	print("SHOTS DONE ", ProjectSettings.globalize_path(OUT))
	get_tree().quit()


func _wait(t: float) -> void:
	await get_tree().create_timer(t).timeout


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT + name + ".png")
