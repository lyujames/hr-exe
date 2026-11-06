extends Control
## 桌角的针式打印机：盖错章，违规单从顶上的出纸口一截一截吐出来。逐像素画。

const W := 98
const H := 30
## 出纸口（顶面那条黑缝），相对打印机左上角。
const SLOT := Rect2(6, 5, 86, 2)

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
	var body := Color("4a5550")
	# 投影
	_px(2, 2, W, H, Color(0, 0, 0, 0.55))
	# 机身：上窄下宽的一块
	_px(0, 4, W, H - 4, Color("121615"))
	_px(1, 5, W - 2, H - 6, body)
	_px(1, 5, W - 2, 1, body.lightened(0.2))
	_px(1, H - 2, W - 2, 1, body.darkened(0.35))
	# 顶盖和出纸口
	_px(4, 2, W - 8, 4, Color("121615"))
	_px(5, 3, W - 10, 2, body.lightened(0.1))
	_px(SLOT.position.x, SLOT.position.y, SLOT.size.x, SLOT.size.y, Color("0b0d0c"))
	# 两侧的进纸齿轮
	for x: int in [3, W - 7]:
		_px(x, 9, 4, 4, Color("2b3230"))
		_px(x + 1, 10, 2, 2, Color("7c8a84"))
	# 前脸：铭牌、出纸刻度
	_px(10, 12, 30, 7, Color("39423f"))
	_px(12, 14, 3, 3, Color("aeb5af"))
	_px(17, 15, 20, 1, Color("8c9992"))
	for i in 10:
		_px(48 + i * 4, 14, 2, 1, Color("2b3230"))
	# 按键
	_px(48, 19, 8, 4, Color("2b3230"))
	_px(58, 19, 8, 4, Color("2b3230"))
	# 指示灯：平时绿灯，吐单子时红灯闪
	var red_on := _printing and fmod(_blink, 0.24) < 0.14
	_px(W - 18, 19, 4, 3, Color("c8402f") if red_on else Color("4b2a25"))
	_px(W - 11, 19, 4, 3, Color("4f7f68") if _printing else Color("7fd6a4"))
