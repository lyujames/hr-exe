class_name SliceEnd extends Control
## 切片结尾（第一个月底）：破产提前收尾；否则留下未揭晓的引线，并收集“想玩下个月吗”。

signal finished

var _lines: Control


func _ready() -> void:
	UI.panel(self, Rect2(0, 0, 640, 360), UI.DESK_DARK)
	if GameState.is_bankrupt():
		UI.label(self, "存款归零", Vector2(40, 30), UI.RED)
		UI.label(self, "老婆：卡刷不出来了。今晚你别回来了，我带孩子回我妈家。", Vector2(40, 56), UI.TEXT, 560)
		UI.label(self, "（破产结局 · 切片结束）", Vector2(40, 92), UI.TEXT_DIM)
		UI.button(self, "回到标题", Rect2(260, 300, 120, 24), finished.emit)
		return
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
	UI.button(self, "想", Rect2(380, 328, 110, 24), answer.bind(true))
	UI.button(self, "不想", Rect2(500, 328, 110, 24), answer.bind(false))


func answer(wants_next: bool) -> void:
	SaveManager.record_playtest(wants_next)
	finished.emit()
