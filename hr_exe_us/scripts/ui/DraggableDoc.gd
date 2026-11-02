class_name DraggableDoc extends Control
## 可在桌面上自由拖动的物件，按下时置顶。

var _grab_offset := Vector2.ZERO
var _dragging := false


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = event.pressed
		if event.pressed:
			_grab_offset = position - event.global_position
			move_to_front()
	elif event is InputEventMouseMotion and _dragging:
		var limit := get_viewport_rect().size - size
		position = (event.global_position + _grab_offset).clamp(Vector2(0, 16), limit.max(Vector2(0, 16)))
