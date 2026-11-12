class_name SliceEnd extends Control
## 月末回顾：破产提前收尾；否则先回顾这个月见过的手写人物，再回家看门后面是什么，最后是这个月写过的话和下月预告。
## 不是最后一个月时，最后一页的按钮是“下个月”；最后一个月才收集“想玩下个月吗”。

signal finished

## 夫妻感情的分档：月底回家看到什么。感情从第一个月一路累积，每个月的分档跟着抬。
## 第 1 月回家那一幕也加减感情（满打满算约 +31）；第 2 月再加约 +26。
const HOME_TIERS := {
	1: {"warm": 12, "cold": 0, "gone": -10},
	2: {"warm": 22, "cold": 2, "gone": -12},
	3: {"warm": 24, "cold": 6, "gone": -14},
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
		"warm": "你到家七点。孩子在客厅给你演示编程班的作业：一只小猫走迷宫，走到第三格就撞墙。\n“老师说下节课教它自己找路。”\n老婆在旁边削苹果，削完递给你一半。\n“这个月比上个月还累吧？”",
		"cold": "你到家七点。老婆把饭热了一下就回房间对账了，计算器按得很响。\n孩子在平板上看编程班的回放，耳机戴着。\n你们三个人，各自亮着一块屏幕。",
		"gone": "你到家七点。门口只有你一双拖鞋摆着。\n老婆在孩子房间陪他睡，门没关严，你站在门口听了一会儿。\n她在给孩子讲编程班的作业，讲得比你耐心。",
		"left": "家里很整齐，整齐得像没人住。\n冰箱上贴着一张便利贴：“孩子这周在我妈那。编程班的钱我交了。”\n你在冰箱前站了很久，想起你这个月拒掉的那些人，也有人是这样一个人回家的。",
		"mail": "下月邮件预览：“降本增效第二阶段。程序员 HC 减半，空出来的用 AI 补。下个月起招高级全栈：一个人带着 AI，顶一个组。我们是一家人。”",
	},
	3: {
		"warm": "你到家晚了。孩子还没睡，坐在沙发上等你，手里拿着平板。\n“爸爸，HireBot 是你同事吗？它是不是比你厉害？”\n老婆把他抱回房间，出来的时候说：“他今天问了我一晚上。”\n她在你旁边坐下，把手机里的记账软件给你看。“这个月我们俩，一起算。”",
		"cold": "你到家晚了。孩子已经睡了，平板压在枕头底下，屏幕上是 AI 创想课的作业。\n老婆在阳台打电话，说的是面试的事。看见你进门，她背过身去。\n茶几上摊着她那份协议，第二页折了一个角。",
		"gone": "你到家晚了。客厅的灯没开，餐桌上压着一张水电费的单子，旁边写着一个数。\n孩子房间的门关着。门上贴着一张纸：“爸爸，HireBot 是你同事吗？”\n你站在门口想了很久该怎么回。",
		"left": "家里没人。冰箱上贴着一张便利贴：“孩子这周在我妈那。英语一对一我停了。”\n便利贴下面压着她那份协议，签了字。基数那一格是降薪后的，她没改。",
		"mail": "下月邮件预览：“组织升级。HireBot 2.0 上线，招聘流程全面托管。下个月招产品经理：一个人，带着 AI，从需求做到上线。大家再坚持一下。我们是一家人。”",
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
	var first := GameState.month_first_day(_month)
	for d in range(first, GameState.month_last_day(_month) + 1):
		for c: Candidate in RuleEngine.load_day(d).story_candidates:
			if not c.is_story or GameState.story_skipped(c):
				continue
			var outcome := GameState.story_outcome(String(c.id))
			var key: String = outcome.verdict if outcome.verdict != "" else "unseen"
			if outcome.exception and key == "pass" and c.epilogue.has("exception"):
				key = "exception"
			elif key == "pass" and c.epilogue.has("exposed") and GameState.echo_matches(String(c.id) + ":exposed"):
				key = "exposed"
			var line: String = c.epilogue.get(key, "")
			if line == "" and key == "hired":
				line = c.epilogue.get("pass", "")
			if key == "pass" and outcome.unbooked:
				line = c.epilogue.get("unbooked", "你放了 TA，可那天晚上你约的是别人。")
			if key == "unseen":
				line = "这份简历你没来得及看。"
			if outcome.chief_pick:
				line += "（%s推荐）" % outcome.picked_by
			var who := UI.label(_lines, "第 %d 天　%s" % [d, c.display_name], Vector2(40, y), UI.TEXT)
			who.size.x = 120
			var text := UI.label(_lines, line.replace("{reason}", outcome.reason.trim_suffix("。")), Vector2(164, y), UI.TEXT_DIM, 436)
			y += maxf(16.0, text.get_line_count() * 15.0) + 5.0
	y += 4.0
	for note in _kickback_notes() + _work_notes():
		var l := UI.label(_lines, note, Vector2(40, y), UI.YELLOW, 560)
		y += maxf(16.0, l.get_line_count() * 15.0) + 4.0
	UI.button(_lines, "继续", Rect2(484, 328, 110, 24), _show_home)


func _kickback_notes() -> Array:
	var notes := []
	for k: Dictionary in GameState.kickbacks_in(_month):
		match k.get("candidate_id", ""):
			"story_headhunter":
				notes.append("抽屉里有个信封，¥%d。%s 发来 WChat：“亲戚家孩子下个月也找工作，老规矩。”" % [k.amount, k.from] if k.taken \
					else "%s 发来 WChat：“行，我记住你了。”" % k.from)
			"story_lizhe_cousin":
				notes.append("抽屉里又多了一个信封，¥%d。这回是李哲的表哥。" % k.amount if k.taken \
					else "李哲的表哥那个信封，你原样退了回去。他爸没再发 WChat。")
			"private_23":
				notes.append("李哲他爸的私单，一个人头 ¥%d，当天到账。收款是你自己点的。" % k.amount)
			"story_xiaoliu":
				notes.append("小刘家那张购物卡，¥%d，你拿去交了孩子的编程班。" % k.amount if k.taken \
					else "小刘家的烟和购物卡，你爸替你拎回去了。回来的时候他在楼下站了很久才上楼。")
	# 猎头：这个月放进来几个带“钱”字的，收了多少，还有多少在路上
	var passes := GameState.broker_passes(_month)
	if not passes.is_empty():
		var got := 0
		var returned := 0
		for k: Dictionary in GameState.kickbacks_in(_month):
			if k.get("broker", "") != "":
				if k.taken:
					got += int(k.amount)
				else:
					returned += 1
		var names := PackedStringArray(passes.map(func(k: Dictionary) -> String: return k.get("name", "")))
		var line := "右下角写着“钱”的简历，你放进去 %d 份：%s。" % [passes.size(), "、".join(names)]
		if got > 0:
			line += "李哲他爸转的钱，你收了 ¥%d。" % got
		if returned > 0:
			line += "退回去 %d 笔，他每次都回一个“？”。" % returned
		var pending := GameState.broker_pending().size()
		if pending > 0:
			line += "还有 %d 个人试用期没满，他说“到时候一起结”。" % pending
		notes.append(line)
	return notes


## 这个月的活：初筛系统推翻了几次；月底那张盘点表你怎么交的。
func _work_notes() -> Array:
	var notes := _exception_notes()
	var ats := GameState.ats_overrides(_month)
	if ats.agree + ats.override > 0:
		var line := "系统上线那两天，你跟它一致 %d 份。王总在周会上念了这个数。" % ats.agree
		if ats.override > 0:
			line += "你推翻了它 %d 次，判对 %d 次。这个数只有你知道。" % [ats.override, ats.ok]
		notes.append(line)
	if _month == 3:
		notes.append_array(_month3_notes())
		return notes
	match str(GameState.family.get("w16_table", "")):
		"true":
			notes.append("这个月你招了 %d 个人，月底交了一张表。表上每个人的学历、年龄都是真的。" % _hired_count())
		"fudge":
			notes.append("这个月你招了 %d 个人，月底交了一张表。表上有几格，你改过。" % _hired_count())
		"delay", "ignored":
			notes.append("这个月你招了 %d 个人。那张表你没交，王总说他自己来。" % _hired_count())
	return notes


## 破格章：这个月一次没盖，主管在月会上点你；盖过的，记下保了几个、几个干得好。按规矩筛掉、后来在别家干得好的，单列一行。
func _exception_notes() -> Array:
	var notes := []
	if GameState.month_last_day(_month) < GameState.EXCEPTION_DAY:
		return notes
	var used := GameState.exceptions_in(_month)
	var boss := "赵主管" if _month == 1 else "王总"
	var missed := GameState.blocked_rejected_in("real", _month)
	var tail := "按规则筛掉、后来在别家干得好的：%d 个。" % missed if missed > 0 else ""
	if used == 0:
		notes.append("月会上%s说：“你太按规矩办事了。”这个月，破格章你一次没用。%s" % [boss, tail])
		return notes
	else:
		var first := GameState.month_first_day(_month)
		var vouched := GameState.hires.filter(func(h: Dictionary) -> bool: return h.get("vouched", false) and int(h.day_hired) >= first)
		var good := vouched.filter(func(h: Dictionary) -> bool: return h.event_resolved and EmployeeEvents.fate(Candidate.from_dict(h.candidate)) == "praise").size()
		var line := "这个月你盖了 %d 次破格章，最后录了 %d 个。" % [used, vouched.size()]
		if not vouched.is_empty():
			line += "满了试用期、干得好的 %d 个。" % good
		notes.append(line + tail)
	return notes


## 第三个月：HireBot、离职谈话、抽屉。
const EVIDENCE_NAMES := {
	"mail_19": "王总关于“已婚未育”的邮件打印件",
	"voice_22": "王总那条六十秒语音：“她那个情况你知道，别提名单，就说岗位没了。”",
	"zhou_book": "老周的手抄规则本：每条规则旁边记着哪天、谁、怎么说的",
}


func _month3_notes() -> Array:
	var notes := []
	var talks := GameState.talk_log.filter(func(t: Dictionary) -> bool: return GameState.month_of(int(t.day)) == 3)
	if not talks.is_empty():
		var people := {}
		for t: Dictionary in talks:
			people[t.name] = true
		notes.append("这个月你谈了 %d 个人。念话术 %d 句，敷衍 %d 句，说实话 %d 句。念过的话术都存档了。" % [people.size(), GameState.talk_count("lie", 3), GameState.talk_count("safe", 3), GameState.talk_count("truth", 3)])
	if GameState.lawsuit_risk > 0:
		notes.append("法务那边的表上，你名下记着 %d 笔“风险”。你没看过这张表。" % GameState.lawsuit_risk)
	var drawer: Array = GameState.evidence.map(func(id: String) -> String: return EVIDENCE_NAMES.get(id, id))
	var envelopes := GameState.kickbacks.filter(func(k: Dictionary) -> bool: return k.taken).size()
	if not drawer.is_empty():
		notes.append("抽屉里：%s。%s" % ["；".join(PackedStringArray(drawer)), "信封也在，%d 个，压在最底下。" % envelopes if envelopes > 0 else ""])
	elif envelopes > 0:
		notes.append("抽屉里只有信封，%d 个。" % envelopes)
	notes.append("HireBot 本月为公司节省人力 0.6 人。")
	return notes


func _hired_count() -> int:
	var first := GameState.month_first_day(_month)
	return GameState.hires.filter(func(h: Dictionary) -> bool: return int(h.day_hired) >= first).size()


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
	UI.label(_lines, facts, Vector2(40, y), UI.TEXT_DIM, 560)
	for line in facts.split("\n"):
		y += ceili(line.length() / 34.0) * 16.0
	y += 18.0
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
	# 按组招的月底，下班不固定：“到家七点”换成实际钟点
	if GameState.config.team_folders and GameState.off_minutes() > GameState.CLOCK_OUT:
		scene = scene.replace("你到家七点", "你到家 " + GameState.clock_text(GameState.home_minutes()))
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
			# 钱不够的月底，她开始“加班”（第 16 天的短信同一个条件，见 day_16.tres）
			var money := "\n还完房贷，卡里剩 ¥%d。" % GameState.savings
			if GameState.savings < LATE_SAVINGS:
				GameState.family["m2_late"] = "yes"
				money = "\n还完房贷，卡里剩 ¥%d。今晚她说要加班，十一点才到家。" % GameState.savings
			return _recital() + money
		3:
			var money := "\n还完房贷，卡里剩 ¥%d。" % GameState.savings
			if GameState.family.get("m2_late", "") == "yes":
				# 四月底那几次“加班”：日子还过得去，是误会（下个月她自己说）；过不下去，就是真的
				if GameState.family_state >= -2 and GameState.marriage >= _tiers().cold:
					money += "她又说要加班。十一点半到家，身上有汽油味。她说是打车回来的。"
				else:
					money += "她又说要加班。快一点才到家。手机一直扣在桌上，亮了两次。"
			var dad := ""
			if "dad_envelope" in GameState.stats.rescues:
				dad = "\n你爸那个信封，三百，你收下了。他很高兴，走的时候把药盒忘在桌上。"
			else:
				dad = "\n你爸塞来一个信封，退休金攒的三百。你没收。第二天孩子从文具盒底下翻出来，问你这是什么。"
			return money + dad
	return ""


## 第 2 月底：孩子编程班结课展示，晚上六点半在学校。你几点下班，决定你赶不赶得上（路上半小时）。
func _recital() -> String:
	if not GameState.config.team_folders:
		return ""
	var off := GameState.off_minutes()
	if off <= GameState.CLOCK_OUT:
		return "\n18:00 你直接去了学校。六点半，孩子的小猫走出了迷宫，他在台上找到了你，挥了一下手。"
	if off <= GameState.CLOCK_OUT + 30:
		return "\n%s 下班，你赶到学校，展示刚结束。孩子站在门口：“小猫走出来了，你没看到。”" % GameState.clock_text(off)
	return "\n%s 下班。你到学校的时候，教室的灯已经关了。老婆发来一段视频，四十秒，你在地铁上看了三遍。" % GameState.clock_text(off)


## 你爸的话：第 1 月留话头，第 2 月看小刘的事你怎么办的。
func _dad_line() -> String:
	if _month == 3:
		if GameState.echo_matches("story_xiaoliu:hired"):
			return "你爸说，小刘的儿子在基础架构组凌晨两点被叫起来过三回，没吭声。"
		return "你爸说，他跟老刘下棋又坐到一头了。两个人谁也没再提那件事。"
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
	var first := GameState.month_first_day(_month)
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
