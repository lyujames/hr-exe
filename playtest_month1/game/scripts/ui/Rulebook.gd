class_name Rulebook extends DraggableDoc
## 规则手册：每页两条，新规则带便利贴高亮，打开时停在最新一页。

const SIZE := Vector2(186, 212)
const PER_PAGE := 2

var page := 0
var _content: Control
var _page_label: Label


func setup() -> void:
	size = SIZE
	UI.panel(self, Rect2(Vector2(2, 2), SIZE), UI.BLACK)
	UI.panel(self, Rect2(Vector2.ZERO, SIZE), UI.PAPER_DIM, UI.INK_SOFT)
	UI.panel(self, Rect2(0, 0, SIZE.x, 18), UI.GREEN_DIM)
	UI.label(self, "招聘规范手册", Vector2(6, 2), UI.BLACK)
	_content = Control.new()
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_content)
	UI.button(self, "<", Rect2(6, 191, 22, 17), func() -> void: _turn(-1))
	UI.button(self, ">", Rect2(158, 191, 22, 17), func() -> void: _turn(1))
	_page_label = UI.label(self, "", Vector2(80, 193), UI.INK)
	page = _page_count() - 1
	_render()


func _page_count() -> int:
	return ceili(float(RuleEngine.active_rules.size()) / PER_PAGE)


func _turn(delta: int) -> void:
	page = posmod(page + delta, _page_count())
	Sfx.paper()
	_render()


func _render() -> void:
	UI.clear(_content)
	_page_label.text = "%d / %d" % [page + 1, _page_count()]
	var rules := RuleEngine.active_rules.slice(page * PER_PAGE, (page + 1) * PER_PAGE)
	var y := 24.0
	for rule: Rule in rules:
		var sticky := UI.panel(_content, Rect2(4, y - 2, SIZE.x - 8, 0), UI.YELLOW)
		sticky.visible = rule.day_added == GameState.day
		if sticky.visible:
			UI.label(_content, "新", Vector2(SIZE.x - 22, y), UI.RED)
		UI.label(_content, "▌" + rule.title_key, Vector2(8, y), UI.INK)
		var body := UI.label(_content, rule.text_key, Vector2(10, y + 16), UI.INK, SIZE.x - 20)
		var height := 22.0 + body.get_line_count() * 15.0
		sticky.size.y = height
		y += height + 4.0
