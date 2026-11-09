class_name DayReport extends Control
## 日结：违规通知单统一在这里出现；可选开销可以不付，代价是家庭状态。

signal finished

var paid := {}
var _total: Label
var _mortgage_label: Label
var _mortgage_bar: Panel
var settled_net := 0


func _ready() -> void:
	var s := GameState.stats
	UI.panel(self, Rect2(0, 0, 640, 360), UI.DESK_DARK)
	UI.panel(self, Rect2(30, 12, 280, 336), UI.PAPER, UI.BLACK)
	UI.label(self, "日结单 · 第 %d 天" % GameState.day, Vector2(40, 18), UI.INK)
	var y := 40.0
	var pay := GameState.pay
	y = _row("底薪", int(pay.base), y)
	y = _row("绩效 %d 份 × ¥%d" % [s.processed, pay.per_resume], GameState.performance_pay(), y)
	y = _row("判对 %d 份 × ¥%d" % [s.correct, pay.per_correct], GameState.judge_bonus(), y)
	for r: Dictionary in s.retained:
		if r.left:
			y = _row("留任 %s：已离职" % r.name, 0, y)
		elif pay.retention_deferred:
			y = _row("留任 %s 满 %d 天（延发）" % [r.name, r.days], 0, y)
		else:
			y = _row("留任 %s 满 %d 天" % [r.name, r.days], int(pay.retention), y)
	if s.wrong > 0:
		if GameState.fines_on():
			var free := mini(s.wrong, GameState.FREE_WARNINGS)
			y = _row("违规 %d 次（%d 次警告）" % [s.wrong, free], -GameState.fines(), y)
		else:
			y = _row("违规 %d 次（本月不罚款）" % s.wrong, 0, y)
	if s.event_fine > 0:
		y = _row("员工事故", -s.event_fine, y)
	if GameState.is_month_end():
		y = _row("房贷（月供）", -GameState.MORTGAGE, y)
	y += 6.0
	for bill: Dictionary in GameState.config.bills:
		paid[bill.id] = true
		var box := CheckBox.new()
		box.text = "%s  −¥%d" % [bill.label, bill.amount]
		box.button_pressed = true
		box.position = Vector2(38, y)
		box.focus_mode = Control.FOCUS_NONE
		box.add_theme_color_override("font_color", UI.INK)
		box.add_theme_color_override("font_pressed_color", UI.INK)
		box.add_theme_color_override("font_hover_color", UI.INK)
		box.add_theme_color_override("font_hover_pressed_color", UI.INK)
		box.toggled.connect(_toggle_bill.bind(bill.id))
		add_child(box)
		y += 24.0
	_mortgage_label = UI.label(self, "", Vector2(40, 244), UI.INK)
	UI.panel(self, Rect2(40, 262, 260, 10), UI.PAPER_DIM, UI.INK_SOFT)
	_mortgage_bar = UI.panel(self, Rect2(41, 263, 0, 8), UI.GREEN_DIM)
	_total = UI.label(self, "", Vector2(40, 284), UI.INK)
	UI.button(self, "确认", Rect2(40, 316, 260, 24), confirm)
	_build_notice()
	_refresh()


func _row(text: String, amount: int, y: float) -> float:
	UI.label(self, text, Vector2(40, y), UI.INK)
	var prefix := "+" if amount > 0 else ("−" if amount < 0 else "")
	var value := UI.label(self, "%s¥%d" % [prefix, absi(amount)], Vector2(220, y), UI.RED if amount < 0 else UI.INK)
	value.size.x = 80
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	return y + 18.0


func _build_notice() -> void:
	var s := GameState.stats
	UI.panel(self, Rect2(326, 12, 284, 336), UI.PAPER_DIM, UI.BLACK)
	UI.label(self, "违规通知单", Vector2(336, 18), UI.RED)
	var y := 40.0
	if s.errors.is_empty():
		UI.label(self, "今日无违规。继续保持。", Vector2(336, y), UI.INK)
	for error: Dictionary in s.errors.slice(0, 8):
		UI.label(self, error.name + " —— " + error.why, Vector2(336, y), UI.INK, 266)
		y += 32.0
	if s.errors.size() > 8:
		UI.label(self, "……另有 %d 条" % (s.errors.size() - 8), Vector2(336, y), UI.INK_SOFT)
	var pending := GameState.pending_hires()
	if not pending.is_empty():
		# 只是让玩家知道，不进今天的收入
		var due := pending.map(func(h: Dictionary) -> String: return "%s 第 %d 天" % [h.candidate.display_name, GameState.retention_due(h)])
		UI.label(self, "在路上：留任奖金（%s 满期）" % "、".join(PackedStringArray(due)), Vector2(336, 270), UI.INK_SOFT, 266)
	if not GameState.passed_today.is_empty() and GameState.day < GameState.LAST_DAY:
		UI.label(self, "今天通过 %d 人，约明天面试。" % GameState.passed_today.size(), Vector2(336, 288), UI.INK_SOFT)
	if s.unprocessed > 0:
		UI.label(self, "未处理简历 %d 份。" % s.unprocessed, Vector2(336, 306), UI.INK_SOFT)
	UI.label(self, "正确 %d / 已处理 %d" % [s.correct, s.processed], Vector2(336, 324), UI.INK_SOFT)


func _toggle_bill(pressed: bool, id: String) -> void:
	paid[id] = pressed
	_refresh()


func paid_ids() -> Array:
	return paid.keys().filter(func(id: String) -> bool: return paid[id])


func _refresh() -> void:
	var net := GameState.income() - GameState.mortgage_today()
	for bill: Dictionary in GameState.config.bills:
		if paid[bill.id]:
			net -= int(bill.amount)
	var after := GameState.savings + net
	_total.text = "今日结余 %+d　→　存款 ¥%d" % [net, after]
	# 进度条：手里的钱够不够这个月的月供
	var funds := after + GameState.mortgage_today()
	var short := GameState.MORTGAGE - funds
	if GameState.is_month_end():
		_mortgage_label.text = "今天还月供 ¥%d" % GameState.MORTGAGE + ("　还差 ¥%d" % short if short > 0 else "")
	else:
		_mortgage_label.text = "距月底还房贷 %d 天　" % GameState.days_to_mortgage() + ("还差 ¥%d" % short if short > 0 else "已够月供")
	_mortgage_label.add_theme_color_override("font_color", UI.RED if short > 0 else UI.INK)
	_mortgage_bar.size.x = 258.0 * clampf(float(funds) / GameState.MORTGAGE, 0.0, 1.0)
	_mortgage_bar.get_theme_stylebox("panel").bg_color = UI.RED if short > 0 else UI.GREEN_DIM


func confirm() -> void:
	settled_net = GameState.settle(paid_ids())
	finished.emit()
