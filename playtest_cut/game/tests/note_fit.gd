extends Control
## 排版检查：每天的邮件屏，便签不出显示器下框、不压早间推送。
## Godot --path . res://tests/NoteFit.tscn（带 --shots 每天存一张 user://shots/note_*.png）
func _ready() -> void:
	theme = UI.theme()
	var gs = get_node("/root/GameState")
	gs.new_game(1, 1)
	var bad := 0
	for d in range(1, 24):
		gs.day = d
		gs.begin_day()
		gs.paper = {}
		gs.late_today = {}
		var mail: Control = load("res://scenes/MailScreen.tscn").instantiate()
		add_child(mail)
		await get_tree().process_frame
		var sticky: Rect2
		var push: Rect2
		for c in mail.get_children():
			if c is Panel and c.rotation != 0.0:
				sticky = Rect2(c.position, c.size)
			elif c is Panel and c.position.y == 52.0:
				push = Rect2(Vector2(418, 52), c.size)
		var ok: bool = sticky.end.y <= mail.NOTE_BOTTOM and (push.size == Vector2.ZERO or not push.intersects(sticky))
		if not ok:
			bad += 1
		print("第 %d 天 便签 %s 推送 %s %s" % [d, sticky, push, "OK" if ok else "<<< 出界/压推送"])
		if "--shots" in OS.get_cmdline_user_args():
			await get_tree().create_timer(0.5).timeout
			DirAccess.make_dir_recursive_absolute("user://shots/")
			get_viewport().get_texture().get_image().save_png("user://shots/note_%02d.png" % d)
		mail.queue_free()
		await get_tree().process_frame
	print("不合格 %d 天" % bad)
	get_tree().quit(bad)
