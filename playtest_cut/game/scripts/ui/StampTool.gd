class_name StampTool extends Control
## 印章：用 _get_drag_data 拖到简历上，由 ResumeDoc 的 _drop_data 接收。
## 漆木把手、铜箍、印身贴标签，橡胶面沾着墨（图是 素材/美术脚本/desk_art.py 画的）。
## 抓手区还是 92×40；图高 48，往上多出的 8 像素是把手顶。

const SIZE := Vector2(92, 40)
const ART_TOP := -8.0

var verdict := "pass"
var title := "通过"
var _art: TextureRect


func setup(stamp_verdict: String) -> void:
	verdict = stamp_verdict
	title = {"pass": "通过", "exception": "破格"}.get(verdict, "拒绝")
	size = SIZE
	mouse_default_cursor_shape = Control.CURSOR_DRAG
	_art = _draw_block(self)
	# 鼠标放上去，章微微抬起一像素；拿起来拖走时，桌上那个位置空出来（只剩一点影子）
	mouse_entered.connect(func() -> void: _art.position.y = ART_TOP - 1.0)
	mouse_exited.connect(func() -> void: _art.position.y = ART_TOP)


func _draw_block(parent: Control) -> TextureRect:
	return UI.sprite(parent, "res://assets/desk/stamp_%s.png" % verdict, Vector2(0, ART_TOP))


func _get_drag_data(_at: Vector2) -> Variant:
	var preview := Control.new()
	var ghost := Control.new()
	ghost.position = -SIZE / 2.0
	ghost.modulate.a = 0.85
	preview.add_child(ghost)
	_draw_block(ghost)
	set_drag_preview(preview)
	_art.modulate.a = 0.25
	return {"type": "stamp", "verdict": verdict}


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END and _art:
		_art.modulate.a = 1.0
		_art.position.y = ART_TOP
