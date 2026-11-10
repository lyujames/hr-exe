extends Control
## 桌角的针式打印机：米灰机壳、烟色顶盖。盖错章，违规单从顶上的出纸口一截一截吐出来，红灯闪。
## 图是 素材/美术脚本/desk_art.py 画的。

const W := 100
const H := 32
## 出纸口（顶面那条黑缝），相对打印机左上角。
const SLOT := Rect2(8, 5, 84, 2)
const IDLE := preload("res://assets/desk/printer_idle.png")
const BUSY := preload("res://assets/desk/printer_busy.png")

var _printing := false
var _blink := 0.0


func _ready() -> void:
	custom_minimum_size = Vector2(W + 2, H + 2)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _px(x: float, y: float, w: float, h: float, c: Color) -> void:
	draw_rect(Rect2(x, y, w, h), c)


## 吐单子那一阵红灯闪。
func print_for(seconds: float) -> void:
	_printing = true
	_blink = 0.0
	queue_redraw()
	get_tree().create_timer(seconds).timeout.connect(func() -> void:
		_printing = false
		queue_redraw())


func _process(delta: float) -> void:
	if _printing:
		_blink += delta
		queue_redraw()


func _draw() -> void:
	var red_on := _printing and fmod(_blink, 0.24) < 0.14
	draw_texture(BUSY if red_on else IDLE, Vector2.ZERO)
