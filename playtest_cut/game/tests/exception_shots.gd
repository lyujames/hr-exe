extends Control
## 破格章那几屏的截图：桌上被卡住的人（自评、附件、附言）、破格确认框、日结单（担保奖 / 补贴 / HC 没招满）、邮件附言、月底那一句。
## Godot --path . res://tests/ExceptionShots.tscn -- <截图目录>（要开窗口；不给目录就存 user://shots/）。

var out := "user://shots/"


func _ready() -> void:
	theme = UI.theme()
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		out = args[0].trim_suffix("/") + "/"
	DirAccess.make_dir_recursive_absolute(out)
	var gs = get_node("/root/GameState")
	var cheat = get_node_or_null("/root/Cheat")
	gs.new_game(4242, 1)
	# 第 8 天：翻到被卡住的那份，拍桌面，再拿破格章盖它
	gs.day = 8
	gs.begin_day()
	var desk: Control = load("res://scenes/Desk.tscn").instantiate()
	add_child(desk)
	await _wait(0.6)
	for i in 12:
		if desk.doc and desk.doc.candidate.blocked != "":
			break
		var e: Dictionary = cheat._expected(desk.doc.candidate)
		desk.commit(e.verdict, e.rule, e.reason)
		await _wait(0.3)
	await _shot("ex_desk_8")
	desk._ask_vouch()
	await _wait(0.2)
	await _shot("ex_vouch_8")
	desk.queue_free()
	# 第 11 天：HC 硬指标（后端），邮件附言里还有一条两天前筛掉的真人
	gs.new_game_month2(false, "try", 4242)
	gs.day = 11
	gs.begin_day()
	gs.blocked_rejects.append({"name": "胡涛", "kind": "real", "text": "胡涛 去了竞对，第二周就把他们线上那个三年没人敢动的服务重写了。", "day": 9, "due": 11})
	gs.blocked_rejects.append({"name": "李洋", "kind": "fake", "text": "李洋 去了别家，背调时证书编号对不上。", "day": 9, "due": 11})
	var mail: Control = load("res://scenes/MailScreen.tscn").instantiate()
	add_child(mail)
	await _wait(0.6)
	await _shot("ex_mail_11")
	mail.queue_free()
	# 日结单：担保的人干得好、面了一场破格、HC 没放进去
	gs.stats.processed = 5
	gs.stats.correct = 5
	gs.stats.vouch.append({"name": "赵晓东", "good": true})
	gs.stats.solo_done.append("赵晓东")
	var report: Control = load("res://scenes/DayReport.tscn").instantiate()
	add_child(report)
	await _wait(0.4)
	await _shot("ex_report_11")
	report.queue_free()
	# 月底：第一个月一次没破格
	gs.new_game(4242, 1)
	gs.day = 9
	gs.begin_day()
	gs.blocked_rejects.append({"name": "高洋", "kind": "real", "text": "", "day": 6, "due": 8})
	var end: Control = load("res://scenes/SliceEnd.tscn").instantiate()
	add_child(end)
	await _wait(0.4)
	await _shot("ex_month_end_9")
	print("SHOTS DONE ", ProjectSettings.globalize_path(out))
	get_tree().quit()


func _wait(t: float) -> void:
	await get_tree().create_timer(t).timeout


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out + name + ".png")
