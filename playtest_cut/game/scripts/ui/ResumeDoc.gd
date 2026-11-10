class_name ResumeDoc extends DraggableDoc
## 一份简历，两页：第 1 页基本信息，第 2 页工作经历（实习生是在校项目）与自我评价。

signal stamped(verdict: String, at: Vector2)

const SIZE := Vector2(232, 268)
## 抬头文字的左边（照片右边）、正文内容栏的左边、正文行高。
const HEAD_X := 80
const VALUE_X := 44
const LINE := 17
## 正文最低到这儿，再往下是页码、翻页按钮和初筛章。
const BOTTOM := 245.0
## HireBot 小条最低到这儿（纸 268 高，留一道边）；最底下那一行（页码左边）的位置。
const PAPER_BOTTOM := 264.0
const FOOTER_Y := 247.0
## 底下那一行 HireBot 建议条的宽（到页码前面）；背面拟回复那张小条的高。
const STRIP_W := 152.0
const REPLY_H := 34.0

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
	if candidate.broker:
		# 猎头推来的：右下角一个铅笔字，两页都在同一张纸的角上
		var mark := UI.label(_content, "钱", Vector2(140, 247), UI.INK_SOFT)
		mark.rotation = -0.25
		mark.modulate.a = 0.75
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
	# 抬头：照片右边姓名、出生；应聘岗位单独一行，横跨整张纸，岗位名再长也放得下
	fields.display_name = UI.label(_content, c.fact("display_name"), Vector2(HEAD_X, 10), UI.INK)
	# 出生那一行可以被删掉（邵东第二次投：让 AI 重写，出生年月删了）
	if String(c.fact("birth_date")) == "":
		fields.birth_date = UI.label(_content, "出生：（未填）", Vector2(HEAD_X, 30), UI.INK_SOFT)
	else:
		var birth := DateUtil.parse(c.fact("birth_date"))
		fields.birth_date = UI.label(_content, "出生：%d年%d月" % [birth.x, birth.y], Vector2(HEAD_X, 30), UI.INK)
	_render_ats()
	if c.ai_prob > 0:
		# HireBot 标的，右上角
		var ink := UI.RED if c.ai_prob > 50 else UI.INK_SOFT
		var tag := UI.label(_content, "AI 生成 %d%%" % c.ai_prob, Vector2(SIZE.x - 82, 10), ink)
		tag.size.x = 74
		tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	# 婚育写在抬头里（照片右边、出生下面）：正文已经够挤了，附注长了就截掉，规则只看前四个字
	if c.marital != "":
		_one_line(("%s · " % c.gender if c.gender != "" else "") + c.marital, Vector2(HEAD_X, 52), UI.INK, SIZE.x - HEAD_X - 6)
	var applied := UI.label(_content, "应聘：" + c.applied_position, Vector2(8, 77), UI.INK, SIZE.x - 16)
	# 一行放不下就整段括号挪到第二行，别把“组）”孤零零甩下去
	var font := applied.get_theme_font("font")
	var font_size := applied.get_theme_font_size("font_size")
	if font.get_string_size(applied.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > applied.size.x and "（" in applied.text:
		applied.text = applied.text.replace("（", "\n　　　（")
	var rule_y := 77 + _height(applied) + 3
	UI.panel(_content, Rect2(8, rule_y, SIZE.x - 16, 1), UI.INK_SOFT)
	# 正文：左边一栏小字标题，右边内容，内容长就在右栏里折行
	var line := rule_y + 5
	line = _row("学历", c.degree_name() + ("在读" if c.is_intern else "") + "　" + c.school, line)
	if c.undergrad_school != "":
		line = _note("（本科：%s）" % c.undergrad_school, line)
	if c.degree_note != "":
		line = _note("（%s）" % c.degree_note, line)
	if c.is_intern:
		line = _row("专业", c.major, line)
		if c.major_note != "":
			line = _note("（%s）" % c.major_note, line)
		line = _row("绩点", "%.2f / 4.0" % c.gpa, line)
		line = _row("可实习", "每周 %d 天，%d 个月" % [c.intern_days, c.intern_months], line)
	else:
		line = _row("期望", "月薪 " + c.salary_text(), line)
		line = _row("工作年限", c.exp_text(), line)
		if c.exp_note != "":
			line = _note("（%s）" % c.exp_note, line)
	line += 3
	# 技能写得多、折到第三行会压住最底下那条：挤一挤，去掉斜杠两边的空格
	var holder := Control.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var front := _content
	front.add_child(holder)
	_content = holder
	var end := _row("技能", " / ".join(c.skills), line)
	_content = front
	if end > FOOTER_Y - 1 and _hirebot_on():
		holder.free()
		_row("技能", "/".join(c.skills), line)
	_render_hirebot_strip()


## HireBot（第 17 天起）：第一页最底下一行（页码左边，原来盖初筛章的地方）写它的建议和依据，这一行永远空着；
## 替你拟好的拒绝回复（你写得最多的那句，原话）印在背面最底下。第一页写得再满也不会被挤出纸。
func _hirebot_on() -> bool:
	return GameState.config != null and GameState.config.hirebot > 0 and not candidate.is_intern


func _render_hirebot_strip() -> void:
	if not _hirebot_on():
		return
	var s := HireBot.suggest(candidate)
	var ink: Color = Color("2f5d8a") if s.pass else Color("8a3a2f")
	UI.panel(_content, Rect2(6, FOOTER_Y - 1, STRIP_W, 17), Color(1, 1, 1, 0.35), ink).mouse_filter = Control.MOUSE_FILTER_IGNORE
	var text := "HireBot：建议通过" if s.pass else "HireBot：不推荐（%s）" % s.why
	_one_line(text, Vector2(10, FOOTER_Y), ink, STRIP_W - 8)


## 背面最底下：HireBot 替你拟好的回复。y 是自评、附件排完的下沿。
func _render_hirebot_reply(y: float) -> void:
	if not _hirebot_on():
		return
	var s := HireBot.suggest(candidate)
	if s.pass:
		return
	var ink := Color("8a3a2f")
	var top := maxf(y + 3.0, BOTTOM - REPLY_H)
	var one := maxf(y + 3.0, BOTTOM - 17.0)
	if top + REPLY_H > BOTTOM + 1.0 and one + 17.0 <= BOTTOM + 1.0:
		# 只放得下一行：整行只印那句回复（第一页底下已经写着是 HireBot 的）
		UI.panel(_content, Rect2(6, one - 1, SIZE.x - 12, 17), Color(1, 1, 1, 0.35), ink).mouse_filter = Control.MOUSE_FILTER_IGNORE
		_one_line("“%s”" % s.reason, Vector2(10, one), ink, SIZE.x - 20)
		return
	if top + REPLY_H > BOTTOM + 1.0:
		# 经历、自评写满了：缩成最底下一行（页码左边）
		UI.panel(_content, Rect2(6, FOOTER_Y - 1, STRIP_W, 17), Color(1, 1, 1, 0.35), ink).mouse_filter = Control.MOUSE_FILTER_IGNORE
		_one_line("拟回复：“%s”" % s.reason, Vector2(10, FOOTER_Y), ink, STRIP_W - 8)
		return
	UI.panel(_content, Rect2(6, top - 1, SIZE.x - 12, REPLY_H), Color(1, 1, 1, 0.35), ink).mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.label(_content, "HireBot 拟回复：", Vector2(10, top), ink)
	_one_line("“%s”" % s.reason, Vector2(10, top + 16), UI.INK, SIZE.x - 20)


## 一行放不下就截成“……”。
func _one_line(text: String, at: Vector2, color: Color, width: float) -> void:
	var l := UI.label(_content, text, at, color)
	l.clip_text = true
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	l.custom_minimum_size.x = 0
	l.size = Vector2(width, 16)


## 一行“标题 | 内容”：内容对齐在左栏后面，标题比左栏长（可实习、工作年限）就往后让。返回下一行的位置。
func _row(key: String, value: String, line: int) -> int:
	var title := UI.label(_content, key, Vector2(8, line), UI.INK_SOFT)
	var x := maxf(VALUE_X, 8 + title.get_combined_minimum_size().x + 6)
	var text := UI.label(_content, value, Vector2(x, line), UI.INK, SIZE.x - x - 8)
	return line + _height(text) + 1


## 折行的字收紧到跟行距一样（字体自带的行高 22，比一行一行排的 LINE 大），返回占的高度。
## Label 刚建出来时 get_line_count() 有时还没排版，这里自己按字体量。
func _height(label: Label) -> int:
	var font := label.get_theme_font("font")
	var font_size := label.get_theme_font_size("font_size")
	var pitch := font.get_height(font_size)
	label.add_theme_constant_override("line_spacing", LINE - roundi(pitch))
	var flags := TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE
	var h := font.get_multiline_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, label.size.x, font_size, -1, flags).y
	return LINE * maxi(1, roundi(h / pitch))


## 初筛系统上线以后（DayConfig.ats）：左下角盖一个系统的章。它只看技能栏，见 Ats。
func _render_ats() -> void:
	if GameState.config == null or (not GameState.config.ats and GameState.config.hirebot <= 0):
		return
	var tag := HireBot.label(candidate) if GameState.config.hirebot > 0 else Ats.label(candidate)
	# HireBot 的建议写在底下那张小条上（_render_hirebot），这里不再盖章
	if GameState.config.hirebot > 0:
		return
	if tag == "":
		return
	var ink: Color = Color("2f5d8a") if tag == Ats.MATCH else Color("8a3a2f")
	UI.panel(_content, Rect2(8, 247, 112, 16), Color(ink, 0.1), ink).mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.label(_content, "HireBot 0.1 初筛：" + tag, Vector2(12, 247), ink)


## 学历、专业后面的小字，写在右栏里，太长就折行。返回下一行的位置。
func _note(text: String, line: int) -> int:
	var note := UI.label(_content, text, Vector2(VALUE_X, line), UI.INK_SOFT, SIZE.x - VALUE_X - 8)
	return line + _height(note) + 1


func _render_back() -> void:
	var c := candidate
	# 上面经历排到哪：在校项目或工作经历的最后一行下面
	var top := float(_render_projects() if c.is_intern else _render_jobs())
	# 自评和附件先排出来量高度，再整块放：平时从 172 起，放不下就往上提，最低不压经历；
	# 底下 BOTTOM 以下是页码、翻页按钮、初筛章，不让字压上去
	var head := UI.label(_content, "自我评价", Vector2.ZERO, UI.INK_SOFT)
	var eval := UI.label(_content, c.self_eval, Vector2.ZERO, UI.INK, 216)
	var attach := UI.label(_content, "附：" + c.attachment, Vector2.ZERO, UI.INK_SOFT, 216)
	var eval_h := _height(eval)
	var attach_h := _height(attach)
	var block := 16.0 + eval_h + 3.0 + attach_h
	# HireBot 拟的回复要贴在最底下：自评那一块再往上让一让
	var floor_y := BOTTOM - (REPLY_H + 3.0 if _hirebot_on() and not HireBot.suggest(candidate).pass else 0.0)
	var y := maxf(top, minf(172.0, floor_y - block))
	head.position = Vector2(8, y)
	eval.position = Vector2(8, y + 16)
	attach.position = Vector2(8, y + 16 + eval_h + 3)
	_render_hirebot_reply(y + block)


## 返回项目下面空出来的那一行。
func _render_projects() -> int:
	UI.label(_content, "在校项目（从新到旧）", Vector2(8, 8), UI.INK_SOFT)
	var line := 26
	if candidate.projects.is_empty():
		UI.label(_content, "（未填写）", Vector2(8, line), UI.INK)
		line += 20
	for project: Dictionary in candidate.projects:
		UI.label(_content, "%s – %s" % [project.start.replace("-", "."), project.end.replace("-", ".")], Vector2(8, line), UI.INK)
		UI.label(_content, "%s · %s" % [project.name, project.role], Vector2(16, line + 14), UI.INK_SOFT, 208)
		line += 44
	return line + 2


## 返回经历下面空出来的那一行。
func _render_jobs(start := 8) -> int:
	var c := candidate
	UI.label(_content, "工作经历（从新到旧）", Vector2(8, start), UI.INK_SOFT)
	var line := start + 18
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
	return line + 2


func _can_drop_data(_at: Vector2, data: Variant) -> bool:
	return not is_stamped and data is Dictionary and data.get("type") == "stamp"


func _drop_data(at: Vector2, data: Variant) -> void:
	stamp(data.verdict, at)


## label：章上的字；空就按 verdict 写“通过 / 破格 / 拒绝”。按组招的日子放进文件夹，盖的是组名。
func stamp(verdict: String, at: Vector2, label := "") -> void:
	is_stamped = true
	var ink: Color = {"pass": UI.GREEN.darkened(0.3), "exception": UI.YELLOW.darkened(0.35)}.get(verdict, UI.RED)
	var mark := Control.new()
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mark.position = at.clamp(Vector2(40, 20), SIZE - Vector2(40, 20))
	mark.rotation = randf_range(-0.2, 0.2)
	UI.panel(mark, Rect2(-38, -15, 76, 30), Color(ink, 0.12), ink)
	UI.panel(mark, Rect2(-36, -13, 72, 26), Color.TRANSPARENT, ink)
	var text := UI.label(mark, label if label != "" else {"pass": "通 过", "exception": "破 格"}.get(verdict, "拒 绝"), Vector2(-36, -8), ink)
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
