class_name ResumeDoc extends DraggableDoc
## 一份简历，两页：第 1 页基本信息，第 2 页工作经历（实习生是在校项目）与自我评价。

signal stamped(verdict: String, at: Vector2)

const SIZE := Vector2(232, 268)

var candidate: Candidate
var page := 0
var is_stamped := false
var _content: Control
var _mark: Control


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
	fields.clear()
	UI.label(_content, "%d/2" % (page + 1), Vector2(162, 249), UI.INK_SOFT)
	if page == 0:
		_render_front()
	else:
		_render_back()
	refresh_hotspots()


func _render_front() -> void:
	var c := candidate
	var photo := PortraitView.new()
	photo.setup(c.portrait_seed)
	photo.position = Vector2(8, 8)
	photo.set_process(false)
	_content.add_child(photo)
	fields.display_name = UI.label(_content, c.fact("display_name"), Vector2(80, 8), UI.INK)
	UI.label(_content, "应聘：" + c.applied_position, Vector2(80, 26), UI.INK)
	var birth := DateUtil.parse(c.fact("birth_date"))
	fields.birth_date = UI.label(_content, "出生：%d 年 %d 月" % [birth.x, birth.y], Vector2(80, 44), UI.INK)
	var line := 82
	var degree := "学历：" + c.degree_name() + ("在读" if c.is_intern else "") + "　" + c.school
	UI.label(_content, degree, Vector2(8, line), UI.INK)
	line += 16
	if c.undergrad_school != "":
		line = _note("（本科：%s）" % c.undergrad_school, line)
	if c.degree_note != "":
		line = _note("（%s）" % c.degree_note, line)
	if c.is_intern:
		UI.label(_content, "专业：" + c.major, Vector2(8, line), UI.INK)
		line += 16
		if c.major_note != "":
			line = _note("（%s）" % c.major_note, line)
		UI.label(_content, "绩点：%.2f / 4.0" % c.gpa, Vector2(8, line), UI.INK)
		line += 16
		UI.label(_content, "可实习：每周 %d 天，%d 个月" % [c.intern_days, c.intern_months], Vector2(8, line), UI.INK)
	else:
		UI.label(_content, "期望：月薪 " + c.salary_text(), Vector2(8, line), UI.INK)
	line += 18
	UI.label(_content, "技能：", Vector2(8, line), UI.INK)
	UI.label(_content, " / ".join(c.skills), Vector2(44, line), UI.INK, 180)


## 学历、专业后面的小字，太长就在纸边折行。返回下一行的位置。
func _note(text: String, line: int) -> int:
	var note := UI.label(_content, text, Vector2(8, line), UI.INK_SOFT, SIZE.x - 16)
	return line + 16 * note.get_line_count()


func _render_back() -> void:
	var c := candidate
	if c.is_intern:
		_render_projects()
	else:
		_render_jobs()
	UI.label(_content, "自我评价", Vector2(8, 172), UI.INK_SOFT)
	UI.label(_content, c.self_eval, Vector2(8, 188), UI.INK, 216)
	UI.label(_content, "附：" + c.attachment, Vector2(8, 222), UI.INK_SOFT, 216)


func _render_projects() -> void:
	UI.label(_content, "在校项目（从新到旧）", Vector2(8, 8), UI.INK_SOFT)
	var line := 26
	for project: Dictionary in candidate.projects:
		UI.label(_content, "%s – %s" % [project.start.replace("-", "."), project.end.replace("-", ".")], Vector2(8, line), UI.INK)
		UI.label(_content, "%s · %s" % [project.name, project.role], Vector2(16, line + 14), UI.INK_SOFT, 208)
		line += 44


func _render_jobs() -> void:
	var c := candidate
	UI.label(_content, "工作经历（从新到旧）", Vector2(8, 8), UI.INK_SOFT)
	var line := 26
	var gap_at := c.gap_index()
	for i in c.jobs.size():
		var job: Dictionary = c.jobs[i]
		var end: String = job.end.replace("-", ".") if job.end != "" else "至今"
		UI.label(_content, "%s – %s" % [job.start.replace("-", "."), end], Vector2(8, line), UI.INK)
		UI.label(_content, "%s · %s" % [job.company, job.title], Vector2(16, line + 14), UI.INK_SOFT)
		line += 30
		if i == gap_at:
			var note := c.gap_note if c.gap_note != "" else "（未写）"
			UI.label(_content, "┆ 空窗说明：" + note, Vector2(16, line), UI.INK)
			line += 16


func _can_drop_data(_at: Vector2, data: Variant) -> bool:
	return not is_stamped and data is Dictionary and data.get("type") == "stamp"


func _drop_data(at: Vector2, data: Variant) -> void:
	stamp(data.verdict, at)


func stamp(verdict: String, at: Vector2) -> void:
	is_stamped = true
	var ink: Color = {"pass": UI.GREEN.darkened(0.3), "exception": UI.YELLOW.darkened(0.35)}.get(verdict, UI.RED)
	var mark := Control.new()
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mark.position = at.clamp(Vector2(40, 20), SIZE - Vector2(40, 20))
	mark.rotation = randf_range(-0.2, 0.2)
	UI.panel(mark, Rect2(-38, -15, 76, 30), Color(ink, 0.12), ink)
	UI.panel(mark, Rect2(-36, -13, 72, 26), Color.TRANSPARENT, ink)
	var text := UI.label(mark, {"pass": "通 过", "exception": "破 格"}.get(verdict, "拒 绝"), Vector2(-36, -8), ink)
	text.size.x = 72
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(mark)
	_mark = mark
	stamped.emit(verdict, at)


## 拒绝理由没选、玩家点了返回：擦掉章，简历还能再看再盖。
func unstamp() -> void:
	is_stamped = false
	if _mark:
		_mark.queue_free()
		_mark = null
