class_name Desk extends Control
## 筛简历主玩法：限时内对照手册盖章，对错不当场揭晓。

signal finished

## 东西摆在哪由玩家定（DeskLayout）：平时拖文件、全家福、手机、质询按钮，松手就记住；印章只能在“布置桌面”里挪。默认身份证落在规则手册下面，从桌子下沿推上来，不挡简历。
## 信封从简历底下露出来，和身份证同一个位置；这份简历也带着身份证时，竖着放在桌子左边那条空地上。
const ENVELOPE_POS := Vector2(350, 232)
const ENVELOPE_POS_WITH_ID := Vector2(2, 176)
const ENVELOPE_COLOR := Color("c9b48a")
## 08:00 上班筛简历，15:00 去面试，18:00 下班（当天没人面试就整理材料到下班）。
const DAY_START := 8 * 60
const DAY_END := 15 * 60
## 最后半小时钟变红。
const WARN_MINUTES := 30
const GENERIC_REASON := "综合评估后，您与岗位暂不匹配。"
const MISMATCH_REASON := "您提交的材料信息前后不一致。"
## 质询的代价，扣桌上的钟（分钟）：点了两处其实没问题、打一通电话。
const WRONG_PICK_MINUTES := 5
const CALL_MINUTES := 10
## 桌角的全家福和扣着的手机；家里来消息时手机翻过来亮一下。
## 消息气泡贴在手机右边。
const BUBBLE_OFFSET := Vector2(38, -2)
## 翻消息的面板从上面开始往下长，不压住印章。
const INBOX_POS := Vector2(70, 30)
const FamilyPhoto := preload("res://scripts/ui/FamilyPhoto.gd")
const DeskPhone := preload("res://scripts/ui/DeskPhone.gd")
const DeskPrinter := preload("res://scripts/ui/DeskPrinter.gd")

var queue: Array[Candidate] = []
var doc: ResumeDoc
var id_card: IdCardDoc
var elapsed := 0.0
var closing := false
var _clock: Label
var _count: Label
var _pile: Control
var _picker: Control
var _hint: Label
var _doc_layer: Control
var _done_count := 0
## 质询：桌上有身份证以后才有这个开关。
var inspecting := false
## 这份简历上标出的矛盾字段，和打电话听到的解释 {text, truthful}。
var flagged: Array[String] = []
var call_result := {}
var _lines: InspectLines
var _inspect_button: Button
var _call_button: Button
var _phone: Control
var _toast: Label
var _toast_tween: Tween
var _slip: Control
var _printer: Control
## 夹在这份简历里的信封；玩家没表态就盖章，算原样退回。
var _envelope: Control
var _envelope_answered := false
## 家里的消息：上班时只来一次。
var _home_phone: DeskPhone
var _bubble: Control
## desk_texts 里处理到第几条（没对上 when 的变体也算处理过）。
var _texts_sent := 0
var _unread: Panel
var _inbox_panel: Control
var _called := false
var _leave_button: Button
var _leave_confirm: Control
## 布置桌面：能挪的东西，和布置时停钟。
var _book: Rulebook
var _posting: JobPostingDoc
var _photo: Control
var _stamps := {}
var _arranger: DeskArranger
var arranging := false


func _ready() -> void:
	queue = CandidateGenerator.generate_day(GameState.config, RuleEngine.active_rules, GameState.day_seed())
	_build_room()
	_next()


func _build_room() -> void:
	UI.panel(self, Rect2(0, 0, 640, 360), UI.DESK)
	UI.panel(self, Rect2(0, 0, 640, 18), UI.DESK_DARK)
	UI.label(self, "第 %d 天　%s" % [GameState.day, GameState.today], Vector2(6, 1), UI.TEXT_DIM)
	_clock = UI.label(self, "08:00", Vector2(304, 1), UI.GREEN)
	UI.label(self, "存款 ¥%d / 月供 ¥%d" % [GameState.savings, GameState.MORTGAGE], Vector2(496, 1), UI.TEXT_DIM)

	_pile = Control.new()
	_pile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_pile)
	_count = UI.label(self, "", Vector2(10, 26), UI.TEXT)

	# 处理完的简历飞进这里
	UI.panel(self, Rect2(344, 322, 186, 32), UI.DESK_DARK, UI.BLACK)
	_hint = UI.label(self, "已处理 0", Vector2(352, 326), UI.TEXT_DIM)

	# 咖啡杯：隐形的时间流逝提示
	for i in GameState.day_in_month():
		UI.panel(self, Rect2(14 + i * 22, 318, 16, 18), UI.PAPER_DIM, UI.BLACK)
		UI.panel(self, Rect2(16 + i * 22, 320, 12, 4), Color("3a2f2a"))

	_build_family()

	# 桌上所有纸都在同一层：按下哪张哪张置顶，新递上来的简历、身份证压在最上面；
	# 这一层整个在印章、质询按钮下面，手册点得再多也盖不住它们。
	_doc_layer = Control.new()
	_doc_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_doc_layer)

	_book = load("res://scenes/Rulebook.tscn").instantiate()
	_book.position = DeskLayout.pos("rulebook")
	_book.layout_key = "rulebook"
	_doc_layer.add_child(_book)
	_book.setup()

	if not RuleEngine.active_postings.is_empty():
		_posting = JobPostingDoc.new()
		_posting.position = DeskLayout.pos("posting")
		_posting.layout_key = "posting"
		_doc_layer.add_child(_posting)
		_posting.setup(RuleEngine.active_postings)
	_lines = InspectLines.new()
	add_child(_lines)
	_toast = UI.label(self, "", Vector2(150, 1), UI.YELLOW)
	if "id_card" in RuleEngine.active_docs:
		var at := DeskLayout.pos("inspect")
		_inspect_button = UI.button(self, "质询", Rect2(at, Vector2(60, 22)), toggle_inspect)
		_call_button = UI.button(self, "打电话", Rect2(at + Vector2(0, 26), Vector2(60, 22)), call_candidate)
		_call_button.visible = false
		# 质询按钮能拖着挪（打电话跟着走）；点一下才是质询
		_inspect_button.pressed.disconnect(toggle_inspect)
		DeskDrag.attach(_inspect_button, "inspect", toggle_inspect, [_call_button])

	for verdict: String in ["pass", "reject"]:
		var stamp := StampTool.new()
		stamp.position = DeskLayout.pos(verdict)
		add_child(stamp)
		stamp.setup(verdict)
		_stamps[verdict] = stamp


func _process(delta: float) -> void:
	if closing or arranging:
		return
	elapsed += delta
	var ratio := elapsed / GameState.config.screening_seconds
	var minutes := int(lerpf(DAY_START, DAY_END, minf(ratio, 1.0)))
	_clock.text = "%02d:%02d" % [minutes / 60, minutes % 60]
	_check_home(minutes)
	if minutes >= DAY_END - WARN_MINUTES:
		_clock.add_theme_color_override("font_color", UI.RED)
	if ratio >= 1.0:
		_close_day()


func _next() -> void:
	_draw_pile()
	if queue.is_empty():
		_close_day()
		return
	doc = load("res://scenes/ResumeDoc.tscn").instantiate()
	var doc_pos := DeskLayout.pos("resume")
	doc.layout_key = "resume"
	doc.position = Vector2(-240, doc_pos.y)
	_doc_layer.add_child(doc)
	doc.setup(queue.pop_front())
	doc.stamped.connect(_on_stamped)
	Sfx.paper()
	var tween := create_tween().set_parallel()
	tween.tween_property(doc, "position", doc_pos, 0.16).set_trans(Tween.TRANS_QUAD)
	if "id_card" in doc.candidate.docs:
		id_card = IdCardDoc.new()
		var id_pos := DeskLayout.pos("id_card")
		id_card.layout_key = "id_card"
		id_card.position = Vector2(id_pos.x, 370)
		_doc_layer.add_child(id_card)
		id_card.setup(doc.candidate)
		tween.tween_property(id_card, "position", id_pos, 0.2).set_trans(Tween.TRANS_QUAD)
	if not doc.candidate.envelope.is_empty():
		_show_envelope(doc.candidate)
		tween.tween_property(_envelope, "position", _envelope_pos(doc.candidate), 0.25).set_trans(Tween.TRANS_QUAD)
	for d: DraggableDoc in [doc, id_card]:
		if d:
			d.field_picked.connect(pick_field)
			d.set_inspecting(inspecting)


func _draw_pile() -> void:
	UI.clear(_pile)
	_count.text = "待处理 %d" % queue.size()
	for i in mini(queue.size(), 16):
		UI.panel(_pile, Rect2(14, 262 - i * 3, 70, 8), UI.PAPER if i % 2 == 0 else UI.PAPER_DIM, UI.INK_SOFT)


func _on_stamped(verdict: String, _at: Vector2) -> void:
	Sfx.stamp()
	_shake()
	if verdict == "pass":
		commit("pass", &"", "")
	else:
		_open_picker()


func _shake() -> void:
	var tween := create_tween()
	tween.tween_property(self, "position", Vector2(0, 3), 0.03)
	tween.tween_property(self, "position", Vector2.ZERO, 0.08)


## 拒绝时必须选一条理由，这句话写进决策日志，终章原样回到玩家身上。
func _open_picker() -> void:
	_picker = Control.new()
	add_child(_picker)
	_picker.size = size
	UI.panel(_picker, Rect2(0, 0, 640, 360), Color(0, 0, 0, 0.35)).mouse_filter = Control.MOUSE_FILTER_STOP
	var rules := RuleEngine.active_rules
	var mismatch := 0 if flagged.is_empty() else 1
	var height := 28.0 + 24.0 * (rules.size() + 2 + mismatch)
	var top := 180.0 - height / 2.0
	UI.panel(_picker, Rect2(150, top, 340, height), UI.PAPER, UI.BLACK)
	UI.label(_picker, "选择拒绝理由（将发送给候选人）", Vector2(160, top + 6), UI.INK)
	var y := top + 24.0
	# 质询标出过矛盾才有这一条，排第一：刚抓到的就是它
	if mismatch:
		UI.button(_picker, MISMATCH_REASON, Rect2(158, y, 324, 22), commit.bind("reject", &"mismatch", MISMATCH_REASON))
		y += 24.0
	for rule in rules:
		UI.button(_picker, rule.reject_reason_key, Rect2(158, y, 324, 22), commit.bind("reject", rule.id, rule.reject_reason_key))
		y += 24.0
	UI.button(_picker, GENERIC_REASON, Rect2(158, y, 324, 22), commit.bind("reject", &"generic", GENERIC_REASON))
	y += 24.0
	UI.button(_picker, "← 返回，再看看", Rect2(158, y, 324, 22), _cancel_reject)


## 反悔：关掉理由框、擦掉拒绝章，这份简历回到桌上。15:00 已经到了就直接收工。
func _cancel_reject() -> void:
	_picker.queue_free()
	_picker = null
	doc.unstamp()
	if closing:
		_finish()


func commit(verdict: String, reason_rule: StringName, reason_text: String) -> void:
	if _picker:
		_picker.queue_free()
		_picker = null
	var extra := {}
	if not flagged.is_empty():
		extra = {"flagged": flagged.duplicate(), "called": not call_result.is_empty(), "explanation_truthful": call_result.get("truthful")}
	if _envelope and not _envelope_answered:
		GameState.answer_envelope(doc.candidate, false)
	var why := GameState.record_decision(doc.candidate, verdict, reason_rule, reason_text, extra)
	if why != "":
		_print_slip(doc.candidate.display_name, why)
	_reset_inspect()
	_done_count += 1
	_hint.text = "已处理 %d" % _done_count
	for leaving: Control in [doc, id_card, _envelope]:
		if leaving:
			var tween := create_tween()
			tween.tween_property(leaving, "position", Vector2(400, 330), 0.18).set_trans(Tween.TRANS_QUAD)
			tween.tween_callback(leaving.queue_free)
	doc = null
	id_card = null
	_envelope = null
	if closing:
		_finish()
	else:
		_next()


func _close_day() -> void:
	if closing:
		return
	closing = true
	if _picker:
		return  # 等玩家选完理由
	_finish()


func _finish() -> void:
	if doc:
		doc.queue_free()
		doc = null
		queue.append(null)
	if id_card:
		id_card.queue_free()
		id_card = null
	if _envelope:
		_envelope.queue_free()
		_envelope = null
	_reset_inspect()
	if _inspect_button:
		_inspect_button.disabled = true
	_close_bubble()
	_close_inbox()
	if _leave_confirm:
		_leave_confirm.queue_free()
		_leave_confirm = null
	if _leave_button:
		_leave_button.disabled = true
	GameState.stats.unprocessed = queue.size()
	var interview := not GameState.interviewees.is_empty()
	var note := ("15:00，该去面试了。今天两场。" if InterviewRoom.second_candidate() else "15:00，该去面试了。") if interview else "15:00。今天没有面试，你整理材料到六点下班。"
	if not queue.is_empty():
		note += "还有 %d 份简历没看，计件没了。" % queue.size()
	if GameState.stats.left_early:
		note = "你提前下班了。" + ("" if queue.is_empty() else "还有 %d 份简历没看。" % queue.size())
	UI.panel(self, Rect2(170, 146, 300, 76), UI.BLACK, UI.GREEN_DIM)
	UI.label(self, note, Vector2(182, 154), UI.GREEN, 276)
	UI.button(self, "去面试" if interview and not GameState.stats.left_early else "继续", Rect2(280, 194, 80, 20), finished.emit)


## 盖错章，桌角的打印机当场吐一张违规单。点一下扔掉；下一张来了旧的就收走。
## 第一个月只扣这份的判断奖金；第二个月单子带编号，一天第 3 次起罚款。
func _print_slip(who: String, why: String) -> void:
	if _slip:
		_slip.queue_free()
	var fined := GameState.fines_on()
	var n: int = GameState.stats.wrong
	var slip := Control.new()
	slip.size.x = 92
	slip.mouse_filter = Control.MOUSE_FILTER_STOP
	slip.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var shadow := UI.panel(slip, Rect2(2, 2, slip.size.x, 0), UI.BLACK)
	var paper := UI.panel(slip, Rect2(0, 0, slip.size.x, 0), UI.PAPER, UI.INK_SOFT)
	UI.panel(slip, Rect2(0, 0, slip.size.x, 16), UI.RED)
	UI.label(slip, "违规通知 #%d" % n if fined else "违规通知", Vector2(5, 1), UI.PAPER)
	# 先放进一个临时容器入树，换行宽度才生效，好量出单子多长
	add_child(slip)
	var y := 20.0
	for line: Array in [
		[who, UI.INK],
		[why, UI.INK],
		[_slip_cost(fined, n), UI.RED if fined and n > GameState.FREE_WARNINGS else UI.INK_SOFT],
	]:
		var l := UI.label(slip, line[0], Vector2(5, y), line[1], slip.size.x - 10)
		y += l.get_line_count() * (l.get_line_height() + 1) + 4
	slip.size.y = y + 2
	shadow.size.y = slip.size.y
	paper.size.y = slip.size.y
	remove_child(slip)

	# 单子从出纸口往上冒；打印机被挪到顶上、上面放不下，就从底下吐
	var at := _printer.position
	var mouth := at + DeskPrinter.SLOT.position + Vector2((DeskPrinter.SLOT.size.x - slip.size.x) / 2.0, 0)
	var up := mouth.y - slip.size.y >= DeskLayout.TOP
	var feed := Control.new()
	feed.clip_contents = true
	feed.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if up:
		feed.position = Vector2(mouth.x, mouth.y - slip.size.y)
	else:
		feed.position = Vector2(mouth.x, at.y + DeskPrinter.H)
	feed.size = slip.size + Vector2(2, 2)
	add_child(feed)
	feed.add_child(slip)
	slip.position.y = slip.size.y if up else -slip.size.y
	slip.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			Sfx.paper()
			var away := create_tween()
			away.tween_property(feed, "modulate:a", 0.0, 0.15)
			away.tween_callback(feed.queue_free))
	_slip = feed

	var tween := create_tween()
	tween.tween_interval(0.2)  # 让盖章声先响完
	tween.tween_callback(func() -> void:
		Sfx.printer()
		_printer.print_for(0.6))
	# 针式打印机一截一截往外走
	var steps := 5
	for i in steps:
		tween.tween_property(slip, "position:y", slip.size.y * (1.0 - float(i + 1) / steps) * (1 if up else -1), 0.08)
		tween.tween_interval(0.04)


func _slip_cost(fined: bool, n: int) -> String:
	if not fined:
		return "本月不扣钱，这份绩效少拿 ¥%d" % int(GameState.pay.per_correct)
	if n > GameState.FREE_WARNINGS:
		return "今天第 %d 次，罚款 ¥%d" % [n, GameState.VIOLATION_FINE]
	return "今天第 %d 次。第 %d 次起每次罚 ¥%d" % [n, GameState.FREE_WARNINGS + 1, GameState.VIOLATION_FINE]


func toggle_inspect() -> void:
	inspecting = not inspecting
	_inspect_button.text = "质询中" if inspecting else "质询"
	_lines.picked = []
	for d: DraggableDoc in [doc, id_card]:
		if d:
			d.set_inspecting(inspecting)
	if inspecting:
		_show_toast("点两份材料上的同一项", UI.YELLOW)


## 先点一份材料上的一行，再点另一份上的同一项：值不一样就画红线，一样就白扣钟点。
func pick_field(d: DraggableDoc, key: String) -> void:
	if _lines.picked.is_empty() or _lines.picked[0] == d:
		_lines.picked = [d, key]
		return
	var first: DraggableDoc = _lines.picked[0]
	var first_key: String = _lines.picked[1]
	_lines.picked = []
	if key == first_key and _shown(first, key) != _shown(d, key):
		if key not in flagged:
			flagged.append(key)
			_lines.links.append([first, key, d, key])
		Sfx.paper()
		_show_toast("对不上！", UI.RED)
		_call_button.visible = call_result.is_empty()
		return
	_spend(WRONG_PICK_MINUTES)
	_show_toast(("这两处没问题" if key == first_key else "这两项比不了") + "　−%d 分钟" % WRONG_PICK_MINUTES, UI.TEXT)


## 材料上印的那一项。简历只印到出生年月，所以只比年月。
func _shown(d: DraggableDoc, key: String) -> String:
	var c: Candidate = d.get("candidate")
	var value := str(c.fact(key, "id_card" if d is IdCardDoc else "resume"))
	return value.left(7) if key == "birth_date" else value


## 打电话核实：扣钟点，候选人给一句解释。解释不改判定，只透露这个人诚不诚实。
func call_candidate() -> void:
	if flagged.is_empty() or not call_result.is_empty():
		return
	_spend(CALL_MINUTES)
	_show_toast("−%d 分钟" % CALL_MINUTES, UI.TEXT)
	var c := doc.candidate
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([GameState.day_seed(), c.id])
	var source: Discrepancy = Discrepancy.new()
	for d in RuleEngine.active_discrepancies:
		if d.field in flagged:
			source = d
			break
	call_result = source.explain(c, rng) if c.call_line == "" else {"text": c.call_line, "truthful": true}
	_call_button.visible = false
	_phone = Control.new()
	add_child(_phone)
	UI.panel(_phone, Rect2(110, 218, 220, 76), UI.BLACK, UI.GREEN_DIM)
	UI.label(_phone, "电话　" + c.fact("display_name") + "：", Vector2(118, 222), UI.GREEN)
	UI.label(_phone, "“%s”" % call_result.text, Vector2(118, 238), UI.TEXT, 204)
	UI.button(_phone, "挂断", Rect2(284, 274, 40, 18), _hang_up)
	Sfx.key()


func _hang_up() -> void:
	if _phone:
		_phone.queue_free()
		_phone = null


func _reset_inspect() -> void:
	flagged = []
	call_result = {}
	_lines.clear()
	_hang_up()
	if _call_button:
		_call_button.visible = false


## 桌上的钟往前拨：DAY_START–DAY_END 对应 screening_seconds 真实秒数。
func _spend(minutes: int) -> void:
	elapsed += minutes / float(DAY_END - DAY_START) * GameState.config.screening_seconds


func _show_toast(text: String, color: Color) -> void:
	_toast.text = text
	_toast.add_theme_color_override("font_color", color)
	if _toast_tween:
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_interval(2.5)
	_toast_tween.tween_callback(func() -> void: _toast.text = "")


## 信封：写着谁塞的、塞多少。收进抽屉当晚进存款；退回去就什么都没发生——至少这个月。
func _envelope_pos(c: Candidate) -> Vector2:
	return ENVELOPE_POS_WITH_ID if "id_card" in c.docs else ENVELOPE_POS


func _show_envelope(c: Candidate) -> void:
	_envelope_answered = false
	_envelope = Control.new()
	var narrow := "id_card" in c.docs
	_envelope.size = Vector2(96, 148) if narrow else Vector2(180, 86)
	_envelope.position = Vector2(_envelope_pos(c).x, 370)
	_envelope.mouse_filter = Control.MOUSE_FILTER_STOP
	_doc_layer.add_child(_envelope)
	UI.panel(_envelope, Rect2(Vector2(2, 2), _envelope.size), UI.BLACK)
	UI.panel(_envelope, Rect2(Vector2.ZERO, _envelope.size), ENVELOPE_COLOR, UI.INK_SOFT)
	UI.label(_envelope, "信封（夹在简历里）" if not narrow else "信封", Vector2(6, 2), UI.INK_SOFT)
	UI.label(_envelope, c.envelope.text, Vector2(6, 18), UI.INK, _envelope.size.x - 12)
	if narrow:
		UI.button(_envelope, "收进抽屉", Rect2(6, 104, 84, 18), _answer_envelope.bind(true))
		UI.button(_envelope, "退回去", Rect2(6, 126, 84, 18), _answer_envelope.bind(false))
	else:
		UI.button(_envelope, "收进抽屉", Rect2(6, 62, 80, 20), _answer_envelope.bind(true))
		UI.button(_envelope, "退回去", Rect2(94, 62, 80, 20), _answer_envelope.bind(false))


func _answer_envelope(taken: bool) -> void:
	if _envelope_answered or doc == null:
		return
	_envelope_answered = true
	GameState.answer_envelope(doc.candidate, taken)
	Sfx.paper()
	for child in _envelope.get_children():
		if child is Button:
			child.queue_free()
	var amount := int(doc.candidate.envelope.get("amount", 0))
	var narrow := _envelope.size.x < 120
	UI.label(_envelope, "（¥%d 进了抽屉。）" % amount if taken else "（原样塞回简历里了。）", Vector2(6, 104 if narrow else 64), UI.INK_SOFT, _envelope.size.x - 12)


## 全家福：你、老婆、孩子、你爸。
func _build_family() -> void:
	var photo: Control = FamilyPhoto.new()
	photo.position = DeskLayout.pos("photo")
	add_child(photo)
	_photo = photo
	DeskDrag.attach(photo, "photo")
	_printer = DeskPrinter.new()
	_printer.position = DeskLayout.pos("printer")
	add_child(_printer)
	DeskDrag.attach(_printer, "printer")
	_home_phone = DeskPhone.new()
	_home_phone.position = DeskLayout.pos("phone")
	_home_phone.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	add_child(_home_phone)
	# 点一下翻消息；拖开就是挪手机，挪完把弹出来的消息收起来，下回贴着新位置弹
	DeskDrag.attach(_home_phone, "phone", _toggle_inbox).on_moved = func() -> void:
		_close_bubble()
		_close_inbox()
	_unread = UI.panel(_home_phone, Rect2(22, -3, 8, 8), UI.RED, UI.BLACK)
	_unread.visible = false


func _check_home(minutes: int) -> void:
	var cfg := GameState.config
	while _texts_sent < cfg.desk_texts.size() and minutes >= int(cfg.desk_texts[_texts_sent].at):
		var entry: Dictionary = cfg.desk_texts[_texts_sent]
		_texts_sent += 1
		var id: String = entry.get("id", "")
		var taken: bool = id != "" and GameState.stats.texts.any(func(e: Dictionary) -> bool: return e.get("id", "") == id)
		if taken or not GameState.family_matches(entry.get("when", "")):
			continue
		GameState.receive_text(entry)
		_unread.visible = true
		_ring(entry.text, false)
		return  # 一次只响一条
	if not _called and not cfg.midday_call.is_empty() and minutes >= int(cfg.midday_call.at):
		_called = true
		GameState.stats.called = true
		GameState.receive_text({"at": cfg.midday_call.at, "text": cfg.midday_call.text, "call": true})
		_ring(cfg.midday_call.text, true)


## 手机震、亮屏、旁边弹一条消息。预览几秒后自己消失；来电要点“知道了”，之后桌上多一个“提前下班”。
func _ring(text: String, is_call: bool) -> void:
	Sfx.buzz()
	_close_inbox()
	var home_x := DeskLayout.pos("phone").x
	var shake := create_tween()
	for i in 6:
		shake.tween_property(_home_phone, "position:x", home_x + (2.0 if i % 2 == 0 else -2.0), 0.05)
	shake.tween_property(_home_phone, "position:x", home_x, 0.05)
	_close_bubble()
	_home_phone.set_lit(true, _clock.text)
	_bubble = Control.new()
	_bubble.position = _bubble_pos()
	_bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bubble)
	var height := 64.0 if is_call else 40.0
	UI.panel(_bubble, Rect2(0, 0, 210, height), UI.BLACK, UI.GREEN_DIM)
	UI.label(_bubble, ("来电" if is_call else "短信") + "　" + text, Vector2(6, 4), UI.TEXT, 198)
	if not is_call:
		UI.label(_bubble, "点手机回复", Vector2(150, 26), UI.GREEN_DIM)
	if is_call:
		UI.button(_bubble, "知道了", Rect2(150, 40, 54, 18), _hang_up_home)
	else:
		var shown := _bubble
		var fade := create_tween()
		fade.tween_interval(4.0)
		fade.tween_callback(func() -> void:
			if _bubble == shown:
				_close_bubble())


func _hang_up_home() -> void:
	_close_bubble()
	if not closing and not _leave_button:
		_leave_button = UI.button(self, "提前下班", Rect2(14, 188, 74, 20), _ask_leave)


func _close_bubble() -> void:
	if _bubble:
		_bubble.queue_free()
		_bubble = null
	if _home_phone:
		_home_phone.set_lit(false)


## 点手机：翻今天收到的消息，没回的能选一句回，再点一下手机收起。
func _toggle_inbox() -> void:
	if _inbox_panel:
		_close_inbox()
		return
	if _bubble and _leave_button == null and _called and not closing:
		return  # 来电还没接，先点“知道了”
	_close_bubble()
	_open_inbox()


func _open_inbox() -> void:
	_close_inbox()
	_inbox_panel = Control.new()
	_inbox_panel.position = INBOX_POS
	_inbox_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_inbox_panel)
	var bg := UI.panel(_inbox_panel, Rect2(0, 0, 240, 30), UI.BLACK, UI.GREEN_DIM)
	UI.label(_inbox_panel, "老婆", Vector2(6, 3), UI.GREEN)
	UI.button(_inbox_panel, "收起", Rect2(196, 3, 40, 16), _close_inbox)
	var y := 36.0
	var texts: Array = GameState.stats.texts
	if texts.is_empty():
		UI.label(_inbox_panel, "（今天还没有消息）", Vector2(6, y), UI.TEXT_DIM)
		y += 16.0
	for entry: Dictionary in texts:
		var at := int(entry.at)
		UI.label(_inbox_panel, "%02d:%02d" % [at / 60, at % 60], Vector2(6, y), UI.TEXT_DIM)
		var body: String = ("（来电）" if entry.get("call", false) else "") + String(entry.text).trim_prefix("老婆：")
		var line := UI.label(_inbox_panel, body, Vector2(44, y), UI.TEXT, 190)
		y += maxf(16.0, line.get_minimum_size().y + 2.0)
		if not entry.has("replies"):
			continue
		if GameState.text_replied(entry.id):
			var mine := _reply_label(entry)
			var you := UI.label(_inbox_panel, "你：" + mine, Vector2(44, y), UI.GREEN, 190)
			y += maxf(16.0, you.get_minimum_size().y + 2.0)
			continue
		for option: Dictionary in entry.replies:
			var b := UI.text_button(_inbox_panel, option.label, Rect2(44, y, 190, 18), _reply.bind(entry, option))
			y += b.size.y + 2.0
	bg.size.y = y + 4.0
	_unread.visible = false


func _reply_label(entry: Dictionary) -> String:
	for option: Dictionary in entry.replies:
		if option.key == GameState.family.get(entry.id, ""):
			return option.label
	return ""


## 回一条：打字要花几分钟，钟照走。
func _reply(entry: Dictionary, option: Dictionary) -> void:
	if closing or GameState.text_replied(entry.id):
		return
	GameState.reply_text(entry, option)
	_spend(GameState.REPLY_MINUTES)
	Sfx.key()
	_show_toast("回了老婆　−%d 分钟" % GameState.REPLY_MINUTES, UI.TEXT)
	_open_inbox()


func _close_inbox() -> void:
	if _inbox_panel:
		_inbox_panel.queue_free()
		_inbox_panel = null


## 走之前说清楚丢的是什么：剩下的简历没计件，今天的面试取消。
func _ask_leave() -> void:
	if closing or _leave_confirm or _picker:
		return
	var left := queue.size() + (1 if doc else 0)
	var lines := "剩下 %d 份简历今天不看了，计件没了。" % left
	if not GameState.interviewees.is_empty():
		lines += "\n今天的面试也取消。"
	_leave_confirm = Control.new()
	add_child(_leave_confirm)
	UI.panel(_leave_confirm, Rect2(0, 0, 640, 360), Color(0, 0, 0, 0.35)).mouse_filter = Control.MOUSE_FILTER_STOP
	UI.panel(_leave_confirm, Rect2(180, 130, 280, 90), UI.PAPER, UI.BLACK)
	UI.label(_leave_confirm, "现在就走？", Vector2(192, 138), UI.INK)
	UI.label(_leave_confirm, lines, Vector2(192, 156), UI.INK_SOFT, 256)
	UI.button(_leave_confirm, "走", Rect2(192, 194, 120, 20), _leave)
	UI.button(_leave_confirm, "再等等", Rect2(328, 194, 120, 20), func() -> void:
		_leave_confirm.queue_free()
		_leave_confirm = null)


func _leave() -> void:
	_leave_confirm.queue_free()
	_leave_confirm = null
	GameState.leave_early()
	_close_day()


## 气泡贴在手机右边；手机放在桌子右半边时改贴左边，别伸出屏幕。
func _bubble_pos() -> Vector2:
	var phone := DeskLayout.pos("phone")
	var at := phone + BUBBLE_OFFSET
	if at.x + 210 > 640:
		at.x = phone.x - 214
	return at.clamp(Vector2(0, DeskLayout.TOP), Vector2(430, 360 - 64))


## 布置桌面（从菜单进）：钟停着，拖占位框摆东西，存下来以后每天都这么摆。
func start_arrange() -> void:
	if closing or arranging or _picker or _leave_confirm:
		return
	arranging = true
	_close_bubble()
	_close_inbox()
	_hang_up()
	var keys := ["resume", "rulebook", "photo", "phone", "pass", "reject"]
	if _posting:
		keys.append("posting")
	if "id_card" in RuleEngine.active_docs:
		keys.append_array(["id_card", "inspect"])
	_arranger = DeskArranger.new()
	add_child(_arranger)
	_arranger.setup(keys, _place)
	_arranger.closed.connect(func() -> void:
		arranging = false
		_arranger = null)


func _place(key: String, at: Vector2) -> void:
	match key:
		"resume":
			if doc:
				doc.position = at
		"id_card":
			if id_card:
				id_card.position = at
		"rulebook":
			_book.position = at
		"posting":
			_posting.position = at
		"photo":
			_photo.position = at
		"phone":
			_home_phone.position = at
		"pass", "reject":
			_stamps[key].position = at
		"inspect":
			_inspect_button.position = at
			_call_button.position = at + Vector2(0, 26)
