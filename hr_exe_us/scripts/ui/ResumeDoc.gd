class_name ResumeDoc extends DraggableDoc
## 一份简历，三页：基本信息、工作经历与自我评价、工作资格。

signal stamped(verdict: String, at: Vector2)

const SIZE := Vector2(232, 268)
const PAGES := 3

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
	UI.button(self, "Flip", Rect2(186, 247, 40, 18), flip)
	_render()


func flip() -> void:
	page = (page + 1) % PAGES
	Sfx.paper()
	_render()


func _render() -> void:
	UI.clear(_content)
	UI.label(_content, "%d/%d" % [page + 1, PAGES], Vector2(162, 249), UI.INK_SOFT)
	match page:
		0:
			_render_front()
		1:
			_render_back()
		_:
			_render_eligibility()


func _render_front() -> void:
	var c := candidate
	# 法务删了照片和生日，规则还在：年龄只能从毕业年份反推。
	UI.panel(_content, Rect2(8, 8, 64, 64), UI.PAPER_DIM, UI.INK_SOFT)
	UI.label(_content, "REMOVED\nBY LEGAL", Vector2(14, 26), UI.INK_SOFT)
	UI.label(_content, c.display_name, Vector2(80, 8), UI.INK)
	UI.label(_content, "Role: " + c.applied_position, Vector2(80, 26), UI.INK, 146)
	UI.label(_content, "DOB: [removed]", Vector2(80, 44), UI.INK_SOFT)
	var line := 82
	UI.label(_content, "%s, %s" % [c.degree_name(), c.school], Vector2(8, line), UI.INK, 216)
	line += 16
	UI.label(_content, "Graduated: %d" % c.graduation_year(), Vector2(8, line), UI.INK)
	line += 16
	if c.degree_note != "":
		UI.label(_content, "（%s）" % c.degree_note, Vector2(8, line), UI.INK_SOFT)
		line += 16
	UI.label(_content, "Desired: $%dk + %d%% bonus" % [c.salary_k, c.bonus_pct], Vector2(8, line), UI.INK)
	line += 18
	UI.label(_content, "Skills:", Vector2(8, line), UI.INK)
	UI.label(_content, " / ".join(c.skills), Vector2(48, line), UI.INK, 176)


func _render_back() -> void:
	var c := candidate
	UI.label(_content, "Experience (newest first)", Vector2(8, 8), UI.INK_SOFT)
	var line := 26
	for job: Dictionary in c.jobs:
		var end: String = job.end.replace("-", ".") if job.end != "" else "now"
		UI.label(_content, "%s – %s" % [job.start.replace("-", "."), end], Vector2(8, line), UI.INK)
		UI.label(_content, "%s · %s" % [job.company, job.title], Vector2(16, line + 14), UI.INK_SOFT)
		line += 32
	UI.label(_content, "Summary", Vector2(8, 172), UI.INK_SOFT)
	UI.label(_content, c.self_eval, Vector2(8, 188), UI.INK, 216)
	UI.label(_content, "Note: " + c.attachment, Vector2(8, 222), UI.INK_SOFT, 216)


func _render_eligibility() -> void:
	var c := candidate
	UI.label(_content, "Work eligibility", Vector2(8, 8), UI.INK_SOFT)
	UI.label(_content, "Citizenship: " + c.nationality, Vector2(8, 28), UI.INK)
	UI.label(_content, "Status: " + c.work_status, Vector2(8, 46), UI.INK)
	UI.label(_content, "Expires: " + (c.status_expiry if c.status_expiry != "" else "n/a"), Vector2(8, 64), UI.INK)


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
	var text := UI.label(mark, "PASS" if verdict == "pass" else "REJECT", Vector2(-36, -8), ink)
	text.size.x = 72
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(mark)
	stamped.emit(verdict, at)
