class_name ResumeDoc extends DraggableDoc
## 一份简历，两页：第 1 页基本信息，第 2 页工作经历与自我评价。

signal stamped(verdict: String, at: Vector2)

const SIZE := Vector2(232, 268)

var candidate: Candidate
var page := 0
var is_stamped := false
var _content: Control


func setup(c: Candidate) -> void:
	candidate = c
	size = SIZE
	UI.panel(self, Rect2(Vector2(2, 2), SIZE), UI.BLACK)
	UI.panel(self, Rect2(Vector2.ZERO, SIZE), UI.PAPER, UI.PAPER_DIM)
	_content = Control.new()
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_content)
	UI.button(self, "翻页", Rect2(186, 247, 40, 18), flip)
	_render()


func flip() -> void:
	page = 1 - page
	Sfx.paper()
	_render()


func _render() -> void:
	UI.clear(_content)
	UI.label(_content, "%d/2" % (page + 1), Vector2(162, 249), UI.INK_SOFT)
	if page == 0:
		_render_front()
	else:
		_render_back()


func _render_front() -> void:
	var c := candidate
	var photo := PortraitView.new()
	photo.setup(c.portrait_seed)
	photo.position = Vector2(8, 8)
	photo.set_process(false)
	_content.add_child(photo)
	UI.label(_content, c.display_name, Vector2(80, 8), UI.INK)
	UI.label(_content, "应聘：" + c.applied_position, Vector2(80, 26), UI.INK)
	UI.label(_content, "出生：" + c.birth_date, Vector2(80, 44), UI.INK)
	var line := 82
	var degree := "学历：" + c.degree_name() + "　" + c.school
	UI.label(_content, degree, Vector2(8, line), UI.INK)
	line += 16
	if c.degree_note != "":
		UI.label(_content, "（%s）" % c.degree_note, Vector2(8, line), UI.INK_SOFT)
		line += 16
	UI.label(_content, "期望：月薪 %dk × %d 薪" % [c.salary_k, c.salary_months], Vector2(8, line), UI.INK)
	line += 18
	UI.label(_content, "技能：", Vector2(8, line), UI.INK)
	UI.label(_content, " / ".join(c.skills), Vector2(44, line), UI.INK, 180)


func _render_back() -> void:
	var c := candidate
	UI.label(_content, "工作经历（从新到旧）", Vector2(8, 8), UI.INK_SOFT)
	var line := 26
	for job: Dictionary in c.jobs:
		var end: String = job.end.replace("-", ".") if job.end != "" else "至今"
		UI.label(_content, "%s – %s" % [job.start.replace("-", "."), end], Vector2(8, line), UI.INK)
		UI.label(_content, "%s · %s" % [job.company, job.title], Vector2(16, line + 14), UI.INK_SOFT)
		line += 32
	UI.label(_content, "自我评价", Vector2(8, 172), UI.INK_SOFT)
	UI.label(_content, c.self_eval, Vector2(8, 188), UI.INK, 216)
	UI.label(_content, "附：" + c.attachment, Vector2(8, 222), UI.INK_SOFT, 216)


func _can_drop_data(_at: Vector2, data: Variant) -> bool:
	return not is_stamped and data is Dictionary and data.get("type") == "stamp"


func _drop_data(at: Vector2, data: Variant) -> void:
	stamp(data.verdict, at)


func stamp(verdict: String, at: Vector2) -> void:
	is_stamped = true
	var ink := UI.GREEN.darkened(0.3) if verdict == "pass" else UI.RED
	var mark := Control.new()
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mark.position = at.clamp(Vector2(40, 20), SIZE - Vector2(40, 20))
	mark.rotation = randf_range(-0.2, 0.2)
	UI.panel(mark, Rect2(-38, -15, 76, 30), Color(ink, 0.12), ink)
	UI.panel(mark, Rect2(-36, -13, 72, 26), Color.TRANSPARENT, ink)
	var text := UI.label(mark, "通 过" if verdict == "pass" else "拒 绝", Vector2(-36, -8), ink)
	text.size.x = 72
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(mark)
	stamped.emit(verdict, at)
