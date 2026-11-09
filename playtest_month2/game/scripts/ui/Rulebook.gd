class_name Rulebook extends DraggableDoc
## 规则手册：按字数排版，一页放得下几条放几条，长的接到下一页，翻页按钮和页码上面不压字。
## 新规则带便利贴高亮，打开时停在最新那条。

const SIZE := Vector2(186, 212)
## 正文从标题栏下面开始，到翻页按钮上面为止
const TOP := 24.0
const BOTTOM := 186.0
const GAP := 4.0
## 标题一行占的高度，正文底下留的边
const TITLE_H := 16.0
const PAD := 4.0

var page := 0
var _content: Control
var _page_label: Label
var _pages: Array = []


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
	_paginate()
	page = _newest_page()
	_render()


func _page_count() -> int:
	return maxi(1, _pages.size())


## 按真实行高排版：一页放得下几条放几条；一条太长放不下，剩下的行接到下一页（标题写“续”）。
## 每页是一串片段 {rule, from, count}：从第 from 行起显示 count 行。
func _paginate() -> void:
	_pages = []
	var current: Array = []
	var y := TOP
	for rule: Rule in RuleEngine.active_rules:
		var probe := _body_label(rule, 0.0)
		var lines := probe.get_line_count()
		var lh := _line_h(probe)
		_content.remove_child(probe)
		probe.free()
		# 一整页放得下几行正文
		var cap := maxi(1, int(floor((BOTTOM - TOP - TITLE_H - PAD) / lh)))
		# 这一页剩下的地方放不下整条：整条挪到新的一页，不从中间断开
		if not current.is_empty() and y + TITLE_H + lines * lh + PAD > BOTTOM:
			_pages.append(current)
			current = []
			y = TOP
		if lines <= cap:
			current.append({"rule": rule, "from": 0, "count": lines})
			y += TITLE_H + lines * lh + PAD + GAP
			continue
		# 比一整页还长：拆成几页，每页行数平均，不剩一行孤零零的“续”
		var parts := ceili(float(lines) / cap)
		var per := ceili(float(lines) / parts)
		var from := 0
		while from < lines:
			if not current.is_empty():
				_pages.append(current)
				current = []
				y = TOP
			var count := mini(per, lines - from)
			current.append({"rule": rule, "from": from, "count": count})
			y += TITLE_H + count * lh + PAD + GAP
			from += count
	if not current.is_empty():
		_pages.append(current)


func _body_label(rule: Rule, y: float) -> Label:
	return UI.label(_content, rule.text_key, Vector2(10, y), UI.INK, SIZE.x - 20)


func _line_h(l: Label) -> float:
	return float(l.get_line_height() + l.get_theme_constant("line_spacing"))


## 打开时停在最新那条规则开头的那一页。
func _newest_page() -> int:
	if RuleEngine.active_rules.is_empty():
		return 0
	var newest: Rule = RuleEngine.active_rules.back()
	for i in _pages.size():
		for piece: Dictionary in _pages[i]:
			if piece.rule == newest and piece.from == 0:
				return i
	return _page_count() - 1


func _turn(delta: int) -> void:
	page = posmod(page + delta, _page_count())
	Sfx.paper()
	_render()


func _render() -> void:
	UI.clear(_content)
	_page_label.text = "%d / %d" % [page + 1, _page_count()]
	var pieces: Array = _pages[page] if page < _pages.size() else []
	var y := TOP
	for piece: Dictionary in pieces:
		var rule: Rule = piece.rule
		var sticky := UI.panel(_content, Rect2(4, y - 2, SIZE.x - 8, 0), UI.YELLOW)
		sticky.visible = rule.day_added == GameState.day
		if sticky.visible:
			UI.label(_content, "新", Vector2(SIZE.x - 22, y), UI.RED)
		UI.label(_content, "▌" + rule.title_key + ("（续）" if piece.from > 0 else ""), Vector2(8, y), UI.INK)
		var body := _body_label(rule, y + TITLE_H)
		body.lines_skipped = piece.from
		body.max_lines_visible = piece.count
		var height: float = TITLE_H + piece.count * _line_h(body) + PAD
		sticky.size.y = height
		y += height + GAP
