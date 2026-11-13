extends Control
## 点开桌上的手机：竖着的一部大手机，界面照 WChat：浅灰底、白色会话列表、头像，别人的白气泡、你的绿气泡。
## 先是联系人列表，点一个人进对话；回话还是选一句（不打字）。老婆会发照片（desk_texts 的 photo）。
## 消息来自 GameState.stats.texts（DayConfig.desk_texts，from 是谁发的，默认老婆），
## 转账卡片来自 stats.transfers（猎头的钱，待收款 → 收款 / 退还）；回话选项带 transfer 的是从零钱转出去。

signal replied(entry: Dictionary, option: Dictionary)
signal transfer_answered(t: Dictionary, taken: bool)
signal closed

const W := 220.0
const H := 290.0
## 对话区
const BODY_TOP := 46.0
const PAD := 6.0
const BUBBLE_W := 132.0
const ROW_H := 38.0
const AVATAR := 24.0
## WChat 的几种颜色
const BG := Color("ededed")
const ROW := Color("ffffff")
const LINE := Color("e2e2e2")
const NAME := Color("191919")
const GREY := Color("9a9a9a")
const BUBBLE := Color("ffffff")
const MINE := Color("95ec69")
const RED_DOT := Color("fa5151")
const CARD := Color("fa9d3b")
const CARD_DONE := Color("f7c48a")
const INPUT := Color("f7f7f7")
## 有画好头像的人；别的人是一块颜色写上名字的第一个字（没换过头像的样子）。
const AVATARS := {"老婆": "wife", "你爸": "dad", "我": "me"}
const PLAIN := [Color("7a9ac0"), Color("8ab07a"), Color("c09a6a"), Color("a08ac0"), Color("6aa8a8")]
## 老婆一直在最上面，没消息也有这一行。
const PINNED := "老婆"

var clock := ""
## 打开着的对话，空是联系人列表。
var thread := ""
## 每个对话看过几条：多出来的算未读（Desk 持有，收起手机也记得）。
var seen: Dictionary = {}
var _root: Control


func _ready() -> void:
	size = Vector2(W, H)
	z_index = 20  # 压在桌上所有纸上面
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	refresh()


func refresh() -> void:
	if _root:
		_root.free()
	_root = Control.new()
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	# 机身一圈黑边，里面是 WChat 的浅灰底
	var body := UI.panel(_root, Rect2(0, 0, W, H), UI.BLACK, UI.GREEN_DIM)
	body.mouse_filter = Control.MOUSE_FILTER_STOP  # 别点穿到底下的简历
	UI.panel(_root, Rect2(3, 3, W - 6, H - 6), BG)
	UI.label(_root, clock, Vector2(PAD + 2, 4), NAME)
	_light(UI.button(_root, "收起", Rect2(W - 46, 5, 40, 16), closed.emit))
	UI.panel(_root, Rect2(3, 42, W - 6, 1), LINE)
	if thread == "":
		_build_list()
	else:
		_build_thread()


## 一个人的消息和转账，按时间排。{at, kind: msg / transfer, data}
static func items(name: String) -> Array:
	var out: Array = []
	for e: Dictionary in GameState.stats.texts:
		if e.get("from", PINNED) == name:
			out.append({"at": int(e.at), "kind": "msg", "data": e})
	for t: Dictionary in GameState.stats.transfers:
		if t.from == name and t.has("at"):
			out.append({"at": int(t.at), "kind": "transfer", "data": t})
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.at < b.at)
	return out


static func threads() -> Array:
	var names: Array = [PINNED]
	for e: Dictionary in GameState.stats.texts:
		var from: String = e.get("from", PINNED)
		if from not in names:
			names.append(from)
	for t: Dictionary in GameState.stats.transfers:
		if t.has("at") and t.from not in names:
			names.append(t.from)
	# 最近有动静的排前面，老婆钉在最上面
	var last := func(n: String) -> int:
		var its := items(n)
		return -1 if its.is_empty() else int(its[-1].at)
	var rest := names.slice(1)
	rest.sort_custom(func(a: String, b: String) -> bool: return last.call(a) > last.call(b))
	return [PINNED] + rest


func unread(name: String) -> bool:
	return items(name).size() > int(seen.get(name, 0))


## 去掉“老婆：”这种开头，对话里不用再写是谁说的。
static func strip(text: String) -> String:
	var i := text.find("：")
	return text.substr(i + 1) if i >= 0 and i <= 8 else text


static func preview(it: Dictionary) -> String:
	if it.kind == "transfer":
		var t: Dictionary = it.data
		return "[转账] ¥%d %s" % [t.amount, {"pending": "待收款", "taken": "已收款", "returned": "已退还"}[t.status]]
	var e: Dictionary = it.data
	if e.has("photo"):
		return "[图片]"
	return ("（来电）" if e.get("call", false) else "") + strip(e.text)


## 头像：画好的贴图，没有的是一块颜色写名字的第一个字。
func _avatar(parent: Control, name: String, at: Vector2, size: int) -> void:
	if AVATARS.has(name):
		UI.sprite(parent, "res://assets/phone/avatar_%s_%d.png" % [AVATARS[name], size], at)
		return
	UI.panel(parent, Rect2(at, Vector2(size, size)), PLAIN[absi(hash(name)) % PLAIN.size()])
	var l := UI.label(parent, name.left(1), at + Vector2(0, (size - 16) / 2.0), Color.WHITE)
	l.size.x = size
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


## 浅色按钮：白底黑字，像 WChat 底下那排。
static func _light(b: Button) -> Button:
	for state: String in ["normal", "hover", "pressed", "focus"]:
		var box := StyleBoxFlat.new()
		box.bg_color = Color("ffffff") if state != "hover" else Color("e8f6e0")
		box.border_color = LINE if state != "hover" else Color("07c160")
		box.set_border_width_all(1)
		box.set_content_margin_all(2)
		b.add_theme_stylebox_override(state, box)
	for key: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(key, NAME)
	return b


func _build_list() -> void:
	var title := UI.label(_root, "WChat", Vector2(0, 24), NAME)
	title.size.x = W
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var y := 44.0
	for name: String in threads():
		var its := items(name)
		UI.panel(_root, Rect2(3, y, W - 6, ROW_H), ROW)
		var b := UI.button(_root, "", Rect2(3, y, W - 6, ROW_H), _open.bind(name))
		b.flat = true
		var pending: bool = its.any(func(it: Dictionary) -> bool: return it.kind == "transfer" and it.data.status == "pending")
		_avatar(_root, name, Vector2(PAD + 2, y + 5), 28)
		if unread(name):
			UI.panel(_root, Rect2(PAD + 26, y + 2, 7, 7), RED_DOT)
		UI.label(_root, name, Vector2(PAD + 36, y + 2), NAME)
		if not its.is_empty():
			var at: int = its[-1].at
			var when := UI.label(_root, "%02d:%02d" % [at / 60, at % 60], Vector2(W - 46, y + 2), GREY)
			when.size.x = 38
			when.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		var line := "（今天还没有消息）" if its.is_empty() else preview(its[-1])
		if pending:
			line = preview(its.filter(func(it: Dictionary) -> bool: return it.kind == "transfer" and it.data.status == "pending")[0])
		if line.length() > 11:
			line = line.substr(0, 10) + "…"
		UI.label(_root, line, Vector2(PAD + 36, y + 19), Color("c8740a") if pending else GREY)
		UI.panel(_root, Rect2(PAD + 36, y + ROW_H - 1, W - PAD * 2 - 36, 1), LINE)
		y += ROW_H
		if y > H - 40:
			break
	# 砍减版：不显示零钱余额。收款 / 退还照旧，收下的钱当晚进存款。


func _open(name: String) -> void:
	thread = name
	refresh()


func _back() -> void:
	thread = ""
	refresh()


func _build_thread() -> void:
	_light(UI.button(_root, "<", Rect2(5, 24, 20, 16), _back))
	var title := UI.label(_root, thread, Vector2(0, 24), NAME)
	title.size.x = W
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var its := items(thread)
	seen[thread] = its.size()
	# 底下先摆回话的选项：第一条还没回的消息
	var replies := Control.new()
	replies.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(replies)
	var ry := 0.0
	var waiting := its.filter(func(it: Dictionary) -> bool: return it.kind == "msg" and it.data.has("replies") and not GameState.text_replied(it.data.id))
	for it: Dictionary in waiting:
		# 前面还有没回的，先回最早那条；标出回的是哪句
		if waiting.size() > 1 or it != its[-1]:
			var quote := preview(it)
			if quote.length() > 14:
				quote = quote.substr(0, 13) + "…"
			UI.label(replies, "回：" + quote, Vector2(PAD, ry), GREY)
			ry += 16.0
		for option: Dictionary in it.data.replies:
			if not GameState.family_matches(option.get("when", "")):
				continue
			var text: String = option.label
			if option.has("transfer"):
				text = "[转账 ¥%d] %s" % [option.transfer, text]
			var b := _light(UI.text_button(replies, text, Rect2(PAD, ry, W - PAD * 2, 18), _reply.bind(it.data, option)))
			ry += b.size.y + 2.0
		break
	var bottom := H - 4.0 - ry
	replies.position = Vector2(0, bottom)
	if ry > 0.0:
		var bar := UI.panel(_root, Rect2(3, bottom - 4.0, W - 6, ry + 5.0), INPUT)
		UI.panel(_root, Rect2(3, bottom - 4.0, W - 6, 1), LINE)
		_root.move_child(bar, replies.get_index())
		_root.move_child(_root.get_child(-1), replies.get_index())
	# 对话区：内容比框高就把最早的推出上沿
	var view := Control.new()
	view.position = Vector2(0, BODY_TOP)
	view.size = Vector2(W, bottom - BODY_TOP - 4.0)
	view.clip_contents = true
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(view)
	var col := Control.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view.add_child(col)
	var y := 2.0
	var last_at := -999
	for it: Dictionary in its:
		if int(it.at) - last_at >= 30:
			var stamp := UI.label(col, "%02d:%02d" % [it.at / 60, it.at % 60], Vector2(0, y), Color("b2b2b2"))
			stamp.size.x = W
			stamp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			y += 16.0
		last_at = int(it.at)
		if it.kind == "transfer":
			y += _card(col, y, it.data.amount, it.data.note, it.data.status, false, it.data) + 4.0
			continue
		var e: Dictionary = it.data
		if e.has("photo"):
			y += _photo(col, y, e.photo) + 4.0
		else:
			y += _bubble(col, y, preview(it), false) + 4.0
		# 赌一把的后账：钱是自动转的，跟一张已转账的卡
		if e.has("reveal") and int(e.get("transfer", 0)) > 0:
			y += _card(col, y, int(e.transfer), e.get("note", ""), "sent", true) + 4.0
		if e.has("replies") and GameState.text_replied(e.id):
			var option := _chosen(e)
			if option.is_empty():
				y += _bubble(col, y, "（没回）", true, true) + 4.0
			elif option.has("transfer"):
				y += _card(col, y, int(option.transfer), option.get("note", ""), "sent", true) + 4.0
				y += _bubble(col, y, option.label, true) + 4.0
			else:
				y += _bubble(col, y, option.label, true) + 4.0
			# 意外支出：选完对方再回一句（Surprises 的 reply）
			if option.get("after", "") != "":
				y += _bubble(col, y, String(option.after).trim_prefix(e.get("from", "老婆") + "："), false) + 4.0
	if its.is_empty():
		UI.label(col, "（今天还没有消息）", Vector2(PAD, y), GREY)
		y += 16.0
	col.position.y = minf(0.0, view.size.y - y)


func _chosen(entry: Dictionary) -> Dictionary:
	for option: Dictionary in entry.replies:
		if option.key == GameState.family.get(entry.id, ""):
			return option
	return {}


## 一个气泡：别人的靠左、白底，左边是 TA 的头像；你的靠右、绿底，右边是你的头像（孩子的照片）。返回高度。
func _bubble(parent: Control, y: float, text: String, mine: bool, dim := false) -> float:
	var probe := UI.label(parent, text, Vector2.ZERO, NAME)
	var w := minf(probe.get_minimum_size().x, BUBBLE_W)
	probe.free()
	var face := Vector2(W - PAD - AVATAR, y) if mine else Vector2(PAD, y)
	_avatar(parent, "我" if mine else thread, face, int(AVATAR))
	var x := face.x - 5.0 - w - 8.0 if mine else face.x + AVATAR + 5.0
	var fill := MINE if mine else BUBBLE
	var bg := UI.panel(parent, Rect2(x, y, w + 8.0, 0), fill)
	# 小尖角朝着头像
	var tip := x + w + 8.0 if mine else x - 3.0
	UI.panel(parent, Rect2(tip, y + 8, 3, 1), fill)
	UI.panel(parent, Rect2(tip + (0.0 if mine else 1.0), y + 7, 2, 3), fill)
	var l := UI.label(parent, text, Vector2(x + 4.0, y + 3.0), GREY if dim else NAME, w)
	var h := maxf(l.get_minimum_size().y + 6.0, AVATAR)
	bg.size.y = l.get_minimum_size().y + 6.0
	return h


## 照片消息：老婆的自拍，白边小卡。
func _photo(parent: Control, y: float, key: String) -> float:
	_avatar(parent, thread, Vector2(PAD, y), int(AVATAR))
	var tex: Texture2D = load("res://assets/phone/%s.png" % key)
	var x := PAD + AVATAR + 5.0
	UI.panel(parent, Rect2(x - 1, y - 1, tex.get_width() + 2, tex.get_height() + 2), LINE)
	UI.sprite(parent, "res://assets/phone/%s.png" % key, Vector2(x, y))
	return tex.get_height()


## 转账卡片：WChat 那种橙色。pending 的带收款 / 退还；sent 是你转出去的，靠右。
func _card(parent: Control, y: float, amount: int, note: String, status: String, mine: bool, t := {}) -> float:
	var cw := 140.0
	var face := Vector2(W - PAD - AVATAR, y) if mine else Vector2(PAD, y)
	_avatar(parent, "我" if mine else thread, face, int(AVATAR))
	var x := face.x - 5.0 - cw if mine else face.x + AVATAR + 5.0
	var open := status == "pending"
	var h := 62.0 if open else 40.0
	UI.panel(parent, Rect2(x, y, cw, h), CARD if open or status == "sent" else CARD_DONE)
	UI.label(parent, "¥%d　%s" % [amount, note], Vector2(x + 6, y + 2), Color.WHITE)
	var state: String = {"pending": "待收款 · 下班退回", "taken": "已收款", "returned": "已退还", "sent": "已转账"}[status]
	UI.label(parent, state, Vector2(x + 6, y + 20), Color("fff4e6"))
	if open:
		_light(UI.button(parent, "收款", Rect2(x + 6, y + 40, 60, 18), _answer.bind(t, true)))
		_light(UI.button(parent, "退还", Rect2(x + 72, y + 40, 60, 18), _answer.bind(t, false)))
	return h


func _reply(entry: Dictionary, option: Dictionary) -> void:
	replied.emit(entry, option)


func _answer(t: Dictionary, taken: bool) -> void:
	transfer_answered.emit(t, taken)
