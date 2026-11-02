class_name Desk extends Control
## 筛简历主玩法：限时内对照手册盖章，对错不当场揭晓。

signal finished

const DOC_POS := Vector2(100, 24)
const DAY_START := 9 * 60
const DAY_END := 18 * 60
const GENERIC_REASON := "综合评估后，您与岗位暂不匹配。"

var queue: Array[Candidate] = []
var doc: ResumeDoc
var elapsed := 0.0
var closing := false
var _clock: Label
var _count: Label
var _pile: Control
var _picker: Control
var _hint: Label
var _doc_layer: Control
var _done_count := 0


func _ready() -> void:
	queue = CandidateGenerator.generate_day(GameState.config, RuleEngine.active_rules, GameState.day_seed())
	_build_room()
	_next()


func _build_room() -> void:
	UI.panel(self, Rect2(0, 0, 640, 360), UI.DESK)
	UI.panel(self, Rect2(0, 0, 640, 18), UI.DESK_DARK)
	UI.label(self, "第 %d 天　%s" % [GameState.day, GameState.today], Vector2(6, 1), UI.TEXT_DIM)
	_clock = UI.label(self, "09:00", Vector2(304, 1), UI.GREEN)
	UI.label(self, "存款 ¥%d" % GameState.savings, Vector2(560, 1), UI.TEXT_DIM)

	_pile = Control.new()
	_pile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_pile)
	_count = UI.label(self, "", Vector2(10, 26), UI.TEXT)

	# 日历：算年龄和空窗期用
	var date := DateUtil.parse(GameState.today)
	UI.panel(self, Rect2(540, 24, 92, 64), UI.PAPER, UI.BLACK)
	UI.panel(self, Rect2(540, 24, 92, 16), UI.RED)
	var month := UI.label(self, "%d 年 %d 月" % [date.x, date.y], Vector2(540, 25), UI.PAPER)
	month.size.x = 92
	month.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var day_label := UI.label(self, "%d 日　%s" % [date.z, DateUtil.weekday(GameState.today)], Vector2(540, 50), UI.INK)
	day_label.size.x = 92
	day_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# 处理完的简历飞进这里
	UI.panel(self, Rect2(344, 300, 186, 52), UI.DESK_DARK, UI.BLACK)
	_hint = UI.label(self, "已处理 0", Vector2(352, 304), UI.TEXT_DIM)

	# 咖啡杯：隐形的时间流逝提示
	for i in GameState.day:
		UI.panel(self, Rect2(14 + i * 22, 318, 16, 18), UI.PAPER_DIM, UI.BLACK)
		UI.panel(self, Rect2(16 + i * 22, 320, 12, 4), Color("3a2f2a"))

	var book: Rulebook = load("res://scenes/Rulebook.tscn").instantiate()
	book.position = Vector2(344, 24)
	add_child(book)
	book.setup()

	var calc := CalcWidget.new()
	calc.position = Vector2(540, 94)
	add_child(calc)
	calc.setup()

	_doc_layer = Control.new()
	_doc_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_doc_layer)

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
	create_tween().tween_property(doc, "position", DOC_POS, 0.16).set_trans(Tween.TRANS_QUAD)


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
	var height := 28.0 + 24.0 * (rules.size() + 1)
	var top := 180.0 - height / 2.0
	UI.panel(_picker, Rect2(150, top, 340, height), UI.PAPER, UI.BLACK)
	UI.label(_picker, "选择拒绝理由（将发送给候选人）", Vector2(160, top + 6), UI.INK)
	var y := top + 24.0
	for rule in rules:
		UI.button(_picker, rule.reject_reason_key, Rect2(158, y, 324, 22), commit.bind("reject", rule.id, rule.reject_reason_key))
		y += 24.0
	UI.button(_picker, GENERIC_REASON, Rect2(158, y, 324, 22), commit.bind("reject", &"generic", GENERIC_REASON))


func commit(verdict: String, reason_rule: StringName, reason_text: String) -> void:
	if _picker:
		_picker.queue_free()
		_picker = null
	GameState.record_decision(doc.candidate, verdict, reason_rule, reason_text)
	_done_count += 1
	_hint.text = "已处理 %d" % _done_count
	var leaving := doc
	doc = null
	var tween := create_tween()
	tween.tween_property(leaving, "position", Vector2(400, 330), 0.18).set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(leaving.queue_free)
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
	GameState.stats.unprocessed = queue.size()
	var note := "下班" if queue.is_empty() else "下班。还有 %d 份简历没看，计件没了。" % queue.size()
	UI.panel(self, Rect2(170, 150, 300, 60), UI.BLACK, UI.GREEN_DIM)
	UI.label(self, note, Vector2(182, 158), UI.GREEN, 276)
	UI.button(self, "继续", Rect2(280, 184, 80, 20), finished.emit)
