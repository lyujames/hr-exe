class_name Desk extends Control
## 筛简历主玩法：限时内对照手册盖章，对错不当场揭晓。

signal finished

const DOC_POS := Vector2(100, 24)
## 身份证落在规则手册下面，从桌子下沿推上来，不挡简历。
const ID_POS := Vector2(350, 246)
const DAY_START := 9 * 60
const DAY_END := 18 * 60
const GENERIC_REASON := "综合评估后，您与岗位暂不匹配。"
const MISMATCH_REASON := "您提交的材料信息前后不一致。"
## 质询的代价，扣桌上的钟（分钟）：点了两处其实没问题、打一通电话。
const WRONG_PICK_MINUTES := 10
const CALL_MINUTES := 20

var queue: Array[Candidate] = []
var doc: ResumeDoc
var id_card: IdCardDoc
var elapsed := 0.0
var closing := false
var _clock: Label
var _count: Label
var _pile: Control
var _picker: Control
var _hint: Label
var _doc_layer: Control
var _done_count := 0
## 质询：桌上有身份证以后才有这个开关。
var inspecting := false
## 这份简历上标出的矛盾字段，和打电话听到的解释 {text, truthful}。
var flagged: Array[String] = []
var call_result := {}
var _lines: InspectLines
var _inspect_button: Button
var _call_button: Button
var _phone: Control
var _toast: Label
var _toast_tween: Tween
var _slip: Control


func _ready() -> void:
	queue = CandidateGenerator.generate_day(GameState.config, RuleEngine.active_rules, GameState.day_seed())
	_build_room()
	_next()


func _build_room() -> void:
	UI.panel(self, Rect2(0, 0, 640, 360), UI.DESK)
	UI.panel(self, Rect2(0, 0, 640, 18), UI.DESK_DARK)
	UI.label(self, "第 %d 天　%s" % [GameState.day, GameState.today], Vector2(6, 1), UI.TEXT_DIM)
	_clock = UI.label(self, "09:00", Vector2(304, 1), UI.GREEN)
	UI.label(self, "存款 ¥%d / 月供 ¥%d" % [GameState.savings, GameState.MORTGAGE], Vector2(496, 1), UI.TEXT_DIM)

	_pile = Control.new()
	_pile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_pile)
	_count = UI.label(self, "", Vector2(10, 26), UI.TEXT)

	# 处理完的简历飞进这里
	UI.panel(self, Rect2(344, 322, 186, 32), UI.DESK_DARK, UI.BLACK)
	_hint = UI.label(self, "已处理 0", Vector2(352, 326), UI.TEXT_DIM)

	# 咖啡杯：隐形的时间流逝提示
	for i in GameState.day:
		UI.panel(self, Rect2(14 + i * 22, 318, 16, 18), UI.PAPER_DIM, UI.BLACK)
		UI.panel(self, Rect2(16 + i * 22, 320, 12, 4), Color("3a2f2a"))

	var book: Rulebook = load("res://scenes/Rulebook.tscn").instantiate()
	book.position = Vector2(344, 24)
	add_child(book)
	book.setup()

	if GameState.job_posting:
		var posting := JobPostingDoc.new()
		posting.position = Vector2(532, 24)
		add_child(posting)
		posting.setup(GameState.job_posting)

	_doc_layer = Control.new()
	_doc_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_doc_layer)
	_lines = InspectLines.new()
	add_child(_lines)
	_toast = UI.label(self, "", Vector2(150, 1), UI.YELLOW)
	if "id_card" in RuleEngine.active_docs:
		_inspect_button = UI.button(self, "质询", Rect2(536, 296, 60, 22), toggle_inspect)
		_call_button = UI.button(self, "打电话", Rect2(536, 322, 60, 22), call_candidate)
		_call_button.visible = false

	for verdict: String in ["pass", "reject"]:
		var stamp := StampTool.new()
		stamp.position = Vector2(112 if verdict == "pass" else 216, 306)
		add_child(stamp)
		stamp.setup(verdict)


func _process(delta: float) -> void:
	if closing:
		return
	elapsed += delta
	var ratio := elapsed / GameState.config.screening_seconds
	var minutes := int(lerpf(DAY_START, DAY_END, minf(ratio, 1.0)))
	_clock.text = "%02d:%02d" % [minutes / 60, minutes % 60]
	if minutes >= DAY_END - 60:
		_clock.add_theme_color_override("font_color", UI.RED)
	if ratio >= 1.0:
		_close_day()


func _next() -> void:
	_draw_pile()
	if queue.is_empty():
		_close_day()
		return
	doc = load("res://scenes/ResumeDoc.tscn").instantiate()
	doc.position = Vector2(-240, DOC_POS.y)
	_doc_layer.add_child(doc)
	doc.setup(queue.pop_front())
	doc.stamped.connect(_on_stamped)
	Sfx.paper()
	var tween := create_tween().set_parallel()
	tween.tween_property(doc, "position", DOC_POS, 0.16).set_trans(Tween.TRANS_QUAD)
	if "id_card" in doc.candidate.docs:
		id_card = IdCardDoc.new()
		id_card.position = Vector2(ID_POS.x, 370)
		_doc_layer.add_child(id_card)
		id_card.setup(doc.candidate)
		tween.tween_property(id_card, "position", ID_POS, 0.2).set_trans(Tween.TRANS_QUAD)
	for d: DraggableDoc in [doc, id_card]:
		if d:
			d.field_picked.connect(pick_field)
			d.set_inspecting(inspecting)


func _draw_pile() -> void:
	UI.clear(_pile)
	_count.text = "待处理 %d" % queue.size()
	for i in mini(queue.size(), 16):
		UI.panel(_pile, Rect2(14, 262 - i * 3, 70, 8), UI.PAPER if i % 2 == 0 else UI.PAPER_DIM, UI.INK_SOFT)


func _on_stamped(verdict: String, _at: Vector2) -> void:
	Sfx.stamp()
	_shake()
	if verdict == "pass":
		commit("pass", &"", "")
	else:
		_open_picker()


func _shake() -> void:
	var tween := create_tween()
	tween.tween_property(self, "position", Vector2(0, 3), 0.03)
	tween.tween_property(self, "position", Vector2.ZERO, 0.08)


## 拒绝时必须选一条理由，这句话写进决策日志，终章原样回到玩家身上。
func _open_picker() -> void:
	_picker = Control.new()
	add_child(_picker)
	_picker.size = size
	UI.panel(_picker, Rect2(0, 0, 640, 360), Color(0, 0, 0, 0.35)).mouse_filter = Control.MOUSE_FILTER_STOP
	var rules := RuleEngine.active_rules
	var mismatch := 0 if flagged.is_empty() else 1
	var height := 28.0 + 24.0 * (rules.size() + 2 + mismatch)
	var top := 180.0 - height / 2.0
	UI.panel(_picker, Rect2(150, top, 340, height), UI.PAPER, UI.BLACK)
	UI.label(_picker, "选择拒绝理由（将发送给候选人）", Vector2(160, top + 6), UI.INK)
	var y := top + 24.0
	# 质询标出过矛盾才有这一条，排第一：刚抓到的就是它
	if mismatch:
		UI.button(_picker, MISMATCH_REASON, Rect2(158, y, 324, 22), commit.bind("reject", &"mismatch", MISMATCH_REASON))
		y += 24.0
	for rule in rules:
		UI.button(_picker, rule.reject_reason_key, Rect2(158, y, 324, 22), commit.bind("reject", rule.id, rule.reject_reason_key))
		y += 24.0
	UI.button(_picker, GENERIC_REASON, Rect2(158, y, 324, 22), commit.bind("reject", &"generic", GENERIC_REASON))
	y += 24.0
	UI.button(_picker, "← 返回，再看看", Rect2(158, y, 324, 22), _cancel_reject)


## 反悔：关掉理由框、擦掉拒绝章，这份简历回到桌上。下班铃已经响了就直接下班。
func _cancel_reject() -> void:
	_picker.queue_free()
	_picker = null
	doc.unstamp()
	if closing:
		_finish()


func commit(verdict: String, reason_rule: StringName, reason_text: String) -> void:
	if _picker:
		_picker.queue_free()
		_picker = null
	var extra := {}
	if not flagged.is_empty():
		extra = {"flagged": flagged.duplicate(), "called": not call_result.is_empty(), "explanation_truthful": call_result.get("truthful")}
	var why := GameState.record_decision(doc.candidate, verdict, reason_rule, reason_text, extra)
	if why != "" and GameState.instant_notice():
		_print_slip(doc.candidate.display_name, why)
	_reset_inspect()
	_done_count += 1
	_hint.text = "已处理 %d" % _done_count
	for leaving: Control in [doc, id_card]:
		if leaving:
			var tween := create_tween()
			tween.tween_property(leaving, "position", Vector2(400, 330), 0.18).set_trans(Tween.TRANS_QUAD)
			tween.tween_callback(leaving.queue_free)
	doc = null
	id_card = null
	if closing:
		_finish()
	else:
		_next()


func _close_day() -> void:
	if closing:
		return
	closing = true
	if _picker:
		return  # 等玩家选完理由
	_finish()


func _finish() -> void:
	if doc:
		doc.queue_free()
		doc = null
		queue.append(null)
	if id_card:
		id_card.queue_free()
		id_card = null
	_reset_inspect()
	if _inspect_button:
		_inspect_button.disabled = true
	GameState.stats.unprocessed = queue.size()
	var note := "下班" if queue.is_empty() else "下班。还有 %d 份简历没看，计件没了。" % queue.size()
	UI.panel(self, Rect2(170, 150, 300, 60), UI.BLACK, UI.GREEN_DIM)
	UI.label(self, note, Vector2(182, 158), UI.GREEN, 276)
	UI.button(self, "继续", Rect2(280, 184, 80, 20), finished.emit)


## 教学期：盖错章，打印机当场从桌边吐一张违规单。点一下扔掉；下一张来了旧的就收走。
func _print_slip(who: String, why: String) -> void:
	if _slip:
		_slip.queue_free()
	var slip := Control.new()
	slip.size = Vector2(106, 104)
	slip.position = Vector2(640, 182)
	slip.mouse_filter = Control.MOUSE_FILTER_STOP
	slip.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	add_child(slip)  # 先入树，换行宽度才生效
	UI.panel(slip, Rect2(Vector2(2, 2), slip.size), UI.BLACK)
	UI.panel(slip, Rect2(Vector2.ZERO, slip.size), UI.PAPER, UI.INK_SOFT)
	UI.panel(slip, Rect2(0, 0, slip.size.x, 16), UI.RED)
	UI.label(slip, "违规通知", Vector2(6, 1), UI.PAPER)
	UI.label(slip, who, Vector2(6, 20), UI.INK)
	UI.label(slip, why, Vector2(6, 36), UI.INK, 96)
	var cost := "第 3 次起罚款" if GameState.fines_on() else "本月不扣钱，这份绩效少拿 ¥%d" % int(GameState.pay.per_correct)
	UI.label(slip, cost, Vector2(6, 68), UI.INK_SOFT, 96)
	slip.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			var away := create_tween()
			away.tween_property(slip, "position:x", 660.0, 0.15)
			away.tween_callback(slip.queue_free))
	_slip = slip
	var tween := create_tween()
	tween.tween_interval(0.2)  # 让盖章声先响完
	tween.tween_callback(Sfx.printer)
	tween.tween_property(slip, "position:x", 532.0, 0.5)


func toggle_inspect() -> void:
	inspecting = not inspecting
	_inspect_button.text = "质询中" if inspecting else "质询"
	_lines.picked = []
	for d: DraggableDoc in [doc, id_card]:
		if d:
			d.set_inspecting(inspecting)
	if inspecting:
		_show_toast("点两份材料上的同一项", UI.YELLOW)


## 先点一份材料上的一行，再点另一份上的同一项：值不一样就画红线，一样就白扣钟点。
func pick_field(d: DraggableDoc, key: String) -> void:
	if _lines.picked.is_empty() or _lines.picked[0] == d:
		_lines.picked = [d, key]
		return
	var first: DraggableDoc = _lines.picked[0]
	var first_key: String = _lines.picked[1]
	_lines.picked = []
	if key == first_key and _shown(first, key) != _shown(d, key):
		if key not in flagged:
			flagged.append(key)
			_lines.links.append([first, key, d, key])
		Sfx.paper()
		_show_toast("对不上！", UI.RED)
		_call_button.visible = call_result.is_empty()
		return
	_spend(WRONG_PICK_MINUTES)
	_show_toast(("这两处没问题" if key == first_key else "这两项比不了") + "　−%d 分钟" % WRONG_PICK_MINUTES, UI.TEXT)


## 材料上印的那一项。简历只印到出生年月，所以只比年月。
func _shown(d: DraggableDoc, key: String) -> String:
	var c: Candidate = d.get("candidate")
	var value := str(c.fact(key, "id_card" if d is IdCardDoc else "resume"))
	return value.left(7) if key == "birth_date" else value


## 打电话核实：扣钟点，候选人给一句解释。解释不改判定，只透露这个人诚不诚实。
func call_candidate() -> void:
	if flagged.is_empty() or not call_result.is_empty():
		return
	_spend(CALL_MINUTES)
	_show_toast("−%d 分钟" % CALL_MINUTES, UI.TEXT)
	var c := doc.candidate
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([GameState.day_seed(), c.id])
	var source: Discrepancy = Discrepancy.new()
	for d in RuleEngine.active_discrepancies:
		if d.field in flagged:
			source = d
			break
	call_result = source.explain(c, rng)
	_call_button.visible = false
	_phone = Control.new()
	add_child(_phone)
	UI.panel(_phone, Rect2(110, 218, 220, 76), UI.BLACK, UI.GREEN_DIM)
	UI.label(_phone, "电话　" + c.fact("display_name") + "：", Vector2(118, 222), UI.GREEN)
	UI.label(_phone, "“%s”" % call_result.text, Vector2(118, 238), UI.TEXT, 204)
	UI.button(_phone, "挂断", Rect2(284, 274, 40, 18), _hang_up)
	Sfx.key()


func _hang_up() -> void:
	if _phone:
		_phone.queue_free()
		_phone = null


func _reset_inspect() -> void:
	flagged = []
	call_result = {}
	_lines.clear()
	_hang_up()
	if _call_button:
		_call_button.visible = false


## 桌上的钟往前拨：DAY_START–DAY_END 对应 screening_seconds 真实秒数。
func _spend(minutes: int) -> void:
	elapsed += minutes / float(DAY_END - DAY_START) * GameState.config.screening_seconds


func _show_toast(text: String, color: Color) -> void:
	_toast.text = text
	_toast.add_theme_color_override("font_color", color)
	if _toast_tween:
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_interval(2.5)
	_toast_tween.tween_callback(func() -> void: _toast.text = "")
