class_name DraggableDoc extends Control
## 可在桌面上自由拖动的物件，按下时置顶。
## 有 layout_key 的（简历、身份证、手册、JD）松手就记进桌面布置：下一份简历、明天的手册都摆在你放的地方。

## 质询时点了这份材料上的某一行。
signal field_picked(doc: DraggableDoc, key: String)

## 质询时能点的行 {字段: Label}，子类渲染时登记；翻页重绘后重新登记。
var fields := {}
var inspecting := false
var _grab_offset := Vector2.ZERO
var _dragging := false
var _hot: Control
## DeskLayout 里的名字；空的不记位置。
var layout_key := ""
var _press_pos := Vector2.ZERO
## 拖着走时、松手时回调（全局坐标）。松手的回调返回 true 表示东西被收走了（放进了文件夹），不记位置。
var on_drag: Callable
var on_release: Callable


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = event.pressed
		_lift(event.pressed)
		if event.pressed:
			_grab_offset = position - event.global_position
			_press_pos = position
			move_to_front()
		elif on_release.is_valid() and on_release.call(event.global_position):
			return
		else:
			if position.distance_to(_press_pos) > 6.0:
				Sfx.slide()
			if layout_key != "" and position != _press_pos:
				DeskLayout.set_pos(layout_key, position)
	elif event is InputEventMouseMotion and _dragging:
		var limit := get_viewport_rect().size - size
		position = (event.global_position + _grab_offset).clamp(Vector2(0, 16), limit.max(Vector2(0, 16)))
		if on_drag.is_valid():
			on_drag.call(event.global_position)


## 拿起来的纸影子拉开一点，像离了桌面；放下回到原处。影子是每张纸的第一个子节点（偏 2 像素的黑块）。
func _lift(on: bool) -> void:
	if get_child_count() == 0 or not get_child(0) is Panel:
		return
	var shadow: Panel = get_child(0)
	if shadow.position in [Vector2(2, 2), Vector2(4, 5)]:
		shadow.position = Vector2(4, 5) if on else Vector2(2, 2)
		shadow.modulate.a = 0.7 if on else 1.0


func set_inspecting(on: bool) -> void:
	inspecting = on
	refresh_hotspots()


## 质询开着时，每一行登记过的字段上盖一块可点的黄框。
func refresh_hotspots() -> void:
	if _hot:
		_hot.queue_free()
		_hot = null
	if not inspecting:
		return
	_hot = Control.new()
	_hot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hot)
	for key: String in fields:
		var label: Label = fields[key]
		var spot := Button.new()
		spot.focus_mode = Control.FOCUS_NONE
		spot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		spot.add_theme_stylebox_override("normal", _spot_box(0.12))
		spot.add_theme_stylebox_override("hover", _spot_box(0.35))
		spot.add_theme_stylebox_override("pressed", _spot_box(0.5))
		spot.position = label.global_position - global_position - Vector2(2, 1)
		spot.size = label.get_combined_minimum_size() + Vector2(4, 2)
		spot.pressed.connect(func() -> void: field_picked.emit(self, key))
		# 黄框盖在简历上，印章照样能盖下去
		spot.set_drag_forwarding(Callable(),
			func(at: Vector2, data: Variant) -> bool: return _can_drop_data(at + spot.position, data),
			func(at: Vector2, data: Variant) -> void: _drop_data(at + spot.position, data))
		_hot.add_child(spot)


static func _spot_box(alpha: float) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(UI.YELLOW, alpha)
	box.border_color = UI.YELLOW
	box.set_border_width_all(1)
	return box
