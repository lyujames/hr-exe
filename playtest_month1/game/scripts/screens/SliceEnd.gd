class_name SliceEnd extends Control
## 切片结尾（第一个月底）：破产提前收尾；否则先回顾这个月见过的手写人物，
## 再留下未揭晓的引线，并收集“想玩下个月吗”。

signal finished

## 夫妻感情的分档：月底回家看到什么。回家那一幕也加减感情（满打满算约 +31），分档跟着抬了。
const HOME_WARM := 12
const HOME_COLD := 0
const HOME_GONE := -10

var _lines: Control


func _ready() -> void:
	UI.panel(self, Rect2(0, 0, 640, 360), UI.DESK_DARK)
	if GameState.is_bankrupt():
		UI.label(self, "存款归零", Vector2(40, 30), UI.RED)
		var wife := "老婆：卡刷不出来了。没事，我那还有一点。你先回来，我们一起想办法。" if GameState.marriage >= HOME_WARM \
			else "老婆：卡刷不出来了。今晚你别回来了，我带孩子回我妈家。"
		UI.label(self, wife, Vector2(40, 56), UI.TEXT, 560)
		UI.label(self, "（破产结局 · 切片结束）", Vector2(40, 92), UI.TEXT_DIM)
		UI.button(self, "回到标题", Rect2(260, 300, 120, 24), finished.emit)
		return
	_show_people()


## 第一页：这个月的手写人物各自去了哪里，以及抽屉里那个信封。
func _show_people() -> void:
	_lines = Control.new()
	add_child(_lines)
	UI.label(_lines, "这个月，你记得这些人吗？", Vector2(40, 18), UI.GREEN)
	var y := 44.0
	for d in range(1, GameState.LAST_DAY + 1):
		for c: Candidate in RuleEngine.load_day(d).story_candidates:
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
	if not GameState.kickbacks.is_empty():
		var k: Dictionary = GameState.kickbacks[0]
		var note := "抽屉里有个信封，¥%d。%s 发来微信：“亲戚家孩子下个月也找实习，老规矩。”" % [k.amount, k.from] if k.taken \
			else "%s 发来微信：“行，我记住你了。”" % k.from
		UI.label(_lines, note, Vector2(40, y), UI.YELLOW, 560)
	UI.button(_lines, "继续", Rect2(484, 328, 110, 24), _show_home)


## 第二页：下班回家。老婆发的消息你回了多少，第 4 天上午你走没走，决定门后面是什么。
func _show_home() -> void:
	_lines.queue_free()
	_lines = Control.new()
	add_child(_lines)
	UI.label(_lines, "3 月 31 日，晚上", Vector2(40, 18), UI.GREEN)
	var counts := GameState.text_counts()
	var y := 46.0
	var facts := "这个月她上班时给你发了 %d 条消息，你回了 %d 条。" % [counts.got, counts.replied]
	if GameState.family.has("d4_left") or GameState.decision_log.any(func(e: Dictionary) -> bool: return e.day == 4):
		facts += "\n3 月 5 日上午，她问你能不能早点回去。" + ("你走了。" if GameState.family.get("d4_left", "") == "yes" else "你没走。")
	y += UI.label(_lines, facts, Vector2(40, y), UI.TEXT_DIM, 560).get_line_count() * 16.0 + 18.0
	var m := GameState.marriage
	var scene := ""
	var tag := ""
	if m >= HOME_WARM:
		scene = "18:00 下班，你到家快七点了。桌上扣着一碗饭，还是热的。\n孩子从房间冲出来：“爸爸！我作文写的你！”本子上写着：我的爸爸是 HR，他每天帮别人找工作。\n老婆坐在你对面看你吃。\n“下个月的事，下个月再说。”"
	elif m >= HOME_COLD:
		scene = "你到家七点。老婆在阳台打电话，看见你进门，挂了。\n“吃了吗？”“吃了。”\n孩子在写作业，抬头叫了声爸爸，又低下头去。\n九点，孩子房间的灯关了。"
	elif m > HOME_GONE:
		scene = "你到家七点，客厅的灯没开。\n饭桌上压着孩子的作文本，题目是《我的爸爸》，只写了一行：我爸爸很忙。\n老婆和孩子睡在一个房间，门关着。\n你点开手机，你们的对话停在她那边。"
	else:
		scene = "茶几上压着一张纸：\n“我带孩子去我妈那住一阵。你爸那边我会去看。你先忙你的。”\n你在星桥谈过几百个人，没想过要跟她谈。"
		tag = "（婚姻结局）"
	UI.label(_lines, scene, Vector2(40, y), UI.TEXT, 560)
	# 小刘是第二个月的暗线：这个月只埋话头，简历、送礼和结局都在下个月。
	# 标签刚建好时还没排版，行数按字数估：一行约 34 个字。
	for line in scene.split("\n"):
		y += ceili(line.length() / 34.0) * 20.0
	y += 26.0
	UI.label(_lines, "手机亮了一下，是你爸：“我回自己那边住了，离得近，有事喊我。小刘那边，下个月你给个准话。”", Vector2(40, y), UI.TEXT_DIM, 560)
	if tag != "":
		UI.label(_lines, tag, Vector2(40, 300), UI.TEXT_DIM)
	UI.button(_lines, "继续", Rect2(484, 328, 110, 24), _show_summary)


func _show_summary() -> void:
	_lines.queue_free()
	UI.label(self, "第一个月结束　月供已扣，存款 ¥%d" % GameState.savings, Vector2(40, 18), UI.GREEN)
	var rejects := GameState.decision_log.filter(func(d: Dictionary) -> bool: return d.verdict == "reject")
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
	var mail := "下月邮件预览：“降本增效。从下个月起招程序员，入门岗要 5 年经验。我们是一家人。”"
	if GameState.boss_promised_rule:
		mail += "\n以及：“另外，评分表满分的，HR 要手写担保书。”"
	UI.label(self, mail, Vector2(40, y), UI.YELLOW, 560)
	# 理由和试用期名单越攒越长，问题放在最底下一行，不和上面抢位置
	UI.label(self, "想继续上下个月的班吗？", Vector2(40, 332), UI.GREEN)
	UI.button(self, "想", Rect2(364, 328, 110, 24), answer.bind(true))
	UI.button(self, "不想", Rect2(484, 328, 110, 24), answer.bind(false))


func answer(wants_next: bool) -> void:
	SaveManager.record_playtest(wants_next)
	finished.emit()
