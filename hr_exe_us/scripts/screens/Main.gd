extends Control
## 流程控制：晨会邮件 → [老板对质] → 筛简历 → 面试 → 日结 → 报纸 → 第二天。

var current: Control


func _ready() -> void:
	theme = UI.theme()
	UI.panel(self, Rect2(0, 0, 640, 360), UI.DESK_DARK)
	show_title()


func _swap(path: String, next: Callable) -> Control:
	if current:
		current.queue_free()
	current = load(path).instantiate()
	add_child(current)
	current.finished.connect(next, CONNECT_ONE_SHOT)
	return current


func show_title() -> void:
	_swap("res://scenes/Title.tscn", start_day)


func start_day() -> void:
	_swap("res://scenes/MailScreen.tscn", _after_mail)


func _after_mail() -> void:
	var event := EmployeeEvents.due_event()
	if event.is_empty():
		show_desk()
	else:
		GameState.event_today = event
		var office: BossOffice = _swap("res://scenes/BossOffice.tscn", show_desk)
		office.setup(event)


func show_desk() -> void:
	_swap("res://scenes/Desk.tscn", show_interview)


func show_interview() -> void:
	if GameState.passed_today.is_empty():
		show_report()
	else:
		_swap("res://scenes/InterviewRoom.tscn", show_report)


func show_report() -> void:
	_swap("res://scenes/DayReport.tscn", show_news)


func show_news() -> void:
	_swap("res://scenes/Newspaper.tscn", next_day)


func next_day() -> void:
	if GameState.is_bankrupt() or GameState.day >= GameState.LAST_DAY:
		SaveManager.clear()
		_swap("res://scenes/SliceEnd.tscn", show_title)
	else:
		GameState.day += 1
		GameState.begin_day()
		SaveManager.save_game()
		start_day()
