class_name ExitTalk extends Control
## 离职谈话（第三个月起）：倒过来的面试。面试结束以后的傍晚，对面坐的是你招进来的人、你的同事。
## TA 问你三个问题，你每个问题从话术、敷衍、实话里挑一句（和候选人反问是一个意思，反过来用）。
## 后果也反过来：话术签得快，王总满意，诉讼风险 +1；实话签得慢甚至不签，公司多掏钱，“补偿超预算”从你绩效里扣。
## 钟照走：开场 5 分钟，话术 4 分钟、敷衍 3 分钟、实话 8 分钟。谈得越细，下班越晚（GameState.stats.clock）。
## 你念过的每一句记进 GameState.talk_log；话术那几句，第四个月底 HireBot 用来谈你。
## 一场的数据在 DayConfig.exit_talks，见那里的注释；questions 写 template 的用下面三句默认的。

signal finished

const INTRO_MINUTES := 5
const STYLE_MINUTES := {"lie": 4, "safe": 3, "truth": 8}
const STYLE_NAMES := {"lie": "话术", "safe": "敷衍", "truth": "实话"}
## 默认三问：为什么是我、补偿怎么算、我能不签吗。{criteria} 换成名单上的那条标准。
const TEMPLATES := {
	"why": {"q": "为什么是我？", "options": [
		{"style": "lie", "label": "这是公司业务调整，不针对任何人。", "reply": "……业务调整。行。", "effects": {"lawsuit": 1}},
		{"style": "safe", "label": "名单不是我定的。", "reply": "那是谁定的？……算了，你也不知道。"},
		{"style": "truth", "label": "名单是按{criteria}拉的。", "reply": "……原来是这个。我还以为是我活干得不好。", "effects": {"conscience": 1}},
	]},
	"comp": {"q": "补偿怎么算？", "options": [
		{"style": "lie", "label": "N+1，法定标准，一分不少。", "reply": "那我签哪儿？", "effects": {"lawsuit": 1}},
		{"style": "safe", "label": "算式在协议第二页。", "reply": "（TA 翻到第二页，看了很久。）"},
		{"style": "truth", "label": "基数用的是降薪后的。该按前十二个月的平均算，你可以要。", "reply": "……谢谢。我回去找人算一下。", "effects": {"conscience": 1, "fine": 50, "trust": -1}},
	]},
	"sign": {"q": "我能不签吗？", "options": [
		{"style": "lie", "label": "这是对你最好的安排。今天签，多给半个月。", "reply": "……好吧。笔给我。", "effects": {"lawsuit": 1}},
		{"style": "safe", "label": "你回去想想。", "reply": "那我明天再来。"},
		{"style": "truth", "label": "能。不签，公司就得走正式程序，那个更麻烦的是公司。", "reply": "（TA 把笔放下了。）", "effects": {"conscience": 1}},
	]},
}

const DESK_TOP := 152.0
const SPEECH_RECT := Rect2(144, 24, 318, 92)
const PORTRAIT_POS := Vector2(8, 22)

var talk: Dictionary
var _clock := 0
var _q := 0
var _styles: Array[String] = []
var _header: Label
var _speech: Label
var _options: Array[Button] = []
var _log: VBoxContainer
var _next: Button
## 选项里写了 outcome 的（韩蕾那一问），这一场签没签按它算。
var _forced := ""


func _ready() -> void:
	talk = GameState.next_talk()
	GameState.stats.talks.append({"id": talk.get("id", ""), "name": talk.get("name", ""), "outcome": ""})
	_clock = maxi(GameState.CLOCK_OUT, int(GameState.stats.clock))
	_build()
	_spend(INTRO_MINUTES)
	_say(talk.get("opener", "（%s 坐下。桌上是一份协议。）" % talk.name))
	_next = UI.button(self, "开始", Rect2(520, 328, 110, 24), _ask)


func _build() -> void:
	UI.panel(self, Rect2(0, 0, 640, DESK_TOP), UI.WALL)
	UI.panel(self, Rect2(0, 0, 640, 18), UI.DESK_DARK)
	_header = UI.label(self, "", Vector2(10, 2), UI.GREEN)
	var portrait := PortraitView.new()
	var face := int(talk.get("seed", hash(talk.get("name", ""))))
	if talk.has("female"):
		face = PortraitFactory.seed_for(face, talk.female)
	portrait.setup(face, 2)
	portrait.position = PORTRAIT_POS
	add_child(portrait)
	UI.panel(self, SPEECH_RECT, UI.PAPER)
	_speech = UI.label(self, "", SPEECH_RECT.position + Vector2(9, 5), UI.INK, SPEECH_RECT.size.x - 18)
	_speech.max_lines_visible = 5
	# 右上：TA 的人事档案一行
	UI.label(self, talk.get("name", ""), Vector2(474, 26), UI.TEXT)
	UI.label(self, talk.get("info", ""), Vector2(474, 44), UI.TEXT_DIM, 156)
	UI.panel(self, Rect2(0, DESK_TOP, 640, 360 - DESK_TOP), UI.DESK)
	UI.panel(self, Rect2(0, DESK_TOP, 640, 2), UI.DESK_DARK)
	# 左边：协议第二页
	# 协议书：米色厚纸，左上两颗订书钉，右下折角
	UI.panel(self, Rect2(12, 160, 220, 190), UI.PAPER_DEAL, UI.INK_SOFT)
	UI.sprite(self, "res://assets/desk/staple.png", Vector2(15, 163))
	UI.sprite(self, "res://assets/desk/staple.png", Vector2(15, 168))
	var corner := Polygon2D.new()
	corner.polygon = PackedVector2Array([Vector2(222, 350), Vector2(232, 350), Vector2(232, 340)])
	corner.color = UI.DESK
	add_child(corner)
	UI.sprite(self, "res://assets/desk/dogear.png", Vector2(222, 340))
	UI.label(self, "协商解除劳动合同协议书（第二页）", Vector2(20, 166), UI.INK)
	var sheet: String = talk.get("sheet", "经济补偿：N+1\n计算基数：解除前月基本工资（降薪后）\n支付方式：签署后次月发放\n乙方确认：本协议系双方真实意思表示。\n\n甲方（盖章）：蜂巢科技\n乙方（签字）：＿＿＿＿＿＿")
	UI.label(self, sheet, Vector2(20, 186), UI.INK_SOFT, 204)
	# 右边：你说过的话（笔录）
	UI.panel(self, Rect2(244, 160, 386, 162), UI.PAPER_DIM, UI.INK_SOFT)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(250, 164)
	scroll.size = Vector2(376, 154)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	_log = VBoxContainer.new()
	_log.custom_minimum_size.x = 364
	_log.add_theme_constant_override("separation", 3)
	scroll.add_child(_log)
	UI.label(_log, "谈话记录　附件话术：老周（去年）", Vector2.ZERO, UI.INK_SOFT)


func _spend(minutes: int) -> void:
	_clock += minutes
	GameState.stats.clock = _clock
	_header.text = "%s 离职谈话 · %s" % [GameState.clock_text(_clock), talk.get("name", "")]
	_header.add_theme_color_override("font_color", UI.RED if _clock >= GameState.CLOCK_OUT + 60 else UI.GREEN)


func _say(text: String) -> void:
	_speech.text = text


func _note(text: String, color := UI.INK) -> void:
	var l := UI.label(_log, text, Vector2.ZERO, color, 364)
	l.custom_minimum_size.x = 364


func _questions() -> Array:
	var all: Array = talk.get("questions", [{"template": "why"}, {"template": "comp"}, {"template": "sign"}])
	return all.filter(func(q: Dictionary) -> bool: return GameState.family_matches(q.get("when", "")))


func _question(i: int) -> Dictionary:
	var q: Dictionary = _questions()[i]
	if q.has("template"):
		var base: Dictionary = TEMPLATES[q.template].duplicate(true)
		base.merge(q, true)
		# 每个人可以改自己那几句回话：replies {"why_truth": "..."}
		for o: Dictionary in base.options:
			var key := "%s_%s" % [q.template, o.style]
			if talk.get("replies", {}).has(key):
				o.reply = talk.replies[key]
			o.label = String(o.label).replace("{criteria}", talk.get("criteria", "学历、年龄和工资"))
		return base
	return q


func _ask() -> void:
	_next.visible = false
	if _q >= _questions().size():
		_finish()
		return
	var q := _question(_q)
	_say("%s：%s" % [talk.name, q.q])
	_note("%s：%s" % [talk.name, q.q], UI.INK)
	var y := 330.0
	var options: Array = q.options.filter(func(o: Dictionary) -> bool: return GameState.family_matches(o.get("when", "")))
	for i in range(options.size() - 1, -1, -1):
		var o: Dictionary = options[i]
		var tag: String = STYLE_NAMES.get(o.get("style", ""), "")
		var b := UI.text_button(self, ("【%s】" % tag if tag != "" else "") + String(o.label), Rect2(244, 0, 386, 22), _choose.bind(q, o))
		y -= b.size.y
		b.position.y = y
		y -= 2.0
		_options.append(b)
	Sfx.paper()


func _choose(q: Dictionary, o: Dictionary) -> void:
	for b in _options:
		b.queue_free()
	_options = []
	var style: String = o.get("style", "safe")
	_styles.append(style)
	GameState.record_talk(talk.name, q.q, style, o.label)
	GameState.apply_effects(o.get("effects", {}))
	if o.has("outcome"):
		_forced = o.outcome
	_spend(int(o.get("minutes", STYLE_MINUTES.get(style, 4))))
	_note("你：" + String(o.label), UI.GREEN.darkened(0.4))
	var reply: String = o.get("reply", "")
	if reply != "":
		_say(reply)
		_note(reply, UI.INK_SOFT)
	Sfx.key()
	_q += 1
	_next.text = "下一句" if _q < _questions().size() else "收尾"
	_next.visible = true


## 收尾：实话说了两句以上，TA 没签；全是话术，签得飞快。
func _finish() -> void:
	var truths := _styles.count("truth")
	var lies := _styles.count("lie")
	var outcome := "refused" if truths >= 2 else "signed"
	if _forced != "":
		outcome = _forced
	var line: String
	if outcome == "refused":
		line = talk.get("refused", "TA 把协议折好，放进包里：“我回去问问。”")
	elif lies == _styles.size() and lies > 0:
		line = talk.get("signed_fast", "TA 签了。前后不到二十分钟。王总在群里回了一个“效率”。")
		GameState.boss_trust += 1
	else:
		line = talk.get("signed", "TA 签了字，把笔帽扣上，看了你一眼。")
	GameState.stats.talks.back().outcome = outcome
	GameState.family["talk_" + String(talk.get("id", ""))] = outcome
	GameState.apply_effects(talk.get("after_" + outcome, {}))
	_say(line)
	_note(line, UI.INK_SOFT)
	_next.text = "下一场" if GameState.next_talk_index() >= 0 else "下班"
	_next.visible = true
	_next.pressed.disconnect(_ask)
	_next.pressed.connect(finished.emit, CONNECT_ONE_SHOT)
