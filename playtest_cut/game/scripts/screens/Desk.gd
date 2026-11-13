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
## 昨天破格了人，今天 14:00 先去单独面 TA：筛简历少一个钟头（钟走得一样快，只是早收工）。
const VOUCH_DAY_END := 14 * 60
## 最后半小时钟变红。
const WARN_MINUTES := 30
const GENERIC_REASON := "综合评估后，您与岗位暂不匹配。"
const MISMATCH_REASON := "您提交的材料信息前后不一致。"
## 质询的代价，扣桌上的钟（分钟）：点了两处其实没问题、打一通电话。
const WRONG_PICK_MINUTES := 5
const CALL_MINUTES := 10
## 入职登记表：核对、签一张扣的钟点。老周被抽走以后，这活归你（DayConfig.intake）。
const INTAKE_MINUTES := 8
const INTAKE_POS := Vector2(14, 164)
## 桌角的全家福和扣着的手机；家里来消息时手机翻过来亮一下。
## 消息气泡贴在手机右边。
const BUBBLE_OFFSET := Vector2(38, -2)
## 翻消息的面板从上面开始往下长，不压住印章。
const INBOX_POS := Vector2(70, 30)
const FamilyPhoto := preload("res://scripts/ui/FamilyPhoto.gd")
const DeskPhone := preload("res://scripts/ui/DeskPhone.gd")
const DeskPrinter := preload("res://scripts/ui/DeskPrinter.gd")
const PhoneChat := preload("res://scripts/ui/PhoneChat.gd")

var queue: Array[Candidate] = []
var doc: ResumeDoc
var id_card: IdCardDoc
var elapsed := 0.0
var closing := false
var _clock: Label
var _count: Label
var _pile: Control
## 文件盒（待处理那摞）和抽屉的位置。
const PILE_POS := Vector2(6, 196)
const DRAWER_POS := Vector2(0, 338)
const FILE_BOX := preload("res://assets/desk/file_box.png")
var _picker: Control
var _hint: Label
var _doc_layer: Control
## 上一份简历、身份证：新的一份插在它们原来那一层，玩家压在上面的手册/JD 继续压着。
var _last_doc: Control
var _last_id: Control
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
var _inbox_panel: PhoneChat
## 手机里每个对话看过几条，收起再打开还记得。
var _seen := {}
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
## 今天几点收工：平时 15:00，有破格面试 14:00。
var day_end := DAY_END
## 破格章：第 3 天起有（第二个月一直在桌上）。第一个月第 3 天要等主角看到那份心动的简历，才从抽屉里拿出来。
var _exception_stamp: StampTool
## 按组招的日子左下那块印章托盘：跟着拒绝章走（布置桌面挪拒绝章，托盘一起挪）。
var _stamp_tray: Control
var _reveal: Control
var _vouch_confirm: Control
## 赵主管早上贴的便签，没有就是 null；_chief_open 是点开摊在桌上的那张。
var _chief_note: Control
var _chief_open: Panel
## 今天要签的入职登记表（昨天录用的人），签完的从这里拿掉。
var _intake: Array = []
var _intake_button: Button
var _intake_form: Control
## 按组招的日子：一排文件夹，和这一份正要放进哪个组。
const FULL_MINUTES := 2
var _folder_row: Control
var _folders: Array[TeamFolder] = []
var _filing: JobPosting
var _folder_picker: Control
## HireBot 预筛（DayConfig.hirebot >= 2）：跟它不一样的，写一句理由、扣几分钟。
const OVERRIDE_MINUTES := 3
const OVERRIDE_REASONS := ["它没看身份证上的年份", "它没看工作年限后面的小字", "这一条它看错了，我核过", "说不清，我想再看看这个人"]
var _override: Control
## 上班时桌上弹出来的事（DayConfig.desk_memos），处理到第几件；弹着的那一件。
var _memos_done := 0
var _memo: Control
var _pace_label: Label


func _ready() -> void:
	if not GameState.vouched.is_empty():
		day_end = VOUCH_DAY_END
	var cfg := GameState.config
	if cfg.standard_time:
		cfg = cfg.duplicate()
		cfg.resume_count = GameState.resume_count_today()
	queue = CandidateGenerator.generate_day(cfg, RuleEngine.active_rules, GameState.day_seed(), not GameState.late_today.is_empty())
	# HireBot 预筛：来的时候已经分成两叠，推荐的在上面
	if GameState.config.hirebot >= 2:
		var yes := queue.filter(func(c: Candidate) -> bool: return HireBot.label(c) == HireBot.RECOMMEND)
		var no := queue.filter(func(c: Candidate) -> bool: return HireBot.label(c) != HireBot.RECOMMEND)
		queue.assign(yes + no)
	# 晚到：钟一样快，从到公司那一刻走起，早上那截没了
	elapsed = int(GameState.late_today.get("minutes", 0)) * _seconds_per_minute()
	_build_room()
	_next()


func _build_room() -> void:
	# 桌面：三聚氰胺板、简历底下一块深绿皮台垫、右下一圈咖啡杯印
	UI.sprite(self, "res://assets/desk/desk_bg.png", Vector2.ZERO)
	UI.panel(self, Rect2(0, 0, 640, 18), UI.DESK_DARK)
	UI.label(self, "第 %d 天　%s" % [GameState.day, GameState.today], Vector2(6, 1), UI.TEXT_DIM)
	_clock = UI.label(self, GameState.arrival_time(), Vector2(304, 1), UI.GREEN)
	UI.label(self, "存款 ¥%d / 月供 ¥%d" % [GameState.savings, GameState.MORTGAGE], Vector2(496, 1), UI.TEXT_DIM)

	_pile = Control.new()
	_pile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pile.position = PILE_POS
	add_child(_pile)
	_build_drawer()
	# 待处理的数写在文件盒前壁的白标签上
	_count = UI.label(self, "", PILE_POS + Vector2(10, 42), UI.INK)
	_count.size.x = 64
	_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# 处理完的简历飞进这里；按组招的日子底下摆文件夹，计数挪到顶上那条
	if RuleEngine.folder_mode:
		_hint = UI.label(self, "已处理 0", Vector2(352, 1), UI.TEXT_DIM)
	else:
		UI.panel(self, Rect2(344, 322, 186, 32), UI.DESK_DARK, UI.BLACK)
		_hint = UI.label(self, "已处理 0", Vector2(352, 326), UI.TEXT_DIM)
		# 标准耗时的日子：人效看板写在已处理底下
		if GameState.quota_today() > 0 and GameState.config.standard_time:
			var pace := "标准耗时 %.0f 分钟/份" % GameState.best_pace if GameState.best_pace > 0.0 else "标准耗时 —"
			_pace_label = UI.label(self, pace + "（王总照这个排量）", Vector2(352, 339), UI.YELLOW)

	# 咖啡杯：隐形的时间流逝提示。按组招的日子底下一排是文件夹，杯子挪到简历下沿、文件夹上面
	var cups := Vector2(104, 294) if RuleEngine.folder_mode else Vector2(14, 318)
	for i in GameState.day_in_month():
		UI.panel(self, Rect2(cups.x + i * 22, cups.y, 16, 18), UI.PAPER_DIM, UI.BLACK)
		UI.panel(self, Rect2(cups.x + 2 + i * 22, cups.y + 2, 12, 4), Color("3a2f2a"))
	if RuleEngine.folder_mode:
		_build_stamp_tray()

	_build_family()
	_build_chief_note()

	# 桌上所有纸都在同一层：按下哪张哪张置顶；新递上来的简历、身份证接替上一份那一层，玩家压上去的不会被盖住；
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
	# 身份证先上桌、只核年龄；材料之间开始有矛盾的那天，才有质询
	if _can_inspect():
		var at := DeskLayout.pos("inspect")
		_inspect_button = UI.button(self, "质询", Rect2(at, Vector2(60, 22)), toggle_inspect)
		_call_button = UI.button(self, "打电话", Rect2(at + Vector2(0, 26), Vector2(60, 22)), call_candidate)
		_call_button.visible = false
		# 质询按钮能拖着挪（打电话跟着走）；点一下才是质询
		_inspect_button.pressed.disconnect(toggle_inspect)
		DeskDrag.attach(_inspect_button, "inspect", toggle_inspect, [_call_button])

	if RuleEngine.folder_mode:
		_build_folders()
	for verdict: String in (["reject"] if RuleEngine.folder_mode else ["pass", "reject"]):
		var stamp := StampTool.new()
		stamp.position = DeskLayout.pos("reject_team" if RuleEngine.folder_mode else verdict)
		add_child(stamp)
		stamp.setup(verdict)
		_stamps[verdict] = stamp
	# 第 3 天以后破格章一直在桌上；第 3 天当天等那份简历出现才拿出来
	if GameState.day > GameState.EXCEPTION_DAY:
		_add_exception_stamp()
	if GameState.config.intake:
		_intake = GameState.hired_on(GameState.day - 1).map(func(h: Dictionary) -> Dictionary: return h.candidate)
		if not _intake.is_empty():
			_intake_button = UI.button(self, "", Rect2(INTAKE_POS, Vector2(74, 20)), _open_intake)
			_refresh_intake()


func _process(delta: float) -> void:
	if closing or arranging or _reveal or _memo:
		return
	elapsed += delta
	# screening_seconds 是 08:00–15:00 的真实秒数；有破格面试的日子钟一样快，14:00 就收工
	var minutes := mini(int(DAY_START + elapsed / _seconds_per_minute()), day_end)
	_clock.text = "%02d:%02d" % [minutes / 60, minutes % 60]
	_check_home(minutes)
	_check_transfers(minutes)
	_check_memos(minutes)
	if minutes >= day_end - WARN_MINUTES:
		_clock.add_theme_color_override("font_color", UI.RED)
	if minutes >= day_end:
		_close_day()


func _seconds_per_minute() -> float:
	return GameState.config.screening_seconds / float(DAY_END - DAY_START)


func _next() -> void:
	_draw_pile()
	if queue.is_empty():
		_close_day()
		return
	doc = load("res://scenes/ResumeDoc.tscn").instantiate()
	var doc_pos := DeskLayout.pos("resume")
	doc.layout_key = "resume"
	doc.position = Vector2(-240, doc_pos.y)
	_insert_doc(doc, _last_doc)
	doc.setup(queue.pop_front())
	_attach_cover_note(doc)
	doc.stamped.connect(_on_stamped)
	if RuleEngine.folder_mode:
		doc.on_drag = _hover_folders
		doc.on_release = _drop_on_folder
	Sfx.paper()
	var tween := create_tween().set_parallel()
	tween.tween_property(doc, "position", doc_pos, 0.16).set_trans(Tween.TRANS_QUAD)
	if "id_card" in doc.candidate.docs:
		id_card = IdCardDoc.new()
		var id_pos := DeskLayout.pos("id_card")
		id_card.layout_key = "id_card"
		id_card.position = Vector2(id_pos.x, 370)
		_insert_doc(id_card, _last_id if is_instance_valid(_last_id) else doc)
		id_card.setup(doc.candidate)
		tween.tween_property(id_card, "position", id_pos, 0.2).set_trans(Tween.TRANS_QUAD)
	if not doc.candidate.envelope.is_empty():
		_show_envelope(doc.candidate)
		tween.tween_property(_envelope, "position", _envelope_pos(doc.candidate), 0.25).set_trans(Tween.TRANS_QUAD)
	for d: DraggableDoc in [doc, id_card]:
		if d:
			d.field_picked.connect(pick_field)
			d.set_inspecting(inspecting)
	if GameState.day == GameState.EXCEPTION_DAY and _exception_stamp == null and doc.candidate.liked_line != "":
		_show_reveal(doc.candidate)


## 砍减版：生成的简历底下夹一张小纸条，一句人话（不进规则）。按背景挑，按候选人 id 定，不动生成器的随机数。
const COVER_NOTES := {
	"fresh": ["第一次投简历，请多指教。", "辅导员说这家公司好。", "每天都能来，不怕远。", "投了四十家，就您回了。", "我爸妈不知道我在投实习。", "能学东西就行，不挑活。"],
	"regular": ["组快散了，想早点走。", "孩子上小学，想离家近。", "薪资好谈，想做事。", "上一家拖了两个月工资。", "周末面试也可以。", "刚在这个城市买了房。"],
	"changer": ["转行三年了，还在补课。", "当过老师，自学两年代码。", "年纪是大了点，但学得快。", "原来的行业没了，只能换。", "试用期降薪也可以。"],
	"laid_off": ["被优化了，不是因为绩效。", "赔偿拿完了，房贷还在。", "在家待了三个月了。", "前公司整个部门都没了。", "投了一百多份，求个面试。", "老婆还不知道我没上班。"],
}


func _attach_cover_note(d: ResumeDoc) -> void:
	var c := d.candidate
	if c.is_story or c.broker:
		return
	var pool: Array = COVER_NOTES.get(c.background, COVER_NOTES.regular)
	var text: String = pool[absi(hash(String(c.id))) % pool.size()]
	if c.blocked != "":
		text = BlockedTalent.cover_note(c)
	var note := Control.new()
	note.position = Vector2(6, ResumeDoc.SIZE.y + 2)
	note.rotation = -0.02
	note.mouse_filter = Control.MOUSE_FILTER_IGNORE
	d.add_child(note)
	var label := UI.label(note, "附言：" + text, Vector2(4, 0), UI.INK)
	label.clip_text = true
	label.size = Vector2(176, 15)
	var paper := UI.panel(note, Rect2(0, 0, 184, 16), UI.STICKY)
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	note.move_child(paper, 0)
	UI.panel(note, Rect2(0, 0, 184, 2), Color("e4c64a"))
	note.move_child(note.get_child(-1), 1)
	UI.sprite(note, "res://assets/desk/curl.png", Vector2(177, 9))


## 新递上来的纸接替上一份的那一层，不往最上面放：玩家放在上面的东西一直在上面。
## 当天第一份（没有上一份）照旧放最上面。
func _insert_doc(paper: Control, after: Control) -> void:
	if is_instance_valid(after) and after.get_parent() == _doc_layer:
		after.add_sibling(paper)
	else:
		_doc_layer.add_child(paper)


func _draw_pile() -> void:
	UI.clear(_pile)
	_count.text = "待处理 %d" % queue.size()
	if GameState.config.hirebot >= 2:
		var yes := queue.filter(func(c: Candidate) -> bool: return c != null and HireBot.label(c) == HireBot.RECOMMEND).size()
		_count.text = "荐 %d 否 %d" % [yes, queue.size() - yes]
	# 牛皮纸档案盒：剩几份就露几层纸边（最多十层）
	var box := AtlasTexture.new()
	box.atlas = FILE_BOX
	box.region = Rect2(mini(queue.size(), 10) * 86, 0, 86, 62)
	var t := TextureRect.new()
	t.texture = box
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pile.add_child(t)


## 左下角的抽屉：点开是俯视图，信封压在最底下，第三个月起放进去的证据一样一样摆着。钟照走。
func _build_drawer() -> void:
	var front := UI.sprite(self, "res://assets/desk/drawer_closed.png", DRAWER_POS)
	front.mouse_filter = Control.MOUSE_FILTER_STOP
	front.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	front.tooltip_text = "抽屉"
	front.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_open_drawer())


func _open_drawer() -> void:
	Sfx.drawer(true)
	var cover := UI.panel(self, Rect2(0, 0, 640, 360), Color(0, 0, 0, 0.55))
	cover.mouse_filter = Control.MOUSE_FILTER_STOP
	var at := Vector2(170, 92)
	UI.sprite(cover, "res://assets/desk/drawer_open.png", at)
	var things := 0
	var envelopes := GameState.kickbacks.filter(func(k: Dictionary) -> bool: return k.taken and k.from != "小刘家")
	# 信封压在最底下，左边一溜，多了就往右错开一点
	var slots := [Vector2(12, 26), Vector2(12, 82), Vector2(36, 54), Vector2(36, 96)]
	for i in envelopes.size():
		var e := UI.sprite(cover, "res://assets/desk/envelope.png", at + slots[i % slots.size()] + Vector2(i / slots.size() * 4, 0))
		UI.label(e, "¥%d" % int(envelopes[i].amount), Vector2(8, 16), Color("5a3a1a"))
		things += 1
	if "mail_19" in GameState.evidence:
		UI.sprite(cover, "res://assets/desk/mail_print.png", at + Vector2(96, 12))
		things += 1
	if "zhou_book" in GameState.evidence:
		var book := UI.sprite(cover, "res://assets/desk/zhou_book.png", at + Vector2(184, 20))
		UI.label(book, "规则", Vector2(18, 11), Color("1e2a44"))
		things += 1
	if "voice_22" in GameState.evidence:
		UI.sprite(cover, "res://assets/desk/usb.png", at + Vector2(116, 104))
		things += 1
	var caption := "抽屉里只有几支没水的笔。" if things == 0 else "抽屉"
	UI.label(cover, caption, at + Vector2(0, -18), UI.TEXT)
	UI.label(cover, "点哪儿都关上", at + Vector2(212, 140), UI.TEXT_DIM)
	cover.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			Sfx.drawer(false)
			cover.queue_free())


func _on_stamped(verdict: String, _at: Vector2) -> void:
	Sfx.stamp(verdict)
	_shake()
	if verdict == "pass":
		_maybe_override("pass", commit.bind("pass", &"", ""))
	elif verdict == "exception":
		_ask_vouch()
	else:
		_open_picker()


func _shake() -> void:
	var tween := create_tween()
	tween.tween_property(self, "position", Vector2(0, 3), 0.03)
	tween.tween_property(self, "position", Vector2.ZERO, 0.08)


## 破格章：一天一次，只盖不合规的。确认框写明违反哪条、代价是什么。
func _ask_vouch() -> void:
	var c := doc.candidate
	if not GameState.can_vouch():
		doc.unstamp()
		_show_toast("今天的破格已经给了 %s" % GameState.stats.exception, UI.YELLOW)
		return
	var result := RuleEngine.evaluate(c)
	if result.pass:
		doc.unstamp()
		_show_toast("这份合规，不用破格，拖进文件夹就行" if RuleEngine.folder_mode else "这份合规，不用破格，盖通过就行", UI.YELLOW)
		return
	var broken: Array = result.failed.map(func(r: Rule) -> String: return r.title_key)
	var when := "下个月第一天" if GameState.day >= GameState.LAST_DAY else "明天 14:00"
	_vouch_confirm = Control.new()
	add_child(_vouch_confirm)
	UI.panel(_vouch_confirm, Rect2(0, 0, 640, 360), Color(0, 0, 0, 0.35)).mouse_filter = Control.MOUSE_FILTER_STOP
	UI.panel(_vouch_confirm, Rect2(160, 96, 320, 160), UI.PAPER, UI.BLACK)
	UI.label(_vouch_confirm, "破格：%s" % c.display_name, Vector2(172, 104), UI.INK)
	var lines := "不合规：%s。\n%s你单独面 TA（补贴 ¥%d）。录用了满试用期：干得好，担保奖 +¥%d；出了事，担保金 −¥%d。\n今天的破格只有这一次。" % ["、".join(PackedStringArray(broken)), when, GameState.SOLO_PAY, GameState.VOUCH_BONUS, GameState.VOUCH_FINE]
	UI.label(_vouch_confirm, lines, Vector2(172, 124), UI.INK_SOFT, 296)
	UI.button(_vouch_confirm, "我签字", Rect2(172, 226, 140, 22), _confirm_vouch)
	UI.button(_vouch_confirm, "算了", Rect2(326, 226, 140, 22), _cancel_vouch)


func _confirm_vouch() -> void:
	_vouch_confirm.queue_free()
	_vouch_confirm = null
	if RuleEngine.folder_mode:
		_open_folder_picker()
		return
	commit("exception", &"", "")


## 按组招的日子，破格的人也得放进一个组：规则管不着了，放哪个组你定，满了的放不进。
func _open_folder_picker() -> void:
	_folder_picker = Control.new()
	add_child(_folder_picker)
	UI.panel(_folder_picker, Rect2(0, 0, 640, 360), Color(0, 0, 0, 0.35)).mouse_filter = Control.MOUSE_FILTER_STOP
	var height := 34.0 + 24.0 * (_folders.size() + 1)
	var top := 180.0 - height / 2.0
	UI.panel(_folder_picker, Rect2(170, top, 300, height), UI.PAPER, UI.BLACK)
	UI.label(_folder_picker, "破格放进哪个组？", Vector2(180, top + 6), UI.INK)
	var y := top + 26.0
	for f in _folders:
		var p := f.posting
		var b := UI.button(_folder_picker, "%s%s　%s　≤%dk　%d/%d" % [p.role + "·" if p.role != "" else "", p.team, "★".repeat(p.workload), p.salary_cap_k, GameState.folder_count(p), p.hc], Rect2(178, y, 284, 22), _vouch_into.bind(p))
		b.disabled = GameState.folder_full(p)
		y += 24.0
	UI.button(_folder_picker, "← 算了，不破格", Rect2(178, y, 284, 22), _cancel_folder_pick)


func _vouch_into(p: JobPosting) -> void:
	_folder_picker.queue_free()
	_folder_picker = null
	_filing = p
	commit("exception", &"", "")


func _cancel_folder_pick() -> void:
	_folder_picker.queue_free()
	_folder_picker = null
	doc.unstamp()
	if closing:
		_finish()


func _build_folders() -> void:
	_folder_row = Control.new()
	_folder_row.position = DeskLayout.pos("folders")
	_folder_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_folder_row)
	var x := 0.0
	for p in RuleEngine.folders():
		var f := TeamFolder.new()
		f.position = Vector2(x, 0)
		_folder_row.add_child(f)
		f.setup(p)
		_folders.append(f)
		x += TeamFolder.SIZE.x + 4.0


func _folder_at(global_point: Vector2) -> TeamFolder:
	for f in _folders:
		if f.contains(global_point):
			return f
	return null


## 拖着简历经过文件夹，那个文件夹亮框。
func _hover_folders(global_point: Vector2) -> void:
	var under := _folder_at(global_point) if doc and not doc.is_stamped else null
	for f in _folders:
		f.set_hot(f == under)


## 简历在文件夹上松手：放进那个组。满了组长退回，扣一点钟；不在文件夹上就照常记位置。
func _drop_on_folder(global_point: Vector2) -> bool:
	for f in _folders:
		f.set_hot(false)
	var f := _folder_at(global_point)
	if f == null or doc == null or doc.is_stamped or closing or arranging or _picker or _vouch_confirm or _folder_picker:
		return false
	var p := f.posting
	if GameState.folder_full(p):
		_spend(FULL_MINUTES)
		_show_toast("%s：满了，退回来。　−%d 分钟" % [p.lead.get("name", p.team), FULL_MINUTES], UI.YELLOW)
		create_tween().tween_property(doc, "position", DeskLayout.pos("resume"), 0.15).set_trans(Tween.TRANS_QUAD)
		return true
	file_into(p)
	return true


## 把这一份放进这个组（修改器也走这里）。
func file_into(p: JobPosting) -> void:
	_filing = p
	doc.stamp("pass", doc.size / 2.0, TeamFolder.short_name(p.team))


func _cancel_vouch() -> void:
	_vouch_confirm.queue_free()
	_vouch_confirm = null
	doc.unstamp()
	if closing:
		_finish()


const TRAY_OFFSET := Vector2(-4, -58)


## 印章托盘：一块深色底，上面写“印章”，破格章、拒绝章默认一上一下摆在里面。
func _build_stamp_tray() -> void:
	_stamp_tray = Control.new()
	_stamp_tray.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stamp_tray.position = DeskLayout.pos("reject_team") + TRAY_OFFSET
	add_child(_stamp_tray)
	UI.panel(_stamp_tray, Rect2(0, 0, 100, 100), UI.DESK_DARK, UI.BLACK).mouse_filter = Control.MOUSE_FILTER_IGNORE
	var title := UI.label(_stamp_tray, "印章", Vector2(0, 1), UI.TEXT_DIM)
	title.size.x = 100
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _add_exception_stamp() -> void:
	_exception_stamp = StampTool.new()
	_exception_stamp.position = DeskLayout.pos("exception_team" if RuleEngine.folder_mode else "exception")
	add_child(_exception_stamp)
	_exception_stamp.setup("exception")
	_stamps["exception"] = _exception_stamp


## 第一次见破格章：主角心里动了一下，从抽屉最底下把章拿出来。钟停着，等玩家点。
func _show_reveal(c: Candidate) -> void:
	_reveal = Control.new()
	add_child(_reveal)
	UI.panel(_reveal, Rect2(0, 0, 640, 360), Color(0, 0, 0, 0.45)).mouse_filter = Control.MOUSE_FILTER_STOP
	var box := UI.panel(_reveal, Rect2(140, 60, 360, 0), UI.BLACK, UI.GREEN_DIM)
	# 两段话都会换行：先入树量高度，再往下排，框跟着长
	var liked := UI.label(_reveal, c.liked_line, Vector2(154, 70), UI.TEXT, 332)
	var y := 70.0 + liked.get_line_count() * (liked.get_line_height() + 1) + 10.0
	var drawer := UI.label(_reveal, "抽屉最底下有个章，入职那天就在，你一直没用过。章上刻着两个字：破格。\n盖了，明天你自己面；人是你保的：干得好有担保奖，出了事你兜着。一天只能盖一次。", Vector2(154, y), UI.TEXT_DIM, 332)
	y += drawer.get_line_count() * (drawer.get_line_height() + 1) + 8.0
	UI.button(_reveal, "拿出来", Rect2(390, y, 96, 20), _take_out_stamp)
	box.size.y = y + 28.0 - 60.0
	Sfx.paper()


func _take_out_stamp() -> void:
	_reveal.queue_free()
	_reveal = null
	_add_exception_stamp()
	var home := _exception_stamp.position
	_exception_stamp.position = Vector2(home.x, 380)
	create_tween().tween_property(_exception_stamp, "position", home, 0.25).set_trans(Tween.TRANS_QUAD)
	_show_toast("破格章：拖到简历上", UI.YELLOW)


## 拒绝时必须选一条理由，这句话写进决策日志，终章原样回到玩家身上。
func _open_picker() -> void:
	_picker = Control.new()
	add_child(_picker)
	_picker.size = size
	UI.panel(_picker, Rect2(0, 0, 640, 360), Color(0, 0, 0, 0.35)).mouse_filter = Control.MOUSE_FILTER_STOP
	# 不进手册的口头规则没有自己的那句拒绝理由
	var rules := RuleEngine.active_rules.filter(func(r: Rule) -> bool: return not r.hidden)
	var mismatch := 0 if flagged.is_empty() else 1
	var height := 28.0 + 24.0 * (rules.size() + 2 + mismatch)
	var top := 180.0 - height / 2.0
	UI.panel(_picker, Rect2(150, top, 340, height), UI.PAPER, UI.BLACK)
	UI.label(_picker, "选择拒绝理由（将发送给候选人）", Vector2(160, top + 6), UI.INK)
	var y := top + 24.0
	# 质询标出过矛盾才有这一条，排第一：刚抓到的就是它
	if mismatch:
		UI.button(_picker, MISMATCH_REASON, Rect2(158, y, 324, 22), _pick_reason.bind(&"mismatch", MISMATCH_REASON))
		y += 24.0
	for rule in rules:
		UI.button(_picker, rule.reject_reason_key, Rect2(158, y, 324, 22), _pick_reason.bind(rule.id, rule.reject_reason_key))
		y += 24.0
	UI.button(_picker, GENERIC_REASON, Rect2(158, y, 324, 22), _pick_reason.bind(&"generic", GENERIC_REASON))
	y += 24.0
	UI.button(_picker, "← 返回，再看看", Rect2(158, y, 324, 22), _cancel_reject)


func _pick_reason(rule_id: StringName, text: String) -> void:
	if _picker:
		_picker.queue_free()
		_picker = null
	_maybe_override("reject", commit.bind("reject", rule_id, text))


## HireBot 预筛的日子，跟它不一样要写一句理由（扣 OVERRIDE_MINUTES）；一样就直接盖。
func _maybe_override(verdict: String, then: Callable) -> void:
	if GameState.config.hirebot < 2 or doc == null or (HireBot.label(doc.candidate) == HireBot.RECOMMEND) == (verdict == "pass"):
		then.call()
		return
	_override = Control.new()
	add_child(_override)
	UI.panel(_override, Rect2(0, 0, 640, 360), Color(0, 0, 0, 0.35)).mouse_filter = Control.MOUSE_FILTER_STOP
	var height := 34.0 + 24.0 * (OVERRIDE_REASONS.size() + 1)
	var top := 180.0 - height / 2.0
	UI.panel(_override, Rect2(150, top, 340, height), UI.PAPER, UI.BLACK)
	UI.label(_override, "推翻 HireBot（%s）：写一句理由，抄送王总" % ("它不推荐" if verdict == "pass" else "它推荐"), Vector2(160, top + 6), UI.INK)
	var y := top + 26.0
	for reason: String in OVERRIDE_REASONS:
		UI.button(_override, reason + "　−%d 分钟" % OVERRIDE_MINUTES, Rect2(158, y, 324, 22), func() -> void:
			_override.queue_free()
			_override = null
			GameState.stats.overrides.append({"name": doc.candidate.display_name, "reason": reason})
			_spend(OVERRIDE_MINUTES)
			then.call())
		y += 24.0
	UI.button(_override, "← 算了，跟它一样", Rect2(158, y, 324, 22), func() -> void:
		_override.queue_free()
		_override = null
		doc.unstamp()
		if closing:
			_finish())


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
	var why := ""
	var folder := _filing if verdict != "reject" else null
	_filing = null
	if verdict == "exception":
		GameState.record_exception(doc.candidate, folder)
	else:
		why = GameState.record_decision(doc.candidate, verdict, reason_rule, reason_text, extra, folder)
	GameState.record_pace(_minutes_now())
	for f in _folders:
		f.refresh()
	if why != "":
		_print_slip(doc.candidate.display_name, why)
	_reset_inspect()
	_done_count += 1
	_hint.text = "已处理 %d" % _done_count if GameState.quota_today() <= 0 else "已处理 %d / 人效 %d" % [_done_count, GameState.quota_today()]
	var away := Vector2(400, 330)
	for f in _folders:
		if folder and f.posting == folder:
			away = f.global_position + Vector2(10, -20)
	for leaving: Control in [doc, id_card, _envelope]:
		if leaving:
			var tween := create_tween()
			tween.tween_property(leaving, "position", away, 0.18).set_trans(Tween.TRANS_QUAD)
			tween.tween_callback(leaving.queue_free)
	_last_doc = doc
	_last_id = id_card
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
	if _picker or _vouch_confirm or _folder_picker or _override:
		return  # 等玩家选完理由、签完字、选完组
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
	_close_intake()
	if _intake_button:
		_intake_button.disabled = true
	GameState.stats.intake_left = _intake.map(func(c: Dictionary) -> String: return c.display_name)
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
	# 砍减版：有离职谈话的日子普通人不面（GameState.skip_plain_interview）
	var plain_interview := not GameState.interviewees.is_empty() and not GameState.skip_plain_interview()
	var interview := plain_interview or not GameState.vouched.is_empty()
	if GameState.config.team_folders and not GameState.interviewees.is_empty():
		GameState.plan_sessions()
	var note := ("15:00，该去面试了。今天两场。" if InterviewRoom.second_candidate() else "15:00，该去面试了。") if interview else "15:00。今天没有面试，你整理材料到六点下班。"
	if GameState.config.team_folders and not GameState.sessions.is_empty():
		var names := PackedStringArray(GameState.sessions.map(func(c: Candidate) -> String:
			var t := GameState.team_posting(c)
			return t.lead.get("name", "赵主管") if t else "赵主管"))
		note = "15:00 面试，今天 %d 场：%s。面完才下班。" % [names.size(), "、".join(names)]
	if not GameState.vouched.is_empty():
		var later := note
		note = "14:00，先去面你破格的 %s。" % GameState.vouched[0].display_name
		if GameState.config.team_folders and not GameState.sessions.is_empty():
			note += later
		elif plain_interview:
			note += "15:00 还有%s那场。" % GameState.config.interviewer.get("name", "赵主管")
	if not GameState.config.exit_talks.is_empty() and GameState.next_talk_index() >= 0:
		note += "面试之后，傍晚还有离职谈话。" if interview else "傍晚还有离职谈话，谈完才下班。"
		interview = true
	if not queue.is_empty():
		note += "还有 %d 份简历没看，计件没了。" % queue.size()
	if GameState.stats.left_early:
		note = "你提前下班了。" + ("" if queue.is_empty() else "还有 %d 份简历没看。" % queue.size())
	UI.panel(self, Rect2(170, 132, 300, 100), UI.BLACK, UI.GREEN_DIM)
	UI.label(self, note, Vector2(182, 140), UI.GREEN, 276)
	UI.button(self, ("去面试" if plain_interview or not GameState.vouched.is_empty() else "去谈话") if interview and not GameState.stats.left_early else "继续", Rect2(280, 204, 80, 20), finished.emit)


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
	var paper := UI.panel(slip, Rect2(0, 0, slip.size.x, 0), UI.PAPER_SLIP)
	# 针式连续纸：两边齿孔、淡绿横条，等量出多长再铺
	var feed_marks := Control.new()
	feed_marks.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slip.add_child(feed_marks)
	UI.label(slip, "违规通知 #%d" % n if fined else "违规通知", Vector2(10, 1), UI.RED)
	# 先放进一个临时容器入树，换行宽度才生效，好量出单子多长
	add_child(slip)
	var y := 20.0
	for line: Array in [
		[who, UI.INK],
		[why, UI.INK],
		[_slip_cost(fined, n), UI.RED if fined and n > GameState.FREE_WARNINGS else UI.INK_SOFT],
	]:
		var l := UI.label(slip, line[0], Vector2(10, y), line[1], slip.size.x - 20)
		y += l.get_line_count() * (l.get_line_height() + 1) + 4
	slip.size.y = y + 2
	shadow.size.y = slip.size.y
	paper.size.y = slip.size.y
	for band in range(6, int(slip.size.y), 12):
		UI.panel(feed_marks, Rect2(8, band, slip.size.x - 16, mini(6, int(slip.size.y) - band)), Color("d8e6d0"))
	for hole in range(3, int(slip.size.y) - 3, 6):
		UI.panel(feed_marks, Rect2(2, hole, 3, 3), Color("3a403c"))
		UI.panel(feed_marks, Rect2(slip.size.x - 5, hole, 3, 3), Color("3a403c"))
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


func _minutes_now() -> int:
	return mini(int(DAY_START + elapsed / _seconds_per_minute()), day_end)


## 桌上弹出来的事：到点了、条件对上了，钟停着，选一项再接着干。一次只弹一件。
func _check_memos(minutes: int) -> void:
	var memos: Array = GameState.config.desk_memos
	while _memos_done < memos.size() and minutes >= int(memos[_memos_done].get("at", 480)):
		var memo: Dictionary = memos[_memos_done]
		_memos_done += 1
		if GameState.family.has(memo.id) or not GameState.family_matches(memo.get("when", "")):
			continue
		_show_memo(memo)
		return


func _show_memo(memo: Dictionary) -> void:
	_close_bubble()
	_close_inbox()
	_memo = Control.new()
	add_child(_memo)
	UI.panel(_memo, Rect2(0, 0, 640, 360), Color(0, 0, 0, 0.45)).mouse_filter = Control.MOUSE_FILTER_STOP
	var printed: bool = memo.get("printed", false)
	var box := UI.panel(_memo, Rect2(130, 30, 380, 0), Color.WHITE.darkened(0.08) if printed else UI.PAPER, UI.BLACK)
	UI.label(_memo, memo.get("title", ""), Vector2(142, 38), UI.RED if memo.get("alarm", false) else UI.INK)
	var body := UI.label(_memo, memo.text, Vector2(142, 58), UI.INK, 356)
	var y := 58.0 + body.get_line_count() * (body.get_line_height() + 1) + 10.0
	var options: Array = memo.options.filter(func(o: Dictionary) -> bool: return GameState.family_matches(o.get("when", "")))
	var buttons: Array[Button] = []
	for option: Dictionary in options:
		var b := UI.text_button(_memo, option.label, Rect2(142, y, 356, 22), func() -> void: _answer_memo(memo, option, buttons, box))
		buttons.append(b)
		y += b.size.y + 4.0
	box.size.y = y + 6.0 - 30.0
	Sfx.paper()


func _answer_memo(memo: Dictionary, option: Dictionary, buttons: Array[Button], box: Panel) -> void:
	for b in buttons:
		b.queue_free()
	GameState.family[memo.id] = option.key
	GameState.apply_effects(option.get("effects", {}))
	_spend(int(option.get("minutes", 0)))
	Sfx.stamp()
	var y := buttons[0].position.y if not buttons.is_empty() else box.position.y + box.size.y
	var reply: String = option.get("reply", "")
	var said := UI.label(_memo, "你：" + option.label if reply == "" else reply, Vector2(142, y), UI.INK_SOFT, 356)
	y += said.get_line_count() * (said.get_line_height() + 1) + 8.0
	UI.button(_memo, "接着干活", Rect2(398, y, 100, 20), func() -> void:
		_memo.queue_free()
		_memo = null)
	box.size.y = y + 28.0 - box.position.y


## 桌上的钟往前拨：DAY_START–DAY_END 对应 screening_seconds 真实秒数。
func _spend(minutes: int) -> void:
	elapsed += minutes * _seconds_per_minute()


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


## 入职手续：一叠登记表，点开一张核对签字。钟照走。
func _refresh_intake() -> void:
	_intake_button.text = "入职手续 %d" % _intake.size()
	_intake_button.visible = not _intake.is_empty()


func _open_intake() -> void:
	if closing or arranging or _intake.is_empty() or _intake_form or _picker or _vouch_confirm or _leave_confirm:
		return
	var c: Dictionary = _intake[0]
	_intake_form = Control.new()
	add_child(_intake_form)
	UI.panel(_intake_form, Rect2(0, 0, 640, 360), Color(0, 0, 0, 0.35)).mouse_filter = Control.MOUSE_FILTER_STOP
	var box := UI.panel(_intake_form, Rect2(160, 40, 320, 0), UI.PAPER, UI.BLACK)
	UI.label(_intake_form, "入职登记表", Vector2(172, 48), UI.INK)
	var body := UI.label(_intake_form, "姓名：%s\n岗位：%s\n□ 身份证复印件　□ 学历证明\n□ 离职证明　　　□ 银行卡、社保\n□ 劳动合同两份\n（老周以前办这个。）" % [c.display_name, c.get("applied_position", "")], Vector2(172, 68), UI.INK_SOFT, 296)
	var y := 68.0 + body.get_line_count() * (body.get_line_height() + 1) + 8.0
	UI.button(_intake_form, "核对签字（%d 分钟）" % INTAKE_MINUTES, Rect2(172, y, 150, 20), _sign_intake)
	UI.button(_intake_form, "先放着", Rect2(330, y, 138, 20), _close_intake)
	box.size.y = y + 28.0 - 40.0
	Sfx.paper()


func _sign_intake() -> void:
	if _intake.is_empty():
		return
	_intake.pop_front()
	_spend(INTAKE_MINUTES)
	Sfx.stamp()
	_show_toast("签好一份入职　−%d 分钟" % INTAKE_MINUTES, UI.TEXT)
	_close_intake()
	_refresh_intake()


func _close_intake() -> void:
	if _intake_form:
		_intake_form.queue_free()
		_intake_form = null
## 赵主管早上贴在桌角的便签：今天筛的人里，他明天想见什么样的。
## 桌角窄，便签上只写一句要点（need.short）；点一下摊开整张，再点收起。
func _build_chief_note() -> void:
	var need: Dictionary = GameState.config.chief_need
	# 第二个月起赵主管不提前贴，面试开场才拍便签（InterviewRoom）
	if need.is_empty() or not GameState.config.interviewer.is_empty() or GameState.month() > 1:
		return
	_chief_note = Control.new()
	_chief_note.position = DeskLayout.pos("chief")
	_chief_note.size = DeskLayout.size_of("chief")
	add_child(_chief_note)
	for node: Control in [
		UI.panel(_chief_note, Rect2(Vector2(2, 2), _chief_note.size), Color(0, 0, 0, 0.3)),
		UI.panel(_chief_note, Rect2(Vector2.ZERO, _chief_note.size), UI.STICKY),
		UI.label(_chief_note, "赵主管要：", Vector2(4, 1), UI.INK_SOFT),
		UI.label(_chief_note, String(need.get("short", need.note)), Vector2(4, 17), UI.INK, _chief_note.size.x - 8),
	]:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	DeskDrag.attach(_chief_note, "chief", _toggle_chief_note)


func _toggle_chief_note() -> void:
	if _chief_open:
		_chief_open.queue_free()
		_chief_open = null
		return
	var need: Dictionary = GameState.config.chief_need
	_chief_open = UI.panel(self, Rect2(_chief_note.position + Vector2(_chief_note.size.x + 4, -24), Vector2(220, 0)), UI.STICKY, UI.BLACK)
	_chief_open.rotation = -0.02
	# 两段都会折行：先入树量高度，再往下排，纸跟着长
	var note := UI.label(_chief_open, "赵主管：" + String(need.note), Vector2(8, 6), UI.INK, 204)
	var y := 6.0 + note.get_line_count() * (note.get_line_height() + 1) + 6.0
	var tip := UI.label(_chief_open, "明天面试录了对得上的人，推荐奖 ¥%d。对不对得上，看简历第二页。" % int(GameState.pay.get("chief_bonus", 0)), Vector2(8, y), UI.INK_SOFT, 204)
	_chief_open.size.y = y + tip.get_line_count() * (tip.get_line_height() + 1) + 8.0
	_chief_open.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			_toggle_chief_note())


func _can_inspect() -> bool:
	return "id_card" in RuleEngine.active_docs and not RuleEngine.active_discrepancies.is_empty()


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
	# 意外支出（Surprises）：到点从手机上来，和别的消息一样一次只响一条
	var sur := GameState.surprise_today
	if not sur.is_empty() and minutes >= int(sur.at) and not GameState.stats.texts.any(func(e: Dictionary) -> bool: return e.get("id", "") == sur.id):
		GameState.receive_text(sur)
		_unread.visible = true
		_ring(sur.text, false)
		return
	# 前两天赌一把的后账：到点揭晓（钱下班时自动从工资卡转）
	for r: Dictionary in GameState.reveal_today:
		if minutes >= int(r.at) and not GameState.stats.texts.any(func(e: Dictionary) -> bool: return e.get("id", "") == r.id):
			GameState.receive_text(r)
			_unread.visible = true
			_ring(r.text, false)
			return
	while _texts_sent < cfg.desk_texts.size() and minutes >= int(cfg.desk_texts[_texts_sent].at):
		var entry: Dictionary = cfg.desk_texts[_texts_sent]
		_texts_sent += 1
		var id: String = entry.get("id", "")
		var taken: bool = id != "" and GameState.stats.texts.any(func(e: Dictionary) -> bool: return e.get("id", "") == id)
		if taken or not GameState.family_matches(entry.get("when", "")):
			continue
		if "{done}" in entry.text:
			entry = entry.duplicate()
			entry.text = entry.text.replace("{done}", str(GameState.stats.processed))
		GameState.receive_text(entry)
		_unread.visible = true
		_ring(entry.text, false)
		return  # 一次只响一条
	if not _called and not cfg.midday_call.is_empty() and minutes >= int(cfg.midday_call.at):
		_called = true
		GameState.stats.called = true
		GameState.receive_text({"at": cfg.midday_call.at, "text": cfg.midday_call.text, "call": true})
		_ring(cfg.midday_call.text, true)


## 猎头的转账：record_decision 或早上的留任结算挂上去的，第一次看到时记下几点到的、手机震一下。
func _check_transfers(minutes: int) -> void:
	for t: Dictionary in GameState.stats.transfers:
		if t.has("at"):
			continue
		t.at = minutes
		_unread.visible = true
		_ring("%s：[转账] ¥%d %s" % [t.from, t.amount, t.note], false)
		return


## 手机震、亮屏、旁边弹一条消息。预览几秒后自己消失；来电要点“知道了”，之后桌上多一个“提前下班”。
## 手机开着的时候不弹，直接刷新屏幕。
func _ring(text: String, is_call: bool) -> void:
	Sfx.buzz()
	if _inbox_panel and not is_call:
		_inbox_panel.clock = _clock.text
		_inbox_panel.refresh()
		return
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
	# 框跟着字撑高：正文几行就多高，底下一行放“点手机回复”或“知道了”，不压字
	var frame := UI.panel(_bubble, Rect2(0, 0, 210, 40), UI.BLACK, UI.GREEN_DIM)
	var body := UI.label(_bubble, ("来电" if is_call else "消息") + "　" + text, Vector2(6, 4), UI.TEXT, 198)
	var text_bottom := 4.0 + body.get_line_count() * (body.get_line_height() + 1)
	if is_call:
		UI.button(_bubble, "知道了", Rect2(150, text_bottom + 4, 54, 18), _hang_up_home)
		frame.size.y = text_bottom + 26
	else:
		UI.label(_bubble, "点手机回复", Vector2(142, text_bottom), UI.GREEN_DIM)
		frame.size.y = text_bottom + 18
	# 高了以后底边别出屏幕
	_bubble.position.y = minf(_bubble.position.y, 360.0 - frame.size.y)
	if not is_call:
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
	_inbox_panel = PhoneChat.new()
	_inbox_panel.position = INBOX_POS
	_inbox_panel.clock = _clock.text
	_inbox_panel.seen = _seen
	_inbox_panel.replied.connect(_reply)
	_inbox_panel.transfer_answered.connect(_answer_transfer)
	_inbox_panel.closed.connect(_close_inbox)
	add_child(_inbox_panel)
	_unread.visible = false


## 回一条：打字要花几分钟，钟照走。带 transfer 的是从零钱转过去。
func _reply(entry: Dictionary, option: Dictionary) -> void:
	if closing or GameState.text_replied(entry.id):
		return
	GameState.reply_text(entry, option)
	_spend(GameState.REPLY_MINUTES)
	Sfx.key()
	var who: String = entry.get("from", "老婆")
	if option.has("transfer"):
		_show_toast("转给%s ¥%d　−%d 分钟" % [who, option.transfer, GameState.REPLY_MINUTES], UI.YELLOW)
	else:
		_show_toast("回了%s　−%d 分钟" % [who, GameState.REPLY_MINUTES], UI.TEXT)
	_inbox_panel.clock = _clock.text
	_inbox_panel.refresh()


## 收款 / 退还：点一下的事，不花时间。
func _answer_transfer(t: Dictionary, taken: bool) -> void:
	if closing:
		return
	GameState.answer_transfer(t, taken)
	Sfx.key()
	_show_toast("收下 ¥%d" % t.amount if taken else "退还了 ¥%d" % t.amount, UI.YELLOW if taken else UI.TEXT)
	_inbox_panel.refresh()


func _close_inbox() -> void:
	if _inbox_panel:
		_inbox_panel.queue_free()
		_inbox_panel = null


## 走之前说清楚丢的是什么：剩下的简历没计件，今天的面试取消。
func _ask_leave() -> void:
	if closing or _leave_confirm or _picker or _vouch_confirm or _reveal:
		return
	var left := queue.size() + (1 if doc else 0)
	var lines := "剩下 %d 份简历今天不看了，计件没了。" % left
	if not GameState.interviewees.is_empty() or not GameState.vouched.is_empty():
		lines += "\n今天的面试也取消。" + ("（包括你破格的那位。）" if not GameState.vouched.is_empty() else "")
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
	if closing or arranging or _picker or _leave_confirm or _reveal or _vouch_confirm or _folder_picker or _intake_form or _override or _memo:
		return
	arranging = true
	_close_bubble()
	_close_inbox()
	_hang_up()
	var keys := ["resume", "rulebook", "photo", "phone"]
	keys.append_array(["folders", "reject_team"] if RuleEngine.folder_mode else ["pass", "reject"])
	if _exception_stamp:
		keys.append("exception_team" if RuleEngine.folder_mode else "exception")
	if _posting:
		keys.append("posting")
	if "id_card" in RuleEngine.active_docs:
		keys.append("id_card")
	if _inspect_button:
		keys.append("inspect")
	if _chief_note:
		keys.append("chief")
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
		"pass", "reject", "exception":
			_stamps[key].position = at
		"reject_team":
			_stamps["reject"].position = at
			_stamp_tray.position = at + TRAY_OFFSET
		"exception_team":
			_stamps["exception"].position = at
		"folders":
			_folder_row.position = at
		"chief":
			_chief_note.position = at
		"inspect":
			_inspect_button.position = at
			_call_button.position = at + Vector2(0, 26)
