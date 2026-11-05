class_name DeskLayout
## 玩家自己布置的桌面：每样东西放在哪。存在 user:// 里，跟存档无关，换一局也照旧。

const PATH := "user://desk_layout.json"
## 能挪的东西：名字、默认位置、大小（布置时画的占位框）。
const ITEMS := {
	"resume": {"name": "简历", "pos": Vector2(100, 24), "size": Vector2(232, 268)},
	"id_card": {"name": "身份证", "pos": Vector2(350, 246), "size": Vector2(170, 72)},
	"rulebook": {"name": "规则手册", "pos": Vector2(344, 24), "size": Vector2(186, 212)},
	"posting": {"name": "岗位 JD", "pos": Vector2(532, 24), "size": Vector2(106, 232)},
	"photo": {"name": "全家福", "pos": Vector2(16, 48), "size": Vector2(64, 50)},
	"phone": {"name": "手机", "pos": Vector2(32, 112), "size": Vector2(30, 52)},
	"pass": {"name": "通过章", "pos": Vector2(112, 306), "size": Vector2(92, 40)},
	"reject": {"name": "拒绝章", "pos": Vector2(216, 306), "size": Vector2(92, 40)},
	"inspect": {"name": "质询", "pos": Vector2(536, 296), "size": Vector2(60, 48)},
	"printer": {"name": "打印机", "pos": Vector2(536, 262), "size": Vector2(100, 32)},
}
## 顶上那条状态栏不让放。
const TOP := 18.0

static var _cache := {}
static var _loaded := false


static func pos(key: String) -> Vector2:
	_load()
	return _cache.get(key, ITEMS[key].pos)


static func size_of(key: String) -> Vector2:
	return ITEMS[key].size


static func clamp_pos(key: String, at: Vector2) -> Vector2:
	var limit := Vector2(640, 360) - size_of(key)
	return at.clamp(Vector2(0, TOP), limit.max(Vector2(0, TOP))).round()


## 平时拖文件松手时记一样东西；别的照旧。
static func set_pos(key: String, at: Vector2) -> void:
	_load()
	var layout := _cache.duplicate()
	layout[key] = clamp_pos(key, at)
	save(layout)


static func save(layout: Dictionary) -> void:
	_cache = layout.duplicate()
	_loaded = true
	var out := {}
	for key: String in _cache:
		out[key] = [_cache[key].x, _cache[key].y]
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(out))


static func defaults() -> Dictionary:
	var out := {}
	for key: String in ITEMS:
		out[key] = ITEMS[key].pos
	return out


static func _load() -> void:
	if _loaded:
		return
	_loaded = true
	if not FileAccess.file_exists(PATH):
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if data is not Dictionary:
		return
	for key: String in data:
		var v = data[key]
		if key in ITEMS and v is Array and v.size() == 2:
			_cache[key] = clamp_pos(key, Vector2(float(v[0]), float(v[1])))
