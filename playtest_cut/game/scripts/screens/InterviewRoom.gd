class_name InterviewRoom extends Control
## 面试：HR 与赵主管共同面试，一共问 5 个问题。主管在随机的时候插进来抢走 1–2 问，
## 问什么从他到今天为止的问题里随机抽；玩家问卡时他当场改评分表。候选人反问后填老板评分表，决定是否录用。
## 实习生和社招各有一套问题卡：实习生问的是 TA 知不知道来干什么、项目里做了什么、能来多久。
## 在读研究生多问 2 问，还多一套问题卡：导师放不放人、读不读博、研究方向和岗位的关系。
## 每个回答刚说完可以追问一次（占一问）：背的接不上，说实话的越说越具体，露破绽的越问越慌。
## 招程序员（第 10 天）起，主管抢的第一问总是一道尖锐题（DayConfig.chief_sharp），玩家手里也混着尖锐题卡。
## 当天没有剧情候选人进面试，抽中的普通人可能是个奇葩（DayConfig.quirk）：简历正常，一开口才知道。
## 剧情候选人进了面试、今天又有奇葩，就面两场：剧情候选人 15:00–16:30，奇葩 16:30–18:00。
## 第 6 天起主管每天早上在你桌上贴一张便签（DayConfig.chief_need），写他明天要什么经历；第二天面试他把这张拍在桌上，
## 录用的人简历第二页对得上，发主管推荐奖。只看纸面，项目掺没掺水不管。
## 破格的人（GameState.vouched）第二天 14:00–15:00 你单独面：主管的椅子空着，没人抢问、没人改表，
## 评分表是空的 3 分，红笔照样只改一处；录用了记作你担保（GameState.add_hire 的 vouched）。
## 第 13 天起程序员按组招，坐在主管位置上的换成用人组的组长（DayConfig.interviewer）：他带自己的题、每场抢两问，
## 听的是真话不是官话（QuestionCard.lead_reaction），不碰老板评分表，填表时直接说这个人他要不要。
##
## 画面学《Papers, Please》：上半屏是对面坐着的人和赵主管，下半屏是桌面。
## 桌面左边摊着 TA 的简历（InterviewResume）：点一行就问这一行，尖锐卡拖到行上是把这一行问穿（ResumeQuestions）；
## 红笔圈出来的行是你的疑点，抄到评分表上。中间是手牌：洗成牌堆，手里 3 张，问掉一张补一张，拖到候选人身上就是问。
## 右边是面试笔录，每一问自动打一行；问简历问出来的反应（认了、支吾、答不上）也贴回简历那一行上。

signal finished

const QUESTION_PATHS := [
	"q_overtime", "q_weakness", "q_leaving", "q_future", "q_gap", "q_test",
	"q_family", "q_friday", "q_company", "q_probation",
	"q_intern_role", "q_project", "q_our_app", "q_data_test", "q_chores", "q_schedule", "q_return_offer",
	"q_grad_advisor", "q_grad_phd", "q_grad_why_ops", "q_grad_research",
	"q_tech_depth", "q_code_review", "q_oncall",
]
# 砍减版：玩家手里不再混尖锐题卡（拖到简历行上“问穿”那一套）；主管 / 组长开场的尖锐题照旧，是他口头问的。
# q_ai_tool（用不用 AI 编程助手）留着给下个月：第二个月 AI 只在新闻里出现。
## 含主管抢走的那几问。
const QUESTIONS_ALLOWED := 5
const GRAD_QUESTIONS_ALLOWED := 7
## 手里同时拿几张卡。
const HAND_SIZE := 3
## 主管抢几问；第一问总是玩家开场。组长每场都抢两问。
const CHIEF_ASKS_MIN := 1
const CHIEF_ASKS_MAX := 2
const LEAD_ASKS := 2
const CHIEF_CUT_IN_LINES := ["等一下，我问一句。", "我插一句。", "这个我来问。", "你先停一下。"]
const SCORE_ITEMS := ["狼性", "格局", "稳定性", "颜值"]
## 表上每一项的小字：王总的词，底下其实问的是什么。颜值没有底下。
const SCORE_HINTS := {"狼性": "扛得住吗", "格局": "干得了吗", "稳定性": "待得住吗", "颜值": "王总加的"}
const CHIEF_SEED := 4101
const LIE_LOYALTY_HIT := 25
const SAFE_LOYALTY_HIT := 10
## 有能力的人有退路，听到实话就走；走不了的才留下。
const WALK_OUT_ABILITY := 60
## 主管印象（只记他自己加减的分，评分表玩家能改、这个改不了）够到多少算“他要的人”。
const CHIEF_PICK_MARK := 1

## 画面分区：墙（候选人、对话）在上，桌面在下。
## 墙上不画框：候选人的话是一个对话气泡，追问、主管插话是气泡下面的小签；主管是右上角的小头像加一个小气泡。
const DESK_TOP := 152.0
const SPEECH_RECT := Rect2(144, 24, 318, 92)
const ACTION_POS := Vector2(144, 123)
const DROP_RECT := Rect2(0, 18, 640, DESK_TOP - 18)
const PORTRAIT_POS := Vector2(8, 22)
const CHIEF_POS := Vector2(472, 24)
const CHIEF_BUBBLE := Rect2(472, 91, 164, 59)
## 桌面：左边带页签的简历纸（高度随内容），纸边一支红笔；右上一张主管便签，下面一排三张手牌。
const TAB_POS := Vector2(12, 158)
const RESUME_POS := Vector2(12, 174)
const PEN_POS := Vector2(318, 182)
const NOTE_RECT := Rect2(486, 160, 146, 38)
const HAND_POS := Vector2(340, 222)
const HAND_SLOTS := [Vector2(0, 0), Vector2(99, 0), Vector2(198, 0)]
## 笔录是简历那张纸的背面：点页签翻面。
const TRANSCRIPT_RECT := Rect2(12, 174, 300, 180)
## 反问、评分表这些收尾的纸，盖满整张桌面。
const END_X := 4.0
const END_WIDTH := 632.0
const END_TOP := 160.0

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
## 今天坐在主管位置上的是组长（DayConfig.interviewer 不空）。
var lead := false
var scorecard := {}
## 主管自己当场加减的分，-2..+2；评分表上的数是 3 加它，玩家改评分表动不了这里。
var chief_marks := {}
## 进评分表那一刻主管填好的样子；你只能用红笔改其中一处：{item, from, to}，空表示没改。
var _filled := {}
var hr_edit := {}
## 刚说完的那一问，可以追问：{card, reply, by_chief}；空表示没得追问。
var _last := {}
var _followups := 0
## 组长这一场有没有被打动过（合上电脑那一下只演一次）。
var _lead_won := false
var _promise := ""
var _loyalty_hit := 0
## 候选人要反问的几个问题：社会人一个，学生一到两个。
var _asks: Array[CandidateAsk] = []
var _ask_index := 0
## 笔录：每一问一条 {who, question, reply}。
var transcript: Array[Dictionary] = []
## 开场的自我介绍（SelfIntro.build），说到第几句；划过的句子按简历行 key 记，对质过的就划掉。
var intro: Array[Dictionary] = []
var _intro_at := 0
var underlined := {}
var _confronted: PackedStringArray = []
## 笔录上自我介绍那几行的 Label，划线时改颜色；按句子下标。
var _intro_labels := {}
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
var resume: InterviewResume
var _transcript_box: Control
var _tabs: Control
var _pen: Control
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
## 这一场是破格的单独面试（GameState.vouched）：14:00–15:00，主管 / 组长的椅子空着，没人抢问、没人动表，
## 评分表是空的 3 分，你自己填；录用了记作你担保（GameState.add_hire 的 vouched_hire）。
var solo := false
const SOLO_START := 14 * 60
## 按组招的日子（DayConfig.team_folders）：钟按实际走。每问 10 分钟，追问多 5 分钟，反问和填表 10 分钟；
## 组长有自己的事（JobPosting.lead.delay）。一场接一场，下一场从上一场交表开始，过了 18:00 照样面。
const QUESTION_MINUTES := 10
const FOLLOWUP_EXTRA := 5
const WRAP_MINUTES := 10
const PHONE_RECT := Rect2(336, 158, 146, 40)
var timed := false
## 这一场来面的组（候选人放进的文件夹，或者投的那个岗位）；组长写在它的 lead 里。
var _team: JobPosting
## 组长那边耽误掉的分钟。
var _waited := 0
var _mid_delay_done := false
var _eta: Label
var _phone_note: Control


func _ready() -> void:
	var vouched := GameState.next_vouched()
	if vouched:
		solo = true
		candidate = vouched
		GameState.stats.solo_done.append(candidate.display_name)
		_start = SOLO_START
		_scorecard_at = SOLO_START + 55
		_questions_end = SOLO_START + 48
	else:
		slot = GameState.interviewed_today.size()
		candidate = pick_candidate()
		GameState.interviewed_today.append(candidate.display_name)
	timed = GameState.config.team_folders
	# 破格那场没有组长（_who 为空），表头照样写 TA 放进的组
	_team = GameState.team_posting(candidate)
	if timed:
		_start = maxi(SOLO_START if solo else START_MINUTES, int(GameState.stats.clock))
	elif not solo and (slot > 0 or second_candidate()):
		_start = START_MINUTES + slot * SLOT_MINUTES
		_scorecard_at = _start + SLOT_MINUTES - 8
		_questions_end = _scorecard_at - 7
	if candidate.is_grad():
		questions_allowed = GRAD_QUESTIONS_ALLOWED
	lead = not solo and not _who().is_empty()
	for item in SCORE_ITEMS:
		scorecard[item] = 3
		chief_marks[item] = 0
	for item in QuestionCard.LEAD_ITEMS:
		chief_marks[item] = 0
	_plan_chief()
	_build_deck()
	_build_wall()
	_build_desk()
	_tick(_start)
	_draw_hand()
	_start_intro()
	if timed and lead and _who().get("delay", {}).get("at", "") == "start" and not _seen_lead_today():
		_delay()


## 能问的卡洗成牌堆，种子跟着这一天走：读档重来，手里还是那几张。
func _build_deck() -> void:
	var paths := QUESTION_PATHS.duplicate()
	# 第三个月起 AI 进了办公室：面试多一张“平时用 AI 编程助手吗”
	if GameState.month() >= 3:
		paths.append("q_ai_tool")
	for path in paths:
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
	_drop_frame = UI.panel(self, Rect2(PORTRAIT_POS - Vector2(3, 3), Vector2(134, 134)), Color.TRANSPARENT, UI.GREEN)
	(_drop_frame.get_theme_stylebox("panel") as StyleBoxFlat).set_border_width_all(2)
	_drop_frame.visible = false
	_portrait = PortraitView.new()
	_portrait.setup(candidate.portrait_seed, 2, PortraitFactory.art_key(candidate.portrait_seed, candidate.id))
	_portrait.position = PORTRAIT_POS
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_portrait)
	UI.panel(self, SPEECH_RECT, UI.PAPER)
	_tail(SPEECH_RECT.position + Vector2(-6, 30), UI.PAPER, true)
	var opening := candidate.entrance if candidate.entrance != "" else "（%s 坐下，等你提问。）" % candidate.display_name
	_speech = UI.label(self, opening, SPEECH_RECT.position + Vector2(9, 5), UI.INK, SPEECH_RECT.size.x - 18)
	_speech.max_lines_visible = 5
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
	UI.panel(self, Rect2(0, DESK_TOP, 640, 2), UI.DESK_DARK)
	_build_transcript()
	_build_resume()
	_tabs = Control.new()
	_tabs.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_tabs)
	_build_pen()
	_deck_label = UI.label(self, "", HAND_POS + Vector2(0, -17), UI.TEXT_DIM)
	_hand_view = Control.new()
	_hand_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hand_view)
	_hand_hint = UI.label(self, "", HAND_POS + Vector2(0, QuestionCardView.SIZE.y + 4), UI.TEXT_DIM)
	_build_chief()
	_build_need_note()
	_draw_tabs()
	_side = Control.new()
	_side.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_side)


## 左边一张打印纸：每问一句自动打一行。
func _build_transcript() -> void:
	var r := TRANSCRIPT_RECT
	_transcript_box = Control.new()
	_transcript_box.visible = false
	add_child(_transcript_box)
	UI.panel(_transcript_box, r, UI.PAPER)
	_transcript_scroll = ScrollContainer.new()
	_transcript_scroll.position = r.position + Vector2(8, 6)
	_transcript_scroll.size = r.size - Vector2(10, 10)
	_transcript_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_transcript_box.add_child(_transcript_scroll)
	_transcript_list = VBoxContainer.new()
	_transcript_list.custom_minimum_size.x = r.size.x - 24
	_transcript_list.add_theme_constant_override("separation", 4)
	_transcript_scroll.add_child(_transcript_list)
	var empty := UI.label(_transcript_list, "（还没问。）", Vector2.ZERO, UI.INK_SOFT)
	empty.name = "Empty"


func _build_chief() -> void:
	if solo:
		_build_empty_chair()
		return
	var chief := PortraitView.new()
	chief.setup(int(_who().get("seed", CHIEF_SEED)))
	chief.position = CHIEF_POS
	add_child(chief)
	UI.label(self, interviewer_name(), CHIEF_POS + Vector2(72, 4), UI.TEXT_DIM)
	_chief_mark = UI.label(self, "", CHIEF_POS + Vector2(72, 22), UI.TEXT)
	var r := CHIEF_BUBBLE
	UI.panel(self, r, UI.PAPER_DIM)
	_tail(r.position + Vector2(14, -6), UI.PAPER_DIM, false)
	var opener: String = GameState.config.chief_opener if slot == 0 else _who().get("next_line", "下一个。抓紧，六点我还有会。")
	if timed and _who().has("opener"):
		opener = _who().next_line if _seen_lead_today() else _who().opener
	# 砍减版按组招的日子没有主管开场白：组长有自己的就说自己的，都没有就写他在干什么，不留一对空引号
	if opener == "" and _who().get("opener", "") != "":
		opener = _who().opener
	var said := "“%s”" % opener if opener != "" else "（%s低头看简历。）" % interviewer_name()
	_chief_line = UI.label(self, said, r.position + Vector2(5, 0), UI.INK, r.size.x - 8)
	_chief_line.add_theme_constant_override("line_spacing", -5)
	_chief_line.max_lines_visible = 3


## 这个组长今天前面已经面过一场了（开场白只说一次）。
func _seen_lead_today() -> bool:
	for i in mini(slot, GameState.sessions.size()):
		var t := GameState.team_posting(GameState.sessions[i])
		if t and t.lead.get("name", "") == _who().get("name", ""):
			return true
	return false


## 破格那场：主管的位置上是一把空椅子，小气泡里是旁白。
func _build_empty_chair() -> void:
	UI.panel(self, Rect2(CHIEF_POS + Vector2(10, 30), Vector2(44, 36)), UI.DESK_DARK, UI.BLACK)
	UI.panel(self, Rect2(CHIEF_POS + Vector2(14, 6), Vector2(36, 26)), UI.DESK_DARK, UI.BLACK)
	UI.label(self, "（空椅子）", CHIEF_POS + Vector2(68, 4), UI.TEXT_DIM)
	_chief_mark = UI.label(self, "", CHIEF_POS + Vector2(72, 22), UI.TEXT)
	var r := CHIEF_BUBBLE
	UI.panel(self, r, UI.PAPER_DIM)
	_chief_line = UI.label(self, "这一场你自己面。人是你保的。", r.position + Vector2(5, 0), UI.INK_SOFT, r.size.x - 8)
	_chief_line.add_theme_constant_override("line_spacing", -5)
	_chief_line.max_lines_visible = 3


## 坐在主管位置上的人：赵主管，或者今天这个组的组长。
func _who() -> Dictionary:
	if solo:
		return {}
	if _team and not _team.lead.is_empty():
		return _team.lead
	return GameState.config.interviewer


func interviewer_name() -> String:
	return _who().get("name", "赵主管")


## 气泡的小尖角：一个转了 45° 的小方块，一半藏在气泡后面。left 为真朝左，否则朝上。
func _tail(at: Vector2, color: Color, left: bool) -> void:
	var tip := UI.panel(self, Rect2(at + (Vector2(2, 0) if left else Vector2(0, 2)), Vector2(9, 9)), color)
	tip.pivot_offset = Vector2(4.5, 4.5)
	tip.rotation = PI / 4
	tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	move_child(tip, tip.get_index() - 1)


## 主管开场拍在桌上的便签：今天他要什么样的人。
func _build_need_note() -> void:
	var need := chief_need()
	if need.is_empty():
		return
	var sticky := Control.new()
	sticky.position = NOTE_RECT.position
	sticky.rotation = -0.035
	sticky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sticky)
	UI.panel(sticky, Rect2(Vector2(2, 2), NOTE_RECT.size), Color(0, 0, 0, 0.3))
	UI.panel(sticky, Rect2(Vector2.ZERO, NOTE_RECT.size), UI.YELLOW)
	var note := UI.label(sticky, need.note, Vector2(6, 3), UI.INK, NOTE_RECT.size.x - 12)
	note.add_theme_constant_override("line_spacing", -3)
	note.max_lines_visible = 2


## 赵主管的便签是昨天早上贴在你桌上的：昨天筛的人，今天来面。组长的便签当天写。
func chief_need() -> Dictionary:
	if solo:
		return {}
	if _team and not _team.lead.is_empty():
		return _team.lead.get("need", {})
	# 第一个月：赵主管的便签头一天就贴在桌上，面的是昨天筛的人，看昨天那张；第二个月起他当天开场拍便签
	if lead or GameState.day <= 1 or GameState.month() > 1:
		return GameState.config.chief_need
	return RuleEngine.load_day(GameState.day - 1).chief_need


## 他要的人：便签写的是经历，就看简历第二页对不对得上（只看纸面）；写的是评分项，看他自己心里那一项够了没有。
func is_chief_pick() -> bool:
	var need := chief_need()
	if need.is_empty():
		return false
	if need.has("project") or need.has("role") or need.has("months"):
		return candidate.fits(need)
	return int(chief_marks.get(need.item, 0)) >= CHIEF_PICK_MARK


## 第一场优先剧情候选人，否则从昨天通过的人里随机抽，今天有奇葩就是这个人；第二场就是奇葩。
func pick_candidate() -> Candidate:
	if GameState.config.team_folders:
		if GameState.sessions.is_empty() and slot == 0:
			GameState.plan_sessions()
		return GameState.sessions[mini(slot, GameState.sessions.size() - 1)]
	if slot > 0:
		return second_candidate()
	for c in GameState.interviewees:
		if c.is_story:
			return c
	return _plain_pick()


## 第二场的人：今天有奇葩、昨晚约了两个人才有（第一场是剧情候选人时第二场是奇葩），否则 null。
static func second_candidate() -> Candidate:
	# 砍减版：一天只面一场，没有第二场奇葩
	return null


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
	if solo:
		return
	if lead:
		_plan_lead()
		return
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


## 组长只问自己带来的题：第一张尖锐题必问，剩下的抽一张；插在哪一问随机。
func _plan_lead() -> void:
	var source: Array[QuestionCard] = _team.lead_cards if _team and not _team.lead.is_empty() else GameState.config.lead_cards
	var cards := source.filter(func(c: QuestionCard) -> bool: return c.available_for(candidate))
	var slots := range(1, questions_allowed)
	for i in mini(LEAD_ASKS, cards.size()):
		chief_slots.append(slots.pop_at(_rng.randi_range(0, slots.size() - 1)))
		chief_cards.append(cards.pop_at(0 if i == 0 else _rng.randi_range(0, cards.size() - 1)))
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
		view.position = HAND_POS + HAND_SLOTS[i]
		view.enabled = open
		_hand_view.add_child(view)
	_deck_label.text = "手牌 · 牌堆 %d" % deck.size()
	_hand_hint.text = "拖到人身上问 · 尖锐卡可拖到简历行" if open else "先把这一问说完（追问也算一问）"
	if resume:
		resume.set_open(open)


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
	_just_caught = false
	hand.erase(card)
	deck.erase(card)
	_draw_hand()
	asked += 1
	_tick()
	var reply := _flavor(card.answer(candidate), String(card.id))
	_say("你", card.text_key, reply)
	_chief_react(card, _reaction(card, reply))
	_last = {"card": card, "reply": reply}
	_next()


func _build_resume() -> void:
	resume = InterviewResume.new()
	resume.position = RESUME_POS
	add_child(resume)
	resume.setup(candidate)
	resume.line_asked.connect(ask_line)
	resume.sharp_dropped.connect(ask_line_sharp)


## 简历和笔录是同一张纸的两面。
func _flip_paper() -> void:
	_transcript_box.visible = not _transcript_box.visible
	resume.visible = not _transcript_box.visible
	_pen.visible = resume.visible
	Sfx.paper()
	_draw_tabs()
	if _transcript_box.visible:
		_scroll_log()


## 纸顶上露出的两个页签：当前这一面亮，另一面暗；笔录上写着问了几问。
func _draw_tabs() -> void:
	UI.clear(_tabs)
	var x := TAB_POS.x
	var showing_log := _transcript_box.visible
	var h := RESUME_POS.y - TAB_POS.y
	for tab in [["简历", false], ["笔录 %d" % transcript.size(), true]]:
		var on: bool = tab[1] == showing_log
		var label := UI.label(_tabs, tab[0], Vector2(x + 8, TAB_POS.y - 1), UI.INK if on else Color("3a403c"))
		var w := label.get_combined_minimum_size().x + 16
		var face := UI.panel(_tabs, Rect2(x, TAB_POS.y, w, h + (1 if on else 0)), UI.PAPER if on else Color("9aa39c"))
		_tabs.move_child(face, label.get_index())
		if not on:
			face.mouse_filter = Control.MOUSE_FILTER_STOP
			face.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			face.gui_input.connect(func(event: InputEvent) -> void:
				if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
					_flip_paper())
		x += w + 2


## 纸边斜放着一支红笔：点一下拿起来（笔抬高、亮一点），在简历上点哪行圈哪行；再点放下。
func _build_pen() -> void:
	_pen = Control.new()
	_pen.position = PEN_POS
	_pen.size = Vector2(18, 56)
	_pen.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_pen.tooltip_text = "红笔：圈出疑点（不占问）"
	add_child(_pen)
	_pen.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			resume.toggle_pen()
			_draw_pen())
	_draw_pen()


func _draw_pen() -> void:
	UI.clear(_pen)
	var up := resume.pen
	var body := Control.new()
	body.position = Vector2(6, 2 if up else 8)
	body.rotation = 0.3
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pen.add_child(body)
	UI.panel(body, Rect2(2, 2, 7, 42), Color(0, 0, 0, 0.35))
	UI.panel(body, Rect2(0, 0, 7, 40), UI.RED.lightened(0.15) if up else UI.RED)
	UI.panel(body, Rect2(0, 40, 7, 6), UI.BLACK)


## 点简历上的一行：不用卡，照样占一问。
func ask_line(line: Dictionary) -> void:
	_ask_about(line, ResumeQuestions.card_for(candidate, line))


## 尖锐卡拖到简历的一行上：卡用掉，这一行问穿。
func ask_line_sharp(line: Dictionary, sharp_card: QuestionCard) -> void:
	hand.erase(sharp_card)
	deck.erase(sharp_card)
	_draw_hand()
	_ask_about(line, ResumeQuestions.card_for(candidate, line, true))


func _ask_about(line: Dictionary, card: QuestionCard) -> void:
	_just_caught = false
	var said := {} if line.key in _confronted else SelfIntro.hook(intro, line.key, underlined, resume.circled)
	if not said.is_empty():
		card = SelfIntro.confront(candidate, line, card, said)
		_confronted.append(line.key)
	# 先怀疑、后问：划过线（对质）或者红笔先圈了，问出东西来才算你说中
	var committed: bool = not said.is_empty() or line.key in resume.circled
	asked += 1
	_tick()
	var reply := _flavor(card.answer(candidate), String(card.id))
	var tag := _line_tag(line, card, reply, false)
	var caught := committed and tag != ""
	var broke: PackedStringArray = []
	if tag == "认了":
		broke = _surface(line)
	if card.has_meta("petty"):
		tag = "抓字眼"
	elif caught:
		tag += " · 被你说中"
	elif not said.is_empty() and reply.kind == "standard":
		tag = "圆过去了"
	if not broke.is_empty():
		tag += " · 按规则不该过"
	_say("你·对质" if not said.is_empty() else "你·简历", card.text_key, reply, tag)
	var reaction := _reaction(card, reply)
	if card.has_meta("petty"):
		# 划了一句没毛病的话去顶人：TA 心里记一笔，主管嫌你抠字眼
		candidate.loyalty = maxi(0, candidate.loyalty - SelfIntro.PETTY_LOYALTY)
		reaction = {"line": SelfIntro.PETTY_LINE, "delta": 0}
	_chief_react(card, reaction)
	if caught:
		_caught(line, broke)
	_last = {"card": card, "reply": reply, "line": line}
	_next()


## 说中了：简历那一行盖红戳“查实”，候选人当场冒汗，主管把手机放下。
## 这一下只给你先下过判断的（划线对质、红笔先圈），没下判断就问出来的，只是一个灰色的“认了”。
const CAUGHT_FIRST := "（%s把手机扣在桌上。）嗯？你再说一遍？"
const CAUGHT_AGAIN := ["有意思。接着问。", "这个记下来。", "（%s没再看手机。）"]
const CAUGHT_RULE := "等等——按规定，这个人本来就不该进面试。"
var _catches := 0

## 刚说中：主管紧接着插话时，不拿“我插一句”盖掉他放下手机那一下。
var _just_caught := false

func _caught(line: Dictionary, broke: PackedStringArray) -> void:
	_catches += 1
	_just_caught = true
	GameState.stats.called_out += 1
	resume.stamp(line.key)
	_portrait.tic = QuestionCard.escalate(_portrait.tic if _portrait.tic != "none" else "eyes")
	Sfx.stamp()
	if solo:
		return
	var said: String = CAUGHT_FIRST if _catches == 1 else CAUGHT_AGAIN[(_catches - 2) % CAUGHT_AGAIN.size()]
	if not broke.is_empty():
		said = CAUGHT_RULE
	said = said.replace("%s", interviewer_name())
	# 旁白（括号开头的）不加引号
	_chief_line.text = said if said.begins_with("（") else "“%s”" % said


## 真相浮出来：简历上那一项红笔划掉、写上真的；拿真的重新过一遍今天的规则，返回原来过了、现在过不了的那几条。
## found 里记着，评分表的疑点栏抄过去。一行只浮一次。
var found := {}

func _surface(line: Dictionary) -> PackedStringArray:
	var out: PackedStringArray = []
	if found.has(line.key):
		return out
	var t := SelfIntro.truth(candidate, line)
	if t.is_empty():
		return out
	resume.set_truth(line.key, t.show)
	if not t.patch.is_empty():
		var real := candidate.duplicate() as Candidate
		real.doc_overrides = {}
		for k: String in t.patch:
			real.set(k, t.patch[k])
		var before: Array = RuleEngine.evaluate(candidate).failed
		for rule: Rule in RuleEngine.evaluate(real).failed:
			if rule not in before:
				out.append(rule.title_key)
	found[line.key] = {"paper": line.text, "real": t.show, "broke": out}
	return out


## 坐下先让 TA 自我介绍：一句一句出在气泡里，同时打进笔录。手牌压着，简历和红笔照常能看能圈。
func _start_intro() -> void:
	intro = SelfIntro.build(candidate)
	_intro_at = 0
	_show_hand(false)
	_hand_hint.text = "先听 TA 说 · 觉得不对就划这句"
	var opening := _speech.text
	_speech.text = "%s\n你：%s" % [opening, SelfIntro.ask_text(candidate)]
	_chip("请 TA 开始 ▸", UI.YELLOW, UI.INK, _intro_step, ACTION_POS.x)


## 说下一句；绕开不说的那条不出声，直接跳过。
func _intro_step() -> void:
	while _intro_at < intro.size() and intro[_intro_at].text == "":
		_intro_at += 1
	if _intro_at >= intro.size():
		_end_intro()
		return
	var i := _intro_at
	_intro_at += 1
	var s := intro[i]
	_speech.text = "（自我介绍）\n%s：%s" % [candidate.display_name, s.text]
	_portrait.tic = "none"
	Sfx.key()
	_log_intro(i)
	_draw_intro_chips(i)


func _draw_intro_chips(i: int) -> void:
	UI.clear(_action)
	var s := intro[i]
	var x := ACTION_POS.x
	if s.key != "":
		var on: bool = underlined.has(s.key) and underlined[s.key] == s
		x = _chip("已划 ✓" if on else "划这句", UI.RED if on else Color("6b2a24"), UI.PAPER, _toggle_underline.bind(i), x) + 6
	var more := intro.slice(_intro_at).any(func(t: Dictionary) -> bool: return t.text != "")
	_chip("接着说 ▸" if more else "说完了，开始问 ▸", UI.YELLOW, UI.INK, _intro_step, x)


## 划线：这句话连上简历那一行（行上画一道红波浪），问那一行时拿它对质。再点擦掉。
func _toggle_underline(i: int) -> void:
	var s := intro[i]
	if underlined.has(s.key) and underlined[s.key] == s:
		underlined.erase(s.key)
	else:
		underlined[s.key] = s
	if underlined.has(s.key):
		resume.set_conflict(s.key, s, "没提" if s.slip == "skip" else "对不上")
	else:
		resume.clear_conflict(s.key)
	var label: Label = _intro_labels.get(i)
	if label:
		var on: bool = underlined.has(s.key)
		label.text = ("～ " if on else "") + "“%s”" % s.text
		label.add_theme_color_override("font_color", UI.RED if on else UI.INK)
	Sfx.paper()
	_draw_intro_chips(i)


func _end_intro() -> void:
	_speech.text = "%s：……就这些。" % candidate.display_name
	_hand_hint.text = ""
	_show_hand()


## 笔录最上面一段“自我介绍”，不编号、不算问。
func _log_intro(i: int) -> void:
	var empty := _transcript_list.get_node_or_null("Empty")
	if empty:
		empty.queue_free()
	var width := TRANSCRIPT_RECT.size.x - 24
	if _intro_labels.is_empty():
		UI.label(_transcript_list, "自我介绍", Vector2.ZERO, UI.INK_SOFT, width)
	var a := UI.label(_transcript_list, "“%s”" % intro[i].text, Vector2.ZERO, UI.INK, width)
	a.custom_minimum_size.x = width
	_intro_labels[i] = a
	_scroll_log()


## 问简历问出来的反应，只看得见的：自己认了水分、支支吾吾、一追问就答不上细节。
## 有没有水分本身看不见，圈不圈由玩家定。手写人物的回答不贴“认了”，露不露馅写在台词里。
func _line_tag(line: Dictionary, card: QuestionCard, reply: Dictionary, followup: bool) -> String:
	var key := String(card.id) + ("+" if followup else "")
	var tag := ""
	if reply.kind == "flaw":
		tag = "支吾"
	elif followup and reply.kind == "standard":
		tag = "答不上"
	elif not followup and reply.kind == "honest" and not candidate.answers.has(key) and ResumeQuestions.padded(candidate, line):
		tag = "认了"
	if tag != "":
		resume.mark(line.key, tag)
	return tag


## 奇葩没手写的那几问照常按属性答，前面贴一句 TA 的小动作；轮着贴，读档重来也一样。
func _flavor(reply: Dictionary, key: String) -> Dictionary:
	if candidate.asides.is_empty() or candidate.answers.has(key):
		return reply
	var aside := candidate.asides[transcript.size() % candidate.asides.size()]
	var out := reply.duplicate()
	out.text = "%s%s" % [aside, reply.text]
	return out


func _say(who: String, question: String, reply: Dictionary, tag := "") -> void:
	var speaker := "你" if who.begins_with("你") else who
	_speech.text = "%s：%s\n%s：%s" % [speaker, question, candidate.display_name, reply.text]
	_portrait.tic = reply.tic
	Sfx.key()
	_log(who, question, reply.text, tag)


## 笔录上打一行；纸满了往上卷，新的一行总在眼前。
func _log(who: String, question: String, said: String, tag := "") -> void:
	transcript.append({"who": who, "question": question, "reply": said})
	var empty := _transcript_list.get_node_or_null("Empty")
	if empty:
		empty.queue_free()
	var width := TRANSCRIPT_RECT.size.x - 24
	var entry := VBoxContainer.new()
	entry.add_theme_constant_override("separation", 0)
	_transcript_list.add_child(entry)
	var q := UI.label(entry, "Q%d %s：%s" % [transcript.size(), who, _clip(question, 40)], Vector2.ZERO, UI.INK_SOFT, width)
	q.custom_minimum_size.x = width
	var a := UI.label(entry, "“%s”" % _clip(said, 60), Vector2.ZERO, UI.INK, width)
	a.custom_minimum_size.x = width
	if tag != "":
		UI.label(entry, "▲ " + tag, Vector2.ZERO, InterviewResume.tag_color(tag), width)
	_draw_tabs()
	_scroll_log()


## 笔录卷到最底下：新的一行总在眼前。纸翻在背面时没有高度，翻过来再卷一次。
func _scroll_log() -> void:
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
	var x := _chip("追问：" + _clip(card.followup_text, 17), UI.YELLOW, UI.INK, follow_up, ACTION_POS.x)
	_actions_tip(card.followup_text)
	_chip("不追问", Color.TRANSPARENT, UI.TEXT_DIM, _skip_follow_up, x + 6)


## 气泡下面的小签：一块底色加字，返回右边界，下一个签接着往右排。
func _chip(text: String, bg: Color, fg: Color, on_press: Callable, x: float) -> float:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.content_margin_left = 7
	box.content_margin_right = 7
	box.content_margin_top = 1
	box.content_margin_bottom = 1
	var hover := box.duplicate()
	hover.bg_color = bg.lightened(0.2) if bg.a > 0 else Color(1, 1, 1, 0.08)
	b.add_theme_stylebox_override("normal", box)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	b.add_theme_color_override("font_color", fg)
	b.add_theme_color_override("font_hover_color", fg if bg.a > 0 else UI.TEXT)
	b.add_theme_color_override("font_pressed_color", fg)
	b.position = Vector2(x, ACTION_POS.y)
	b.pressed.connect(on_press)
	_action.add_child(b)
	b.size = b.get_combined_minimum_size()
	return x + b.size.x


## 追问签上写不下的，鼠标停上去看全句。
func _actions_tip(full: String) -> void:
	for child in _action.get_children():
		if child is Button:
			child.tooltip_text = full
			return


func _skip_follow_up() -> void:
	_last = {}
	_next()


func follow_up() -> void:
	_just_caught = false
	var card: QuestionCard = _last.card
	var first: Dictionary = _last.reply
	var line: Dictionary = _last.get("line", {})
	_last = {}
	asked += 1
	_followups += 1
	_tick()
	# 顺着主管的违法问题往下问，你也算问了
	GameState.lawsuit_risk += card.lawsuit_risk
	var reply := _flavor(card.follow_up(candidate, first), String(card.id) + "+")
	var cracks := candidate.crack_lines
	if _followups <= cracks.size():
		# 背得再熟，追到第二次就接不住了；第一层的完美回答主管全加了分，这里他在回消息
		var last := _followups == cracks.size()
		reply = {"text": cracks[_followups - 1], "tic": "shake" if last else "sweat", "kind": "flaw", "strong": first.strong}
		if last:
			GameState.expose(candidate)
	var tag := "" if line.is_empty() else _line_tag(line, card, reply, true)
	var broke: PackedStringArray = []
	var caught := false
	var truth := {} if line.is_empty() else SelfIntro.truth(candidate, line)
	if line.get("key", "") in _confronted and not truth.is_empty() and not found.has(line.key) \
			and _followups > cracks.size() and not candidate.answers.has(String(card.id) + "+"):
		# 对质完了再追一句：刚才圆的、支吾的，这下圆不住了，自己把真的说出来
		reply = {"text": "（TA 不说话了。过了一会儿。）" + truth.confess, "tic": "shake", "kind": "honest", "strong": first.strong}
		tag = "破防"
		caught = true
	if tag in ["认了", "破防"]:
		broke = _surface(line)
	if not caught and tag != "" and line.key in _confronted:
		caught = true
	if caught:
		tag += " · 被你说中"
	if not broke.is_empty():
		tag += " · 按规则不该过"
	_say("追问", card.followup_text, reply, tag)
	var reaction: Dictionary = card.lead_followup_reaction(reply, _followups) if lead else card.chief_followup_reaction(reply, _followups)
	if tag.begins_with("破防"):
		# 被拆穿的人不该因为“说了实话”加分；这一下主管只看着，不动表
		reaction = {"line": "", "delta": 0}
	_chief_react(card, reaction)
	if caught:
		_caught(line, broke)
	_next()


## 第一层回答时主管 / 组长的反应。
func _reaction(card: QuestionCard, reply: Dictionary) -> Dictionary:
	return card.lead_reaction(reply, asked) if lead else card.chief_reaction(reply.kind, candidate)


## 评分表和主管印象一起动：评分表玩家能改，主管印象不能。组长只动自己心里的分，不碰评分表。
func _chief_react(card: QuestionCard, reaction: Dictionary) -> void:
	if solo:
		return
	var note := ""
	var item := QuestionCard.lead_item_for(card) if lead else card.chief_item
	if item != "" and reaction.delta != 0:
		var before: int = chief_marks[item]
		chief_marks[item] = clampi(before + reaction.delta, -2, 2)
		var moved: int = chief_marks[item] - before
		if not lead:
			scorecard[item] = clampi(scorecard[item] + moved, 1, 5)
		if moved != 0:
			note = "%s%+d" % [item, moved]
			_chief_mark.add_theme_color_override("font_color", UI.GREEN_DIM if moved > 0 else UI.RED)
	_chief_mark.text = note
	_chief_line.text = "“%s”" % reaction.line if reaction.line != "" else "（在回消息。）"
	# 组长心里这一项第一次顶到 +2：真本事被问出来了，他把手上的事放下
	if lead and item != "" and note != "" and chief_marks[item] == 2 and not _lead_won:
		_lead_won = true
		_chief_line.text = "（%s把电脑合上了。）“你继续说。”" % interviewer_name()


## 主管插话：手牌压着，对话框下面只有一个按钮。
func _show_chief_cut_in() -> void:
	_show_hand(false)
	var again := _chief_asked > 0
	var line: String = "还有一个。" if again else CHIEF_CUT_IN_LINES[_rng.randi_range(0, CHIEF_CUT_IN_LINES.size() - 1)]
	if not _just_caught:
		_chief_line.text = "“%s”" % line
	_just_caught = false
	var who := _who()
	var cue: String = who.get("cut_in_again", "赵主管又抬起头：") if again else who.get("cut_in", "赵主管放下手机：")
	var said := UI.label(_action, cue, ACTION_POS + Vector2(0, 3), UI.TEXT_DIM)
	_chip("让组长问" if lead else "让主管问", UI.YELLOW, UI.INK, chief_ask, ACTION_POS.x + said.get_combined_minimum_size().x + 6)


## 主管的问题照样占名额，玩家拦不住；他自己问的，他也当场打分。问完你可以接着追问。
func chief_ask() -> void:
	_just_caught = false
	chief_slots.pop_front()
	var card: QuestionCard = chief_cards[_chief_asked]
	_chief_asked += 1
	asked += 1
	_tick()
	GameState.lawsuit_risk += card.lawsuit_risk
	var reply := _flavor(card.answer(candidate), String(card.id))
	_say(interviewer_name(), card.text_key, reply)
	var reaction := _reaction(card, reply)
	_chief_react(card, reaction)
	if reaction.line == "":
		_chief_line.text = "（问完，继续看手机。）"
	_last = {"card": card, "reply": reply}
	_next()


## 问完了，手牌收起来，桌上换成反问。
func _clear_hand() -> void:
	_hand_open = false
	resume.set_open(false)
	UI.clear(_action)
	UI.clear(_hand_view)
	_hand_hint.text = ""


func _show_candidate_ask() -> void:
	if _asks.is_empty():
		_prepare_asks()
	if _asks.is_empty():
		_show_scorecard()
		return
	var question := _asks[_ask_index]
	_tick(_now() if timed else _questions_end)
	_chief_mark.text = ""
	_clear_hand()
	UI.clear(_side)
	var top := END_TOP
	var box := UI.panel(_side, Rect2(END_X, top, END_WIDTH, 0), UI.PAPER, UI.BLACK)
	var opener := "你：“你有什么想问我们的？”" if _ask_index == 0 else "%s：“那……我还能再问一个吗？”" % candidate.display_name
	UI.label(_side, opener, Vector2(END_X + 10, top + 6), UI.INK_SOFT)
	var asked_line := UI.label(_side, "%s：%s" % [candidate.display_name, question.asked_by(candidate.is_intern)], Vector2(END_X + 10, top + 24), UI.INK, END_WIDTH - 20)
	var y := top + 24.0 + asked_line.get_line_count() * 15.0 + 8.0
	for choice: String in ["lie", "safe", "truth"]:
		var b := UI.text_button(_side, "“%s”" % question.get(choice), Rect2(END_X + 10, y, END_WIDTH - 20, 26), answer_candidate.bind(choice))
		y += b.size.y + 4.0
	box.size.y = y + 4.0 - top


## 社会人只问当天那一题；在校生青涩，想到什么问什么，问一到两个。
func _prepare_asks() -> void:
	var day_ask := GameState.config.candidate_ask
	if candidate.is_intern:
		var before := GameState.reply_log.map(func(r: Dictionary) -> String: return r.question)
		_asks = StudentAsks.for_candidate(candidate, GameState.day, day_ask, before)
	elif day_ask:
		_asks = [day_ask]
	_ask_index = 0


func answer_candidate(choice: String) -> void:
	var question := _asks[_ask_index]
	var text: String = question.get(choice)
	var student := candidate.is_intern
	GameState.record_reply(candidate, question, choice, text)
	var response := ""
	match choice:
		"lie":
			_promise = text if _promise == "" else _promise + "；" + text
			_loyalty_hit = maxi(_loyalty_hit, LIE_LOYALTY_HIT)
			response = "哇，真的吗！那太好了！" if student else "太好了，这正是我想要的。"
			if not solo:
				_chief_line.text = "（看了你一眼，没说话。）" if lead else "（点了点头。）"
		"safe":
			_loyalty_hit = maxi(_loyalty_hit, SAFE_LOYALTY_HIT)
			response = "哦哦……好的，谢谢老师。" if student else "……明白了。"
			if not solo:
				_chief_line.text = "（低头记了一笔。）" if lead else "“滴水不漏。”"
		"truth":
			if not solo:
				GameState.boss_trust -= 1
				_chief_line.text = "“说得对。这话别让赵主管听见。”" if lead else "“这话，下来我们单独聊。”"
			if candidate.ability >= WALK_OUT_ABILITY:
				var leave := "啊……这样啊。谢谢您跟我说实话，我回去再想想。\n（TA 把简历收回书包，走了。）" if student else "谢谢，我再考虑一下。\n（TA 合上笔记本，走了。）"
				_speech.text = "你：%s\n\n%s：%s" % [text, candidate.display_name, leave]
				_show_walk_out()
				return
			response = "啊？……没、没关系，我能接受的。" if student else "……没关系，我能接受。"
	_speech.text = "你：%s\n\n%s：%s" % [text, candidate.display_name, response]
	_ask_index += 1
	if _ask_index < _asks.size():
		_show_candidate_ask()
	else:
		_show_scorecard()


func _show_walk_out() -> void:
	UI.clear(_side)
	UI.panel(_side, Rect2(END_X, 220, END_WIDTH, 96), UI.PAPER, UI.BLACK)
	UI.label(_side, "评分表用不上了。\nHC 还空着。", Vector2(END_X + 10, 230), UI.INK)
	UI.button(_side, "送客", Rect2(END_X + 10, 274, END_WIDTH - 20, 30), finished.emit)


## 评分表主管已经填好了（他当场加减的分），你手里的红笔只能改一处：改了签你的名，留任期满那天对账。
## 点另一行的数，等于把红笔挪过去，前一处还原；点回主管原来的数，就是不改了。
func _show_scorecard() -> void:
	if _filled.is_empty():
		_filled = scorecard.duplicate()
	_tick(_now() + WRAP_MINUTES / 2 if timed else _scorecard_at)
	UI.clear(_side)
	var top := END_TOP
	UI.panel(_side, Rect2(END_X, top, END_WIDTH, 196), UI.PAPER, UI.BLACK)
	var who := "赵主管开会，没来，表是空的" if lead else "%s填好了" % interviewer_name()
	if solo:
		who = "你单独面的，表是空的"
	UI.label(_side, "老板评分表（%s）" % who, Vector2(END_X + 10, top + 6), UI.INK)
	var need: String = chief_need().get("item", "")
	var y := top + 26.0
	for item: String in SCORE_ITEMS:
		var edited: bool = hr_edit.get("item", "") == item
		UI.label(_side, item + ("★" if item == need else ""), Vector2(END_X + 10, y + 4), UI.RED if item == need else UI.INK)
		UI.label(_side, SCORE_HINTS[item], Vector2(END_X + 78, y + 4), UI.INK_SOFT)
		for score in range(1, 6):
			var rect := Rect2(END_X + 122 + score * 28, y, 25, 24)
			var b := UI.button(_side, str(score), rect, set_score.bind(item, score))
			b.toggle_mode = true
			b.button_pressed = scorecard[item] == score
			# 主管原来填的那格，被你改掉以后划一道红线
			if edited and _filled[item] == score:
				var strike := UI.panel(_side, Rect2(rect.position + Vector2(3, 11), Vector2(rect.size.x - 6, 2)), UI.RED)
				strike.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if edited:
			UI.label(_side, "✎", Vector2(END_X + 296, y + 4), UI.RED)
		y += 28.0
	var hint := "你单独面的，表不用填 · 只决定录不录" if solo else "表是%s填的 · 你只决定录不录" % interviewer_name()
	UI.label(_side, hint, Vector2(END_X + 14, top + 138), UI.INK_SOFT)
	_draw_doubts(top)
	if lead:
		_draw_lead_verdict(top)
	UI.button(_side, "录用", Rect2(END_X + 10, top + 156, 140, 34), decide.bind(true))
	UI.button(_side, "不录用", Rect2(END_X + 162, top + 156, 140, 34), decide.bind(false))


## 评分表右边一栏：简历上红笔圈过的行，原样抄过来。
func _draw_doubts(top: float) -> void:
	var x := END_X + 330
	UI.label(_side, "疑点（红笔）", Vector2(x, top + 26), UI.RED)
	var doubts := resume.doubt_texts()
	for key: String in underlined:
		if not found.has(key):
			doubts.append("嘴上：" + String(underlined[key].said))
	# 查实的放最前面：划掉的、真的、违了哪条
	var facts: PackedStringArray = []
	for key: String in found:
		var f: Dictionary = found[key]
		facts.append("查实：%s → %s" % [_clip(f.paper, 10), f.real])
		for rule: String in f.broke:
			facts.append("  违反：" + rule)
	facts.append_array(doubts)
	doubts = facts
	if doubts.is_empty():
		UI.label(_side, "没圈。", Vector2(x, top + 44), UI.INK_SOFT)
		return
	var y := top + 44.0
	for text in doubts:
		var l := UI.label(_side, "○ " + _clip(text, 24), Vector2(x, y), UI.INK, END_WIDTH - 340)
		y += 15.0 * l.get_line_count()
		if y > top + (96 if lead else 150):
			break


## 组长不填表，直说：便签上那一项他心里够了就要。规则让不让过，他不管。
func _draw_lead_verdict(top: float) -> void:
	var x := END_X + 330
	var want := is_chief_pick()
	UI.panel(_side, Rect2(x - 4, top + 112, END_WIDTH - 334, 1), UI.INK_SOFT)
	var line := "%s：“%s”" % [interviewer_name(), "这个人我要。" if want else "我们组不要。"]
	UI.label(_side, line, Vector2(x, top + 118), UI.GREEN_DIM if want else UI.RED, END_WIDTH - 340)


## 砍减版：表是主管填的，你只决定录不录（红笔改分、留任期满对账拿掉了）。点了也不改，重画一遍把按下去的那格弹回来。
func set_score(_item: String, _score: int) -> void:
	_show_scorecard()


func decide(hire: bool) -> void:
	if timed:
		GameState.stats.clock = _now() + WRAP_MINUTES
		GameState.stats.held = int(GameState.stats.held) + (0 if solo else 1)
	var pick := is_chief_pick()
	var evidence := {"found": found.keys(), "caught": _catches}
	if hire:
		GameState.add_hire(candidate, scorecard, _promise, _loyalty_hit, pick, "你" if solo else interviewer_name(), hr_edit.duplicate(), solo, evidence)
		if pick:
			GameState.stats.chief_picks.append(candidate.display_name)
		Sfx.stamp()
	else:
		GameState.add_reject(candidate, evidence, pick)
	finished.emit()


## 墙上的钟：开场 15:00，每问一题往后走，反问 17:30，评分表 17:45，交表就是 18:00 下班。
## 右上角的方块是问题额度：问掉一问亮一格。
func _tick(minutes := -1) -> void:
	if timed:
		_timed_tick(_now() if minutes < 0 else minutes)
		return
	if minutes < 0:
		minutes = _start + int(float(_questions_end - _start) * asked / questions_allowed)
	_header.text = "%02d:%02d 面试 · %s · %s" % [minutes / 60, minutes % 60, candidate.display_name, candidate.applied_position]
	UI.clear(_quota)
	var x := 630.0 - questions_allowed * 10.0
	for i in questions_allowed:
		UI.panel(_quota, Rect2(x + i * 10, 5, 8, 8), UI.YELLOW if i < asked else Color("46524d"), UI.BLACK)



# ---------------------------------------------------------------- 按组招的日子：钟按实际走

## 这一场到现在几点：开场 + 组长耽误的 + 每问 10 分钟 + 每次追问多 5 分钟。
func _now() -> int:
	return _start + _waited + asked * QUESTION_MINUTES + _followups * FOLLOWUP_EXTRA


## 后面还有几场正式面试（不含这一场）。
func _sessions_left() -> int:
	if solo:
		return GameState.sessions.size() if not GameState.sessions.is_empty() else mini(GameState.interviewees.size(), GameState.MAX_SESSIONS)
	return maxi(0, GameState.sessions.size() - slot - 1)


func _timed_tick(minutes: int) -> void:
	var total := GameState.sessions.size()
	var which := "破格" if solo else ("第%d场/共%d场" % [slot + 1, total] if total > 1 else "")
	var team := _team.team if _team and _team.team != "" else candidate.applied_position
	var parts := PackedStringArray([which] if which != "" else [])
	parts.append_array([candidate.display_name, team])
	_header.text = "%s 面试 %s" % [GameState.clock_text(minutes), " · ".join(parts)]
	_header.add_theme_color_override("font_color", UI.RED if minutes >= GameState.CLOCK_OUT else UI.GREEN)
	# 这一场剩下的问题 + 收尾，再加后面每场一个钟头，最早 18:00
	var left := maxi(0, questions_allowed - asked) * QUESTION_MINUTES + WRAP_MINUTES
	var eta := maxi(GameState.CLOCK_OUT, minutes + left + _sessions_left() * (QUESTION_MINUTES * QUESTIONS_ALLOWED + WRAP_MINUTES))
	if _eta == null:
		_eta = UI.label(self, "", Vector2(392, 2), UI.YELLOW)
	_eta.text = "预计下班 " + GameState.clock_text(eta)
	UI.clear(_quota)
	var x := 630.0 - questions_allowed * 10.0
	for i in questions_allowed:
		UI.panel(_quota, Rect2(x + i * 10, 5, 8, 8), UI.YELLOW if i < asked else Color("46524d"), UI.BLACK)
	if lead and not _mid_delay_done and _who().get("delay", {}).get("at", "") == "mid" and asked >= questions_allowed / 2 and not _seen_lead_today():
		_delay()
	if minutes >= GameState.CLOCK_OUT:
		_wife_texts(minutes)


## 组长那边的事：等发布、被告警叫走、被王总叫出去。钟往后拨，气泡里写一句。一个组长一天只出一次这种事。
func _delay() -> void:
	var d: Dictionary = _who().get("delay", {})
	if d.is_empty():
		return
	if d.get("at", "") == "mid":
		if _mid_delay_done:
			return
		_mid_delay_done = true
	_waited += int(d.get("minutes", 0))
	_chief_line.text = "（%s）" % d.get("line", "")
	_tick()


## 过了六点，老婆发来消息；过了七点又一条。只看，不能回：你在面试。
func _wife_texts(minutes: int) -> void:
	var late := minutes >= GameState.CLOCK_OUT + 60
	var key := "wife_late" if late else "wife_six"
	if GameState.stats.get(key, false) and _phone_note:
		return
	GameState.stats[key] = true
	var line := "饭我先热上了。你几点？" if late else "几点回？孩子等你吃饭。"
	if _phone_note:
		_phone_note.queue_free()
	_phone_note = Control.new()
	_phone_note.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_phone_note)
	UI.panel(_phone_note, PHONE_RECT, UI.BLACK, UI.GREEN_DIM)
	UI.label(_phone_note, "老婆 " + GameState.clock_text(minutes), PHONE_RECT.position + Vector2(5, 2), UI.GREEN)
	UI.label(_phone_note, line, PHONE_RECT.position + Vector2(5, 19), UI.TEXT, PHONE_RECT.size.x - 10)
