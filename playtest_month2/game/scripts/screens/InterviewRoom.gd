class_name InterviewRoom extends Control
## 面试：HR 与赵主管共同面试，一共问 5 个问题。主管在随机的时候插进来抢走 1–2 问，
## 问什么从他到今天为止的问题里随机抽；玩家问卡时他当场改评分表。候选人反问后填老板评分表，决定是否录用。
## 实习生和社招各有一套问题卡：实习生问的是 TA 知不知道来干什么、项目里做了什么、能来多久。
## 在读研究生多问 2 问，还多一套问题卡：导师放不放人、读不读博、研究方向和岗位的关系。
## 每个回答刚说完可以追问一次（占一问）：背的接不上，说实话的越说越具体，露破绽的越问越慌。
## 招程序员（第 8 天）起，主管抢的第一问总是一道尖锐题（DayConfig.chief_sharp），玩家手里也混着尖锐题卡。
## 当天没有剧情候选人进面试，抽中的普通人可能是个奇葩（DayConfig.quirk）：简历正常，一开口才知道。
## 剧情候选人进了面试、今天又有奇葩，就面两场：剧情候选人 15:00–16:30，奇葩 16:30–18:00。
## 第 3 天起主管开场拍一张便签（DayConfig.chief_need），录用的人在他自己心里那一项够了，发主管推荐奖。
##
## 画面学《Papers, Please》：上半屏是对面坐着的人，下半屏是桌面。
## 问题卡不再一次全摊开：洗成牌堆，手里只有 3 张，问掉一张补一张。把卡拖到候选人身上就是问。
## 每一问自动打进左边的面试笔录，问过什么、TA 怎么答的都留在纸上。

signal finished

const QUESTION_PATHS := [
	"q_overtime", "q_weakness", "q_leaving", "q_future", "q_gap", "q_test",
	"q_family", "q_friday", "q_company", "q_probation",
	"q_intern_role", "q_project", "q_our_app", "q_data_test", "q_chores", "q_schedule", "q_return_offer",
	"q_grad_advisor", "q_grad_phd", "q_grad_why_ops", "q_grad_research",
	"q_tech_depth", "q_code_review", "q_oncall",
	"q_sharp_slow_sql", "q_sharp_cache", "q_sharp_banyan", "q_sharp_numbers", "q_sharp_incident", "q_sharp_whiteboard",
]
# q_ai_tool（用不用 AI 编程助手）留着给下个月：第二个月 AI 只在新闻里出现。
## 含主管抢走的那几问。
const QUESTIONS_ALLOWED := 5
const GRAD_QUESTIONS_ALLOWED := 7
## 手里同时拿几张卡。
const HAND_SIZE := 3
## 主管抢几问；第一问总是玩家开场。
const CHIEF_ASKS_MIN := 1
const CHIEF_ASKS_MAX := 2
const CHIEF_CUT_IN_LINES := ["等一下，我问一句。", "我插一句。", "这个我来问。", "你先停一下。"]
const SCORE_ITEMS := ["狼性", "格局", "稳定性", "颜值"]
const CHIEF_SEED := 4101
const LIE_LOYALTY_HIT := 25
const SAFE_LOYALTY_HIT := 10
## 有能力的人有退路，听到实话就走；走不了的才留下。
const WALK_OUT_ABILITY := 60
## 主管印象（只记他自己加减的分，评分表玩家能改、这个改不了）够到多少算“他要的人”。
const CHIEF_PICK_MARK := 1

## 画面分区：墙（候选人、对话）在上，桌面在下。
const DESK_TOP := 196.0
const SPEECH_RECT := Rect2(196, 26, 432, 116)
const ACTION_POS := Vector2(196, 148)
const DROP_RECT := Rect2(0, 18, 640, DESK_TOP - 18)
const PORTRAIT_POS := Vector2(40, 40)
const TRANSCRIPT_RECT := Rect2(8, 204, 158, 150)
const HAND_POS := Vector2(176, 222)
const CHIEF_RECT := Rect2(496, 204, 136, 150)
## 反问、评分表这些收尾的纸，盖在手牌那一块桌面上。
const END_X := 176.0
const END_WIDTH := 312.0

var candidate: Candidate
## 洗好的牌堆和手牌；卡从牌堆抽到手里，问掉就没了。
var deck: Array[QuestionCard] = []
var hand: Array[QuestionCard] = []
var asked := 0
var questions_allowed := QUESTIONS_ALLOWED
## 问到第几问之后主管插进来（asked 的值），以及他要问的卡，按顺序一一对应。
var chief_slots: Array[int] = []
var chief_cards: Array[QuestionCard] = []
var _rng := RandomNumberGenerator.new()
var _chief_asked := 0
var scorecard := {}
## 主管自己当场加减的分，-2..+2；评分表上的数是 3 加它，玩家改评分表动不了这里。
var chief_marks := {}
## 刚说完的那一问，可以追问：{card, reply, by_chief}；空表示没得追问。
var _last := {}
var _followups := 0
var _promise := ""
var _loyalty_hit := 0
## 笔录：每一问一条 {who, question, reply}。
var transcript: Array[Dictionary] = []
var _portrait: PortraitView
var _speech: Label
var _chief_line: Label
## 主管刚在评分表上动了哪一项，写在他名字旁边。
var _chief_mark: Label
var _header: Label
var _quota: Control
## 对话框下面那一行：追问、主管插话。
var _action: Control
var _hand_view: Control
var _deck_label: Label
var _hand_hint: Label
var _drop_frame: Panel
var _transcript_list: VBoxContainer
var _transcript_scroll: ScrollContainer
## 收尾阶段（反问、评分表）盖在桌上的纸。
var _side: Control
var _hand_open := false
## 15:00 开始面试，18:00 下班：问题按份平分 15:00–17:30，候选人反问和填评分表占最后半小时。
## 两场的日子各占一个半小时，每场的反问和评分表压到最后十五分钟。
const START_MINUTES := 15 * 60
const QUESTIONS_END := 17 * 60 + 30
const SLOT_MINUTES := 90
## 这一场是今天第几场（0 起），以及这一场的钟：开场、问完、填表。
var slot := 0
var _start := START_MINUTES
var _questions_end := QUESTIONS_END
var _scorecard_at := 17 * 60 + 45


func _ready() -> void:
	slot = GameState.interviewed_today.size()
	candidate = pick_candidate()
	GameState.interviewed_today.append(candidate.display_name)
	if slot > 0 or second_candidate():
		_start = START_MINUTES + slot * SLOT_MINUTES
		_scorecard_at = _start + SLOT_MINUTES - 8
		_questions_end = _scorecard_at - 7
	if candidate.is_grad():
		questions_allowed = GRAD_QUESTIONS_ALLOWED
	for item in SCORE_ITEMS:
		scorecard[item] = 3
		chief_marks[item] = 0
	_plan_chief()
	_build_deck()
	_build_wall()
	_build_desk()
	_tick(_start)
	_draw_hand()
	_show_hand()


## 能问的卡洗成牌堆，种子跟着这一天走：读档重来，手里还是那几张。
func _build_deck() -> void:
	for path in QUESTION_PATHS:
		var card: QuestionCard = load("res://data/questions/%s.tres" % path)
		if card.available_for(candidate):
			deck.append(card)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([GameState.day_seed(), "deck", candidate.display_name])
	for i in range(deck.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t := deck[i]
		deck[i] = deck[j]
		deck[j] = t


func _build_wall() -> void:
	UI.panel(self, Rect2(0, 0, 640, DESK_TOP), UI.WALL)
	UI.panel(self, Rect2(0, 0, 640, 18), UI.DESK_DARK)
	_header = UI.label(self, "", Vector2(10, 2), UI.GREEN)
	UI.label(self, "问题", Vector2(518, 2), UI.TEXT_DIM)
	_quota = Control.new()
	_quota.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_quota)
	_drop_frame = UI.panel(self, Rect2(PORTRAIT_POS - Vector2(6, 6), Vector2(140, 140)), Color.TRANSPARENT, UI.GREEN)
	(_drop_frame.get_theme_stylebox("panel") as StyleBoxFlat).set_border_width_all(2)
	_drop_frame.visible = false
	_portrait = PortraitView.new()
	_portrait.setup(candidate.portrait_seed, 2)
	_portrait.position = PORTRAIT_POS
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_portrait)
	UI.panel(self, SPEECH_RECT, UI.PAPER, UI.BLACK)
	var opening := candidate.entrance if candidate.entrance != "" else "（%s 坐下，等你提问。）" % candidate.display_name
	_speech = UI.label(self, opening, SPEECH_RECT.position + Vector2(10, 8), UI.INK, SPEECH_RECT.size.x - 20)
	_action = Control.new()
	_action.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_action)
	# 整面墙都是落点：卡拖到上半屏就算递给候选人
	var drop := Control.new()
	drop.position = DROP_RECT.position
	drop.size = DROP_RECT.size
	drop.mouse_filter = Control.MOUSE_FILTER_PASS
	drop.set_drag_forwarding(Callable(), _can_drop_card, _drop_card)
	add_child(drop)
	move_child(drop, 1)


func _build_desk() -> void:
	UI.panel(self, Rect2(0, DESK_TOP, 640, 360 - DESK_TOP), UI.DESK)
	UI.panel(self, Rect2(0, DESK_TOP, 640, 3), UI.DESK_DARK)
	_build_transcript()
	_hand_hint = UI.label(self, "", Vector2(HAND_POS.x, 203), UI.TEXT_DIM)
	_hand_view = Control.new()
	_hand_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hand_view)
	UI.panel(self, Rect2(HAND_POS.x, 322, 92, 32), UI.DESK_DARK, Color("46524d"))
	UI.panel(self, Rect2(HAND_POS.x + 3, 319, 92, 32), Color("3a4440"), Color("56605b"))
	_deck_label = UI.label(self, "", Vector2(HAND_POS.x + 10, 327), UI.TEXT_DIM)
	_build_need_note()
	_build_chief()
	_side = Control.new()
	_side.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_side)


## 左边一张打印纸：每问一句自动打一行。
func _build_transcript() -> void:
	var r := TRANSCRIPT_RECT
	UI.panel(self, r, Color("e2e5df"), UI.BLACK)
	UI.label(self, "面试笔录 · %s" % candidate.display_name, r.position + Vector2(6, 3), UI.INK)
	UI.panel(self, Rect2(r.position + Vector2(6, 19), Vector2(r.size.x - 12, 1)), UI.INK_SOFT)
	_transcript_scroll = ScrollContainer.new()
	_transcript_scroll.position = r.position + Vector2(6, 23)
	_transcript_scroll.size = r.size - Vector2(8, 26)
	_transcript_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_transcript_scroll)
	_transcript_list = VBoxContainer.new()
	_transcript_list.custom_minimum_size.x = r.size.x - 20
	_transcript_list.add_theme_constant_override("separation", 4)
	_transcript_scroll.add_child(_transcript_list)
	var empty := UI.label(_transcript_list, "（还没问。）", Vector2.ZERO, UI.INK_SOFT)
	empty.name = "Empty"


func _build_chief() -> void:
	var r := CHIEF_RECT
	UI.panel(self, r, UI.PAPER_DIM, UI.BLACK)
	var chief := PortraitView.new()
	chief.setup(CHIEF_SEED)
	chief.position = r.position + Vector2(1, 1)
	add_child(chief)
	UI.label(self, "赵主管", r.position + Vector2(70, 4), UI.INK_SOFT)
	UI.label(self, "创始员工", r.position + Vector2(70, 20), UI.INK_SOFT)
	_chief_mark = UI.label(self, "", r.position + Vector2(70, 44), UI.INK)
	var opener := GameState.config.chief_opener if slot == 0 else "下一个。抓紧，六点我还有会。"
	_chief_line = UI.label(self, "“%s”" % opener, r.position + Vector2(6, 70), UI.INK, r.size.x - 12)


## 主管开场拍在桌上的便签：今天他要什么样的人。
func _build_need_note() -> void:
	var need := chief_need()
	if need.is_empty():
		return
	UI.panel(self, Rect2(HAND_POS.x + 104, 320, 210, 34), UI.YELLOW, UI.BLACK)
	UI.label(self, "主管便签：%s" % need.note, Vector2(HAND_POS.x + 110, 323), UI.INK, 198)


func chief_need() -> Dictionary:
	return GameState.config.chief_need


## 他要的那一项，他自己心里够了没有。
func is_chief_pick() -> bool:
	var need := chief_need()
	return not need.is_empty() and int(chief_marks.get(need.item, 0)) >= CHIEF_PICK_MARK


## 第一场优先剧情候选人，否则从昨天通过的人里随机抽，今天有奇葩就是这个人；第二场就是奇葩。
func pick_candidate() -> Candidate:
	if slot > 0:
		return second_candidate()
	for c in GameState.interviewees:
		if c.is_story:
			return c
	return _plain_pick()


## 第二场的人：第一场是剧情候选人、今天有奇葩、昨天还过了别的普通人才有，否则 null。
static func second_candidate() -> Candidate:
	if GameState.config.quirk == null:
		return null
	if not GameState.interviewees.any(func(c: Candidate) -> bool: return c.is_story):
		return null
	return _plain_pick()


## 从昨天通过的普通人里抽一个，种子跟着这一天走；今天有奇葩就套上。没有普通人返回 null。
static func _plain_pick() -> Candidate:
	var plain := GameState.interviewees.filter(func(c: Candidate) -> bool: return not c.is_story)
	if plain.is_empty():
		return null
	var rng := RandomNumberGenerator.new()
	rng.seed = GameState.day_seed()
	var c: Candidate = plain[rng.randi_range(0, plain.size() - 1)]
	var quirk := GameState.config.quirk
	if quirk and c.quirk == &"":
		quirk.apply(c)
	return c


## 种子跟着这一局和这一天走：读档重来同一天，主管还是那样插话。
func _plan_chief() -> void:
	_rng.seed = hash([GameState.day_seed(), "chief", slot])
	var pool: Array[QuestionCard] = []
	var sharp: Array[QuestionCard] = []
	for d in range(1, GameState.day + 1):
		var cfg := RuleEngine.load_day(d)
		var card := cfg.chief_question
		if card and card not in pool and card.available_for(candidate):
			pool.append(card)
		card = cfg.chief_sharp
		if card and card not in sharp and card.available_for(candidate):
			sharp.append(card)
	var slots := range(1, questions_allowed)
	var count := mini(_rng.randi_range(CHIEF_ASKS_MIN, CHIEF_ASKS_MAX), pool.size() + sharp.size())
	for i in count:
		chief_slots.append(slots.pop_at(_rng.randi_range(0, slots.size() - 1)))
		# 第一问先拿尖锐题，今天新写的那张最常被抽到；剩下的和老问题混着抽
		if i == 0 and not sharp.is_empty():
			var today := sharp.size() - 1
			chief_cards.append(sharp.pop_at(today if _rng.randf() < 0.6 else _rng.randi_range(0, today)))
			pool.append_array(sharp)
		else:
			if i == 0:
				pool.append_array(sharp)
			chief_cards.append(pool.pop_at(_rng.randi_range(0, pool.size() - 1)))
	chief_slots.sort()


## 主管该插话了：到了他挑的那一问，或者剩下的问题只够他问了（追问不能把他挤掉）。
func _chief_due() -> bool:
	if chief_slots.is_empty():
		return false
	return chief_slots[0] <= asked or questions_allowed - asked <= chief_slots.size()


## 剩下的名额除了留给主管的，还够不够追问一次。
func _can_follow_up() -> bool:
	return not _last.is_empty() and _last.card.can_follow_up() and questions_allowed - asked > chief_slots.size()


## 手牌补到 3 张。
func _draw_hand() -> void:
	while hand.size() < HAND_SIZE and not deck.is_empty():
		hand.append(deck.pop_back())


## 摆手牌；open 为假时卡压着，拖不动（等追问、等主管）。
func _show_hand(open := true) -> void:
	_hand_open = open
	UI.clear(_action)
	UI.clear(_hand_view)
	for i in hand.size():
		var view := QuestionCardView.new()
		view.setup(hand[i])
		view.position = HAND_POS + Vector2(i * 106, 0 if i == 1 else 4)
		view.enabled = open
		_hand_view.add_child(view)
	_deck_label.text = "牌堆 %d 张" % deck.size()
	_hand_hint.text = "手牌 · 拖到候选人身上提问" if open else "手牌 · 先把这一问说完"
	_hand_hint.add_theme_color_override("font_color", UI.TEXT if open else UI.TEXT_DIM)


func _can_drop_card(_at: Vector2, data: Variant) -> bool:
	var ok: bool = _hand_open and data is Dictionary and data.has("question_card")
	_drop_frame.visible = ok
	return ok


func _drop_card(_at: Vector2, data: Variant) -> void:
	_drop_frame.visible = false
	ask(data.question_card)


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END and _drop_frame:
		_drop_frame.visible = false


func ask(card: QuestionCard) -> void:
	hand.erase(card)
	deck.erase(card)
	_draw_hand()
	asked += 1
	_tick()
	var reply := _flavor(card.answer(candidate), String(card.id))
	_say("你", card.text_key, reply)
	_chief_react(card, card.chief_reaction(reply.kind))
	_last = {"card": card, "reply": reply}
	_next()


## 奇葩没手写的那几问照常按属性答，前面贴一句 TA 的小动作；轮着贴，读档重来也一样。
func _flavor(reply: Dictionary, key: String) -> Dictionary:
	if candidate.asides.is_empty() or candidate.answers.has(key):
		return reply
	var aside := candidate.asides[transcript.size() % candidate.asides.size()]
	var out := reply.duplicate()
	out.text = "%s%s" % [aside, reply.text]
	return out


func _say(who: String, question: String, reply: Dictionary) -> void:
	_speech.text = "%s：%s\n\n%s：%s" % [who, question, candidate.display_name, reply.text]
	_portrait.tic = reply.tic
	Sfx.key()
	_log(who, question, reply.text)


## 笔录上打一行；纸满了往上卷，新的一行总在眼前。
func _log(who: String, question: String, said: String) -> void:
	transcript.append({"who": who, "question": question, "reply": said})
	var empty := _transcript_list.get_node_or_null("Empty")
	if empty:
		empty.queue_free()
	var width := TRANSCRIPT_RECT.size.x - 20
	var entry := VBoxContainer.new()
	entry.add_theme_constant_override("separation", 0)
	_transcript_list.add_child(entry)
	var q := UI.label(entry, "Q%d %s：%s" % [transcript.size(), who, _clip(question, 18)], Vector2.ZERO, UI.INK_SOFT, width)
	q.custom_minimum_size.x = width
	var a := UI.label(entry, "“%s”" % _clip(said, 26), Vector2.ZERO, UI.INK, width)
	a.custom_minimum_size.x = width
	await get_tree().process_frame
	_transcript_scroll.scroll_vertical = int(_transcript_scroll.get_v_scroll_bar().max_value)


static func _clip(text: String, length: int) -> String:
	text = text.replace("\n", " ")
	return text if text.length() <= length else text.left(length - 1) + "…"


func _next() -> void:
	if asked >= questions_allowed:
		_show_candidate_ask()
	elif _can_follow_up():
		_show_follow_up_choice()
	elif _chief_due():
		_show_chief_cut_in()
	elif hand.is_empty():
		_show_candidate_ask()
	else:
		_show_hand()


## 刚说完，可以趁热追问；不追就往下走，这一问就过去了。手牌这时压着。
func _show_follow_up_choice() -> void:
	var card: QuestionCard = _last.card
	_show_hand(false)
	var b := UI.text_button(_action, "追问：“%s”（也算一问）" % card.followup_text, Rect2(ACTION_POS, Vector2(316, 26)), follow_up)
	b.add_theme_color_override("font_color", UI.YELLOW)
	UI.button(_action, "不追问", Rect2(ACTION_POS + Vector2(324, 0), Vector2(108, 26)), _skip_follow_up)


func _skip_follow_up() -> void:
	_last = {}
	_next()


func follow_up() -> void:
	var card: QuestionCard = _last.card
	var first: Dictionary = _last.reply
	_last = {}
	asked += 1
	_followups += 1
	_tick()
	# 顺着主管的违法问题往下问，你也算问了
	GameState.lawsuit_risk += card.lawsuit_risk
	var reply := _flavor(card.follow_up(candidate, first), String(card.id) + "+")
	_say("追问", card.followup_text, reply)
	_chief_react(card, card.chief_followup_reaction(reply, _followups))
	_next()


## 评分表和主管印象一起动：评分表玩家能改，主管印象不能。
func _chief_react(card: QuestionCard, reaction: Dictionary) -> void:
	var note := ""
	if card.chief_item != "" and reaction.delta != 0:
		var item := card.chief_item
		var before: int = chief_marks[item]
		chief_marks[item] = clampi(before + reaction.delta, -2, 2)
		var moved: int = chief_marks[item] - before
		scorecard[item] = clampi(scorecard[item] + moved, 1, 5)
		if moved != 0:
			note = "%s%+d" % [item, moved]
			_chief_mark.add_theme_color_override("font_color", UI.GREEN_DIM if moved > 0 else UI.RED)
	_chief_mark.text = note
	_chief_line.text = "“%s”" % reaction.line if reaction.line != "" else "（在回消息。）"


## 主管插话：手牌压着，对话框下面只有一个按钮。
func _show_chief_cut_in() -> void:
	_show_hand(false)
	var again := _chief_asked > 0
	var line: String = "还有一个。" if again else CHIEF_CUT_IN_LINES[_rng.randi_range(0, CHIEF_CUT_IN_LINES.size() - 1)]
	_chief_line.text = "“%s”" % line
	UI.panel(_action, Rect2(ACTION_POS, Vector2(316, 26)), UI.YELLOW, UI.BLACK)
	UI.label(_action, "%s“%s”" % ["赵主管又抬起头：" if again else "赵主管放下手机：", line], ACTION_POS + Vector2(6, 6), UI.INK)
	UI.button(_action, "让主管问", Rect2(ACTION_POS + Vector2(324, 0), Vector2(108, 26)), chief_ask)


## 主管的问题照样占名额，玩家拦不住；他自己问的，他也当场打分。问完你可以接着追问。
func chief_ask() -> void:
	chief_slots.pop_front()
	var card: QuestionCard = chief_cards[_chief_asked]
	_chief_asked += 1
	asked += 1
	_tick()
	GameState.lawsuit_risk += card.lawsuit_risk
	var reply := _flavor(card.answer(candidate), String(card.id))
	_say("赵主管", card.text_key, reply)
	var reaction := card.chief_reaction(reply.kind)
	_chief_react(card, reaction)
	if reaction.line == "":
		_chief_line.text = "（问完，继续看手机。）"
	_last = {"card": card, "reply": reply}
	_next()


## 问完了，手牌收起来，桌上换成反问。
func _clear_hand() -> void:
	_hand_open = false
	UI.clear(_action)
	UI.clear(_hand_view)
	_hand_hint.text = ""


func _show_candidate_ask() -> void:
	var question := GameState.config.candidate_ask
	_tick(_questions_end)
	_chief_mark.text = ""
	_clear_hand()
	UI.clear(_side)
	var top := 150.0
	var box := UI.panel(_side, Rect2(END_X, top, END_WIDTH, 0), UI.PAPER, UI.BLACK)
	UI.label(_side, "你：“你有什么想问我们的？”", Vector2(END_X + 10, top + 6), UI.INK_SOFT)
	var asked_line := UI.label(_side, "%s：%s" % [candidate.display_name, question.question], Vector2(END_X + 10, top + 24), UI.INK, END_WIDTH - 20)
	var y := top + 24.0 + asked_line.get_line_count() * 15.0 + 8.0
	for choice: String in ["lie", "safe", "truth"]:
		var b := UI.text_button(_side, "“%s”" % question.get(choice), Rect2(END_X + 10, y, END_WIDTH - 20, 26), answer_candidate.bind(choice))
		y += b.size.y + 4.0
	box.size.y = y + 4.0 - top


func answer_candidate(choice: String) -> void:
	var question := GameState.config.candidate_ask
	var text: String = question.get(choice)
	GameState.record_reply(candidate, question, choice, text)
	var response := ""
	match choice:
		"lie":
			_promise = text
			_loyalty_hit = LIE_LOYALTY_HIT
			response = "太好了，这正是我想要的。"
			_chief_line.text = "（点了点头。）"
		"safe":
			_loyalty_hit = SAFE_LOYALTY_HIT
			response = "……明白了。"
			_chief_line.text = "“滴水不漏。”"
		"truth":
			GameState.boss_trust -= 1
			_chief_line.text = "“这话，下来我们单独聊。”"
			if candidate.ability >= WALK_OUT_ABILITY:
				_speech.text = "你：%s\n\n%s：谢谢，我再考虑一下。\n（TA 合上笔记本，走了。）" % [text, candidate.display_name]
				_show_walk_out()
				return
			response = "……没关系，我能接受。"
	_speech.text = "你：%s\n\n%s：%s" % [text, candidate.display_name, response]
	_show_scorecard()


func _show_walk_out() -> void:
	UI.clear(_side)
	UI.panel(_side, Rect2(END_X, 220, END_WIDTH, 96), UI.PAPER, UI.BLACK)
	UI.label(_side, "评分表用不上了。\nHC 还空着。", Vector2(END_X + 10, 230), UI.INK)
	UI.button(_side, "送客", Rect2(END_X + 10, 274, END_WIDTH - 20, 30), finished.emit)


func _show_scorecard() -> void:
	_tick(_scorecard_at)
	UI.clear(_side)
	var top := 150.0
	UI.panel(_side, Rect2(END_X, top, END_WIDTH, 204), UI.PAPER, UI.BLACK)
	UI.label(_side, "老板评分表（主管已动过）", Vector2(END_X + 10, top + 6), UI.INK)
	var need: String = chief_need().get("item", "")
	var y := top + 26.0
	for item: String in SCORE_ITEMS:
		UI.label(_side, item + ("★" if item == need else ""), Vector2(END_X + 14, y + 4), UI.RED if item == need else UI.INK)
		for score in range(1, 6):
			var b := UI.button(_side, str(score), Rect2(END_X + 76 + score * 34, y, 30, 24), set_score.bind(item, score))
			b.toggle_mode = true
			b.button_pressed = scorecard[item] == score
		y += 30.0
	UI.button(_side, "录用", Rect2(END_X + 10, top + 162, 140, 34), decide.bind(true))
	UI.button(_side, "不录用", Rect2(END_X + 162, top + 162, 140, 34), decide.bind(false))


func set_score(item: String, score: int) -> void:
	scorecard[item] = score
	_show_scorecard()


func decide(hire: bool) -> void:
	if hire:
		var pick := is_chief_pick()
		GameState.add_hire(candidate, scorecard, _promise, _loyalty_hit, pick)
		if pick:
			GameState.stats.chief_picks.append(candidate.display_name)
		Sfx.stamp()
	finished.emit()


## 墙上的钟：开场 15:00，每问一题往后走，反问 17:30，评分表 17:45，交表就是 18:00 下班。
## 右上角的方块是问题额度：问掉一问亮一格。
func _tick(minutes := -1) -> void:
	if minutes < 0:
		minutes = _start + int(float(_questions_end - _start) * asked / questions_allowed)
	_header.text = "%02d:%02d 面试 · %s · %s" % [minutes / 60, minutes % 60, candidate.display_name, candidate.applied_position]
	UI.clear(_quota)
	var x := 630.0 - questions_allowed * 10.0
	for i in questions_allowed:
		UI.panel(_quota, Rect2(x + i * 10, 5, 8, 8), UI.YELLOW if i < asked else Color("46524d"), UI.BLACK)
