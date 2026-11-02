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
	UI.label(self, "Daily statement · Day %d" % GameState.day, Vector2(40, 18), UI.INK)
	var y := 40.0
	y = _row("Base pay", GameState.BASE_PAY, y)
	y = _row("Piece pay × %d" % s.processed, s.processed * GameState.PIECE_PAY, y)
	if s.bonus > 0:
		y = _row("Accuracy bonus", s.bonus, y)
	if s.wrong > 0:
		var free := mini(s.wrong, GameState.FREE_WARNINGS)
		y = _row("Violations %d (%d warned)" % [s.wrong, free], -GameState.fines(), y)
	if s.event_fine > 0:
		y = _row("Employee incident", -s.event_fine, y)
	if GameState.legal_fine() > 0:
		y = _row("EEOC settlement", -GameState.legal_fine(), y)
	y = _row("Rent", -GameState.MORTGAGE, y)
	y += 6.0
	for bill: Dictionary in GameState.config.bills:
		paid[bill.id] = true
		var box := CheckBox.new()
		box.text = "%s  −%s%d" % [bill.label, GameState.CURRENCY, bill.amount]
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
	UI.button(self, "Confirm", Rect2(40, 316, 260, 24), confirm)
	_build_notice()
	_refresh()


func _row(text: String, amount: int, y: float) -> float:
	UI.label(self, text, Vector2(40, y), UI.INK)
	var value := UI.label(self, "%s%s%d" % ["+" if amount > 0 else "−", GameState.CURRENCY, absi(amount)], Vector2(220, y), UI.RED if amount < 0 else UI.INK)
	value.size.x = 80
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	return y + 18.0


func _build_notice() -> void:
	var s := GameState.stats
	UI.panel(self, Rect2(326, 12, 284, 336), UI.PAPER_DIM, UI.BLACK)
	UI.label(self, "Violation notice", Vector2(336, 18), UI.RED)
	var y := 40.0
	if s.errors.is_empty():
		UI.label(self, "No violations today. Keep it up.", Vector2(336, y), UI.INK)
	for error: Dictionary in s.errors.slice(0, 8):
		UI.label(self, error.name + " —— " + error.why, Vector2(336, y), UI.INK, 266)
		y += 32.0
	if s.errors.size() > 8:
		UI.label(self, "...and %d more" % (s.errors.size() - 8), Vector2(336, y), UI.INK_SOFT)
	for flag: String in s.legal_flags:
		y += 4.0
		UI.label(self, "Legal: “%s”\nPlease don't ask that." % flag, Vector2(336, y), UI.RED, 266)
		y += 44.0
	if GameState.legal_fine() > 0:
		UI.label(self, "EEOC charge filed. Company settled. Guess whose budget.", Vector2(336, 276), UI.RED, 266)
	if s.unprocessed > 0:
		UI.label(self, "%d resumes unprocessed." % s.unprocessed, Vector2(336, 306), UI.INK_SOFT)
	UI.label(self, "Correct %d / processed %d" % [s.correct, s.processed], Vector2(336, 324), UI.INK_SOFT)


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
	_total.text = "Today %+d  →  savings %s%d" % [net, GameState.CURRENCY, GameState.savings + net]


func confirm() -> void:
	settled_net = GameState.settle(paid_ids())
	finished.emit()
