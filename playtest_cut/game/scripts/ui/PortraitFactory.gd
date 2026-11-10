class_name PortraitFactory
## 64×64 部件化头像：脸型、发型、眼镜、衣服、表情。美术到位前用程序拼装。

enum Frame { NEUTRAL, BLINK, EYES_LEFT, EYES_RIGHT, SWEAT }

const SIZE := 64
const SKINS := ["e0c0a4", "d3ad8d", "bd9474", "e6cbb5"]
const HAIRS := ["1c1d20", "33292a", "54463c", "6b6f70", "22262e"]
const CLOTHES := ["3b4a57", "4a4f55", "2f3a3a", "57606a", "39453f"]

static var _cache := {}


static func make(seed_value: int, frame: Frame = Frame.NEUTRAL) -> ImageTexture:
	var key := [seed_value, frame]
	if not _cache.has(key):
		_cache[key] = ImageTexture.create_from_image(_draw(seed_value, frame))
	return _cache[key]


## 这个种子画出来是哪种发型（0–4，3 是长发、4 是盘发）：和 _draw 抽随机数的顺序一致。
static func style_of(seed_value: int) -> int:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	rng.randi_range(0, SKINS.size() - 1)
	rng.randi_range(0, HAIRS.size() - 1)
	rng.randi_range(0, CLOTHES.size() - 1)
	rng.randi_range(22, 28)
	rng.randi_range(26, 30)
	return rng.randi_range(0, 4)


## 从 base 往后找一个看得出男女的种子：女的长发或盘发，男的短发。
static func seed_for(base: int, female: bool) -> int:
	for k in 64:
		var style := style_of(base + k)
		if (style >= 3) == female:
			return base + k
	return base


static func _draw(seed_value: int, frame: Frame) -> Image:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color("5a6763"))
	var skin := Color(SKINS[rng.randi_range(0, SKINS.size() - 1)])
	var hair := Color(HAIRS[rng.randi_range(0, HAIRS.size() - 1)])
	var cloth := Color(CLOTHES[rng.randi_range(0, CLOTHES.size() - 1)])
	var face_w := rng.randi_range(22, 28)
	var face_h := rng.randi_range(26, 30)
	var style := rng.randi_range(0, 4)
	var glasses := rng.randf() < 0.35
	var left := 32 - face_w / 2
	var top := 15
	# 衣服与脖子
	img.fill_rect(Rect2i(10, 52, 44, 12), cloth)
	img.fill_rect(Rect2i(6, 56, 52, 8), cloth)
	img.fill_rect(Rect2i(28, 42, 8, 11), skin.darkened(0.12))
	img.fill_rect(Rect2i(29, 52, 6, 4), Color("cfd4cf"))
	# 长发在脸后
	if style == 3:
		img.fill_rect(Rect2i(left - 3, top - 1, face_w + 6, 34), hair)
	# 脸
	img.fill_rect(Rect2i(left, top, face_w, face_h), skin)
	img.fill_rect(Rect2i(left + 1, top + face_h, face_w - 2, 2), skin)
	img.fill_rect(Rect2i(left - 1, top + 12, 1, 6), skin.darkened(0.1))
	img.fill_rect(Rect2i(left + face_w, top + 12, 1, 6), skin.darkened(0.1))
	# 发型
	match style:
		0:
			img.fill_rect(Rect2i(left - 1, top - 3, face_w + 2, 8), hair)
		1:
			img.fill_rect(Rect2i(left - 1, top - 4, face_w + 2, 6), hair)
			img.fill_rect(Rect2i(left - 1, top + 2, 8, 5), hair)
		2:
			img.fill_rect(Rect2i(left + 3, top - 2, face_w - 6, 3), hair)
			img.fill_rect(Rect2i(left - 1, top, 3, 7), hair)
			img.fill_rect(Rect2i(left + face_w - 2, top, 3, 7), hair)
		3:
			img.fill_rect(Rect2i(left - 1, top - 3, face_w + 2, 7), hair)
		4:
			img.fill_rect(Rect2i(left - 1, top - 3, face_w + 2, 6), hair)
			img.fill_rect(Rect2i(26, top - 9, 12, 7), hair)
	# 眼睛
	var eye_y := top + 13
	var eye_l := 32 - 7
	var eye_r := 32 + 4
	if frame == Frame.BLINK:
		img.fill_rect(Rect2i(eye_l, eye_y + 1, 4, 1), INK_EYE)
		img.fill_rect(Rect2i(eye_r, eye_y + 1, 4, 1), INK_EYE)
	else:
		var shift := -1 if frame == Frame.EYES_LEFT else (1 if frame == Frame.EYES_RIGHT else 0)
		img.fill_rect(Rect2i(eye_l, eye_y, 4, 3), Color("e9ecea"))
		img.fill_rect(Rect2i(eye_r, eye_y, 4, 3), Color("e9ecea"))
		img.fill_rect(Rect2i(eye_l + 1 + shift, eye_y, 2, 3), INK_EYE)
		img.fill_rect(Rect2i(eye_r + 1 + shift, eye_y, 2, 3), INK_EYE)
	if glasses:
		var rim := Color("15191a")
		for x: int in [eye_l - 2, eye_r - 2]:
			img.fill_rect(Rect2i(x, eye_y - 2, 8, 1), rim)
			img.fill_rect(Rect2i(x, eye_y + 4, 8, 1), rim)
			img.fill_rect(Rect2i(x, eye_y - 2, 1, 7), rim)
			img.fill_rect(Rect2i(x + 7, eye_y - 2, 1, 7), rim)
		img.fill_rect(Rect2i(30, eye_y, 4, 1), rim)
	# 鼻与嘴
	img.fill_rect(Rect2i(31, top + 18, 2, 2), skin.darkened(0.18))
	img.fill_rect(Rect2i(28, top + 23, 8, 1), skin.darkened(0.42))
	if frame == Frame.SWEAT:
		img.fill_rect(Rect2i(left + face_w - 3, top + 6, 2, 3), Color("9fd3ea"))
		img.fill_rect(Rect2i(left + face_w - 2, top + 9, 2, 3), Color("9fd3ea"))
		img.fill_rect(Rect2i(left + 2, top + 9, 2, 3), Color("9fd3ea"))
	return img


const INK_EYE := Color("15191a")
