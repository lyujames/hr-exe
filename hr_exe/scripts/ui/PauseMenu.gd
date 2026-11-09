class_name PauseMenu extends Control
## 暂停菜单（Esc 或右下角“菜单”）：存档、退出到主菜单。打开时整棵树暂停，桌上的钟也停。

signal quit_to_title

var _box: Control
var _status: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	size = Vector2(640, 360)
	var dim := UI.panel(self, Rect2(0, 0, 640, 360), Color(UI.BLACK, 0.75))
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	UI.panel(self, Rect2(210, 90, 220, 180), UI.DESK_DARK, UI.GREEN_DIM)
	UI.label(self, "暂停　第 %d 天 · %s" % [GameState.day, GameState.today], Vector2(222, 98), UI.GREEN)
	_box = Control.new()
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_box)
	_status = UI.label(self, "", Vector2(222, 226), UI.TEXT_DIM, 196)
	_show_main()
	get_tree().paused = true


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


func close() -> void:
	get_tree().paused = false
	queue_free()


func _show_main() -> void:
	UI.clear(_box)
	UI.button(_box, "继续上班", Rect2(260, 124, 120, 24), close)
	UI.button(_box, "存档", Rect2(260, 156, 120, 24), save)
	UI.button(_box, "退出到主菜单", Rect2(260, 188, 120, 24), _confirm_quit)


func save() -> void:
	SaveManager.save_checkpoint()
	_status.text = "已存档：第 %d 天早上。今天做到一半的进度不会存进去。" % GameState.day


func _confirm_quit() -> void:
	UI.clear(_box)
	var day := SaveManager.saved_day()
	if day == 0:
		_status.text = "这一局还没有存档，回到主菜单后进度会全部丢失。"
	else:
		_status.text = "存档停在第 %d 天早上，之后的进度会丢失。" % day
	UI.label(_box, "回到主菜单？", Vector2(222, 128), UI.TEXT)
	UI.button(_box, "确定退出", Rect2(260, 156, 120, 24), quit)
	UI.button(_box, "取消", Rect2(260, 188, 120, 24), func() -> void:
		_status.text = ""
		_show_main())


func quit() -> void:
	close()
	quit_to_title.emit()
