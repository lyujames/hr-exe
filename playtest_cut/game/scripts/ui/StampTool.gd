class_name StampTool extends Control
## 印章：用 _get_drag_data 拖到简历上，由 ResumeDoc 的 _drop_data 接收。

const SIZE := Vector2(92, 40)

var verdict := "pass"
var title := "通过"
var ink := UI.GREEN


func setup(stamp_verdict: String) -> void:
	verdict = stamp_verdict
	title = {"pass": "通过", "exception": "破格"}.get(verdict, "拒绝")
	ink = {"pass": UI.GREEN, "exception": UI.YELLOW}.get(verdict, UI.RED)
	size = SIZE
	mouse_default_cursor_shape = Control.CURSOR_DRAG
	_draw_block(self)


func _draw_block(parent: Control) -> void:
	UI.panel(parent, Rect2(16, 0, 60, 18), Color("3a2f2a"), UI.BLACK)
	UI.panel(parent, Rect2(0, 18, SIZE.x, 22), ink.darkened(0.25), UI.BLACK)
	var text := UI.label(parent, title, Vector2(0, 21), UI.BLACK)
	text.size.x = SIZE.x
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _get_drag_data(_at: Vector2) -> Variant:
	var preview := Control.new()
	var ghost := Control.new()
	ghost.position = -SIZE / 2.0
	ghost.modulate.a = 0.85
	preview.add_child(ghost)
	_draw_block(ghost)
	set_drag_preview(preview)
	return {"type": "stamp", "verdict": verdict}
