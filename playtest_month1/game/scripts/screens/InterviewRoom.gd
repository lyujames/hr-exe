class_name InterviewRoom extends Control
## 面试：HR 与赵主管共同面试，一共问 5 个问题。主管在随机的时候插进来抢走 1–2 问，
## 问什么从他到今天为止的问题里随机抽；玩家问卡时他当场改评分表。候选人反问后填老板评分表，决定是否录用。
## 实习生和社招各有一套问题卡：实习生问的是 TA 知不知道来干什么、项目里做了什么、能来多久。
## 在读研究生多问 2 问，还多一套问题卡：导师放不放人、读不读博、研究方向和岗位的关系。
## 每个回答刚说完可以追问一次（占一问）：背的接不上，说实话的越说越具体，露破绽的越问越慌。
## 第 3 天起主管开场拍一张便签（DayConfig.chief_need），录用的人在他自己心里那一项够了，发主管推荐奖。

signal finished

const QUESTION_PATHS := [
	"q_overtime", "q_weakness", "q_leaving", "q_future", "q_gap", "q_test",
	"q_family", "q_friday", "q_company", "q_probation",
	"q_intern_role", "q_project", "q_our_app", "q_data_test", "q_chores", "q_schedule", "q_return_offer",
	"q_grad_advisor", "q_grad_phd", "q_grad_why_ops", "q_grad_research",
]
## 含主管抢走的那几问。
const QUESTIONS_ALLOWED := 5
const GRAD_QUESTIONS_ALLOWED := 7
## 主管抢几问；第一问总是玩家开场。
const CHIEF_ASKS_MIN := 1
const CHIEF_ASKS_MAX := 2
const CHIEF_CUT_IN_LINES := ["等一下，我问一句。", "我插一句。", "这个我来问。", "你先停一下。"]
const SCORE_ITEMS := ["狼性", "格局", "稳定性", "颜值"]
const CHIEF_SEED := 4101
const LIE_LOYALTY_HIT := 25
const SAFE_LOYALTY_HIT := 10
## 问题卡列表的下沿：再往下是赵主管的框。
const CARDS_BOTTOM := 286.0
## 有能力的人有退路，听到实话就走；走不了的才留下。
const WALK_OUT_ABILITY := 60
## 主管印象（只记他自己加减的分，评分表玩家能改、这个改不了）够到多少算“他要的人”。
const CHIEF_PICK_MARK := 1

var candidate: Candidate
var cards: Array[QuestionCard] = []
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
var _portrait: PortraitView
var _speech: Label
var _chief_line: Label
## 主管刚在评分表上动了哪一项，写在他名字旁边。
var _chief_mark: Label
var _side: Control
var _header: Label
## 15:00 开始面试，18:00 下班：问题按份平分 15:00–17:30，候选人反问和填评分表占最后半小时。
const START_MINUTES := 15 * 60
const QUESTIONS_END := 17 * 60 + 30


func _ready() -> void:
	candidate = pick_candidate()
	if candidate.is_grad():
		questions_allowed = GRAD_QUESTIONS_ALLOWED
	for path in QUESTION_PATHS:
		var card: QuestionCard = load("res://data/questions/%s.tres" % path)
		if card.for_audience(candidate):
			cards.append(card)
	for item in SCORE_ITEMS:
		scorecard[item] = 3
		chief_marks[item] = 0
	_plan_chief()
	UI.panel(self, Rect2(0, 0, 640, 360), UI.WALL)
	UI.panel(self, Rect2(0, 210, 300, 150), UI.DESK)
	_header = UI.label(self, "", Vector2(12, 6), UI.GREEN)
	_tick(START_MINUTES)
	_portrait = PortraitView.new()
	_portrait.setup(candidate.portrait_seed, 2)
	_portrait.position = Vector2(86, 62)
	add_child(_portrait)
	UI.panel(self, Rect2(12, 220, 276, 128), UI.PAPER, UI.BLACK)
	_speech = UI.label(self, "（%s 坐下，等你提问。）" % candidate.display_name, Vector2(20, 228), UI.INK, 260)
	_build_chief()
	_build_need_note()
	_side = Control.new()
	_side.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_side)
	_show_cards()


func _build_chief() -> void:
	UI.panel(self, Rect2(316, 290, 308, 66), UI.PAPER_DIM, UI.BLACK)
	var chief := PortraitView.new()
	chief.setup(CHIEF_SEED)
	chief.position = Vector2(317, 291)
	add_child(chief)
	UI.label(self, "赵主管 · 创始员工", Vector2(386, 294), UI.INK_SOFT)
	_chief_mark = UI.label(self, "", Vector2(560, 294), UI.INK)
	_chief_line = UI.label(self, "“%s”" % GameState.config.chief_opener, Vector2(386, 310), UI.INK, 210)


## 主管开场拍在桌上的便签：今天他要什么样的人。
func _build_need_note() -> void:
	var need := chief_need()
	if need.is_empty():
		return
	UI.panel(self, Rect2(12, 28, 284, 22), UI.YELLOW, UI.BLACK)
	UI.label(self, "主管便签：%s" % need.note, Vector2(18, 31), UI.INK)


func chief_need() -> Dictionary:
	return GameState.config.chief_need


## 他要的那一项，他自己心里够了没有。
func is_chief_pick() -> bool:
	var need := chief_need()
	return not need.is_empty() and int(chief_marks.get(need.item, 0)) >= CHIEF_PICK_MARK


## 优先剧情候选人，否则从昨天通过的人里随机抽。
func pick_candidate() -> Candidate:
	var passed := GameState.interviewees
	for c in passed:
		if c.is_story:
			return c
	var rng := RandomNumberGenerator.new()
	rng.seed = GameState.day_seed()
	return passed[rng.randi_range(0, passed.size() - 1)]


## 种子跟着这一局和这一天走：读档重来同一天，主管还是那样插话。
func _plan_chief() -> void:
	_rng.seed = hash([GameState.day_seed(), "chief"])
	var pool: Array[QuestionCard] = []
	for d in range(1, GameState.day + 1):
		var card := RuleEngine.load_day(d).chief_question
		if card and card not in pool and card.available_for(candidate):
			pool.append(card)
	var slots := range(1, questions_allowed)
	var count := mini(_rng.randi_range(CHIEF_ASKS_MIN, CHIEF_ASKS_MAX), pool.size())
	for i in count:
		chief_slots.append(slots.pop_at(_rng.randi_range(0, slots.size() - 1)))
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


func _show_cards() -> void:
	UI.clear(_side)
	UI.label(_side, "问题卡（第 %d / %d 问）" % [asked + 1, questions_allowed], Vector2(316, 12), UI.TEXT)
	# 卡多（研究生 13 张）放不下时滚动，不压到下面赵主管的框
	var list := ScrollContainer.new()
	list.position = Vector2(316, 34)
	list.size = Vector2(308, CARDS_BOTTOM - 34.0)
	list.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_side.add_child(list)
	var inner := Control.new()
	inner.mouse_filter = Control.MOUSE_FILTER_PASS
	list.add_child(inner)
	var width := 308.0 if cards.size() * 25.0 <= list.size.y else 298.0
	var y := 0.0
	for card in cards:
		var b := UI.text_button(inner, card.text_key, Rect2(0, y, width, 23), ask.bind(card))
		b.disabled = not card.available_for(candidate)
		y += b.size.y + 2.0
	inner.custom_minimum_size = Vector2(width, y)


func ask(card: QuestionCard) -> void:
	cards.erase(card)
	asked += 1
	_tick()
	var reply := card.answer(candidate)
	_speech.text = "你：%s\n\n%s：%s" % [card.text_key, candidate.display_name, reply.text]
	_portrait.tic = reply.tic
	_chief_react(card, card.chief_reaction(reply.kind))
	_last = {"card": card, "reply": reply}
	_next()


func _next() -> void:
	if asked >= questions_allowed:
		_show_candidate_ask()
	elif _can_follow_up():
		_show_follow_up_choice()
	elif _chief_due():
		_show_chief_cut_in()
	else:
		_show_cards()


## 刚说完，可以趁热追问；不追就往下走，这一问就过去了。
func _show_follow_up_choice() -> void:
	var card: QuestionCard = _last.card
	UI.clear(_side)
	UI.label(_side, "问题卡（第 %d / %d 问）" % [asked + 1, questions_allowed], Vector2(316, 12), UI.TEXT)
	var box := UI.panel(_side, Rect2(316, 34, 308, 0), UI.PAPER, UI.BLACK)
	UI.label(_side, "趁热追问一句？（也算一问）", Vector2(326, 40), UI.INK_SOFT)
	var b := UI.text_button(_side, "追问：“%s”" % card.followup_text, Rect2(326, 60, 288, 30), follow_up)
	var y := 60.0 + b.size.y + 6.0
	UI.button(_side, "下一问", Rect2(326, y, 288, 30), _skip_follow_up)
	box.size.y = y + 36.0 - 34.0


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
	var reply := card.follow_up(candidate, first)
	_speech.text = "你：%s\n\n%s：%s" % [card.followup_text, candidate.display_name, reply.text]
	_portrait.tic = reply.tic
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


func _show_chief_cut_in() -> void:
	UI.clear(_side)
	UI.panel(_side, Rect2(316, 20, 308, 96), UI.PAPER, UI.BLACK)
	var again := _chief_asked > 0
	var line: String = "还有一个。" if again else CHIEF_CUT_IN_LINES[_rng.randi_range(0, CHIEF_CUT_IN_LINES.size() - 1)]
	UI.label(_side, "%s\n“%s”" % ["赵主管又抬起头。" if again else "赵主管放下手机。", line], Vector2(326, 30), UI.INK)
	UI.button(_side, "让主管问", Rect2(326, 74, 288, 30), chief_ask)


## 主管的问题照样占名额，玩家拦不住；他自己问的，他也当场打分。问完你可以接着追问。
func chief_ask() -> void:
	chief_slots.pop_front()
	var card: QuestionCard = chief_cards[_chief_asked]
	_chief_asked += 1
	asked += 1
	_tick()
	GameState.lawsuit_risk += card.lawsuit_risk
	var reply := card.answer(candidate)
	_speech.text = "赵主管：%s\n\n%s：%s" % [card.text_key, candidate.display_name, reply.text]
	_portrait.tic = reply.tic
	var reaction := card.chief_reaction(reply.kind)
	_chief_react(card, reaction)
	if reaction.line == "":
		_chief_line.text = "（问完，继续看手机。）"
	_last = {"card": card, "reply": reply}
	_next()


func _show_candidate_ask() -> void:
	var question := GameState.config.candidate_ask
	_tick(QUESTIONS_END)
	_chief_mark.text = ""
	UI.clear(_side)
	var box := UI.panel(_side, Rect2(316, 20, 308, 0), UI.PAPER, UI.BLACK)
	UI.label(_side, "你：“你有什么想问我们的？”", Vector2(326, 28), UI.INK_SOFT)
	var asked_line := UI.label(_side, "%s：%s" % [candidate.display_name, question.question], Vector2(326, 50), UI.INK, 288)
	var y := 50.0 + asked_line.get_line_count() * 15.0 + 10.0
	for choice: String in ["lie", "safe", "truth"]:
		var b := UI.text_button(_side, "“%s”" % question.get(choice), Rect2(326, y, 288, 30), answer_candidate.bind(choice))
		y += b.size.y + 4.0
	box.size.y = y + 6.0 - 20.0


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
	UI.panel(_side, Rect2(316, 20, 308, 96), UI.PAPER, UI.BLACK)
	UI.label(_side, "评分表用不上了。\nHC 还空着。", Vector2(326, 30), UI.INK)
	UI.button(_side, "送客", Rect2(326, 74, 288, 30), finished.emit)


func _show_scorecard() -> void:
	_tick(17 * 60 + 45)
	UI.clear(_side)
	UI.panel(_side, Rect2(316, 20, 308, 230), UI.PAPER, UI.BLACK)
	UI.label(_side, "老板评分表（主管已动过）", Vector2(326, 28), UI.INK)
	var need: String = chief_need().get("item", "")
	var y := 52.0
	for item: String in SCORE_ITEMS:
		UI.label(_side, item + ("★" if item == need else ""), Vector2(330, y + 4), UI.RED if item == need else UI.INK)
		for score in range(1, 6):
			var b := UI.button(_side, str(score), Rect2(392 + score * 34, y, 30, 24), set_score.bind(item, score))
			b.toggle_mode = true
			b.button_pressed = scorecard[item] == score
		y += 34.0
	UI.button(_side, "录用", Rect2(326, 202, 136, 34), decide.bind(true))
	UI.button(_side, "不录用", Rect2(476, 202, 136, 34), decide.bind(false))


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
func _tick(minutes := -1) -> void:
	if minutes < 0:
		minutes = START_MINUTES + int(float(QUESTIONS_END - START_MINUTES) * asked / questions_allowed)
	_header.text = "%02d:%02d 面试 · %s · %s" % [minutes / 60, minutes % 60, candidate.display_name, candidate.applied_position]
