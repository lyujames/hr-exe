extends Control
## 流程控制：晨会邮件 → [老板对质] → 筛简历 → 面试 → 日结 → [约面] → 报纸 → 回家 → 第二天。

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


## 昨天破格的人 14:00 先面（你单独面），面完再去赵主管那场。
func show_interview() -> void:
	if GameState.next_vouched():
		_swap("res://scenes/InterviewRoom.tscn", show_interview)
	elif GameState.interviewees.is_empty():
		show_report()
	else:
		_swap("res://scenes/InterviewRoom.tscn", _after_interview)


## 剧情候选人那场面完，今天要是有奇葩，接着面第二场。
func _after_interview() -> void:
	if GameState.interviewed_today.size() == 1 and InterviewRoom.second_candidate():
		_swap("res://scenes/InterviewRoom.tscn", show_report)
	else:
		show_report()


func show_report() -> void:
	_swap("res://scenes/DayReport.tscn", show_booking)


## 今天通过两个人以上、明天还有面试，才要挑；一个人自动约 TA（GameState.advance_day）。
func show_booking() -> void:
	if GameState.is_bankrupt() or GameState.day >= GameState.LAST_DAY or GameState.passed_today.size() < 2:
		show_news()
	else:
		_swap("res://scenes/BookingScreen.tscn", show_news)


func show_news() -> void:
	_swap("res://scenes/Newspaper.tscn", show_home)


## 最后一天回家写在月底结尾里；破产也直接去结尾。
func show_home() -> void:
	if GameState.is_bankrupt() or GameState.day >= GameState.LAST_DAY or GameState.config.home_scene.is_empty():
		next_day()
	else:
		_swap("res://scenes/HomeScreen.tscn", next_day)


func next_day() -> void:
	if GameState.is_bankrupt() or GameState.day >= GameState.LAST_DAY:
		SaveManager.clear()
		_swap("res://scenes/SliceEnd.tscn", show_title)
	else:
		GameState.advance_day()
		SaveManager.save_game()
		start_day()
