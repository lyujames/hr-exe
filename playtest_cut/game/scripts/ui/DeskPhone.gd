extends Control
## 桌上的手机：平时扣着，背面朝上（深蓝壳，孩子贴的小火箭）；来消息翻过来亮屏，显示时间和一条通知。
## 图是 素材/美术脚本/desk_art.py 画的，时间在这儿按点阵写上去。

const W := 30
const H := 52
## 屏幕区
const SX := 3
const SY := 3
const SW := 24
const SH := 46
const DOWN := preload("res://assets/desk/phone_down.png")
const LIT := preload("res://assets/desk/phone_lit.png")

## 3×5 数字点阵
const DIGITS := {
	"0": ["111", "101", "101", "101", "111"],
	"1": ["010", "110", "010", "010", "111"],
	"2": ["111", "001", "111", "100", "111"],
	"3": ["111", "001", "111", "001", "111"],
	"4": ["101", "101", "111", "001", "001"],
	"5": ["111", "100", "111", "001", "111"],
	"6": ["111", "100", "111", "101", "111"],
	"7": ["111", "001", "010", "010", "010"],
	"8": ["111", "101", "111", "101", "111"],
	"9": ["111", "101", "111", "001", "111"],
}

var lit := false
var time_text := ""


func _ready() -> void:
	custom_minimum_size = Vector2(W + 2, H + 2)
	size = custom_minimum_size


func set_lit(on: bool, time := "") -> void:
	lit = on
	time_text = time
	queue_redraw()


func _px(x: float, y: float, w: float, h: float, c: Color) -> void:
	draw_rect(Rect2(x, y, w, h), c)


func _draw() -> void:
	draw_texture(LIT if lit else DOWN, Vector2.ZERO)
	if lit and time_text != "":
		_draw_time(time_text, 9)


func _draw_time(text: String, y: int) -> void:
	var width := 0
	for ch in text:
		width += 2 if ch == ":" else 4
	var x := SX + (SW - width + 1) / 2
	for ch in text:
		if ch == ":":
			_px(x, y + 1, 1, 1, Color("d8e8e8"))
			_px(x, y + 3, 1, 1, Color("d8e8e8"))
			x += 2
			continue
		var rows: Array = DIGITS.get(ch, [])
		for r in rows.size():
			for k in 3:
				if rows[r][k] == "1":
					_px(x + k, y + r, 1, 1, Color("d8e8e8"))
		x += 4
