class_name SliceEnd extends Control
## 月末回顾：破产提前收尾；否则先回顾这个月见过的手写人物，再回家看门后面是什么，最后是这个月写过的话和下月预告。
## 不是最后一个月时，最后一页的按钮是“下个月”；最后一个月才收集“想玩下个月吗”。

signal finished

## 夫妻感情的分档：月底回家看到什么。感情从第一个月一路累积，每个月的分档跟着抬。
## 第 1 月回家那一幕也加减感情（满打满算约 +31）；第 2 月再加约 +26。
const HOME_TIERS := {
	1: {"warm": 12, "cold": 0, "gone": -10},
	2: {"warm": 22, "cold": 2, "gone": -12},
}

## 每个月的回家、你爸的话和下月预告。
const MONTH_TEXT := {
	1: {
		"warm": "18:00 下班，你到家快七点了。桌上扣着一碗饭，还是热的。\n孩子从房间冲出来：“爸爸！我作文写的你！”本子上写着：我的爸爸是 HR，他每天帮别人找工作。\n老婆坐在你对面看你吃。\n“下个月的事，下个月再说。”",
		"cold": "你到家七点。老婆在阳台打电话，看见你进门，挂了。\n“吃了吗？”“吃了。”\n孩子在写作业，抬头叫了声爸爸，又低下头去。\n九点，孩子房间的灯关了。",
		"gone": "你到家七点，客厅的灯没开。\n饭桌上压着孩子的作文本，题目是《我的爸爸》，只写了一行：我爸爸很忙。\n老婆和孩子睡在一个房间，门关着。\n你点开手机，你们的对话停在她那边。",
		"left": "茶几上压着一张纸：\n“我带孩子去我妈那住一阵。你爸那边我会去看。你先忙你的。”\n你在星桥谈过几百个人，没想过要跟她谈。",
		"mail": "下月邮件预览：“降本增效。从下个月起招程序员，入门岗要 5 年经验。我们是一家人。”",
	},
	2: {
		"warm": "你到家七点。孩子在客厅给你演示编程班的作业：一只小猫走迷宫，走到第三格就撞墙。\n“老师说下节课教我们让 AI 帮它找路。”\n老婆在旁边削苹果，削完递给你一半。\n“这个月比上个月还累吧？”",
		"cold": "你到家七点。老婆把饭热了一下就回房间对账了，计算器按得很响。\n孩子在平板上看编程班的回放，耳机戴着。\n你们三个人，各自亮着一块屏幕。",
		"gone": "你到家七点。门口只有你一双拖鞋摆着。\n老婆在孩子房间陪他睡，门没关严，你站在门口听了一会儿。\n她在给孩子讲编程班的作业，讲得比你耐心。",
		"left": "家里很整齐，整齐得像没人住。\n冰箱上贴着一张便利贴：“孩子这周在我妈那。编程班的钱我交了。”\n你在冰箱前站了很久，想起你这个月拒掉的那些人，也有人是这样一个人回家的。",
		"mail": "下月邮件预览：“降本增效第二阶段。程序员 HC 减半，空出来的用 AI 补。下个月起招高级全栈：一个人带着 AI，顶一个组。我们是一家人。”",
	},
}

## 第 2 月底还完房贷剩得比这少，老婆开始“加班”（第 3 月的伏笔）。
const LATE_SAVINGS := 300

var _lines: Control
var _month := 1


func _ready() -> void:
	_month = GameState.month()
	UI.panel(self, Rect2(0, 0, 640, 360), UI.DESK_DARK)
	if GameState.is_bankrupt():
		UI.label(self, "存款归零", Vector2(40, 30), UI.RED)
		var wife := "老婆：卡刷不出来了。没事，我那还有一点。你先回来，我们一起想办法。" if GameState.marriage >= _tiers().warm \
			else "老婆：卡刷不出来了。今晚你别回来了，我带孩子回我妈家。"
		UI.label(self, wife, Vector2(40, 56), UI.TEXT, 560)
		UI.label(self, "（破产结局 · 切片结束）", Vector2(40, 92), UI.TEXT_DIM)
		UI.button(self, "回到标题", Rect2(260, 300, 120, 24), finished.emit)
		return
	_show_people()


func _tiers() -> Dictionary:
	return HOME_TIERS.get(_month, HOME_TIERS[1])


func is_last_month() -> bool:
	return GameState.day >= GameState.LAST_DAY


## 第一页：这个月的手写人物各自去了哪里，以及抽屉里的信封、家里收下的东西。
func _show_people() -> void:
	_lines = Control.new()
	add_child(_lines)
	UI.label(_lines, "这个月，你记得这些人吗？", Vector2(40, 18), UI.GREEN)
	var y := 44.0
	var first := (_month - 1) * GameState.DAYS_PER_MONTH + 1
	for d in range(first, first + GameState.DAYS_PER_MONTH):
		for c: Candidate in RuleEngine.load_day(d).story_candidates:
			if c.skip_when != "" and GameState.echo_matches(c.skip_when):
				continue
			var outcome := GameState.story_outcome(String(c.id))
			var key: String = outcome.verdict if outcome.verdict != "" else "unseen"
			var line: String = c.epilogue.get(key, "")
			if line == "" and key == "hired":
				line = c.epilogue.get("pass", "")
			if key == "unseen":
				line = "这份简历你没来得及看。"
			if outcome.chief_pick:
				line += "（赵主管推荐）"
			var who := UI.label(_lines, "第 %d 天　%s" % [d, c.display_name], Vector2(40, y), UI.TEXT)
			who.size.x = 120
			var text := UI.label(_lines, line.replace("{reason}", outcome.reason.trim_suffix("。")), Vector2(164, y), UI.TEXT_DIM, 436)
			y += maxf(16.0, text.get_line_count() * 15.0) + 5.0
	y += 4.0
	for note in _kickback_notes():
		var l := UI.label(_lines, note, Vector2(40, y), UI.YELLOW, 560)
		y += maxf(16.0, l.get_line_count() * 15.0) + 4.0
	UI.button(_lines, "继续", Rect2(484, 328, 110, 24), _show_home)


func _kickback_notes() -> Array:
	var notes := []
	for k: Dictionary in GameState.kickbacks_in(_month):
		match k.get("candidate_id", ""):
			"story_headhunter":
				notes.append("抽屉里有个信封，¥%d。%s 发来微信：“亲戚家孩子下个月也找工作，老规矩。”" % [k.amount, k.from] if k.taken \
					else "%s 发来微信：“行，我记住你了。”" % k.from)
			"story_lizhe_cousin":
				notes.append("抽屉里又多了一个信封，¥%d。这回是李哲的表哥。" % k.amount if k.taken \
					else "李哲的表哥那个信封，你原样退了回去。他爸没再发微信。")
			"story_xiaoliu":
				notes.append("小刘家那张购物卡，¥%d，你拿去交了孩子的编程班。" % k.amount if k.taken \
					else "小刘家的烟和购物卡，你爸替你拎回去了。回来的时候他在楼下站了很久才上楼。")
	return notes


## 第二页：下班回家。老婆发的消息你回了多少，决定门后面是什么。
func _show_home() -> void:
	_lines.queue_free()
	_lines = Control.new()
	add_child(_lines)
	var d := DateUtil.parse(GameState.today)
	UI.label(_lines, "%d 月 %d 日，晚上" % [d.y, d.z], Vector2(40, 18), UI.GREEN)
	var counts := GameState.text_counts(_month)
	var y := 46.0
	var facts := "这个月她上班时给你发了 %d 条消息，你回了 %d 条。" % [counts.got, counts.replied]
	facts += _month_facts()
	y += UI.label(_lines, facts, Vector2(40, y), UI.TEXT_DIM, 560).get_line_count() * 16.0 + 18.0
	var m := GameState.marriage
	var tiers := _tiers()
	var text: Dictionary = MONTH_TEXT.get(_month, MONTH_TEXT[1])
	var scene := ""
	var tag := ""
	if m >= tiers.warm:
		scene = text.warm
	elif m >= tiers.cold:
		scene = text.cold
	elif m > tiers.gone:
		scene = text.gone
	else:
		scene = text.left
		tag = "（婚姻结局）"
	UI.label(_lines, scene, Vector2(40, y), UI.TEXT, 560)
	# 标签刚建好时还没排版，行数按字数估：一行约 34 个字。
	for line in scene.split("\n"):
		y += ceili(line.length() / 34.0) * 20.0
	y += 26.0
	UI.label(_lines, _dad_line(), Vector2(40, y), UI.TEXT_DIM, 560)
	if tag != "":
		UI.label(_lines, tag, Vector2(40, 300), UI.TEXT_DIM)
	UI.button(_lines, "继续", Rect2(484, 328, 110, 24), _show_summary)


func _month_facts() -> String:
	match _month:
		1:
			if GameState.family.has("d4_left") or GameState.decision_log.any(func(e: Dictionary) -> bool: return e.day == 4):
				return "\n3 月 5 日上午，她问你能不能早点回去。" + ("你走了。" if GameState.family.get("d4_left", "") == "yes" else "你没走。")
		2:
			# 钱不够的月底，她开始“加班”（第 14 天的短信同一个条件，见 day_14.tres）
			if GameState.savings < LATE_SAVINGS:
				return "\n还完房贷，卡里剩 ¥%d。今晚她说要加班，十一点才到家。" % GameState.savings
			return "\n还完房贷，卡里剩 ¥%d。" % GameState.savings
	return ""


## 你爸的话：第 1 月留话头，第 2 月看小刘的事你怎么办的。
func _dad_line() -> String:
	if _month == 1:
		return "手机亮了一下，是你爸：“我回自己那边住了，离得近，有事喊我。小刘那边，下个月你给个准话。”"
	var verdict: String = GameState.story_outcome("story_xiaoliu").verdict
	match verdict:
		"hired":
			return "你爸打来电话，声音很亮：“小刘请我吃了顿饭，说你够意思。他儿子说你们公司伙食好。”"
		"pass":
			return "你爸打来电话：“小刘说他儿子去面了，没下文。你是不是没使劲？”你说使了。他说那就好。"
		"reject":
			return "你爸这个月没打电话来。孩子说，爷爷在楼下下棋，跟刘爷爷坐两头。"
	return "你爸发来一条语音，六十秒，你没点开。"


func _show_summary() -> void:
	_lines.queue_free()
	var names := ["", "第一个月", "第二个月", "第三个月", "第四个月"]
	UI.label(self, "%s结束　月供已扣，存款 ¥%d" % [names[mini(_month, names.size() - 1)], GameState.savings], Vector2(40, 18), UI.GREEN)
	var first := (_month - 1) * GameState.DAYS_PER_MONTH + 1
	var rejects := GameState.decision_log.filter(func(e: Dictionary) -> bool: return e.verdict == "reject" and int(e.day) >= first)
	UI.label(self, "这个月你写过的话，都存档了。共 %d 句：" % rejects.size(), Vector2(40, 40), UI.TEXT)
	var y := 60.0
	var seen := {}
	for entry: Dictionary in rejects:
		seen[entry.reason_text] = seen.get(entry.reason_text, 0) + 1
	for reason: String in seen:
		UI.label(self, "“%s” × %d" % [reason, seen[reason]], Vector2(52, y), UI.TEXT_DIM)
		y += 16.0
	y += 8.0
	var pending := GameState.hires.filter(func(h: Dictionary) -> bool: return not h.event_resolved)
	if not pending.is_empty():
		UI.label(self, "还在试用期的人：", Vector2(40, y), UI.TEXT)
		y += 18.0
		for hire: Dictionary in pending:
			UI.label(self, "%s（第 %d 天录用）—— 结果还没回来" % [hire.candidate.display_name, hire.day_hired], Vector2(52, y), UI.TEXT_DIM)
			y += 16.0
		y += 8.0
	var text: Dictionary = MONTH_TEXT.get(_month, MONTH_TEXT[1])
	var mail: String = text.mail
	if GameState.boss_promised_rule:
		mail += "\n以及：“另外，评分表满分的，HR 要手写担保书。”"
	UI.label(self, mail, Vector2(40, y), UI.YELLOW, 560)
	if not is_last_month():
		UI.button(self, "下个月", Rect2(484, 328, 110, 24), finished.emit)
		return
	# 理由和试用期名单越攒越长，问题放在最底下一行，不和上面抢位置
	UI.label(self, "想继续上下个月的班吗？", Vector2(40, 332), UI.GREEN)
	UI.button(self, "想", Rect2(364, 328, 110, 24), answer.bind(true))
	UI.button(self, "不想", Rect2(484, 328, 110, 24), answer.bind(false))


func answer(wants_next: bool) -> void:
	SaveManager.record_playtest(wants_next)
	finished.emit()
