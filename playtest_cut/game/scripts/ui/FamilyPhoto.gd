extends Control
## 桌角的全家福：胡桃木相框、玻璃反光、公园里拍的四口人（你爸、你、老婆、孩子）。逐像素画。

const W := 62
const H := 48
## 照片区（相框内）
const PX := 5
const PY := 5
const PW := 52
const PH := 38

const SKIN := Color("e2bf9c")
const SKIN_SHADE := Color("c99f7c")
const EYE := Color("3a2a24")


func _ready() -> void:
	custom_minimum_size = Vector2(W + 2, H + 2)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _px(x: float, y: float, w: float, h: float, c: Color) -> void:
	draw_rect(Rect2(x, y, w, h), c)


func _draw() -> void:
	# 投影
	_px(2, 2, W, H, Color(0, 0, 0, 0.55))
	_frame()
	_scene()
	_people()
	_glare()


func _frame() -> void:
	var wood := Color("7a5536")
	_px(0, 0, W, H, Color("1a1411"))
	_px(1, 1, W - 2, H - 2, wood)
	# 木纹：几条断续的深色横纹
	for i in 40:
		var gx := (i * 37) % (W - 4) + 2
		var gy := 1 + (i * 13) % (H - 2)
		if gy > 3 and gy < H - 4 and gx > 3 and gx < W - 4:
			continue  # 只画在边框上
		_px(gx, gy, 2 + i % 3, 1, Color("664429"))
	# 外沿受光（左上亮、右下暗）
	_px(1, 1, W - 2, 1, Color("a3784d"))
	_px(1, 1, 1, H - 2, Color("926a44"))
	_px(1, H - 2, W - 2, 1, Color("4a3220"))
	_px(W - 2, 1, 1, H - 2, Color("553a26"))
	# 内沿倒角（反过来：左上暗、右下亮）
	_px(PX - 1, PY - 1, PW + 2, 1, Color("3b281a"))
	_px(PX - 1, PY - 1, 1, PH + 2, Color("3b281a"))
	_px(PX - 1, PY + PH, PW + 2, 1, Color("9a7048"))
	_px(PX + PW, PY - 1, 1, PH + 2, Color("8d6542"))


func _scene() -> void:
	var sky_top := Color("86abc8")
	var sky_low := Color("cad9dc")
	var horizon := 20
	for y in horizon:
		_px(PX, PY + y, PW, 1, sky_top.lerp(sky_low, float(y) / horizon))
	# 云
	for c: Array in [[30, 4, 9], [33, 3, 5], [8, 7, 6]]:
		_px(PX + c[0], PY + c[1], c[2], 2, Color("eef3f2"))
		_px(PX + c[0] + 1, PY + c[1] - 1, c[2] - 3, 1, Color("f6f9f8"))
	# 远山
	for x in PW:
		var hill := int(3.0 + 2.0 * sin(x * 0.21) + 1.5 * sin(x * 0.53 + 1.0))
		_px(PX + x, PY + horizon - hill, 1, hill, Color("8aa39a"))
	# 草地
	for y in range(horizon, PH):
		_px(PX, PY + y, PW, 1, Color("8aa463").lerp(Color("5f7a44"), float(y - horizon) / (PH - horizon)))
	for i in 18:
		_px(PX + (i * 23) % PW, PY + horizon + 2 + (i * 7) % (PH - horizon - 3), 1, 1, Color("546d3c"))
	# 右边一棵树
	var tx := PX + 46
	_px(tx, PY + 12, 2, 10, Color("5a4430"))
	_px(tx + 1, PY + 12, 1, 10, Color("47352a"))
	for blob: Array in [[-4, 3, 10, 7], [-3, 1, 8, 2], [-5, 6, 12, 4], [-2, 10, 6, 2]]:
		_px(tx + blob[0], PY + blob[1], blob[2], blob[3], Color("4c6b45"))
	_px(tx - 3, PY + 3, 4, 3, Color("67875a"))
	_px(tx - 4, PY + 7, 3, 2, Color("67875a"))
	# 树影
	_px(tx - 3, PY + 22, 9, 1, Color(0, 0, 0, 0.15))


## 一个人：cx 中心，h 总高，脚踩在 feet。
func _person(cx: int, h: int, feet: int, hair: Color, top: Color, bottom: Color, long_hair := false, dress := false) -> void:
	var head := 6 if h > 18 else 5
	var head_y := feet - h
	var hx := cx - head / 2
	var body_w := head + 2
	var bx := cx - body_w / 2
	var torso_y := head_y + head + 1
	var leg_y := torso_y + int((h - head) * (0.55 if dress else 0.45))
	# 地上的影子
	_px(bx - 1, feet, body_w + 2, 1, Color(0, 0, 0, 0.18))
	# 长发在身后
	if long_hair:
		_px(hx - 1, head_y, head + 2, head + 3, hair)
	# 腿 / 裤子 / 鞋
	if dress:
		_px(cx - 2, leg_y, 1, feet - leg_y, SKIN_SHADE)
		_px(cx + 1, leg_y, 1, feet - leg_y, SKIN_SHADE)
	else:
		_px(bx + 1, leg_y, body_w - 2, feet - leg_y, bottom)
		_px(cx, leg_y + 1, 1, feet - leg_y - 1, bottom.darkened(0.3))
	_px(bx + 1, feet - 1, body_w / 2 - 1, 1, Color("2a2420"))
	_px(cx + 1, feet - 1, body_w / 2 - 1, 1, Color("2a2420"))
	# 躯干（裙子往下放宽一格）
	_px(bx, torso_y, body_w, leg_y - torso_y, top)
	if dress:
		_px(bx - 1, leg_y - 3, body_w + 2, 4, top)
		_px(bx - 1, leg_y, body_w + 2, 1, top.darkened(0.2))
	_px(bx + body_w - 2, torso_y, 2, leg_y - torso_y, top.darkened(0.18))  # 右侧暗面
	_px(bx, torso_y, body_w, 1, top.lightened(0.15))  # 肩头受光
	# 手臂和手
	var arm_len := int((leg_y - torso_y) * 0.85)
	_px(bx - 1, torso_y + 1, 1, arm_len, top.darkened(0.08))
	_px(bx + body_w, torso_y + 1, 1, arm_len, top.darkened(0.25))
	_px(bx - 1, torso_y + 1 + arm_len, 1, 1, SKIN)
	_px(bx + body_w, torso_y + 1 + arm_len, 1, 1, SKIN_SHADE)
	# 脖子
	_px(cx - 1, head_y + head, 2, 1, SKIN_SHADE)
	# 脸
	_px(hx, head_y, head, head, SKIN)
	_px(hx + head - 1, head_y + 1, 1, head - 1, SKIN_SHADE)
	_px(hx + 1, head_y + head, head - 2, 1, SKIN)  # 下巴
	_px(hx + 1, head_y + 3, 1, 1, EYE)
	_px(hx + head - 2, head_y + 3, 1, 1, EYE)
	_px(cx - 1, head_y + head - 1, 2, 1, Color("b9806a"))  # 笑
	# 头发
	_px(hx - 1, head_y - 1, head + 2, 2, hair)
	_px(hx, head_y - 2, head, 1, hair)
	_px(hx - 1, head_y + 1, 1, 2 if not long_hair else head + 2, hair)
	_px(hx + head, head_y + 1, 1, 2 if not long_hair else head + 2, hair)
	_px(hx + 1, head_y - 2, 2, 1, hair.lightened(0.25))  # 发顶高光


func _people() -> void:
	var feet := PY + PH - 3
	# 你爸：灰白头发，老式夹克，个子矮一点
	_person(PX + 12, 22, feet, Color("b4b2ac"), Color("6a6f5c"), Color("3d3d3a"))
	# 你：衬衫西裤
	_person(PX + 21, 26, feet, Color("1d1c1e"), Color("4d6788"), Color("2e333b"))
	# 老婆：长发，红裙
	_person(PX + 30, 24, feet, Color("2f2421"), Color("a8504a"), Color("a8504a"), true, true)
	# 孩子：黄色卫衣，牵着妈妈
	_person(PX + 38, 15, feet, Color("2a211e"), Color("d9a43a"), Color("3f5a78"))
	_px(PX + 34, feet - 7, 2, 1, SKIN)  # 牵手


func _glare() -> void:
	# 玻璃反光：两道斜带
	for y in PH:
		var x := 34 - y
		if x >= 0 and x + 4 <= PW:
			_px(PX + x, PY + y, 4, 1, Color(1, 1, 1, 0.13))
		var x2 := 42 - y
		if x2 >= 0 and x2 + 1 <= PW:
			_px(PX + x2, PY + y, 1, 1, Color(1, 1, 1, 0.1))
	_px(PX, PY, PW, 1, Color(1, 1, 1, 0.08))
