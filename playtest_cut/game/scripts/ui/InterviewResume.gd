class_name InterviewResume extends Control
## 面试桌上摊开的那份简历：筛简历时那份的内容，排成一页。
## 能问的行带个小点：点一下就是问这一行（占一问）；尖锐卡拖到行上，是把这一行问穿。
## 纸边的红笔（InterviewRoom 画的）拿起来以后，点哪行圈哪行（不占问），圈出来的是你的疑点，带到评分表上。
## 纸不画框，高度跟着内容走，最高到 SIZE.y；页签在纸外头，由 InterviewRoom 画。
## 问出来的反应贴在行尾：认了水分（黄）、支支吾吾（灰）、一追就答不上（红）。

signal line_asked(line: Dictionary)
signal sharp_dropped(line: Dictionary, card: QuestionCard)
signal circled_changed

const SIZE := Vector2(300, 180)
const MIN_H := 96.0
const PAD := 6.0
## 排在同一行、一个挨一个的（学历和年限一排，技能一排）；其余的一行一条，自评最多两行。
const INLINE := ["edu", "exp", "major", "gpa", "schedule"]
const MAX_ROWS := 2
## 行距收紧一点：这套像素字自带的行高留白太多，四段工作加空窗会挤出纸。
const TIGHTEN := 3
const MARK_COLORS := {"认了": Color("b08a1a"), "支吾": Color("6b6b6b"), "答不上": Color("b03a2e")}
## 笔录上对质的结果：问出来了（红）、圆过去了（灰蓝）。
const HIT_COLOR := Color("c0392b")
const MISS_COLOR := Color("5a6b7a")

var candidate: Candidate
## 手牌开着才能问；红笔什么时候都能用。
var open := true
var pen := false
## 圈了哪些行（key），按圈的先后。
var circled: PackedStringArray = []
var marks := {}
## 自我介绍里和这一行对不上的：{key: {said: 那句话, label: 对不上 / 没提}}。行下画红波浪，点它就是对质。
var conflicts := {}
## 说中的行盖“查实”红戳；问出真的的行，原文红笔划掉，后面写上真的（key → 文字）。
var stamps: PackedStringArray = []
var truths := {}
var _lines: Array[Dictionary] = []
var _spots := {}
var _paper: Panel
var _hint: Label
var _layer: Control


func setup(c: Candidate) -> void:
	candidate = c
	size = SIZE
	_lines = ResumeQuestions.lines(c)
	_paper = UI.panel(self, Rect2(Vector2.ZERO, SIZE), UI.PAPER_RESUME)
	var age := c.get_age(GameState.today)
	var head := "%s · %d 岁" % [c.display_name, age]
	if not c.is_intern:
		head += " · 期望 " + c.salary_text()
	UI.label(self, head, Vector2(PAD + 2, 4), UI.INK_SOFT)
	_hint = UI.label(self, "点一行问这一行 · 拿红笔圈疑点", Vector2.ZERO, Color("9a9a9a"))
	_layer = Control.new()
	_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_layer)
	_render()


func _render() -> void:
	UI.clear(_layer)
	_spots.clear()
	var row := _row_height()
	var y := 23.0
	var x := PAD
	var group := ""
	for line in _lines:
		var g := "head" if line.key in INLINE else ("skill" if line.kind == "skill" else "")
		if g != group:
			if group != "":
				y += row
			x = PAD
			group = g
			if g == "skill":
				var tag := UI.label(_layer, "技能", Vector2(PAD, y), UI.INK_SOFT)
				x = PAD + tag.get_combined_minimum_size().x + 6
		if g != "":
			var chip := UI.label(_layer, line.text, Vector2.ZERO, UI.INK if line.kind != "" else UI.INK_SOFT)
			var w := chip.get_combined_minimum_size().x
			var extra := _note_width(line.key)
			var indent := PAD + (36.0 if g == "skill" else 0.0)
			if x + w + extra > SIZE.x - PAD and x > indent:
				x = indent
				y += row
			chip.position = Vector2(x, y)
			_spot(line, Rect2(x - 2, y, w + 4, row))
			_note(line.key, Vector2(x, y), w, row)
			x += w + extra + 10
			continue
		var width := SIZE.x - PAD * 2 - 8
		# 纸写满了：后面的行不印（四段工作加空窗再加一长串技能才会碰到）
		var left := int((SIZE.y - 4 - y) / row)
		if left < 1:
			break
		var label := UI.label(_layer, line.text, Vector2(PAD + 8, y), UI.INK if line.kind != "" else UI.INK_SOFT, width)
		label.add_theme_constant_override("line_spacing", -TIGHTEN)
		var rows := clampi(label.get_line_count(), 1, mini(MAX_ROWS, left))
		label.max_lines_visible = rows
		if truths.has(line.key) or line.key in stamps:
			var tw := minf(_text_width(line.text), width - _note_width(line.key))
			_note(line.key, Vector2(PAD + 8, y), tw, row)
		if line.kind != "":
			UI.label(_layer, "·", Vector2(PAD, y), Color("3f6fa0"))
			_spot(line, Rect2(PAD, y, width + 8, rows * row))
		y += rows * row
	if group != "":
		y += row
	# 纸跟着内容高；还有地方就在最下面压一行提示，写满了就不压
	_hint.visible = y + row + 4 <= SIZE.y
	var h := clampf(y + (row + 4 if _hint.visible else 2), MIN_H, SIZE.y)
	size = Vector2(SIZE.x, h)
	_paper.size = size
	_hint.position = Vector2(PAD + 2, h - row - 3)


func _row_height() -> float:
	var probe := UI.label(self, "字", Vector2.ZERO)
	var h := probe.get_combined_minimum_size().y
	probe.free()
	return h - TIGHTEN


## 一行的可点区域：点了问（或圈），尖锐卡能放下来。
func _spot(line: Dictionary, rect: Rect2) -> void:
	var key: String = line.key
	if key in circled:
		var ring := UI.panel(_layer, rect.grow(1), Color.TRANSPARENT, UI.RED)
		ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# 问出来的反应：技能、学历这种挤在一排的画下划线，整行的在左边画一道竖条，行尾写字
	# 整行盖了戳的，戳顶替行尾那个小标签
	if marks.has(key) and not (key in stamps and not (line.key in INLINE or line.kind == "skill")):
		var tag: String = marks[key]
		var color: Color = MARK_COLORS[tag]
		if line.key in INLINE or line.kind == "skill":
			UI.panel(_layer, Rect2(rect.position.x + 2, rect.end.y - 2, rect.size.x - 4, 2), color)
		else:
			UI.panel(_layer, Rect2(1, rect.position.y + 1, 3, rect.size.y - 2), color)
			var t := UI.label(_layer, tag, Vector2.ZERO, UI.PAPER)
			var w := t.get_combined_minimum_size().x
			t.position = Vector2(SIZE.x - PAD - w, rect.position.y)
			var bg := UI.panel(_layer, Rect2(t.position - Vector2(2, 0), Vector2(w + 4, rect.size.y if rect.size.y < 20 else 16)), color)
			_layer.move_child(bg, t.get_index())
	if conflicts.has(key) and not marks.has(key):
		_wave(Rect2(rect.position.x + 2, rect.end.y - 3, rect.size.x - 4, 3))
		# 整行的在左边画一道红条（压住那个小圆点）；挤在一排的只有波浪。是“对不上”还是“没提”，鼠标停上去看
		if not (line.key in INLINE or line.kind == "skill"):
			UI.panel(_layer, Rect2(1, rect.position.y + 1, 4, rect.size.y - 2), UI.RED)
	if line.kind == "":
		return
	var spot := Button.new()
	spot.focus_mode = Control.FOCUS_NONE
	spot.flat = true
	spot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	spot.position = rect.position
	spot.size = rect.size
	spot.tooltip_text = "红笔圈出 / 擦掉" if pen else ("对质：%s（占一问）" % conflicts[key].label if conflicts.has(key) else "问这一行")
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(UI.RED if pen else UI.YELLOW, 0.3)
	spot.add_theme_stylebox_override("hover", hover)
	spot.add_theme_stylebox_override("pressed", hover)
	spot.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	spot.pressed.connect(_on_spot.bind(line))
	spot.set_drag_forwarding(Callable(),
		func(_at: Vector2, data: Variant) -> bool: return _can_take(data),
		func(_at: Vector2, data: Variant) -> void: sharp_dropped.emit(line, data.question_card))
	_layer.add_child(spot)
	_spots[key] = spot


func _can_take(data: Variant) -> bool:
	return open and data is Dictionary and data.has("question_card") and data.question_card.sharp


func _on_spot(line: Dictionary) -> void:
	if pen:
		var key: String = line.key
		var i := circled.find(key)
		if i >= 0:
			circled.remove_at(i)
		else:
			circled.append(key)
		Sfx.key()
		_render()
		circled_changed.emit()
	elif open:
		line_asked.emit(line)


func toggle_pen() -> void:
	pen = not pen
	_hint.text = "拿着红笔：点一行圈出，再点擦掉" if pen else "点一行问这一行 · 拿红笔圈疑点"
	_hint.add_theme_color_override("font_color", UI.RED if pen else Color("9a9a9a"))
	_render()


## 一道红波浪线：两排错开的小点。
func _wave(r: Rect2) -> void:
	var x := r.position.x
	var i := 0
	while x < r.end.x:
		var dot := UI.panel(_layer, Rect2(x, r.position.y + (0 if i % 2 == 0 else 2), 2, 1), UI.RED)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		x += 2
		i += 1


## 划掉原文、写上真的、盖戳，画在 at 起宽 w 的那段字后面。
func _note(key: String, at: Vector2, w: float, row: float) -> void:
	var x := at.x + w
	if truths.has(key):
		var strike := UI.panel(_layer, Rect2(at.x - 1, at.y + row * 0.5, w + 2, 1), UI.RED)
		strike.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var real := UI.label(_layer, "→" + String(truths[key]), Vector2(x + 2, at.y), UI.RED)
		real.mouse_filter = Control.MOUSE_FILTER_IGNORE
		x += 2 + real.get_combined_minimum_size().x
	if key in stamps:
		var box := Control.new()
		box.position = Vector2(x + 3, at.y)
		box.rotation = -0.12
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_layer.add_child(box)
		# 问出真的才叫查实；只是支吾、答不上，是你说中了
		var t := UI.label(box, "查实" if truths.has(key) else "说中", Vector2(3, -1), UI.RED)
		UI.panel(box, Rect2(Vector2.ZERO, Vector2(t.get_combined_minimum_size().x + 6, row)), Color.TRANSPARENT, UI.RED)


## _note 画出来要占多宽（换行时要算进去）。
func _note_width(key: String) -> float:
	var w := 0.0
	if truths.has(key):
		w += 2 + _text_width("→" + String(truths[key]))
	if key in stamps:
		w += 3 + _text_width("查实") + 6
	return w


func _text_width(text: String) -> float:
	var probe := UI.label(self, text, Vector2.ZERO)
	var w := probe.get_combined_minimum_size().x
	probe.free()
	return w


func stamp(key: String) -> void:
	if key not in stamps:
		stamps.append(key)
		_render()


func set_truth(key: String, text: String) -> void:
	truths[key] = text
	_render()


func set_conflict(key: String, said: Dictionary, label: String) -> void:
	var entry := said.duplicate()
	entry.label = label
	conflicts[key] = entry
	_render()


func clear_conflict(key: String) -> void:
	conflicts.erase(key)
	_render()


static func tag_color(tag: String) -> Color:
	if tag.ends_with("对质") or "被你说中" in tag or tag.ends_with("不该过"):
		return HIT_COLOR
	return MARK_COLORS.get(tag, MISS_COLOR)


func set_open(on: bool) -> void:
	open = on


func mark(key: String, tag: String) -> void:
	# 答不上压过支吾，支吾压过认了
	var order := ["认了", "支吾", "答不上"]
	if marks.has(key) and order.find(marks[key]) >= order.find(tag):
		return
	marks[key] = tag
	_render()


func line_by_key(key: String) -> Dictionary:
	for line in _lines:
		if line.key == key:
			return line
	return {}


## 评分表上印的疑点：圈过的行，原样抄下来。
func doubt_texts() -> PackedStringArray:
	var out: PackedStringArray = []
	for key in circled:
		var line := line_by_key(key)
		if not line.is_empty():
			out.append(line.text)
	return out
