class_name DeskArranger extends Control
## 布置桌面：桌上每样东西盖一块占位框，拖框就是拖东西。布置时桌上的钟停着，占位框挡住内容，不能趁机看材料。

signal closed

## 桌上今天有的东西 → 挪到哪的回调 apply(key, pos)。
var _apply: Callable
var _layout := {}
var _boxes := {}
var _dragging := ""
var _grab := Vector2.ZERO
## 工具栏按钮永远在最上面，拖到最前的框也盖不住。
var _tools: Array[Button] = []


func setup(keys: Array, apply: Callable) -> void:
	_apply = apply
	size = Vector2(640, 360)
	mouse_filter = Control.MOUSE_FILTER_STOP
	for key: String in DeskLayout.ITEMS:
		_layout[key] = DeskLayout.pos(key)
	UI.panel(self, Rect2(0, 0, 640, 360), Color(UI.BLACK, 0.55))
	UI.panel(self, Rect2(0, 0, 640, 18), UI.DESK_DARK, UI.GREEN_DIM)
	UI.label(self, "布置桌面：拖动方框摆放，钟停着", Vector2(6, 1), UI.GREEN)
	for key: String in keys:
		_boxes[key] = _make_box(key)
	_tools = [UI.button(self, "恢复默认", Rect2(470, 1, 76, 16), _reset), UI.button(self, "完成", Rect2(552, 1, 80, 16), _done)]


func _make_box(key: String) -> Panel:
	var box := UI.panel(self, Rect2(_layout[key], DeskLayout.size_of(key)), UI.DESK_DARK, UI.GREEN)
	box.mouse_filter = Control.MOUSE_FILTER_STOP
	box.mouse_default_cursor_shape = Control.CURSOR_MOVE
	var name := UI.label(box, DeskLayout.ITEMS[key].name, Vector2(4, 2), UI.GREEN, maxf(box.size.x - 8, 24))
	name.clip_text = true
	box.gui_input.connect(_on_box_input.bind(key))
	return box


func _on_box_input(event: InputEvent, key: String) -> void:
	var box: Panel = _boxes[key]
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_dragging = key
			_grab = box.position - event.global_position
			box.move_to_front()
			for b in _tools:
				b.move_to_front()
		elif _dragging == key:
			_dragging = ""
			Sfx.paper()
	elif event is InputEventMouseMotion and _dragging == key:
		_move(key, event.global_position + _grab)


func _move(key: String, at: Vector2) -> void:
	var p := DeskLayout.clamp_pos(key, at)
	_layout[key] = p
	_boxes[key].position = p
	_apply.call(key, p)


func _reset() -> void:
	var fresh := DeskLayout.defaults()
	_layout = fresh.duplicate()
	for key: String in _boxes:
		_move(key, fresh[key])


func _done() -> void:
	DeskLayout.save(_layout)
	closed.emit()
	queue_free()
