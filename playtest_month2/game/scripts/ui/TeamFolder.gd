class_name TeamFolder extends Control
## 按组招的日子桌上的文件夹：一个组一个。简历拖到上面松手 = 放进这个组（Desk 判断松手的位置）。
## 写着组名、加班强度（星）、技术方向、本组薪资上限、名额；名额满了标红。鼠标停上去看组长贴的那句话。

const SIZE := Vector2(104, 40)
const BODY := Color("b39a64")
const TAB := Color("9c8455")

var posting: JobPosting
var _frame: Panel
var _line2: Label


func setup(p: JobPosting) -> void:
	posting = p
	size = SIZE
	mouse_filter = Control.MOUSE_FILTER_PASS
	tooltip_text = p.folder_note
	UI.panel(self, Rect2(4, 0, 36, 7), TAB, UI.BLACK)
	UI.panel(self, Rect2(0, 5, SIZE.x, SIZE.y - 5), BODY, UI.BLACK)
	_frame = UI.panel(self, Rect2(1, 6, SIZE.x - 2, SIZE.y - 7), Color.TRANSPARENT, UI.GREEN)
	(_frame.get_theme_stylebox("panel") as StyleBoxFlat).set_border_width_all(2)
	_frame.visible = false
	UI.label(self, "%s %s" % [short_name(p.team), "★".repeat(p.workload)], Vector2(4, 5), UI.INK)
	_line2 = UI.label(self, "", Vector2(4, 21), UI.INK_SOFT)
	refresh()


## 组名太长就去掉“组”字，好把星放下。
static func short_name(team: String) -> String:
	return team.trim_suffix("组") if team.length() >= 4 else team


func refresh() -> void:
	var n := GameState.folder_count(posting)
	# 写了方向（前端 / 后端 / 运维）的，方向顶掉“名额”两个字，免得一行放不下
	var head := posting.role + " " if posting.role != "" else ""
	if n >= posting.hc:
		_line2.text = "%s≤%dk · 满 %d/%d" % [head, posting.salary_cap_k, n, posting.hc]
		_line2.add_theme_color_override("font_color", UI.RED)
	else:
		_line2.text = "%s≤%dk · %s%d/%d" % [head, posting.salary_cap_k, "" if head else "名额 ", n, posting.hc]
		_line2.add_theme_color_override("font_color", UI.INK_SOFT)


func set_hot(on: bool) -> void:
	_frame.visible = on


func contains(global_point: Vector2) -> bool:
	return get_global_rect().has_point(global_point)
