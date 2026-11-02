class_name InterviewRoom extends Control
## 面试：HR 与赵主管共同面试。玩家问卡，主管抢走一问并当场改评分表，
## 候选人反问后填老板评分表，决定是否录用。

signal finished

const QUESTION_PATHS := [
	"q_overtime", "q_weakness", "q_leaving", "q_future", "q_gap", "q_test",
	"q_family", "q_friday", "q_company", "q_probation",
]
## 含主管抢走的那一问。
const QUESTIONS_ALLOWED := 3
const CHIEF_CUTS_IN_AFTER := 1
const SCORE_ITEMS := ["狼性", "格局", "稳定性", "颜值"]
const CHIEF_SEED := 4101
const LIE_LOYALTY_HIT := 25
const SAFE_LOYALTY_HIT := 10
## 有能力的人有退路，听到实话就走；走不了的才留下。
const WALK_OUT_ABILITY := 60

var candidate: Candidate
var cards: Array[QuestionCard] = []
var asked := 0
var scorecard := {}
var _promise := ""
var _loyalty_hit := 0
var _portrait: PortraitView
var _speech: Label
var _chief_line: Label
var _side: Control


func _ready() -> void:
	candidate = pick_candidate()
	for path in QUESTION_PATHS:
		cards.append(load("res://data/questions/%s.tres" % path))
	for item in SCORE_ITEMS:
		scorecard[item] = 3
	UI.panel(self, Rect2(0, 0, 640, 360), UI.WALL)
	UI.panel(self, Rect2(0, 210, 300, 150), UI.DESK)
	UI.label(self, "面试 · " + candidate.display_name + " · " + candidate.applied_position, Vector2(12, 6), UI.GREEN)
	_portrait = PortraitView.new()
	_portrait.setup(candidate.portrait_seed, 2)
	_portrait.position = Vector2(86, 62)
	add_child(_portrait)
	UI.panel(self, Rect2(12, 220, 276, 128), UI.PAPER, UI.BLACK)
	_speech = UI.label(self, "（%s 坐下，等你提问。）" % candidate.display_name, Vector2(20, 228), UI.INK, 260)
	_build_chief()
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
	UI.label(self, "赵主管 · 41 岁", Vector2(386, 294), UI.INK_SOFT)
	_chief_line = UI.label(self, "“%s”" % GameState.config.chief_opener, Vector2(386, 310), UI.INK, 234)


## 优先剧情候选人，否则从今天通过的人里随机抽。
func pick_candidate() -> Candidate:
	var passed := GameState.passed_today
	for c in passed:
		if c.is_story:
			return c
	var rng := RandomNumberGenerator.new()
	rng.seed = GameState.day_seed()
	return passed[rng.randi_range(0, passed.size() - 1)]


func _show_cards() -> void:
	UI.clear(_side)
	UI.label(_side, "问题卡（还能问 %d 张）" % (QUESTIONS_ALLOWED - asked), Vector2(316, 12), UI.TEXT)
	var y := 34.0
	for card in cards:
		var b := UI.button(_side, card.text_key, Rect2(316, y, 308, 23), ask.bind(card))
		b.disabled = not card.available_for(candidate)
		y += 25.0


func ask(card: QuestionCard) -> void:
	cards.erase(card)
	asked += 1
	var reply := card.answer(candidate)
	_speech.text = "你：%s\n\n%s：%s" % [card.text_key, candidate.display_name, reply.text]
	_portrait.tic = reply.tic
	_chief_react(card, reply.kind)
	if asked == CHIEF_CUTS_IN_AFTER:
		_show_chief_cut_in()
	elif asked >= QUESTIONS_ALLOWED:
		_show_candidate_ask()
	else:
		_show_cards()


func _chief_react(card: QuestionCard, kind: String) -> void:
	var reaction := card.chief_reaction(kind)
	var note := ""
	if card.chief_item != "" and reaction.delta != 0:
		scorecard[card.chief_item] = clampi(scorecard[card.chief_item] + reaction.delta, 1, 5)
		note = "\n（在评分表上给“%s”%+d）" % [card.chief_item, reaction.delta]
	_chief_line.text = ("“%s”" % reaction.line if reaction.line != "" else "（在回消息。）") + note


func _show_chief_cut_in() -> void:
	UI.clear(_side)
	UI.panel(_side, Rect2(316, 20, 308, 96), UI.PAPER, UI.BLACK)
	UI.label(_side, "赵主管放下手机。\n“等一下，我问一句。”", Vector2(326, 30), UI.INK)
	UI.button(_side, "让主管问", Rect2(326, 74, 288, 30), chief_ask)


## 主管的问题照样占名额，玩家拦不住。
func chief_ask() -> void:
	var card := GameState.config.chief_question
	asked += 1
	GameState.lawsuit_risk += card.lawsuit_risk
	var reply := card.answer(candidate)
	_speech.text = "赵主管：%s\n\n%s：%s" % [card.text_key, candidate.display_name, reply.text]
	_portrait.tic = reply.tic
	_chief_line.text = "（问完，继续看手机。）"
	_show_cards()


func _show_candidate_ask() -> void:
	var question := GameState.config.candidate_ask
	UI.clear(_side)
	UI.panel(_side, Rect2(316, 20, 308, 174), UI.PAPER, UI.BLACK)
	UI.label(_side, "你：“你有什么想问我们的？”", Vector2(326, 28), UI.INK_SOFT)
	UI.label(_side, "%s：%s" % [candidate.display_name, question.question], Vector2(326, 50), UI.INK, 288)
	var y := 82.0
	for choice: String in ["lie", "safe", "truth"]:
		UI.button(_side, "“%s”" % question.get(choice), Rect2(322, y, 296, 30), answer_candidate.bind(choice))
		y += 34.0


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
	UI.clear(_side)
	UI.panel(_side, Rect2(316, 20, 308, 230), UI.PAPER, UI.BLACK)
	UI.label(_side, "老板评分表（主管已动过）", Vector2(326, 28), UI.INK)
	var y := 52.0
	for item: String in SCORE_ITEMS:
		UI.label(_side, item, Vector2(330, y + 4), UI.INK)
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
		GameState.add_hire(candidate, scorecard, _promise, _loyalty_hit)
		Sfx.stamp()
	finished.emit()
