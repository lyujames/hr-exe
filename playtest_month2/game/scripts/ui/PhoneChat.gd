extends Control
## 点开桌上的手机：竖着的一部大手机。先是联系人列表，点一个人进对话；回话还是选一句（不打字）。
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
const BUBBLE_W := 156.0
const ROW_H := 38.0
const BUBBLE := Color("3d5a4c")
const CARD := Color("e8c84a")
const CARD_DONE := Color("8c8460")
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
	var body := UI.panel(_root, Rect2(0, 0, W, H), UI.BLACK, UI.GREEN_DIM)
	body.mouse_filter = Control.MOUSE_FILTER_STOP  # 别点穿到底下的简历
	UI.label(_root, clock, Vector2(PAD, 3), UI.TEXT_DIM)
	UI.button(_root, "收起", Rect2(W - 44, 3, 40, 16), closed.emit)
	UI.panel(_root, Rect2(1, 22, W - 2, 1), UI.GREEN_DIM)
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
	return text.substr(i + 1) if i >= 0 and i <= 5 else text


static func preview(it: Dictionary) -> String:
	if it.kind == "transfer":
		var t: Dictionary = it.data
		return "[转账] ¥%d %s" % [t.amount, {"pending": "待收款", "taken": "已收款", "returned": "已退还"}[t.status]]
	var e: Dictionary = it.data
	return ("（来电）" if e.get("call", false) else "") + strip(e.text)


func _build_list() -> void:
	UI.label(_root, "消息", Vector2(PAD, 26), UI.GREEN)
	var y := 46.0
	for name: String in threads():
		var its := items(name)
		var b := UI.button(_root, "", Rect2(2, y, W - 4, ROW_H - 2), _open.bind(name))
		b.flat = true
		var pending: bool = its.any(func(it: Dictionary) -> bool: return it.kind == "transfer" and it.data.status == "pending")
		UI.label(_root, name, Vector2(PAD + 4, y + 2), UI.GREEN if unread(name) else UI.TEXT)
		if not its.is_empty():
			var at: int = its[-1].at
			var when := UI.label(_root, "%02d:%02d" % [at / 60, at % 60], Vector2(W - 44, y + 2), UI.TEXT_DIM)
			when.size.x = 38
			when.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		var line := "（今天还没有消息）" if its.is_empty() else preview(its[-1])
		if pending:
			line = preview(its.filter(func(it: Dictionary) -> bool: return it.kind == "transfer" and it.data.status == "pending")[0])
		if line.length() > 13:
			line = line.substr(0, 12) + "…"
		UI.label(_root, line, Vector2(PAD + 4, y + 18), UI.YELLOW if pending else UI.TEXT_DIM)
		if unread(name):
			UI.panel(_root, Rect2(2, y + 8, 4, 4), UI.RED)
		UI.panel(_root, Rect2(PAD, y + ROW_H - 2, W - PAD * 2, 1), UI.DESK)
		y += ROW_H
		if y > H - 40:
			break
	UI.panel(_root, Rect2(1, H - 24, W - 2, 1), UI.GREEN_DIM)
	UI.label(_root, "零钱", Vector2(PAD, H - 20), UI.TEXT_DIM)
	var wallet := UI.label(_root, "¥%d" % GameState.wallet(), Vector2(W - 86, H - 20), UI.YELLOW if GameState.wallet() > 0 else UI.TEXT_DIM)
	wallet.size.x = 80
	wallet.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT


func _open(name: String) -> void:
	thread = name
	refresh()


func _back() -> void:
	thread = ""
	refresh()


func _build_thread() -> void:
	UI.button(_root, "<", Rect2(2, 25, 20, 15), _back)
	UI.label(_root, thread, Vector2(26, 25), UI.GREEN)
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
			UI.label(replies, "回：" + quote, Vector2(PAD, ry), UI.TEXT_DIM)
			ry += 16.0
		for option: Dictionary in it.data.replies:
			if not GameState.family_matches(option.get("when", "")):
				continue
			var text: String = option.label
			if option.has("transfer"):
				text = "[转账 ¥%d] %s" % [option.transfer, text]
			var b := UI.text_button(replies, text, Rect2(PAD, ry, W - PAD * 2, 18), _reply.bind(it.data, option))
			ry += b.size.y + 2.0
		break
	var bottom := H - 4.0 - ry
	replies.position = Vector2(0, bottom)
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
			var stamp := UI.label(col, "%02d:%02d" % [it.at / 60, it.at % 60], Vector2(0, y), UI.TEXT_DIM)
			stamp.size.x = W
			stamp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			y += 16.0
		last_at = int(it.at)
		if it.kind == "transfer":
			y += _card(col, y, it.data.amount, it.data.note, it.data.status, false, it.data) + 4.0
			continue
		var e: Dictionary = it.data
		y += _bubble(col, y, preview(it), false) + 4.0
		if e.has("replies") and GameState.text_replied(e.id):
			var option := _chosen(e)
			if option.is_empty():
				y += _bubble(col, y, "（没回）", true, true) + 4.0
			elif option.has("transfer"):
				y += _card(col, y, int(option.transfer), option.get("note", ""), "sent", true) + 4.0
				y += _bubble(col, y, option.label, true) + 4.0
			else:
				y += _bubble(col, y, option.label, true) + 4.0
	if its.is_empty():
		UI.label(col, "（今天还没有消息）", Vector2(PAD, y), UI.TEXT_DIM)
		y += 16.0
	col.position.y = minf(0.0, view.size.y - y)


func _chosen(entry: Dictionary) -> Dictionary:
	for option: Dictionary in entry.replies:
		if option.key == GameState.family.get(entry.id, ""):
			return option
	return {}


## 一个气泡：别人的靠左、底色深绿；你的靠右、绿字。返回高度。
func _bubble(parent: Control, y: float, text: String, mine: bool, dim := false) -> float:
	var probe := UI.label(parent, text, Vector2.ZERO, UI.TEXT)
	var w := minf(probe.get_minimum_size().x, BUBBLE_W)
	probe.free()
	var x := W - PAD - w - 8.0 if mine else PAD
	var bg := UI.panel(parent, Rect2(x, y, w + 8.0, 0), UI.DESK if mine else BUBBLE)
	var color := UI.TEXT_DIM if dim else (UI.GREEN if mine else UI.TEXT)
	var l := UI.label(parent, text, Vector2(x + 4.0, y + 2.0), color, w)
	var h := l.get_minimum_size().y + 4.0
	bg.size.y = h
	return h


## 转账卡片。pending 的带收款 / 退还；sent 是你转出去的，靠右。
func _card(parent: Control, y: float, amount: int, note: String, status: String, mine: bool, t := {}) -> float:
	var cw := 150.0
	var x := W - PAD - cw if mine else PAD
	var open := status == "pending"
	var h := 62.0 if open else 40.0
	UI.panel(parent, Rect2(x, y, cw, h), CARD if open or status == "sent" else CARD_DONE)
	UI.label(parent, "¥%d　%s" % [amount, note], Vector2(x + 6, y + 2), UI.INK)
	var state: String = {"pending": "待收款 · 下班退回", "taken": "已收款", "returned": "已退还", "sent": "已转账"}[status]
	UI.label(parent, state, Vector2(x + 6, y + 20), UI.INK_SOFT if open else UI.INK)
	if open:
		UI.button(parent, "收款", Rect2(x + 6, y + 40, 64, 18), _answer.bind(t, true))
		UI.button(parent, "退还", Rect2(x + 78, y + 40, 64, 18), _answer.bind(t, false))
	return h


func _reply(entry: Dictionary, option: Dictionary) -> void:
	replied.emit(entry, option)


func _answer(t: Dictionary, taken: bool) -> void:
	transfer_answered.emit(t, taken)
