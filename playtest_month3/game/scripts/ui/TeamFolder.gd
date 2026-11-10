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
	# 组名加星：放不下先去掉空格，再不行写成“★×4”
	var title := UI.label(self, "", Vector2(4, 5), UI.INK)
	var team_name := short_name(p.team)
	var stars := "★".repeat(p.workload)
	title.text = "%s ★×%d" % [team_name, p.workload]
	for t: String in ["%s %s" % [team_name, stars], team_name + stars]:
		if _fits(title, t):
			title.text = t
			break
	_line2 = UI.label(self, "", Vector2(4, 21), UI.INK_SOFT)
	refresh()


## 组名太长就去掉“组”字，好把星放下。
static func short_name(team: String) -> String:
	return team.trim_suffix("组") if team.length() >= 4 else team


func refresh() -> void:
	var n := GameState.folder_count(posting)
	var full := n >= posting.hc
	# 写了方向（前端 / 后端 / 运维）的，方向顶掉“名额”两个字；一行还放不下就去掉空格和点，再不行连“满”也去掉（红字已经说明满了）
	var head := posting.role if posting.role != "" else ""
	var count := "%d/%d" % [n, posting.hc]
	var tries: Array[String] = []
	if head != "":
		tries.append("%s ≤%dk · %s%s" % [head, posting.salary_cap_k, "满 " if full else "", count])
		tries.append("%s≤%dk %s%s" % [head, posting.salary_cap_k, "满" if full else "", count])
		tries.append("%s≤%dk %s" % [head, posting.salary_cap_k, count])
	else:
		tries.append("≤%dk · %s%s" % [posting.salary_cap_k, "满 " if full else "名额 ", count])
		tries.append("≤%dk %s" % [posting.salary_cap_k, count])
	_line2.text = tries[-1]
	for t in tries:
		if _fits(_line2, t):
			_line2.text = t
			break
	_line2.add_theme_color_override("font_color", UI.RED if full else UI.INK_SOFT)


func _fits(l: Label, text: String) -> bool:
	var font := l.get_theme_font("font")
	return font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, l.get_theme_font_size("font_size")).x <= SIZE.x - 8


func set_hot(on: bool) -> void:
	_frame.visible = on


func contains(global_point: Vector2) -> bool:
	return get_global_rect().has_point(global_point)
