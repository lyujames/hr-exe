extends Control
## 流程控制：[昨天的晚报] → 晨会邮件 → [老板对质] → 筛简历 → 傍晚一场（面试或离职谈话）→ 日结 → 回家（含短信）→ 第二天。
## 砍减版：约面那一屏、第二场奇葩面试拿掉了；晚报挪到第二天早上（MailScreen），短信并进回家那一屏。

## 标题和结尾没有暂停菜单。
const NO_MENU := ["res://scenes/Title.tscn", "res://scenes/SliceEnd.tscn"]

var current: Control
var menu: PauseMenu
## 放在最上层，不被各屏拖来拖去的文件盖住。
var _overlay: Control
var _menu_button: Button


func _ready() -> void:
	theme = UI.theme()
	UI.panel(self, Rect2(0, 0, 640, 360), UI.DESK_DARK)
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	_overlay = Control.new()
	_overlay.theme = theme  # CanvasLayer 隔断了主题继承
	_overlay.size = Vector2(640, 360)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_overlay)
	_menu_button = UI.button(_overlay, "菜单", Rect2(600, 334, 38, 24), open_menu)
	show_title()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and _menu_button.visible:
		get_viewport().set_input_as_handled()
		open_menu()


func open_menu() -> void:
	if is_instance_valid(menu):
		return
	menu = PauseMenu.new()
	var desk := current as Desk
	menu.can_arrange = desk != null and not desk.closing and not desk.arranging
	_overlay.add_child(menu)
	menu.quit_to_title.connect(show_title)
	if menu.can_arrange:
		menu.arrange_desk.connect(desk.start_arrange)


func _swap(path: String, next: Callable) -> Control:
	if current:
		current.queue_free()
	current = load(path).instantiate()
	add_child(current)
	current.finished.connect(next, CONNECT_ONE_SHOT)
	_menu_button.visible = path not in NO_MENU
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


## 昨天破格的人 14:00 先面（你单独面），面完再去主管那场。
func show_interview() -> void:
	if GameState.next_vouched():
		_swap("res://scenes/InterviewRoom.tscn", show_interview)
	elif GameState.interviewees.is_empty() or GameState.skip_plain_interview():
		_after_interviews()
	else:
		_swap("res://scenes/InterviewRoom.tscn", _after_interview)


## 砍减版：一天只面一场，面完直接去离职谈话 / 日结。
func _after_interview() -> void:
	_after_interviews()


## 面试完了，傍晚还有离职谈话（第三个月起，DayConfig.exit_talks）：一场接一场，谈完才去日结。
func _after_interviews() -> void:
	if GameState.next_talk_index() >= 0:
		_swap("res://scenes/ExitTalk.tscn", _after_interviews)
	else:
		show_report()


func show_report() -> void:
	_swap("res://scenes/DayReport.tscn", show_home)


## 回家那一屏（短信也在里面）。今晚的报纸先排好版，第二天早上看。
## 月底回家写在月末回顾里，那天只剩短信；破产直接去结尾。
func show_home() -> void:
	GameState.store_paper()
	if GameState.is_bankrupt() or not HomeScreen.has_content():
		next_day()
	else:
		_swap("res://scenes/HomeScreen.tscn", next_day)


## 月底先看月末回顾（回家那一幕也在里面）；最后一个月或破产是结尾，其余月份看完接着上下个月的班。
func next_day() -> void:
	if GameState.is_bankrupt() or GameState.day >= GameState.LAST_DAY:
		SaveManager.clear()
		_swap("res://scenes/SliceEnd.tscn", show_title)
	elif GameState.is_month_end():
		_swap("res://scenes/SliceEnd.tscn", _next_morning)
	else:
		_next_morning()


func _next_morning() -> void:
	GameState.advance_day()
	SaveManager.save_game()
	start_day()
