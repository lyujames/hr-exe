class_name BossOffice extends Control
## 老板对质与甩锅。优秀员工的事件只是一封邮件，功劳记在老板名下。

signal finished

const BOSS_SEED := 1984

var event: Dictionary
var _options: Control
var _reply: Label


func setup(data: Dictionary) -> void:
	event = data
	EventBus.employee_event.emit(event)
	UI.panel(self, Rect2(0, 0, 640, 360), UI.WALL)
	UI.panel(self, Rect2(0, 250, 640, 110), UI.DESK)
	var boss := PortraitView.new()
	boss.setup(BOSS_SEED, 2)
	boss.position = Vector2(60, 122)
	add_child(boss)
	UI.label(self, "王总", Vector2(108, 254), UI.TEXT_DIM)
	UI.panel(self, Rect2(214, 40, 390, 118), UI.PAPER, UI.BLACK)
	UI.label(self, event.title, Vector2(226, 48), UI.RED if event.fine > 0 else UI.INK)
	UI.label(self, event.body, Vector2(226, 70), UI.INK, 366)
	_reply = UI.label(self, "", Vector2(226, 136), UI.INK_SOFT, 366)
	_options = Control.new()
	_options.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_options)
	if event.blame:
		UI.button(_options, "“这是规则要求的。”", Rect2(214, 170, 390, 24), choose.bind("rule"))
		UI.button(_options, "“是我的判断失误。”", Rect2(214, 198, 390, 24), choose.bind("own"))
		UI.button(_options, "“他面试时评分表都是满分。”", Rect2(214, 226, 390, 24), choose.bind("scorecard"))
	else:
		GameState.stats.event_fine += event.fine
		_show_close()


func choose(choice: String) -> void:
	_reply.text = EmployeeEvents.resolve_blame(event, choice)
	UI.clear(_options)
	_show_close()


func _show_close() -> void:
	UI.button(_options, "回工位", Rect2(214, 198, 390, 24), finished.emit)
