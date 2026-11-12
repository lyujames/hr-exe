extends SceneTree
## 回家一屏的场景图，三个钟点：1930 一家人都在 / 2030 孩子睡了、老婆看手机、你那碗扣着 / 2230 灯全关了。
## 纯 Godot Image 逐像素画，headless 就能跑：
##   Godot --headless --script 素材/美术脚本/home_mock.gd
## 直接写进 playtest_cut/game/assets/home/home_{1930,2030,2230}.png（640×196），
## 另出一张 素材/样板图_回家改版_对比.png（每个钟点上旧下新，按游戏里的裁切，2 倍）。
##
## 跟旧图的区别：
##  1. 光照统一一遍算：每个像素按离吊灯的距离 + 光锥 + 桌下遮挡算亮度，量化成 5 档，档与档之间才抖动；
##     所以光锥、地面光斑、人身上的光是同一套，不再是叠一层半透明梯形。
##  2. 窗外冷光溢进来（窗台、地板一块、妈妈背光一侧的描边），跟灯的暖光对冲。
##  3. 孩子房门缝的光铺到地板上；挂钟 7:30、挂历圈着日子；玄关柜上是你的包和工牌。
##  4. 人重画：坐得住（大腿压椅面、小腿落地 / 孩子脚够不着地），手肘弯着，孩子低头写作业。
##  5. 你的椅子在桌子前面，背对镜头，空着；你那碗还冒着气。

const W := 640
const H := 196
const OUT := "/Users/apple/Desktop/HR/hr-exe-playtest-cut/素材/"
const GAME := "/Users/apple/Desktop/HR/hr-exe-playtest-cut/playtest_cut/game/assets/home/"
## 对比用的旧图：改版前的 home_*.png 留在 2026-11-10 的美术版试玩包里
const OLD_DIR := "/Users/apple/Desktop/HR/HR.exe_砍减版_美术版_2026-11-10/game/assets/home/"
const VARIANTS := ["1930", "2030", "2230"]
const BAYER := [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]
const LAMP := Vector2(293, 60)
const TX0 := 214
const TX1 := 372
const TY := 116

var img: Image
var v := "1930"
var olds: Array[Image] = []
var news: Array[Image] = []
var emis := PackedByteArray()   # 1 = 自发光，不吃光照
var occl := PackedFloat32Array()  # 遮挡系数（桌子底下）


func _init() -> void:
	for variant: String in VARIANTS:
		v = variant
		var old := Image.load_from_file(OLD_DIR + "home_%s.png" % v)
		old.convert(Image.FORMAT_RGBA8)
		olds.append(old)
		_draw()
		img.save_png(GAME + "home_%s.png" % v)
		news.append(img)
	_compare()
	print("saved")
	quit()


func _draw() -> void:
	img = Image.create(W, H, false, Image.FORMAT_RGBA8)
	emis.resize(W * H)
	emis.fill(0)
	occl.resize(W * H)
	occl.fill(1.0)
	_room()
	_window()
	_wall_things()
	_sideboard()
	_door()
	_entry()
	_lamp()
	_wife()
	_kid()
	_table()
	_shade(TX0 + 1, TY + 8, TX1 - TX0 - 2, 152 - TY - 8, 0.5)
	_shade(186, 150, 30, 2, 0.6)
	_shade(366, 150, 32, 2, 0.6)
	_your_chair()
	_tabletop()
	_light()


# ---------- 画笔 ----------

func c(h: String) -> Color:
	return Color.html(h)


func p(x: int, y: int, col: Color, e := false) -> void:
	if x < 0 or y < 0 or x >= W or y >= H:
		return
	img.set_pixel(x, y, col)
	emis[y * W + x] = 1 if e else 0
	occl[y * W + x] = 1.0


func r(x: int, y: int, w: int, h: int, col: Color, e := false) -> void:
	for yy in range(y, y + h):
		for xx in range(x, x + w):
			p(xx, yy, col, e)


func line(a: Vector2i, b: Vector2i, col: Color, e := false) -> void:
	var n := maxi(absi(b.x - a.x), absi(b.y - a.y))
	for i in n + 1:
		var t := float(i) / maxf(1, n)
		p(roundi(lerpf(a.x, b.x, t)), roundi(lerpf(a.y, b.y, t)), col, e)


func _shade(x: int, y: int, w: int, h: int, k: float) -> void:
	for yy in range(y, y + h):
		for xx in range(x, x + w):
			if xx >= 0 and xx < W and yy >= 0 and yy < H:
				occl[yy * W + xx] = k


func bayer(x: int, y: int) -> float:
	return (BAYER[(y % 4) * 4 + (x % 4)] + 0.5) / 16.0


## 只在两档交界处抖动：中间 40% 用棋盘，其余直接取整
func quant(v: float, levels: int, x: int, y: int) -> float:
	var s := clampf(v, 0, 1) * levels
	var lo := floorf(s)
	var f := s - lo
	if f > 0.38 and f < 0.62:
		lo += 1.0 if (f - 0.38) / 0.24 > bayer(x, y) else 0.0
	elif f >= 0.62:
		lo += 1.0
	return lo / levels


# ---------- 房间 ----------

func _room() -> void:
	r(0, 0, W, 147, c("7a6450"))
	r(0, 0, W, 2, c("5a4838"))
	r(0, 145, W, 5, c("4a3a2e"))          # 踢脚线
	r(0, 145, W, 1, c("6a5444"))
	var floor_c := c("5c4636")
	r(0, 150, W, H - 150, floor_c)
	for y in [158, 168, 182]:
		r(0, y, W, 1, floor_c.darkened(0.18))
	var rows := [[150, 158, 0], [159, 168, 37], [169, 182, 12], [183, H, 55]]
	for row in rows:
		for x in range(row[2], W, 74):
			r(x, row[0], 1, row[1] - row[0], floor_c.darkened(0.18))
			r(x + 1, row[0], 1, row[1] - row[0], floor_c.lightened(0.05))


func _window() -> void:
	var wx := 28
	var wy := 26
	var ww := 116
	var wh := 86
	var frame := c("3a3029")
	r(wx - 3, wy - 3, ww + 6, wh + 6, frame)
	for y in wh:
		r(wx, wy + y, ww, 1, c("16203a").lerp(c("2a2638"), float(y) / wh), true)
	var rnd := RandomNumberGenerator.new()
	rnd.seed = 7
	var bx := wx
	while bx < wx + ww:
		var bw := rnd.randi_range(14, 26)
		var bh := rnd.randi_range(30, 70)
		r(bx, wy + wh - bh, mini(bw, wx + ww - bx), bh, c("101625"), true)
		for yy in range(wy + wh - bh + 4, wy + wh - 2, 5):
			for xx in range(bx + 2, mini(bx + bw - 2, wx + ww - 2), 4):
				if rnd.randf() < (0.3 if v != "2230" else 0.12):
					var lit := c("b89a58") if rnd.randf() < 0.8 else c("7a9ab8")
					r(xx, yy, 2, 2, lit, true)
		bx += bw + 1
	# 玻璃上的反光：灯在玻璃里的影子 + 两道斜光
	if v != "2230":
		for k in 5:
			r(wx + 93 - k, wy + 13 + k, 7 + 2 * k, 1, c("2e2c34"), true)
		r(wx + 89, wy + 18, 11, 1, c("6a5e48"), true)
	for k in 10:
		p(wx + 8 + k, wy + 30 - k, c("2e3a58"), true)
		p(wx + 13 + k, wy + 30 - k, c("2e3a58"), true)
	r(wx + ww / 2 - 1, wy, 2, wh, frame)
	r(wx, wy + wh / 2, ww, 2, frame)
	# 窗台：冷光
	r(wx - 6, wy + wh + 3, ww + 12, 3, c("8a8c98"))
	r(wx - 6, wy + wh + 3, ww + 12, 1, c("aab4cc"))
	# 窗帘（褶子）
	var cur := c("7a5a48")
	r(wx - 18, wy - 10, 14, wh + 26, cur)
	for k in [0, 5, 10]:
		r(wx - 18 + k, wy - 10, 2, wh + 26, cur.darkened(0.2))
	r(wx - 18, wy - 10, 14, 2, cur.darkened(0.35))


func _wall_things() -> void:
	# 孩子画的《我的爸爸》（结局伏笔），保留
	var paper := c("e8e4d6")
	r(222, 38, 34, 28, paper)
	r(222, 65, 34, 1, paper.darkened(0.25))
	r(255, 38, 1, 28, paper.darkened(0.15))
	var fig := c("3a6ac8")
	r(236, 44, 6, 6, fig)
	r(238, 50, 2, 9, fig)
	r(234, 52, 10, 1, fig)
	p(236, 60, fig); p(241, 60, fig)
	r(246, 46, 6, 10, c("c8402f"))
	r(225, 62, 8, 2, c("e8c84a"))
	r(238, 35, 2, 3, c("c8402f"))
	# 挂钟：几点到家就是几点
	var cx := 346
	var cy := 42
	for y in range(-8, 9):
		for x in range(-8, 9):
			var d := sqrt(x * x + y * y)
			if d <= 7.6:
				p(cx + x, cy + y, c("2e2620") if d > 6.2 else c("ece6d4"))
	for k in [Vector2i(0, -5), Vector2i(5, 0), Vector2i(0, 5), Vector2i(-5, 0)]:
		p(cx + k.x, cy + k.y, c("6a5a48"))
	line(Vector2i(cx, cy), Vector2i(cx, cy + 5), c("2a2220"))
	var hour := {"1930": Vector2i(-3, 3), "2030": Vector2i(-4, 1), "2230": Vector2i(-3, -3)}[v] as Vector2i
	line(Vector2i(cx, cy), Vector2i(cx, cy) + hour, c("2a2220"))
	p(cx, cy, c("c8402f"))
	# 挂历：红头，圈着一天
	r(410, 40, 22, 28, c("ece6d4"))
	r(410, 40, 22, 5, c("c8402f"))
	r(420, 37, 2, 3, c("2a2220"))
	for row in 4:
		for col in 6:
			p(413 + col * 3, 48 + row * 5, c("8a8070"))
	for k in [Vector2i(-1, -1), Vector2i(0, -2), Vector2i(1, -2), Vector2i(2, -1), Vector2i(2, 0), Vector2i(1, 1), Vector2i(0, 1), Vector2i(-1, 0)]:
		p(422 + k.x, 58 + k.y, c("d8402f"))
	r(410, 67, 22, 1, c("b8b0a0"))


func _sideboard() -> void:
	var top := c("7a6450")
	var body := c("5e4a3a")
	r(144, 112, 40, 35, body)
	r(144, 112, 40, 2, top.lightened(0.1))
	r(163, 116, 1, 28, body.darkened(0.3))
	r(158, 126, 3, 1, c("a08868")); r(166, 126, 3, 1, c("a08868"))
	r(146, 147, 3, 3, body.darkened(0.3)); r(179, 147, 3, 3, body.darkened(0.3))
	# 电饭煲：保温红灯
	r(150, 98, 22, 14, c("dcdcd4"))
	r(152, 96, 18, 2, c("c4c4bc"))
	r(150, 98, 1, 14, c("b8b8b0"))
	r(156, 104, 6, 3, c("5a6a68"))
	r(165, 105, 2, 2, c("ff4a3a"), true)
	r(149, 111, 24, 1, c("3e3028"))


func _door() -> void:
	var door := c("7a6450")
	r(444, 36, 52, 111, door.darkened(0.35))         # 门框
	r(444, 36, 52, 2, door.darkened(0.15))
	if v == "1930":
		# 门缝：孩子屋里亮着
		for y in range(38, 147):
			r(484, y, 10, 1, c("f6e0a0").lerp(c("e8c070"), float(y - 38) / 109.0), true)
		r(491, 60, 3, 30, c("c8a868"), true)              # 屋里书桌一角
		r(447, 38, 37, 109, door)
		r(483, 38, 1, 109, door.darkened(0.3))
		r(484, 38, 1, 109, c("fff6d0"), true)
	else:
		# 关上了；门缝底下一条黑 = 屋里灯也关了
		r(447, 38, 46, 109, door)
		r(492, 38, 1, 109, door.darkened(0.3))
		r(447, 145, 46, 2, c("0e0d0c"), true)
	for yy in [48, 96]:
		r(451, yy, 28, 1, door.darkened(0.15))
		r(451, yy + 38, 28, 1, door.darkened(0.15))
		r(451, yy, 1, 38, door.darkened(0.15))
		r(478, yy, 1, 38, door.lightened(0.08))
	r(456, 56, 18, 13, c("e8e4d6"))                   # 课程表
	for k in 3:
		r(458, 59 + k * 3, 14, 1, c("a8b8d8"))
	r(477 if v == "1930" else 486, 92, 4, 3, c("c8b080"))


func _entry() -> void:
	var cab := c("6a5644")
	r(522, 116, 74, 31, cab)
	r(522, 116, 74, 2, cab.lightened(0.12))
	r(559, 120, 1, 26, cab.darkened(0.3))
	r(524, 147, 3, 3, cab.darkened(0.4)); r(591, 147, 3, 3, cab.darkened(0.4))
	# 你的包 + 挂出来的工牌
	var bag := c("2e3440")
	r(532, 102, 24, 14, bag)
	r(532, 102, 24, 1, bag.lightened(0.15))
	r(538, 98, 12, 1, bag); r(538, 98, 1, 4, bag); r(549, 98, 1, 4, bag)
	line(Vector2i(552, 104), Vector2i(556, 118), c("c8402f"))
	line(Vector2i(556, 118), Vector2i(557, 121), c("c8402f"))
	r(554, 121, 8, 10, c("ece8dc"))
	r(554, 121, 8, 2, c("3a6ac8"))
	r(556, 125, 4, 3, c("a89888"))
	# 入户门
	var d := c("4a3c30")
	r(600, 18, 40, 129, d)
	r(600, 18, 2, 129, d.darkened(0.3))
	r(605, 80, 3, 8, c("c8b080"))
	# 拖鞋（你的，还在门口）+ 摊开的听写本
	r(538, 154, 12, 4, c("5a7ab0")); r(538, 157, 12, 1, c("3e5888"))
	r(552, 156, 12, 4, c("5a7ab0")); r(552, 159, 12, 1, c("3e5888"))
	if v == "2230":
		return
	r(572, 152, 16, 9, c("f2f0e8"))
	r(580, 152, 1, 9, c("c8c4b8"))
	for k in 3:
		r(574, 154 + k * 2, 4, 1, c("3a6ac8"))
		r(582, 154 + k * 2, 4, 1, c("c8402f") if k == 1 else c("3a6ac8"))
	r(572, 161, 16, 1, c("3a2c22"))


func _lamp() -> void:
	r(LAMP.x, 0, 1, 47, c("1e1a18"))
	var on := v != "2230"
	var shade := c("d8b878") if v == "1930" else (c("c8a868") if on else c("6a5a48"))
	for k in 11:
		r(int(LAMP.x) - 6 - k, 47 + k, 13 + 2 * k, 1, shade.darkened(0.25) if k < 3 else shade, on)
	r(int(LAMP.x) - 16, 57, 33, 1, shade.darkened(0.2), on)
	r(int(LAMP.x) - 7, 58, 15, 2, c("fff6d8") if on else c("8a8478"), on)


# ---------- 人 ----------

func _chair(x: int, back_left: bool) -> void:
	var ch := c("6a503c")
	var bx := x if back_left else x + 15
	r(bx, 98, 3, 30, ch)
	r(bx, 98, 3, 1, ch.lightened(0.15))
	r(x, 126, 18, 3, ch)
	r(x, 126, 18, 1, ch.lightened(0.15))
	r(x + 1, 129, 2, 21, ch.darkened(0.2))
	r(x + 15, 129, 2, 21, ch.darkened(0.2))


func _wife() -> void:
	_chair(188, true)
	if v == "2230":
		return
	var body := c("9a8a6a")
	var pants := c("54493f")
	var hair := c("2a2220")
	var skin := c("d8b494")
	var rim := c("a6b0cc")
	# 腿：大腿压在椅面上伸进桌下，小腿落地
	r(194, 120, 22, 6, pants)
	r(194, 120, 22, 1, pants.lightened(0.12))
	r(211, 126, 5, 22, pants)
	r(211, 126, 1, 22, pants.darkened(0.2))
	r(209, 148, 10, 2, c("a85a4a"))
	# 身子：开衫，背光一侧冷描边
	r(193, 95, 15, 26, body)
	p(193, 95, Color(0, 0, 0, 0)); p(207, 95, Color(0, 0, 0, 0))
	img.set_pixel(193, 95, c("7a6450")); img.set_pixel(207, 95, c("7a6450"))
	r(203, 98, 1, 22, body.darkened(0.12))   # 开衫门襟
	r(193, 96, 1, 24, rim)
	if v == "2030":
		_wife_phone(body, hair, skin, rim)
		return
	# 胳膊：上臂垂下，肘弯，小臂搭在桌沿
	r(201, 98, 5, 13, body.darkened(0.15))
	r(203, 110, 22, 4, body.darkened(0.08))
	r(203, 110, 22, 1, body.lightened(0.1))
	r(225, 110, 4, 4, skin)
	line(Vector2i(228, 110), Vector2i(236, 106), c("3a2a1a"))
	line(Vector2i(229, 111), Vector2i(237, 108), c("3a2a1a"))
	# 头：侧脸朝右，看孩子那边
	r(199, 91, 4, 4, skin.darkened(0.1))
	r(196, 78, 12, 14, hair)
	r(197, 77, 9, 1, hair)
	r(204, 82, 4, 9, skin)
	p(208, 85, skin); p(208, 86, skin)
	p(205, 84, c("1a1412"))
	p(206, 89, c("b07a68"))
	r(204, 79, 4, 3, hair)
	r(193, 84, 5, 16, hair)          # 低马尾垂在背后
	r(193, 84, 1, 15, rim)
	r(196, 78, 1, 6, rim)


## 2030：低头看手机，两只胳膊撑在桌上，屏幕的冷光照着脸
func _wife_phone(body: Color, hair: Color, skin: Color, rim: Color) -> void:
	r(201, 98, 5, 12, body.darkened(0.15))
	line(Vector2i(204, 110), Vector2i(214, 113), body.darkened(0.08))
	line(Vector2i(204, 111), Vector2i(214, 114), body.darkened(0.08))
	line(Vector2i(213, 112), Vector2i(218, 105), body.darkened(0.05))
	line(Vector2i(214, 112), Vector2i(219, 105), body.darkened(0.05))
	r(217, 102, 3, 4, skin)
	r(219, 100, 2, 6, c("1a1c20"))
	r(219, 101, 1, 4, c("cfe2ff"), true)      # 屏幕
	# 头低下去，往前探
	r(199, 92, 4, 4, skin.darkened(0.1))
	r(197, 81, 12, 13, hair)
	r(198, 80, 9, 1, hair)
	r(205, 86, 4, 8, c("c8c0c8"))           # 被屏幕照白的半张脸
	p(209, 89, c("c8c0c8"))
	p(206, 88, c("1a1412"))
	r(205, 82, 4, 4, hair)
	r(193, 86, 5, 15, hair)
	r(193, 86, 1, 14, rim)
	r(197, 81, 1, 6, rim)


func _kid() -> void:
	_chair(378, false)
	if v != "1930":
		return
	var uni := c("3a6ac8")
	var pants := c("2a3040")
	var hair := c("1c1a1a")
	var skin := c("e6c4a4")
	# 腿：脚够不着地，悬着
	r(368, 121, 22, 5, pants)
	r(368, 126, 4, 14, pants)
	r(365, 140, 7, 3, c("ecece4"))
	# 身子：校服，领口白边
	r(380, 100, 13, 22, uni)
	r(380, 100, 13, 1, uni.lightened(0.2))
	r(381, 101, 5, 2, c("ece8dc"))
	r(391, 101, 2, 20, uni.darkened(0.2))
	# 胳膊：趴在桌上写，袖子一道白杠
	r(360, 110, 24, 4, uni)
	r(366, 111, 2, 2, c("ece8dc"))
	r(356, 110, 4, 4, skin)
	line(Vector2i(355, 109), Vector2i(352, 113), c("e8c84a"))
	# 头：低着，往前探
	r(375, 87, 12, 13, hair)
	r(376, 86, 9, 1, hair)
	r(375, 92, 4, 8, skin)
	p(374, 96, skin)
	p(376, 94, c("1a1412"))
	r(375, 87, 4, 5, hair)


func _table() -> void:
	var top := c("8a6a4c")
	r(TX0, TY, TX1 - TX0, 4, top)
	r(TX0, TY, TX1 - TX0, 1, top.lightened(0.18))
	r(TX0 + 2, TY + 4, TX1 - TX0 - 4, 4, top.darkened(0.3))
	for lx in [TX0 + 6, TX1 - 10]:
		r(lx, TY + 8, 4, 152 - TY - 8, top.darkened(0.25))
		r(lx, TY + 8, 1, 152 - TY - 8, top.darkened(0.1))


## 你的椅子：在桌子前面、背对镜头，空着
func _your_chair() -> void:
	var ch := c("6a503c")
	var x := 283
	r(x, 119, 3, 38, ch)
	r(x + 18, 119, 3, 38, ch)
	r(x, 119, 21, 4, ch)
	r(x, 119, 21, 1, ch.lightened(0.2))
	r(x + 3, 130, 15, 2, ch.darkened(0.1))
	r(x + 3, 138, 15, 2, ch.darkened(0.1))
	r(x - 1, 157, 23, 1, c("2a201a"))


## 你那碗扣着一个盘子
func _covered(x: int) -> void:
	_bowl(x, false)
	r(x - 2, TY - 7, 14, 3, c("d8d8d0"))
	r(x - 2, TY - 7, 14, 1, c("ecece4"))
	r(x + 3, TY - 8, 4, 1, c("b8b8b0"))


func _bowl(x: int, steam: bool) -> void:
	var b := c("e6e2d6")
	r(x, TY - 4, 10, 3, b)
	r(x + 1, TY - 1, 8, 1, b.darkened(0.2))
	r(x, TY - 4, 10, 1, c("c8c0b0"))
	r(x + 1, TY - 4, 8, 1, c("f6f2ea"))
	if steam:
		for k in [Vector2i(3, -7), Vector2i(4, -10), Vector2i(3, -13), Vector2i(6, -9), Vector2i(7, -12), Vector2i(6, -15)]:
			p(x + k.x, TY + k.y, c("f0ece4"), true)


func _tabletop() -> void:
	if v == "2030":
		_covered(288)
		r(314, TY - 3, 20, 3, c("e8e4d8"))            # 剩菜
		r(318, TY - 4, 10, 1, c("a85a3a"))
		return
	if v == "2230":
		_covered(288)
		r(304, TY - 2, 9, 2, c("e8d870"))             # 便签
		r(305, TY - 2, 6, 1, c("8a7a48"))
		return
	_bowl(240, true)                 # 老婆的
	_bowl(288, true)                 # 你的，热的，没人动
	r(300, TY - 1, 11, 1, c("3a2a1a"))
	r(300, TY - 2, 11, 1, c("4a3828"))
	r(314, TY - 3, 20, 3, c("e8e4d8"))            # 一盘菜
	r(316, TY - 4, 16, 1, c("d06a3a"))
	r(318, TY - 5, 5, 1, c("7aa04a")); r(325, TY - 5, 4, 1, c("7aa04a"))
	_bowl(336, false)                # 孩子的，推到一边
	r(342, TY - 2, 16, 2, c("f2f0e8"))            # 作业本
	r(344, TY - 2, 6, 1, c("a8b8d8"))


# ---------- 光 ----------

func _light() -> void:
	var dark := Vector3(0.30, 0.32, 0.44)
	var warm := Vector3(1.10, 1.00, 0.84)
	var lamp := {"1930": 1.0, "2030": 0.72, "2230": 0.0}[v] as float
	if v == "2230":
		dark = Vector3(0.11, 0.13, 0.22)
		warm = Vector3(0.40, 0.46, 0.70)     # 没开灯，只有窗外的冷光
	for y in H:
		for x in W:
			var i := y * W + x
			var col := img.get_pixel(x, y)
			if emis[i] == 1:
				continue
			var d := Vector2(x, y).distance_to(LAMP)
			var rad := clampf(1.0 - d / 340.0, 0, 1)
			var cone := 0.0
			if y >= 60:
				var hw := 14.0 + (y - 60) * 1.18
				cone = clampf((hw - absf(x - LAMP.x)) / 8.0, 0, 1) * (1.0 - clampf((y - 60) / 260.0, 0, 0.45))
			var L := (0.2 + (0.34 * rad + 0.55 * cone) * lamp) * occl[i]
			if v == "2230":
				var dw := Vector2(x, y).distance_to(Vector2(86, 80))
				L = (0.1 + 0.6 * clampf(1.0 - dw / 280.0, 0, 1)) * occl[i]
			L = quant(L, 5, x, y)
			var t := dark.lerp(warm, L)
			var o := Vector3(col.r, col.g, col.b) * t
			# 2230 电饭煲红灯：一小圈光
			if v == "2230":
				var dr := Vector2(x, y).distance_to(Vector2(166, 106))
				o += Vector3(0.10, 0.01, 0.0) * quant(clampf(1.0 - dr / 9.0, 0, 1), 2, x, y)
			# 窗外冷光：铺到地板上一块
			if y >= 150:
				var a0 := 30.0 + (y - 150) * 0.9
				var a1 := 146.0 + (y - 150) * 1.6
				var e := clampf(minf(x - a0, a1 - x) / 8.0, 0, 1) * (1.0 - (y - 150) / 60.0)
				if e > 0 and quant(e * 0.6, 2, x, y) > 0:
					o += Vector3(-0.01, 0.03, 0.09) * (1.6 if v == "2230" else 1.0)
				# 门缝的光铺到地上
				var b0 := 484.0 - (y - 150) * 0.35
				var b1 := 494.0 + (y - 150) * 1.3
				var e2 := clampf(minf(x - b0, b1 - x) / 6.0, 0, 1) * (1.0 - (y - 150) / 48.0)
				var q := quant(e2, 2, x, y)
				if q > 0 and v == "1930":
					o += Vector3(0.20, 0.15, 0.05) * q
			img.set_pixel(x, y, Color(clampf(o.x, 0, 1), clampf(o.y, 0, 1), clampf(o.z, 0, 1)))


## 对比：每个钟点按游戏里的裁切（y 8..168），上旧下新，2 倍
func _compare() -> void:
	var cmp := Image.create(W, (160 * 2 + 4) * 3 + 8, false, Image.FORMAT_RGBA8)
	cmp.fill(c("141414"))
	for k in 3:
		var y0 := k * (160 * 2 + 8)
		cmp.blit_rect(olds[k], Rect2i(0, 8, W, 160), Vector2i(0, y0))
		cmp.blit_rect(news[k], Rect2i(0, 8, W, 160), Vector2i(0, y0 + 162))
	cmp.resize(W * 2, cmp.get_height() * 2, Image.INTERPOLATE_NEAREST)
	cmp.save_png(OUT + "样板图_回家改版_对比.png")
