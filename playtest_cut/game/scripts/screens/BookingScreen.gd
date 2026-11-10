class_name BookingScreen extends Control
## 约面：日结单之后，今天筛过的人摊在桌上，挑明天来面试的人。名额见 GameState.book_slots()：
## 第一个月只有一个；第二个月按组招的日子最多三场（一场一个钟头左右，面完才下班），不按组的日子两场。
## 规则只管能不能要，约谁得看人：项目、角色、做了多久、自评，都在简历第二页。
## 没约的人进人才库，这个月不会再来；月底回顾按“没约”写（GameState.unbooked）。

signal finished

const LIST_X := 16.0
const LIST_TOP := 52.0
const LIST_BOTTOM := 340.0
const ROW_H := 24.0
const DOC_POS := Vector2(196, 34)
const SIDE_X := 442.0

var _people: Array[Candidate] = []
var _picked := -1
var _slots := 1
var _booked: Array[Candidate] = []
var _rows: Array[Button] = []
var _doc: ResumeDoc
var _book_button: Button
var _done_button: Button
var _who: Label


func _ready() -> void:
	_people = GameState.passed_today.duplicate()
	_slots = GameState.book_slots()
	UI.panel(self, Rect2(0, 0, 640, 360), UI.DESK)
	UI.panel(self, Rect2(0, 0, 640, 18), UI.DESK_DARK)
	UI.label(self, "第 %d 天　约面" % GameState.day, Vector2(6, 1), UI.TEXT_DIM)
	UI.label(self, _headline(), Vector2(LIST_X, 26), UI.GREEN)

	var row_h := minf(ROW_H, (LIST_BOTTOM - LIST_TOP) / maxf(1.0, _people.size()))
	for i in _people.size():
		var row := UI.button(self, _row_text(i), Rect2(LIST_X, LIST_TOP + i * row_h, 168, row_h - 2), _show.bind(i))
		row.toggle_mode = true
		row.alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.clip_text = true
		_rows.append(row)

	_build_side()
	_show(0)


func _headline() -> String:
	if _slots == 1:
		return "明天 15:00 只有一个面试名额。"
	return "明天最多约 %d 场，约谁你定。" % _slots


func _team_name(c: Candidate) -> String:
	var t := GameState.team_posting(c)
	if t and t.team != "":
		return t.team
	return c.applied_position.trim_suffix("实习生")


func _row_text(i: int) -> String:
	var c := _people[i]
	var mark := "✓ " if c in _booked else ""
	return "%s%s · %s" % [mark, c.display_name, _team_name(c)]


func _build_side() -> void:
	var y := 34.0
	if GameState.month() == 1:
		y = _build_chief_sticky(y)
		UI.label(self, "规则管的是能不能要。\n约谁，看简历第二页：\n项目、角色、做了多久、自评。", Vector2(SIDE_X, y), UI.TEXT_DIM, 184)
		y += 58.0
	else:
		y = _note("规则管的是能不能要。\n约谁，看简历上的项目和年限。", y)
		if RuleEngine.load_day(GameState.day + 1).team_folders:
			y = _note("一场一个钟头左右，约满 %d 场就过六点了。" % _slots, y)
		if GameState.few_sessions_noted_tomorrow():
			y = _note("面不满两场，王总记一笔。", y, UI.YELLOW)
	_note("没约的人进人才库，这个月不会再来。", y)
	if _slots == 1:
		_who = UI.label(self, "", Vector2(SIDE_X, 270), UI.TEXT, 184)
		_book_button = UI.button(self, "约 TA 明天来", Rect2(SIDE_X, 296, 184, 28), _confirm)
	else:
		_who = UI.label(self, "", Vector2(SIDE_X, 216), UI.TEXT, 184)
		_book_button = UI.button(self, "约 TA 明天来", Rect2(SIDE_X, 270, 184, 26), _toggle)
		_done_button = UI.button(self, "", Rect2(SIDE_X, 302, 184, 28), _confirm)
		_refresh()


## 右栏一段小字，返回下一段的 y。
func _note(text: String, y: float, color := UI.TEXT_DIM) -> float:
	var l := UI.label(self, text, Vector2(SIDE_X, y), color, 184)
	return y + l.get_line_count() * 17.0 + 8.0


## 第一个月：赵主管今早贴的便签（第二个月起他当天开场才拍便签，前一晚看不到）。
func _build_chief_sticky(y: float) -> float:
	var need: Dictionary = GameState.config.chief_need
	if need.is_empty():
		return y
	var sticky := UI.panel(self, Rect2(SIDE_X, y, 184, 62), UI.YELLOW)
	sticky.rotation = -0.03
	UI.label(sticky, "赵主管今早贴的：", Vector2(6, 3), UI.INK_SOFT)
	UI.label(sticky, String(need.note), Vector2(6, 19), UI.INK, 172)
	y += 74.0
	UI.label(self, "约来的人录了、简历对得上，推荐奖 ¥%d。" % int(GameState.pay.get("chief_bonus", 0)), Vector2(SIDE_X, y), UI.TEXT_DIM, 184)
	return y + 36.0


func _show(i: int) -> void:
	_picked = i
	for j in _rows.size():
		_rows[j].set_pressed_no_signal(j == i)
	if _doc:
		_doc.queue_free()
	_doc = load("res://scenes/ResumeDoc.tscn").instantiate()
	_doc.position = DOC_POS
	add_child(_doc)
	_doc.setup(_people[i])
	Sfx.paper()
	if _slots == 1:
		_who.text = "约：" + _people[i].display_name
	else:
		_refresh()


## 约 / 不约正在看的这一份。
func _toggle() -> void:
	var c := _people[_picked]
	if c in _booked:
		_booked.erase(c)
	elif _booked.size() < _slots:
		_booked.append(c)
	Sfx.stamp()
	_refresh()


func _refresh() -> void:
	for j in _rows.size():
		_rows[j].text = _row_text(j)
	var c: Candidate = _people[_picked] if _picked >= 0 else null
	var booked := c != null and c in _booked
	_book_button.text = "不约 TA 了" if booked else "约 TA 明天来"
	_book_button.disabled = not booked and _booked.size() >= _slots
	var names := PackedStringArray(_booked.map(func(p: Candidate) -> String: return p.display_name))
	_who.text = "已约 %d / %d：%s" % [_booked.size(), _slots, "、".join(names) if not names.is_empty() else "还没约"]
	_done_button.text = "就约这 %d 个" % _booked.size() if not _booked.is_empty() else "先约一个"
	_done_button.disabled = _booked.is_empty()


func _confirm() -> void:
	if _slots == 1:
		GameState.book([_people[_picked]] as Array[Candidate])
	else:
		GameState.book(_booked)
	finished.emit()
