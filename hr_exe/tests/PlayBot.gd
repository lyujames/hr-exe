extends Node
## 端到端冒烟：真实场景跑完第一个月（5 天）并逐屏截图。需要窗口环境。
## godot --path . res://tests/PlayBot.tscn -- <截图目录>

var main: Control
var out_dir := "user://shots"
var shot_index := 0
var failures := 0
var last_mouse := Vector2.ZERO


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		out_dir = args[0]
	DirAccess.make_dir_recursive_absolute(out_dir)
	SaveManager.clear()
	main = load("res://scenes/Main.tscn").instantiate()
	add_child(main)
	await run()
	print("PLAYBOT DONE, failures=", failures, " savings=", GameState.savings, " log=", GameState.decision_log.size())
	get_tree().quit(failures)


func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: ", message)


func frames(count := 3) -> void:
	for i in count:
		await get_tree().process_frame


func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func shot(tag: String) -> void:
	await RenderingServer.frame_post_draw
	shot_index += 1
	get_viewport().get_texture().get_image().save_png("%s/%02d_%s.png" % [out_dir, shot_index, tag])


func press(button_text: String) -> void:
	var button := _find_button(main.current, button_text)
	check(button != null, "button " + button_text)
	if button:
		button.pressed.emit()
	await frames()


func _find_button(node: Node, text: String) -> Button:
	if node is Button and node.text == text and not node.disabled:
		return node
	for child in node.get_children():
		var found := _find_button(child, text)
		if found:
			return found
	return null


func mouse_to_window(view_pos: Vector2) -> Vector2:
	var factor := Vector2(get_window().size) / get_viewport().get_visible_rect().size
	return view_pos * minf(factor.x, factor.y)


func send_mouse(view_pos: Vector2, pressed: bool, is_button: bool) -> void:
	var event: InputEventMouse
	if is_button:
		event = InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	else:
		event = InputEventMouseMotion.new()
		event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
		event.relative = mouse_to_window(view_pos) - last_mouse
	event.position = mouse_to_window(view_pos)
	last_mouse = event.position
	event.global_position = event.position
	Input.parse_input_event(event)
	await frames(2)


func real_drag(from: Vector2, to: Vector2) -> void:
	await send_mouse(from, false, false)
	await send_mouse(from, true, true)
	for i in range(1, 7):
		await send_mouse(from.lerp(to, i / 6.0), true, false)
	await send_mouse(to, false, true)
	await frames()


func stamp_with_mouse(desk: Desk, verdict: String) -> void:
	var from := Vector2(158, 330) if verdict == "pass" else Vector2(262, 330)
	await real_drag(from, desk.doc.position + Vector2(120, 170))


func screen_desk(day: int) -> void:
	var desk: Desk = main.current
	await wait(0.3)
	await shot("day%d_desk" % day)
	if day == 1:
		await screen_menu()
	desk.doc.flip()
	await wait(0.05)
	await shot("day%d_desk_back" % day)
	var doc_before := desk.doc.position
	await real_drag(doc_before + Vector2(20, 6), doc_before + Vector2(10, 12))
	check(desk.doc.position != doc_before, "resume moved by mouse drag")
	await real_drag(desk.doc.position + Vector2(20, 6), DOC_POS_OFFSET)
	var index := 0
	while desk.doc != null:
		var c: Candidate = desk.doc.candidate
		var should_pass: bool = RuleEngine.evaluate(c).pass
		var verdict := "pass" if should_pass else "reject"
		if index == 2:
			verdict = "pass" if verdict == "reject" else "reject"  # 故意错一份，看通知单
		if index < 2:
			await stamp_with_mouse(desk, verdict)
			check(desk.doc == null or desk.doc.candidate != c or desk._picker != null, "mouse stamp landed: " + verdict)
		else:
			desk.doc.stamp(verdict, Vector2(120, 170))
			await frames()
		if verdict == "reject":
			check(desk._picker != null, "picker opens on reject")
			if day == 3 and index < 4:
				await shot("day3_picker")
			var failed: Array = RuleEngine.evaluate(c).failed
			if failed.is_empty():
				desk.commit("reject", &"generic", Desk.GENERIC_REASON)
			else:
				desk.commit("reject", failed[0].id, failed[0].reject_reason_key)
		await wait(0.25)  # 等下一份简历滑入
		index += 1
	await wait(0.3)
	await shot("day%d_closing" % day)
	await press("继续")


## 暂停菜单：Esc 打开，存档，点到“退出”确认后取消，再 Esc 关掉。
func screen_menu() -> void:
	var key := InputEventKey.new()
	key.keycode = KEY_ESCAPE
	key.pressed = true
	Input.parse_input_event(key)
	await frames()
	check(is_instance_valid(main.menu) and get_tree().paused, "esc opens pause menu")
	main.menu.save()
	check(SaveManager.saved_day() == 1, "manual save on day 1")
	await shot("day1_menu_saved")
	main.menu._confirm_quit()
	await shot("day1_menu_quit")
	main.menu.close()
	await frames()
	check(not get_tree().paused, "menu closed")


const DOC_POS_OFFSET := Vector2(120, 30)


func screen_interview(day: int, full_marks: bool) -> void:
	var room: InterviewRoom = main.current
	await wait(0.1)
	await shot("day%d_interview" % day)
	var available: Array = room.cards.filter(func(q: QuestionCard) -> bool: return q.available_for(room.candidate))
	await press(available[0].text_key)
	await wait(0.1)
	await shot("day%d_chief_cut_in" % day)
	await press("让主管问")
	await wait(0.1)
	await shot("day%d_chief_question" % day)
	await press(available[1].text_key)
	await wait(0.1)
	await shot("day%d_candidate_ask" % day)
	for text: String in [GameState.config.candidate_ask.lie, GameState.config.candidate_ask.safe, GameState.config.candidate_ask.truth]:
		var button := _find_button(main.current, "“%s”" % text)
		check(button.size.x <= 296.0, "reply fits panel: " + text)
	await press("“%s”" % GameState.config.candidate_ask.lie)
	await wait(0.1)
	await shot("day%d_scorecard" % day)
	if full_marks:
		for item in InterviewRoom.SCORE_ITEMS:
			room.set_score(item, 5)
	await frames()
	await shot("day%d_scorecard_full" % day)
	await press("录用")


func run() -> void:
	await frames(5)
	print("window=", get_window().size, " visible=", get_viewport().get_visible_rect().size, " content_scale=", get_window().content_scale_size, " focus=", get_window().has_focus())
	await shot("title")
	await press("开始上班")
	check(GameState.day == 1, "day 1")
	var last := GameState.LAST_DAY
	for day in range(1, last + 1):
		await wait(0.35)  # 等早间推送滑入
		await shot("day%d_mail" % day)
		await press("开始筛简历")
		if main.current is BossOffice:
			await shot("day%d_boss_event" % day)
			# 第 1 天的人评分表满分，可以甩给评分表；之后的人只能认错
			if main.current.event.blame:
				await press("“他面试时评分表都是满分。”" if day == 3 else "“是我的判断失误。”")
				await shot("day%d_boss_reply" % day)
			await press("回工位")
		await screen_desk(day)
		if main.current is InterviewRoom:
			await screen_interview(day, day == 1)
		await shot("day%d_report" % day)
		await press("确认")
		await shot("day%d_news" % day)
		await press("第二天" if day < last else "下班回家")
	check(main.current is SliceEnd, "slice end reached")
	check(not GameState.is_bankrupt(), "careful play survives the first mortgage")
	await shot("slice_end")
	check(GameState.hires.size() == last, "one hire a day")
	check(GameState.reply_log.size() == last, "every reply logged")
	check(GameState.lawsuit_risk == 1, "day 3 chief question adds lawsuit risk")
	check(GameState.hires[0].candidate.is_story, "story candidate interviewed first")
	check(GameState.boss_promised_rule, "full scorecard path taken")
	await press("想")
	check(not main.current is SliceEnd, "back to title")
	await shot("title_after")
