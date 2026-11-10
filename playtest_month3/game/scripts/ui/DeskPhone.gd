extends Control
## 桌上的智能手机：圆角机身、金属边、挖孔镜头、玻璃反光。来消息时亮屏，显示时间和一条通知。逐像素画。

const W := 28
const H := 50
## 屏幕区
const SX := 3
const SY := 3
const SW := 22
const SH := 44

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


## 圆角矩形：上下各两行往里收。
func _rrect(x: int, y: int, w: int, h: int, c: Color, r := 2) -> void:
	for i in r:
		var inset := r - i
		_px(x + inset, y + i, w - inset * 2, 1, c)
		_px(x + inset, y + h - 1 - i, w - inset * 2, 1, c)
	_px(x, y + r, w, h - r * 2, c)


func _draw() -> void:
	_rrect(2, 2, W, H, Color(0, 0, 0, 0.55), 3)
	# 侧键（伸出机身一像素）
	_px(-1, 10, 1, 5, Color("596168"))
	_px(-1, 17, 1, 5, Color("596168"))
	_px(W, 13, 1, 7, Color("596168"))
	# 机身：外轮廓 → 金属中框 → 黑色前面板
	_rrect(0, 0, W, H, Color("0b0d0e"), 3)
	_rrect(1, 1, W - 2, H - 2, Color("66707a"), 2)
	_px(2, 1, W - 5, 1, Color("9aa4ac"))  # 中框顶部高光
	_px(1, 3, 1, H - 7, Color("8a949c"))  # 左侧高光
	_px(W - 2, 3, 1, H - 6, Color("454d54"))  # 右侧暗面
	_rrect(2, 2, W - 4, H - 4, Color("15191b"), 2)
	if lit:
		_screen_on()
	else:
		_screen_off()
	# 挖孔镜头
	_px(SX + SW / 2 - 1, SY + 2, 2, 2, Color("030405"))
	_px(SX + SW / 2, SY + 2, 1, 1, Color("2f4458"))
	# 玻璃反光
	for y in SH:
		var x := 15 - y / 2
		if x >= 0 and x + 3 <= SW:
			_px(SX + x, SY + y, 3, 1, Color(1, 1, 1, 0.07 if not lit else 0.05))
	_px(SX + 1, SY, SW - 2, 1, Color(1, 1, 1, 0.08))


func _screen_off() -> void:
	_rrect(SX, SY, SW, SH, Color("0c1012"), 1)
	# 熄屏玻璃里映出一点天花板灯光
	_px(SX + 2, SY + 2, 1, 6, Color(1, 1, 1, 0.06))


func _screen_on() -> void:
	# 壁纸：上青下深，底部一抹暖光
	for y in SH:
		var t := float(y) / SH
		var c := Color("3f7a68").lerp(Color("1b2e38"), t)
		if y > SH - 12:
			c = c.lerp(Color("5a4a3a"), float(y - (SH - 12)) / 24.0)
		var inset := 1 if y == 0 or y == SH - 1 else 0
		_px(SX + inset, SY + y, SW - inset * 2, 1, c)
	# 锁屏时间
	if time_text != "":
		_draw_time(time_text, SY + 7)
	# 通知卡片
	var cy := SY + 18
	_rrect(SX + 2, cy, SW - 4, 9, Color(0.93, 0.95, 0.94, 0.9), 1)
	_px(SX + 3, cy + 2, 3, 3, Color("3fbf6a"))  # 消息 App 图标
	_px(SX + 4, cy + 3, 1, 1, Color("e8f5ec"))
	_px(SX + 8, cy + 2, 7, 1, Color("2a302d"))
	_px(SX + 8, cy + 4, 10, 1, Color("8a948f"))
	_px(SX + 8, cy + 6, 6, 1, Color("8a948f"))
	# 底部手势条
	_px(SX + 7, SY + SH - 3, 8, 1, Color(1, 1, 1, 0.7))
	# 屏幕在机身边缘的辉光
	_px(SX - 1, SY + 4, 1, SH - 8, Color(0.5, 0.85, 0.7, 0.18))
	_px(SX + SW, SY + 4, 1, SH - 8, Color(0.5, 0.85, 0.7, 0.18))


func _draw_time(text: String, y: int) -> void:
	var width := 0
	for ch in text:
		width += 2 if ch == ":" else 4
	var x := SX + (SW - width + 1) / 2
	for ch in text:
		if ch == ":":
			_px(x, y + 1, 1, 1, Color.WHITE)
			_px(x, y + 3, 1, 1, Color.WHITE)
			x += 2
			continue
		var rows: Array = DIGITS.get(ch, [])
		for r in rows.size():
			for k in 3:
				if rows[r][k] == "1":
					_px(x + k, y + r, 1, 1, Color.WHITE)
		x += 4
