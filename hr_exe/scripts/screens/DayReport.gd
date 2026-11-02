class_name DayReport extends Control
## 日结：违规通知单统一在这里出现；可选开销可以不付，代价是家庭状态。

signal finished

var paid := {}
var _total: Label
var settled_net := 0


func _ready() -> void:
	var s := GameState.stats
	UI.panel(self, Rect2(0, 0, 640, 360), UI.DESK_DARK)
	UI.panel(self, Rect2(30, 12, 280, 336), UI.PAPER, UI.BLACK)
	UI.label(self, "日结单 · 第 %d 天" % GameState.day, Vector2(40, 18), UI.INK)
	var y := 40.0
	y = _row("底薪", GameState.BASE_PAY, y)
	y = _row("计件 %d 份" % s.processed, s.processed * GameState.PIECE_PAY, y)
	if s.bonus > 0:
		y = _row("连续正确奖金", s.bonus, y)
	if s.wrong > 0:
		var free := mini(s.wrong, GameState.FREE_WARNINGS)
		y = _row("违规 %d 次（%d 次警告）" % [s.wrong, free], -GameState.fines(), y)
	if s.event_fine > 0:
		y = _row("员工事故", -s.event_fine, y)
	y = _row("房贷", -GameState.MORTGAGE, y)
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
	_total = UI.label(self, "", Vector2(40, 284), UI.INK)
	UI.button(self, "确认", Rect2(40, 316, 260, 24), confirm)
	_build_notice()
	_refresh()


func _row(text: String, amount: int, y: float) -> float:
	UI.label(self, text, Vector2(40, y), UI.INK)
	var value := UI.label(self, "%s¥%d" % ["+" if amount > 0 else "−", absi(amount)], Vector2(220, y), UI.RED if amount < 0 else UI.INK)
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
	if s.unprocessed > 0:
		UI.label(self, "未处理简历 %d 份。" % s.unprocessed, Vector2(336, 306), UI.INK_SOFT)
	UI.label(self, "正确 %d / 已处理 %d" % [s.correct, s.processed], Vector2(336, 324), UI.INK_SOFT)


func _toggle_bill(pressed: bool, id: String) -> void:
	paid[id] = pressed
	_refresh()


func paid_ids() -> Array:
	return paid.keys().filter(func(id: String) -> bool: return paid[id])


func _refresh() -> void:
	var net := GameState.income() - GameState.MORTGAGE
	for bill: Dictionary in GameState.config.bills:
		if paid[bill.id]:
			net -= int(bill.amount)
	_total.text = "今日结余 %+d　→　存款 ¥%d" % [net, GameState.savings + net]


func confirm() -> void:
	settled_net = GameState.settle(paid_ids())
	finished.emit()
