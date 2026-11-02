class_name SliceEnd extends Control
## 切片结尾：破产提前收尾；否则留下未揭晓的引线，并收集“想玩第 4 天吗”。

signal finished

var _lines: Control


func _ready() -> void:
	UI.panel(self, Rect2(0, 0, 640, 360), UI.DESK_DARK)
	if GameState.is_bankrupt():
		UI.label(self, "Out of money", Vector2(40, 30), UI.RED)
		UI.label(self, "Spouse: The card got declined. Don't come home tonight. The kids and I are going to my mom's.", Vector2(40, 56), UI.TEXT, 560)
		UI.label(self, "(Bankruptcy ending · end of slice)", Vector2(40, 92), UI.TEXT_DIM)
		UI.button(self, "Back to title", Rect2(260, 300, 120, 24), finished.emit)
		return
	UI.label(self, "End of Day 3", Vector2(40, 18), UI.GREEN)
	var rejects := GameState.decision_log.filter(func(d: Dictionary) -> bool: return d.verdict == "reject")
	UI.label(self, "Everything you wrote these three days is on file. %d lines:" % rejects.size(), Vector2(40, 40), UI.TEXT)
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
		UI.label(self, "Still in their first 90 days:", Vector2(40, y), UI.TEXT)
		y += 18.0
		for hire: Dictionary in pending:
			UI.label(self, "%s (hired Day %d): no results yet" % [hire.candidate.display_name, hire.day_hired], Vector2(52, y), UI.TEXT_DIM)
			y += 16.0
		y += 8.0
	var mail := "Tomorrow's mail preview: “Starting tomorrow: Ivy League or Top 50 only. We're a family.”"
	if GameState.boss_promised_rule:
		mail += "\nAlso: “Perfect scorecards now require a signed HR guarantee.”"
	UI.label(self, mail, Vector2(40, y), UI.YELLOW, 560)
	UI.label(self, "Want to come in for Day 4?", Vector2(238, 282), UI.GREEN)
	UI.button(self, "Yes", Rect2(190, 304, 120, 24), answer.bind(true))
	UI.button(self, "No", Rect2(330, 304, 120, 24), answer.bind(false))


func answer(wants_day_4: bool) -> void:
	SaveManager.record_playtest(wants_day_4)
	finished.emit()
