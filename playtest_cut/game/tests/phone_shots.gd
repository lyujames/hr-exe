extends Control
## 手机 WChat 界面截图：会话列表、老婆的对话（自拍 + 一条待回的消息）。
## Godot --path . res://tests/PhoneShots.tscn（要开窗口）。截图存到 user://shots/phone_*.png。

const OUT := "user://shots/"


func _ready() -> void:
	theme = UI.theme()
	DirAccess.make_dir_recursive_absolute(OUT)
	var gs = get_node("/root/GameState")
	gs.new_game(4242, 1)
	var desk: Control = load("res://scenes/Desk.tscn").instantiate()
	add_child(desk)
	await _wait(0.4)
	for e: Dictionary in gs.config.desk_texts.slice(0, 2):
		gs.receive_text(e)
	gs.receive_text({"id": "x_dad", "from": "你爸", "at": 610, "text": "你爸：药我自己去拿了，你忙你的。"})
	gs.receive_text({"id": "x_hh", "from": "猎头 王经理", "at": 700, "text": "猎头 王经理：张总，有个候选人想跟您聊聊。"})
	desk._clock.text = "11:42"
	desk._open_inbox()
	await _wait(0.2)
	await _shot("phone_list")
	desk._inbox_panel._open("老婆")
	await _wait(0.2)
	await _shot("phone_thread")
	print("SHOTS DONE ", ProjectSettings.globalize_path(OUT))
	get_tree().quit()


func _wait(t: float) -> void:
	await get_tree().create_timer(t).timeout


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT + name + ".png")
