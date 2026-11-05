class_name DeskDrag extends RefCounted
## 桌上不是纸的那些东西（全家福、手机、质询按钮）：按住拖开几个像素就是挪，松手记进桌面布置；
## 没拖开就算点了一下，照旧干它本来的事（翻手机、开质询）。印章不挂这个：拖印章就是盖章。

## 拖开多远才算挪，不算点。
const THRESHOLD := 4.0

var node: Control
var key: String
var on_click: Callable
## 跟着一起挪的（质询按钮下面的“打电话”）。
var followers: Array[Control] = []
## 挪完以后要做的事（手机挪了，先把弹出来的消息收起来）。
var on_moved: Callable
var _press := Vector2.INF
var _start := Vector2.ZERO
var _dragging := false


static func attach(target: Control, layout_key: String, click := Callable(), follow: Array[Control] = []) -> DeskDrag:
	var d := DeskDrag.new()
	d.node = target
	d.key = layout_key
	d.on_click = click
	d.followers = follow
	target.mouse_filter = Control.MOUSE_FILTER_STOP
	target.gui_input.connect(d._on_input)
	target.set_meta("desk_drag", d)  # 跟着节点活着
	return d


func _on_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_press = event.global_position
			_start = node.position
			_dragging = false
			return
		if _press == Vector2.INF:
			return
		_press = Vector2.INF
		if _dragging:
			_dragging = false
			DeskLayout.set_pos(key, node.position)
			Sfx.paper()
			if on_moved.is_valid():
				on_moved.call()
		elif on_click.is_valid():
			on_click.call()
	elif event is InputEventMouseMotion and _press != Vector2.INF:
		if not _dragging and event.global_position.distance_to(_press) > THRESHOLD:
			_dragging = true
		if _dragging:
			var at := DeskLayout.clamp_pos(key, _start + event.global_position - _press)
			var delta := at - node.position
			node.position = at
			for f in followers:
				f.position += delta
