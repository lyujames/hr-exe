extends Control
## 排版检查：几份写得满的简历，HireBot 小条不出纸。Godot --path . res://tests/ResumeFit.tscn
func _ready() -> void:
	theme = UI.theme()
	var gs = get_node("/root/GameState")
	gs.new_game_month3({}, 1)
	gs.day = 21
	gs.begin_day()
	UI.panel(self, Rect2(0, 0, 640, 360), UI.DESK)
	var base: Candidate = load("res://data/story/candidate_weilai.tres")
	var cases := [[0, "", 4], [1, "含实习 1 年", 6], [2, "含在校兼职 2 年", 8]]
	for i in cases.size():
		var c: Candidate = base.duplicate()
		c.id = &"gen_fit_%d" % i
		c.is_story = false
		c.salary_k = 54
		c.exp_note = cases[i][1]
		c.gender = "女"
		c.marital = "已婚未育（三年内无生育计划，可签承诺书）" if i > 0 else "未婚"
		c.degree_note = "第一学历：中专；网络教育本科，2022 年毕业"
		c.skills = PackedStringArray(["Docker", "Go", "Node.js", "TypeScript", "Vue", "MySQL", "Linux", "Kafka"].slice(0, cases[i][2]))
		var doc: ResumeDoc = load("res://scenes/ResumeDoc.tscn").instantiate()
		doc.position = Vector2(4 + i * 212, 46)
		doc.scale = Vector2(0.9, 0.9)
		add_child(doc)
		doc.setup(c)
	for f in 10:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://shots/resume_fit.png")
	for doc in get_children():
		if doc is ResumeDoc:
			doc.flip()
	for f in 5:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://shots/resume_fit_back.png")
	print("FIT DONE")
	get_tree().quit()
