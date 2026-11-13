extends CanvasLayer
## 试玩用修改器：只在调试运行（编辑器里跑、试玩包的“开始试玩.command”也是）时有，正式导出的包里没有。
## F1 开关面板；F2 当前简历盖对的章；F3 桌上显示答案（含 HireBot 的建议对不对）；F4 冻结桌上的钟；F5 关掉桌上弹出来的事。
## 不改游戏逻辑，只调 GameState / Main / Desk 已有的函数和变量。

const PANEL_RECT := Rect2(4, 4, 312, 352)
const LAST_DAY := 23  # 同 GameState.LAST_DAY

var _root: Control
var _panel: Control
var _status: Label
var _answer: Label
var _list: VBoxContainer
var _day_spin: SpinBox
var _flag_edit: LineEdit
var _freeze_button: Button
var _answer_button: Button
## 冻结时把桌上的钟拉回这个值。
var _frozen_at := -1.0
var _show_answer := false


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.theme = UI.theme()
	_root.size = Vector2(640, 360)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_answer = UI.label(_root, "", Vector2(310, 4), UI.YELLOW, 326)
	_answer.add_theme_color_override("font_outline_color", UI.BLACK)
	_answer.add_theme_constant_override("outline_size", 4)
	_build_panel()
	_panel.visible = false


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	match key.keycode:
		KEY_F1:
			_panel.visible = not _panel.visible
		KEY_F2:
			stamp_correct()
		KEY_F3:
			toggle_answer()
		KEY_F4:
			toggle_freeze()
		KEY_F5:
			close_memo()
		_:
			return
	get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	var desk := _desk()
	if desk and _frozen_at >= 0.0:
		desk.elapsed = _frozen_at
	_answer.text = _answer_text(desk) if _show_answer else ""
	if _panel.visible:
		_status.text = _status_text()


# ---------------------------------------------------------------- 面板

func _build_panel() -> void:
	_panel = UI.panel(_root, PANEL_RECT, Color(UI.BLACK, 0.94), UI.YELLOW)
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	UI.label(_panel, "修改器 F1关 F2盖对章 F3答案 F4停钟 F5关弹窗", Vector2(6, 3), UI.YELLOW)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(4, 20)
	scroll.size = PANEL_RECT.size - Vector2(8, 24)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_panel.add_child(scroll)
	_list = VBoxContainer.new()
	_list.custom_minimum_size.x = scroll.size.x - 12
	_list.add_theme_constant_override("separation", 3)
	scroll.add_child(_list)

	_status = Label.new()
	_status.add_theme_color_override("font_color", UI.TEXT)
	_status.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	_status.custom_minimum_size.x = _list.custom_minimum_size.x
	_list.add_child(_status)

	_section("数值")
	_number_row("存款", "savings", [-1000, -100, 100, 1000])
	_number_row("夫妻感情", "marriage", [-5, -1, 1, 5])
	_number_row("良心", "conscience", [-5, -1, 1, 5])
	_number_row("老板信任", "boss_trust", [-5, -1, 1, 5])
	_number_row("家庭", "family_state", [-5, -1, 1, 5])
	_number_row("诉讼风险", "lawsuit_risk", [-5, -1, 1, 5])
	var sur_row := _row()
	_btn(sur_row, "今天来一件意外支出", func() -> void: GameState.force_surprise())
	_btn(sur_row, "下次赌一把：好", func() -> void: GameState.luck_force = "good")
	_btn(sur_row, "下次：坏", func() -> void: GameState.luck_force = "bad")
	_btn(sur_row, "清零连坏", func() -> void: GameState.luck_streak = 0)

	_section("跳天（从那天早上开始，面试者按前一天的简历补）")
	var row := _row()
	_day_spin = SpinBox.new()
	_day_spin.min_value = 1
	_day_spin.max_value = LAST_DAY
	_day_spin.value = GameState.MONTH3_START
	_day_spin.custom_minimum_size = Vector2(70, 22)
	row.add_child(_day_spin)
	_btn(row, "跳到这天", func() -> void: jump_to_day(int(_day_spin.value)))
	_btn(row, "下一天", func() -> void: jump_to_day(mini(GameState.day + 1, LAST_DAY)))

	_section("跳到今天的某一屏")
	row = _row()
	_btn(row, "晨会邮件", func() -> void: _main_call("start_day"))
	_btn(row, "老板对质", force_boss_event)
	_btn(row, "筛简历", func() -> void: _main_call("show_desk"))
	row = _row()
	_btn(row, "面试", go_interview)
	_btn(row, "日结", func() -> void: _main_call("show_report"))
	row = _row()
	_btn(row, "离职谈话", go_talk)
	_btn(row, "回家", go_home)
	_btn(row, "月末回顾/结尾", go_slice_end)
	_btn(row, "标题", func() -> void: _main_call("show_title"))

	_section("筛简历")
	row = _row()
	_btn(row, "盖对章 F2", stamp_correct)
	_btn(row, "全部盖对", stamp_all)
	_btn(row, "盖错章", stamp_wrong)
	row = _row()
	_answer_button = _btn(row, "显示答案 F3", toggle_answer)
	_freeze_button = _btn(row, "停钟 F4", toggle_freeze)
	_btn(row, "到 15:00", end_screening)

	_section("面试")
	row = _row()
	_btn(row, "用前一天简历补面试者", refill_interviewees)
	_btn(row, "清空面试者", func() -> void: GameState.interviewees.clear())

	_section("家里 / 剧情标记（family 字典）")
	row = _row()
	_btn(row, "信封全收", func() -> void: _set_kickbacks(true))
	_btn(row, "信封全退", func() -> void: _set_kickbacks(false))
	row = _row()
	_btn(row, "小刘：让他投", func() -> void: GameState.family["h5_dad"] = "try")
	_btn(row, "小刘：说不上话", func() -> void: GameState.family["h5_dad"] = "hard")
	row = _row()
	_flag_edit = LineEdit.new()
	_flag_edit.placeholder_text = "标记=选项，选项空着就删掉"
	_flag_edit.custom_minimum_size = Vector2(190, 22)
	row.add_child(_flag_edit)
	_btn(row, "设置", set_flag)

	_section("第三个月（第 17–23 天）")
	row = _row()
	_btn(row, "录用魏来", func() -> void: _fake_hire("story_weilai", "魏来", 17))
	_btn(row, "录用陈默", func() -> void: _fake_hire("story_chenmo_3", "陈默", 13))
	_btn(row, "录用方晓", func() -> void: _fake_hire("story_steady", "方晓", 5))
	row = _row()
	_btn(row, "沈雯：破格", func() -> void: _fake_verdict("story_shenwen", "沈雯", 20, "pass", true))
	_btn(row, "沈雯：拒", func() -> void: _fake_verdict("story_shenwen", "沈雯", 20, "reject", false))
	_btn(row, "周以宁：破格", func() -> void: _fake_verdict("story_zhou_daughter", "周以宁", 8, "pass", true))
	row = _row()
	_btn(row, "替她算补偿", func() -> void: GameState.family["h19_wife"] = "full")
	_btn(row, "加班暗线开", func() -> void: GameState.family["m2_late"] = "yes")
	_btn(row, "盘点表改过", func() -> void: GameState.family["w16_table"] = "fudge")
	row = _row()
	_btn(row, "证据全进抽屉", func() -> void:
		for id: String in ["mail_19", "voice_22", "zhou_book"]:
			GameState.add_evidence(id))
	_btn(row, "清空证据", func() -> void: GameState.evidence.clear())
	_btn(row, "标准耗时清零", func() -> void: GameState.best_pace = 0.0)
	row = _row()
	_btn(row, "关掉弹窗 F5", close_memo)
	_btn(row, "今天谈话全跳过", skip_talks)

	_section("存档")
	row = _row()
	_btn(row, "存当前状态", func() -> void: SaveManager.save_game(GameState.to_dict()))
	_btn(row, "删存档", SaveManager.clear)
	_btn(row, "打印日志", dump_log)


func _section(title: String) -> void:
	var l := Label.new()
	l.text = "— " + title
	l.add_theme_color_override("font_color", UI.GREEN)
	l.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	l.custom_minimum_size.x = _list.custom_minimum_size.x
	_list.add_child(l)


func _row() -> HFlowContainer:
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 3)
	row.add_theme_constant_override("v_separation", 3)
	_list.add_child(row)
	return row


func _btn(parent: Control, text: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size.y = 20
	b.pressed.connect(on_press)
	parent.add_child(b)
	return b


func _number_row(title: String, key: String, steps: Array) -> void:
	var row := _row()
	var l := Label.new()
	l.text = title
	l.custom_minimum_size.x = 56
	l.add_theme_color_override("font_color", UI.TEXT_DIM)
	row.add_child(l)
	for step: int in steps:
		_btn(row, ("%+d" % step), func() -> void: GameState.set(key, int(GameState.get(key)) + step))


func _status_text() -> String:
	var g := GameState
	var screen := _screen()
	var s: Dictionary = g.stats
	var text := "第 %d 天（%d 月第 %d 天）%s · %s\n" % [g.day, g.month(), g.day_in_month(), g.today, screen.get_script().resource_path.get_file().get_basename() if screen else "-"]
	text += "存款 %d　感情 %d　良心 %d　信任 %d\n" % [g.savings, g.marriage, g.conscience, g.boss_trust]
	text += "意外支出：目标线 ¥%d，多出 ¥%d，今天%s\n" % [Surprises.target(g.day), Surprises.surplus(g.day, g.savings), ("有：%s ¥%d" % [g.surprise_today.surprise, g.surprise_today.cost]) if not g.surprise_today.is_empty() else "没有"]
	var lo := Surprises.odds(Surprises.surplus(g.day, g.savings), g.luck_streak)
	text += "赌一把：连坏 %d 次，下次坏 %d%%%s　后账 %s\n" % [g.luck_streak, int(round(lo.bad * 100)), ("（修改器定成 %s）" % g.luck_force) if g.luck_force != "" else "", ", ".join(PackedStringArray(g.surprise_queue.map(func(q: Dictionary) -> String: return "%s→第%d天%s" % [q.id, q.due, q.outcome]))) if not g.surprise_queue.is_empty() else "无"]
	text += "家庭 %d　诉讼 %d　延发奖金 %d　录用 %d\n" % [g.family_state, g.lawsuit_risk, g.deferred_bonus, g.hires.size()]
	text += "今日 处理 %d　对 %d　错 %d　通过 %d　面试者 %d\n" % [s.get("processed", 0), s.get("correct", 0), s.get("wrong", 0), g.passed_today.size(), g.interviewees.size()]
	text += "人效 %d 份　标准耗时 %.1f 分/份　HireBot 档 %d\n" % [g.quota_today(), g.best_pace, g.config.hirebot if g.config else 0]
	text += "抽屉证据 %s　谈话 %d 句（话术 %d）" % [g.evidence, g.talk_log.size(), g.talk_count("lie")]
	return text


# ---------------------------------------------------------------- 流程

func _main() -> Node:
	return get_tree().current_scene


func _screen() -> Node:
	var main := _main()
	return main.get("current") if main else null


func _desk() -> Desk:
	return _screen() as Desk


func _main_call(method: String) -> void:
	_unpause()
	_main().call(method)


## 暂停菜单开着时跳屏，先把它关了，不然树一直停着。
func _unpause() -> void:
	var menu = _main().get("menu")
	if is_instance_valid(menu):
		menu.close()
	get_tree().paused = false


## 从标题直接跳：先按对应的月份开一局。
func _ensure_run(target_day: int) -> void:
	if GameState.run_seed != 0:
		return
	if target_day >= GameState.MONTH3_START:
		GameState.new_game_month3({})
	elif target_day >= GameState.MONTH2_START:
		GameState.new_game_month2(false, "try")
	else:
		GameState.new_game()


func jump_to_day(target_day: int) -> void:
	_ensure_run(target_day)
	GameState.day = target_day
	GameState.begin_day()
	refill_interviewees()
	_frozen_at = -1.0
	_main_call("start_day")


## 前一天的简历堆里，按前一天的规则能过的人，就是今天来面试的人（剧情人物算在里面）。
func refill_interviewees() -> void:
	var g := GameState
	if g.day <= 1 or g.day_in_month() == 1:
		g.interviewees.clear()
		return
	var prev := g.day - 1
	RuleEngine.set_day(prev)
	var pile := CandidateGenerator.generate_day(RuleEngine.load_day(prev), RuleEngine.active_rules, hash([g.run_seed, prev]))
	var passed: Array[Candidate] = []
	var used := {}
	for c in pile:
		if RuleEngine.evaluate(c).pass:
			# 按组招的那天：放进对得上、还有名额的组里放得最少的那个；都满了就当没过
			var fits := RuleEngine.fitting_folders(c).filter(func(p: JobPosting) -> bool: return int(used.get(p.title, 0)) < p.hc)
			if RuleEngine.folder_mode:
				if fits.is_empty():
					continue
				fits.sort_custom(func(a: JobPosting, b: JobPosting) -> bool: return int(used.get(a.title, 0)) < int(used.get(b.title, 0)))
				var p: JobPosting = fits[0]
				used[p.title] = int(used.get(p.title, 0)) + 1
				var placed: Candidate = c.duplicate()
				placed.folder = p.resource_path
				passed.append(placed)
			else:
				passed.append(c)
	RuleEngine.set_day(g.day)
	g.interviewees = passed


func go_interview() -> void:
	if GameState.interviewees.is_empty():
		refill_interviewees()
	if GameState.interviewees.is_empty():
		push_warning("修改器：今天没有面试者（月初第一天，或前一天没人过）")
		return
	GameState.interviewed_today = []
	GameState.sessions = []
	GameState.stats.clock = 0
	_unpause()
	var main := _main()
	main.call("_swap", "res://scenes/InterviewRoom.tscn", Callable(main, "_after_interview"))


func go_talk() -> void:
	if GameState.next_talk_index() < 0:
		push_warning("修改器：今天（第 %d 天）没有还没谈的离职谈话" % GameState.day)
		return
	_unpause()
	var main := _main()
	main.call("_swap", "res://scenes/ExitTalk.tscn", Callable(main, "_after_interviews"))


## 今天的谈话都当谈过（签了）。
func skip_talks() -> void:
	while GameState.next_talk_index() >= 0:
		var t := GameState.next_talk()
		GameState.stats.talks.append({"id": t.id, "name": t.name, "outcome": "signed"})


## 关掉桌上弹出来的事（不选，当没发生；那件事今天不会再弹）。
func close_memo() -> void:
	var desk := _desk()
	if desk and desk.get("_memo"):
		desk._memo.queue_free()
		desk._memo = null


## 假装那天录用了这个人（剧情分支用）。
func _fake_hire(id: String, display_name: String, on_day: int) -> void:
	if GameState.hires.any(func(h: Dictionary) -> bool: return String(h.candidate.id) == id):
		return
	var c := Candidate.new()
	c.id = StringName(id)
	c.display_name = display_name
	c.portrait_seed = hash(id)
	c.ability = 85
	c.loyalty = 80
	GameState.hires.append({"candidate": c.to_dict(), "day_hired": on_day, "scorecard": {"狼性": 3, "格局": 3, "稳定性": 3, "颜值": 3}, "promise": "",
		"event_resolved": true, "retention_due": on_day, "chief_pick": false})


## 假装那天这样判过这个人（写一条决策日志）。
func _fake_verdict(id: String, display_name: String, on_day: int, verdict: String, exception: bool) -> void:
	GameState.decision_log.append({"day": on_day, "candidate_id": id, "candidate_name": display_name, "verdict": verdict,
		"reason_rule": "generic" if verdict == "reject" else "", "reason_text": Desk.GENERIC_REASON if verdict == "reject" else "",
		"expected": "reject", "failed_rules": [], "violated_rule": verdict == "pass", "exception": exception})


func go_home() -> void:
	if GameState.config.home_scene.is_empty():
		push_warning("修改器：今天（第 %d 天）没有回家那一幕" % GameState.day)
		return
	_unpause()
	var main := _main()
	main.call("_swap", "res://scenes/HomeScreen.tscn", Callable(main, "next_day"))


func go_slice_end() -> void:
	if not GameState.is_month_end() and GameState.day < LAST_DAY:
		push_warning("修改器：月末回顾只在第 9、16、23 天；先跳到那天")
		return
	_unpause()
	_main().call("next_day")


## 让所有录用的人今天满期，老板对质那一屏就会出来（没人可满期时出“没招人”的那场，或者什么都没有）。
func force_boss_event() -> void:
	for h: Dictionary in GameState.hires:
		if not h.event_resolved:
			h.retention_due = GameState.day
	_unpause()
	_main().call("_after_mail")


# ---------------------------------------------------------------- 筛简历

func _expected(c: Candidate) -> Dictionary:
	var result := RuleEngine.evaluate(c)
	if result.pass and RuleEngine.folder_mode:
		var open := RuleEngine.fitting_folders(c).filter(func(p: JobPosting) -> bool: return not GameState.folder_full(p))
		if open.is_empty():
			return {"verdict": "reject", "rule": &"generic", "reason": Desk.GENERIC_REASON, "why": "拒绝：能进的组都满了"}
		var teams := PackedStringArray(open.map(func(p: JobPosting) -> String: return p.team))
		return {"verdict": "pass", "folder": open[0], "rule": &"", "reason": "", "why": "放进 " + " / ".join(teams)}
	if result.pass:
		return {"verdict": "pass", "rule": &"", "reason": "", "why": "通过"}
	var rule: Rule = result.failed[0]
	var titles: Array = result.failed.map(func(r: Rule) -> String: return r.title_key)
	# 口头规则没有自己的拒绝理由：用万能那句
	if rule.hidden:
		return {"verdict": "reject", "rule": &"generic", "reason": Desk.GENERIC_REASON, "why": "拒绝：" + "、".join(PackedStringArray(titles))}
	return {"verdict": "reject", "rule": rule.id, "reason": rule.reject_reason_key, "why": "拒绝：" + "、".join(PackedStringArray(titles))}


func _answer_text(desk: Desk) -> String:
	if not desk or not desk.doc:
		return ""
	var c := desk.doc.candidate
	var text := "【答案】%s　%s" % [c.display_name, _expected(c).why]
	if c.is_story:
		text += "　（剧情：%s）" % c.id
	if not c.envelope.is_empty():
		text += "　有信封 ¥%s" % c.envelope.get("amount", 0)
	if GameState.config.hirebot > 0 and not c.is_intern:
		var bot := HireBot.suggest(c)
		text += "　HireBot %s（%s）" % ["说对了" if bot.pass == RuleEngine.evaluate(c).pass else "说错了", bot.why]
	return text


func _can_stamp(desk: Desk) -> bool:
	return desk != null and desk.doc != null and not desk.arranging


func stamp_correct() -> void:
	var desk := _desk()
	if not _can_stamp(desk):
		return
	var e := _expected(desk.doc.candidate)
	if e.has("folder"):
		desk.file_into(e.folder)
	else:
		desk.commit(e.verdict, e.rule, e.reason)


func stamp_wrong() -> void:
	var desk := _desk()
	if not _can_stamp(desk):
		return
	if _expected(desk.doc.candidate).verdict == "pass":
		desk.commit("reject", &"generic", Desk.GENERIC_REASON)
	elif RuleEngine.folder_mode:
		var open := RuleEngine.folders().filter(func(p: JobPosting) -> bool: return not GameState.folder_full(p))
		if not open.is_empty():
			desk.file_into(open[0])
	else:
		desk.commit("pass", &"", "")


func stamp_all() -> void:
	var desk := _desk()
	while _can_stamp(desk) and not desk.closing:
		stamp_correct()


func toggle_answer() -> void:
	_show_answer = not _show_answer
	_answer_button.text = ("隐藏答案" if _show_answer else "显示答案") + " F3"


func toggle_freeze() -> void:
	var desk := _desk()
	if _frozen_at >= 0.0:
		_frozen_at = -1.0
	elif desk:
		_frozen_at = desk.elapsed
	_freeze_button.text = ("走钟" if _frozen_at >= 0.0 else "停钟") + " F4"


func end_screening() -> void:
	var desk := _desk()
	if desk:
		_frozen_at = -1.0
		_freeze_button.text = "停钟 F4"
		desk.elapsed = GameState.config.screening_seconds


# ---------------------------------------------------------------- 标记

func _set_kickbacks(taken: bool) -> void:
	for k: Dictionary in GameState.kickbacks:
		k.taken = taken


func set_flag() -> void:
	var text := _flag_edit.text.strip_edges()
	if "=" not in text:
		return
	var key := text.get_slice("=", 0).strip_edges()
	var value := text.get_slice("=", 1).strip_edges()
	if value == "":
		GameState.family.erase(key)
	else:
		GameState.family[key] = value
	_flag_edit.text = ""


## 打到 Godot 的输出面板，方便对照剧情分支。
func dump_log() -> void:
	print("=== 修改器 · 第 %d 天 ===" % GameState.day)
	print("family: ", JSON.stringify(GameState.family))
	print("kickbacks: ", JSON.stringify(GameState.kickbacks))
	for h: Dictionary in GameState.hires:
		print("hire: %s 第%d天 满期%d 已结算=%s" % [h.candidate.display_name, h.day_hired, GameState.retention_due(h), h.event_resolved])
	for entry: Dictionary in GameState.decision_log.slice(-20):
		print("D%d %s %s（应 %s）%s" % [entry.day, entry.candidate_name, entry.verdict, entry.expected, entry.reason_text])
