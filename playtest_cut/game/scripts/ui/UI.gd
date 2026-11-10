class_name UI
## 调色板与界面小工具。冷灰与荧光灯绿为主；印章红和便利贴黄是画面里唯一的暖色。

const DESK := Color("2b3230")
const DESK_DARK := Color("1f2523")
const WALL := Color("39423f")
const GREEN := Color("7fd6a4")
const GREEN_DIM := Color("4f7f68")
const PAPER := Color("cfd4cf")
const PAPER_DIM := Color("aeb5af")
const INK := Color("232826")
const INK_SOFT := Color("56605b")
const TEXT := Color("d7dfda")
const TEXT_DIM := Color("8c9992")
const RED := Color("c8402f")
const YELLOW := Color("e8c84a")
const BLACK := Color("121615")
## 七种纸各一种纸色（样板图_桌面与印章）。
const PAPER_RESUME := Color("e8e4d8")
const PAPER_BOOK := Color("d8dfd0")
const PAPER_JD := Color("e6eaec")
const PAPER_SLIP := Color("eeecdc")
const PAPER_DEAL := Color("f0ece0")
const STICKY := Color("f0d45a")


static func theme() -> Theme:
	var t := Theme.new()
	t.default_font_size = 12
	var normal := _box(Color("46524d"), Color("6d7d76"))
	t.set_stylebox("normal", "Button", normal)
	t.set_stylebox("hover", "Button", _box(Color("56655f"), GREEN))
	t.set_stylebox("pressed", "Button", _box(Color("2f3835"), GREEN))
	t.set_stylebox("disabled", "Button", _box(Color("333b38"), Color("46524d")))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", GREEN)
	t.set_color("font_disabled_color", "Button", Color("66736d"))
	t.set_stylebox("scroll", "VScrollBar", _box(DESK_DARK, Color("46524d")))
	t.set_stylebox("grabber", "VScrollBar", _box(Color("6d7d76"), Color("6d7d76")))
	t.set_stylebox("grabber_highlight", "VScrollBar", _box(GREEN_DIM, GREEN))
	t.set_stylebox("grabber_pressed", "VScrollBar", _box(GREEN_DIM, GREEN))
	for state in ["normal", "hover", "pressed", "hover_pressed", "focus"]:
		t.set_stylebox(state, "CheckBox", StyleBoxEmpty.new())
	return t


static func _box(fill: Color, border: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(1)
	box.set_content_margin_all(2)
	return box


static func panel(parent: Control, rect: Rect2, fill: Color, border := Color.TRANSPARENT) -> Panel:
	var p := Panel.new()
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(1 if border.a > 0.0 else 0)
	p.add_theme_stylebox_override("panel", box)
	p.position = rect.position
	p.size = rect.size
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(p)
	return p


## 一张美术图（res://assets/...），不接鼠标。
static func sprite(parent: Control, path: String, pos: Vector2) -> TextureRect:
	var t := TextureRect.new()
	t.texture = load(path)
	t.position = pos
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(t)
	return t


## size.x > 0 时自动换行。
static func label(parent: Control, text: String, pos: Vector2, color := TEXT, width := 0.0) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("line_spacing", 1)
	if width > 0.0:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = width
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	if width > 0.0:
		l.size = Vector2(width, 0.0)  # 入树后才生效：之前会被换行前缓存的最小宽度顶掉
	return l


static func button(parent: Control, text: String, rect: Rect2, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.position = rect.position
	b.size = rect.size
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(on_press)
	b.pressed.connect(Sfx.key)
	parent.add_child(b)
	return b


## 宽度固定的按钮：字太长就折成两行、按钮变高，不把按钮撑宽。返回的按钮 size.y 是实际高度。
static func text_button(parent: Control, text: String, rect: Rect2, on_press: Callable) -> Button:
	var b := button(parent, text, rect, on_press)
	b.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	var font := b.get_theme_font("font")
	var font_size := b.get_theme_font_size("font_size")
	var inner := rect.size.x - 16.0
	# 自己先折好行：任意断行会把句号、右引号单独挤到下一行
	b.text = wrap_cjk(text, font, font_size, inner)
	var lines := font.get_multiline_string_size(b.text, HORIZONTAL_ALIGNMENT_CENTER, inner, font_size, -1, TextServer.BREAK_MANDATORY | TextServer.BREAK_GRAPHEME_BOUND)
	b.custom_minimum_size = Vector2(rect.size.x, maxf(rect.size.y, lines.y + 8.0))
	b.size = b.custom_minimum_size
	return b


## 不能出现在行首的标点（避头）和不能留在行尾的标点（避尾）
const NO_LINE_START := "。，、；：！？）》」』”’…—.,;:!?)"
const NO_LINE_END := "（《「『“‘("


## 按宽度逐字折行，守中文排版的避头尾：标点打头时把上一行最后一个字一起带下来。
static func wrap_cjk(text: String, font: Font, font_size: int, width: float) -> String:
	var out := PackedStringArray()
	for para in text.split("\n"):
		var line := ""
		for i in para.length():
			var ch := para[i]
			if line != "" and font.get_string_size(line + ch, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > width:
				var carry := 0
				if NO_LINE_START.contains(ch):
					carry = 1
				# 带下来的字前面要是左括号、左引号，也一起带下来
				while carry < line.length() - 1 and NO_LINE_END.contains(line[line.length() - 1 - carry]):
					carry += 1
				if carry == 0 and NO_LINE_END.contains(line[line.length() - 1]) and line.length() > 1:
					carry = 1
				if carry >= line.length():
					carry = 0
				out.append(line.substr(0, line.length() - carry))
				line = line.substr(line.length() - carry) + ch
			else:
				line += ch
		out.append(line)
	return "\n".join(out)


static func clear(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()
