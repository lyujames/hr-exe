class_name JobPostingDoc extends DraggableDoc
## 桌上的岗位 JD：一页一个岗位，翻页找简历上“应聘”的那个。专业名单是判定用的，其余要求只给人看。
## 今天新开的岗位那页贴便利贴，打开时停在最新开的那页。

const SIZE := Vector2(106, 232)

var postings: Array[JobPosting] = []
var page := 0
var _content: Control
var _page_label: Label


func setup(list: Array[JobPosting]) -> void:
	postings = list
	size = SIZE
	UI.panel(self, Rect2(Vector2(2, 2), SIZE), UI.BLACK)
	UI.panel(self, Rect2(Vector2.ZERO, SIZE), UI.PAPER, UI.INK_SOFT)
	UI.panel(self, Rect2(0, 0, SIZE.x, 18), UI.YELLOW)
	var interns := postings.all(func(p: JobPosting) -> bool: return not p.majors.is_empty())
	UI.label(self, "蜂巢 实习岗位" if interns else "蜂巢 招聘岗位", Vector2(4, 2), UI.INK)
	_content = Control.new()
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_content)
	var prev := UI.button(self, "<", Rect2(4, 211, 20, 17), func() -> void: _turn(-1))
	var next := UI.button(self, ">", Rect2(SIZE.x - 24, 211, 20, 17), func() -> void: _turn(1))
	_page_label = UI.label(self, "", Vector2(38, 212), UI.INK)
	# 只有一个岗位时不用翻
	for node: Control in [prev, next, _page_label]:
		node.visible = postings.size() > 1
	page = postings.size() - 1
	_render()


func _turn(delta: int) -> void:
	page = posmod(page + delta, postings.size())
	Sfx.paper()
	_render()


func _render() -> void:
	UI.clear(_content)
	_page_label.text = "%d/%d" % [page + 1, postings.size()]
	var posting := postings[page]
	var width := SIZE.x - 8
	var y := 22.0
	var fresh := posting in RuleEngine.load_day(GameState.day).new_postings and GameState.day > 1
	var title_bg := UI.panel(_content, Rect2(2, y - 2, SIZE.x - 4, 0), UI.YELLOW)
	title_bg.visible = fresh
	var title := UI.label(_content, posting.title, Vector2(4, y), UI.INK, width)
	y += 2.0 + title.get_line_count() * 15.0
	title_bg.size.y = y - title_bg.position.y
	if fresh:
		UI.label(_content, "新", Vector2(SIZE.x - 16, title_bg.position.y + 2), UI.RED)
	var pay := UI.label(_content, posting.pay_text, Vector2(4, y), UI.RED, width)
	y += 4.0 + pay.get_line_count() * 15.0
	# 实习岗看专业，社招看必备技能；都没有的（关键词规则还没上）就只列要求
	var listed := posting.majors if not posting.majors.is_empty() else posting.keywords
	if not listed.is_empty():
		UI.panel(_content, Rect2(4, y, width, 1), UI.INK_SOFT)
		UI.label(_content, "专业（只要）" if not posting.majors.is_empty() else "必备技能", Vector2(4, y + 3), UI.INK_SOFT)
		y += 20.0
		for item in listed:
			var line := UI.label(_content, "·" + item, Vector2(4, y), UI.INK, width)
			y += 1.0 + line.get_line_count() * 15.0
		y += 3.0
	UI.panel(_content, Rect2(4, y, width, 1), UI.INK_SOFT)
	y += 4.0
	for requirement in posting.requirements:
		var line := UI.label(_content, "·" + requirement, Vector2(4, y), UI.INK_SOFT, width)
		y += 1.0 + line.get_line_count() * 15.0
