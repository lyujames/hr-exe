class_name BookingScreen extends Control
## 约面：日结单之后，今天筛过的人摊在桌上，明天 15:00 只有一个面试名额。
## 规则只管能不能要，约谁得看人：项目、角色、做了多久、自评，都在简历第二页。
## 没约的人进人才库，这个月不会再来；月底回顾按“没约”写（GameState.unbooked）。

signal finished

const LIST_X := 16.0
const LIST_TOP := 52.0
const ROW_H := 24.0
const DOC_POS := Vector2(196, 34)
const SIDE_X := 442.0

var _people: Array[Candidate] = []
var _picked := -1
var _rows: Array[Button] = []
var _doc: ResumeDoc
var _book_button: Button
var _who: Label


func _ready() -> void:
	_people = GameState.passed_today.duplicate()
	UI.panel(self, Rect2(0, 0, 640, 360), UI.DESK)
	UI.panel(self, Rect2(0, 0, 640, 18), UI.DESK_DARK)
	UI.label(self, "第 %d 天　约面" % GameState.day, Vector2(6, 1), UI.TEXT_DIM)
	UI.label(self, "明天 15:00 只有一个面试名额。", Vector2(LIST_X, 26), UI.GREEN)

	for i in _people.size():
		var c := _people[i]
		var row := UI.text_button(self, "%s · %s" % [c.display_name, c.applied_position.trim_suffix("实习生")], Rect2(LIST_X, LIST_TOP + i * ROW_H, 168, 22), _show.bind(i))
		row.toggle_mode = true
		_rows.append(row)

	_build_side()
	_show(0)


func _build_side() -> void:
	var y := 34.0
	var need: Dictionary = GameState.config.chief_need
	if not need.is_empty():
		var sticky := UI.panel(self, Rect2(SIDE_X, y, 184, 62), UI.YELLOW)
		sticky.rotation = -0.03
		UI.label(sticky, "赵主管今早贴的：", Vector2(6, 3), UI.INK_SOFT)
		UI.label(sticky, String(need.note), Vector2(6, 19), UI.INK, 172)
		y += 74.0
		UI.label(self, "约来的人录了、简历对得上，推荐奖 ¥%d。" % int(GameState.pay.get("chief_bonus", 0)), Vector2(SIDE_X, y), UI.TEXT_DIM, 184)
		y += 36.0
	UI.label(self, "规则管的是能不能要。\n约谁，看简历第二页：\n项目、角色、做了多久、自评。", Vector2(SIDE_X, y), UI.TEXT_DIM, 184)
	y += 58.0
	UI.label(self, "没约的人进人才库，这个月不会再来。", Vector2(SIDE_X, y), UI.TEXT_DIM, 184)
	_who = UI.label(self, "", Vector2(SIDE_X, 270), UI.TEXT, 184)
	_book_button = UI.button(self, "约 TA 明天来", Rect2(SIDE_X, 296, 184, 28), _confirm)


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
	_who.text = "约：" + _people[i].display_name


func _confirm() -> void:
	GameState.book(_people[_picked])
	finished.emit()
