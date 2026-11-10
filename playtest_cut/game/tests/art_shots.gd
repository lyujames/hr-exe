extends Control
## 美术接进来以后的几张截图：头像总览、何静的面试半身像、沈雯的简历照、离职谈话、回家三个钟点。
## Godot --path . res://tests/ArtShots.tscn（要开窗口）。截图存到 user://shots/art_*.png。

const OUT := "user://shots/"


func _ready() -> void:
	theme = UI.theme()
	DirAccess.make_dir_recursive_absolute(OUT)
	var gs = get_node("/root/GameState")
	# 头像总览：有名字的人 + 路人池（按种子挑，男女各一半）
	var wall := Control.new()
	add_child(wall)
	UI.panel(wall, Rect2(0, 0, 640, 360), UI.DESK_DARK)
	var seeds: Array = PortraitFactory.BY_SEED.keys()
	var i := 0
	for key: String in PortraitFactory.BY_ID.values() + ["shenwen_photo"]:
		_face(wall, i, 0, key)
		i += 1
	for s: int in seeds:
		_face(wall, i, s, "")
		i += 1
	for k in 60 - i:
		_face(wall, i, 900000 + k * 37, "")
		i += 1
	await _wait(0.3)
	await _shot("art_faces")
	wall.queue_free()
	# 第 14 天面试间：何静（半身像）+ 韩组长
	gs.new_game_month2(false, "try", 4242)
	gs.day = 14
	gs.begin_day()
	gs.interviewees.assign([load("res://data/story/candidate_mother.tres")])
	var room: InterviewRoom = load("res://scenes/InterviewRoom.tscn").instantiate()
	add_child(room)
	await _wait(0.6)
	await _shot("art_interview_hejing")
	room.queue_free()
	# 沈雯：简历上是七年前的照片，面试间里是本人
	gs.interviewed_today.clear()
	gs.interviewees.assign([load("res://data/story/candidate_shenwen.tres")])
	room = load("res://scenes/InterviewRoom.tscn").instantiate()
	add_child(room)
	await _wait(0.6)
	await _shot("art_interview_shenwen")
	room.queue_free()
	# 回家三个钟点：第 18 天有离职谈话，谈到几点算几点
	gs.day = 18
	gs.begin_day()
	for clock: int in [18 * 60, 19 * 60, 21 * 60]:
		gs.stats.clock = clock
		gs.stats.left_early = false
		var home: HomeScreen = load("res://scenes/HomeScreen.tscn").instantiate()
		add_child(home)
		await _wait(0.3)
		for k in 2:
			if not home._options.is_empty():
				home._options[0].emit_signal("pressed")
			else:
				home._advance()
			await _wait(0.05)
		await _shot("art_home_%d" % clock)
		home.queue_free()
	print("SHOTS DONE ", ProjectSettings.globalize_path(OUT))
	get_tree().quit()


func _face(parent: Control, i: int, s: int, key: String) -> void:
	var p := PortraitView.new()
	p.setup(s, 1, key)
	p.position = Vector2(4 + (i % 10) * 63, 4 + (i / 10) * 59)
	p.set_process(false)
	parent.add_child(p)


func _wait(t: float) -> void:
	await get_tree().create_timer(t).timeout


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT + name + ".png")
