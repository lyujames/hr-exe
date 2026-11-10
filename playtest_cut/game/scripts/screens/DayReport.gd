class_name DayReport extends Control
## 日结：违规通知单统一在这里出现；可选开销可以不付，代价是家庭状态。

signal finished

var paid := {}
## 月底补窟窿的路（DayConfig.rescue_options），勾了哪几条。
var rescue := {}
var _rescues: Array = []
var _total: Label
var _mortgage_label: Label
var _mortgage_bar: Panel
var settled_net := 0


func _ready() -> void:
	var s := GameState.stats
	UI.panel(self, Rect2(0, 0, 640, 360), UI.DESK_DARK)
	UI.panel(self, Rect2(30, 12, 280, 336), UI.PAPER, UI.BLACK)
	var off := "提前下班" if GameState.stats.left_early else "%s 下班" % GameState.clock_text(GameState.off_minutes())
	UI.label(self, "日结单 · 第 %d 天 · %s" % [GameState.day, off], Vector2(40, 18), UI.INK)
	var y := 40.0
	var pay := GameState.pay
	var quota := GameState.quota_today()
	if quota > 0:
		y = _row("底薪（人效 %d/%d 份）" % [mini(s.processed, quota), quota], GameState.base_pay(), y)
	else:
		y = _row("底薪", int(pay.base), y)
	# 判对的钱并进绩效，日结单上不单列
	y = _row("简历处理绩效 %d 份" % s.processed, GameState.performance_pay() + GameState.judge_bonus(), y)
	if pay.get("per_reason", 0) > 0:
		y = _row("审核依据准确奖 %d 份 × ¥%d" % [s.reason_ok, pay.per_reason], GameState.reason_bonus(), y)
	for name: String in s.chief_picks:
		y = _row("%s %s" % ["组长推荐奖" if GameState.config.team_folders else GameState.config.interviewer.get("bonus", "用人部门推荐奖"), name], int(pay.get("chief_bonus", 0)), y)
	if int(s.talk_fine) > 0:
		y = _row("补偿超预算（离职谈话）", -int(s.talk_fine), y)
	if int(s.memo_money) != 0:
		y = _row("定薪提成 / 其他", int(s.memo_money), y)
	if GameState.clocked_day() and GameState.off_minutes() > GameState.CLOCK_OUT and not s.left_early:
		y = _row("加班 %d 分钟（弹性工作，不计加班）" % (GameState.off_minutes() - GameState.CLOCK_OUT), 0, y)
	for r: Dictionary in s.retained:
		if r.left:
			y = _row("试用期留任奖 %s：已离职" % r.name, 0, y)
		elif pay.retention_deferred:
			y = _row("试用期留任奖 %s 满 %d 天（延发）" % [r.name, r.days], 0, y)
		else:
			y = _row("试用期留任奖 %s 满 %d 天" % [r.name, r.days], int(pay.retention), y)
	for b: Dictionary in GameState.echo_bonuses():
		y = _row(b.label, int(b.amount), y)
	# 识人：评分表上你改的那一处，满期这天对账；明细（主管填几、你改几、实际几）写在右边那张单子底下
	for e: Dictionary in s.edits:
		var verdict: String = {"right": "准", "wrong": "看走眼", "even": "白改", "blank": "%s不算数" % e.item}[e.verdict]
		y = _row("人才甄别奖 %s：%s" % [e.name, verdict], int(pay.get("edit_bonus", 0)) if e.verdict == "right" else 0, y)
	# 面试完没录的人，满期这天对账：按类合成一行，每个人的去向写在右边那张单子底下
	var dodged: int = s.rejects.filter(func(r: Dictionary) -> bool: return not r.good and r.evidence).size()
	if dodged > 0:
		y = _row("用人风险规避奖 %d 人" % dodged, dodged * int(pay.get("edit_bonus", 0)), y)
	if GameState.reject_cost() > 0:
		y = _row("人才流失扣款 %d 人" % (GameState.reject_cost() / GameState.MISS_COST), -GameState.reject_cost(), y)
	if not s.knowing.is_empty():
		y = _row("违规录用处罚 %d 人" % s.knowing.size(), -GameState.knowing_fine(), y)
	if GameState.late_fine() > 0:
		y = _row("迟到（%s 到）" % GameState.arrival_time(), -GameState.late_fine(), y)
	if s.wrong > 0:
		if GameState.fines_on():
			var free := mini(s.wrong, GameState.FREE_WARNINGS)
			y = _row("审核违规 %d 次（%d 次警告）" % [s.wrong, free], -GameState.fines(), y)
		else:
			y = _row("审核违规 %d 次（本月不罚款）" % s.wrong, 0, y)
	var vouch_bad: int = s.vouch.filter(func(v: Dictionary) -> bool: return not v.good).size()
	for v: Dictionary in s.vouch:
		y = _row("破格担保责任金 %s：%s" % [v.name, "干得好" if v.good else "出事了"], -GameState.VOUCH_FINE if not v.good else 0, y)
	if s.event_fine - vouch_bad * GameState.VOUCH_FINE > 0:
		y = _row("用工事故扣款", -(s.event_fine - vouch_bad * GameState.VOUCH_FINE), y)
	if s.gray > 0:
		y = _row("信封（不入账）", s.gray, y)
	if not s.broker.is_empty():
		y = _row("李哲他爸转账 %d 笔（不入账）" % s.broker.size(), GameState.broker_income(), y)
	for t: Dictionary in s.sent:
		y = _row("手机转给%s（%s）" % [t.to, t.note], -int(t.amount), y)
	if GameState.is_month_end():
		y = _row("房贷（月供）", -GameState.MORTGAGE, y)
	y += 6.0
	for bill: Dictionary in GameState.bills_today():
		paid[bill.id] = true
		var box := CheckBox.new()
		box.text = "%s  −¥%d" % [bill.label, bill.amount]
		box.button_pressed = true
		box.position = Vector2(38, y)
		box.focus_mode = Control.FOCUS_NONE
		box.add_theme_color_override("font_color", UI.INK)
		box.add_theme_color_override("font_pressed_color", UI.INK)
		box.add_theme_color_override("font_hover_color", UI.INK)
		box.add_theme_color_override("font_hover_pressed_color", UI.INK)
		box.toggled.connect(_toggle_bill.bind(bill.id))
		add_child(box)
		y += 24.0
	# 月底还不上：几条补窟窿的路，点开勾选（后果下个月算）
	var rescues: Array = GameState.config.rescue_options.filter(func(r: Dictionary) -> bool: return GameState.family_matches(r.get("when", "")))
	if not rescues.is_empty():
		_rescues = rescues
	_mortgage_label = UI.label(self, "", Vector2(40, 244), UI.INK)
	UI.panel(self, Rect2(40, 262, 260, 10), UI.PAPER_DIM, UI.INK_SOFT)
	_mortgage_bar = UI.panel(self, Rect2(41, 263, 0, 8), UI.GREEN_DIM)
	_total = UI.label(self, "", Vector2(40, 284), UI.INK)
	if _rescues.is_empty():
		UI.button(self, "确认", Rect2(40, 316, 260, 24), confirm)
	else:
		UI.button(self, "确认", Rect2(40, 316, 166, 24), confirm)
		UI.button(self, "补月供……", Rect2(212, 316, 88, 24), _open_rescue.bind(_rescues))
	_build_notice()
	_refresh()


func _row(text: String, amount: int, y: float) -> float:
	UI.label(self, text, Vector2(40, y), UI.INK)
	var prefix := "+" if amount > 0 else ("−" if amount < 0 else "")
	var value := UI.label(self, "%s¥%d" % [prefix, absi(amount)], Vector2(220, y), UI.RED if amount < 0 else UI.INK)
	value.size.x = 80
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	return y + 18.0


func _build_notice() -> void:
	var s := GameState.stats
	UI.panel(self, Rect2(326, 12, 284, 336), UI.PAPER_DIM, UI.BLACK)
	UI.label(self, "违规通知单", Vector2(336, 18), UI.RED)
	var y := 40.0
	if s.errors.is_empty():
		UI.label(self, "今日无违规。继续保持。", Vector2(336, y), UI.INK)
		y += 22.0
	# 底部几行从下往上排：会换行的那行先量高度，违规条目只占剩下的地方
	var footer: Array = []
	for r: Dictionary in s.rejects:
		footer.append(r.text)
	for e: Dictionary in s.edits:
		if e.verdict == "blank":
			footer.append("%s 的%s：主管 %d，你改 %d。这一项对不上任何账。" % [e.name, e.item, e.from, e.to])
		else:
			footer.append("%s 的%s：主管 %d，你改 %d，实际 %d。" % [e.name, e.item, e.from, e.to, e.truth])
	var pending := GameState.pending_hires()
	if not pending.is_empty():
		# 只是让玩家知道，不进今天的收入
		var due := pending.map(func(h: Dictionary) -> String: return "%s 第 %d 天" % [h.candidate.display_name, GameState.retention_due(h)])
		footer.append("在路上：留任奖金（%s 满期）" % "、".join(PackedStringArray(due)))
	var broker := GameState.broker_pending()
	if not broker.is_empty():
		footer.append("在路上：李哲他爸 ¥%d × %d（满试用期才转）" % [GameState.BROKER_RETAIN, broker.size()])
	if not GameState.passed_today.is_empty() and not GameState.is_month_end():
		var n := GameState.passed_today.size()
		var slots := GameState.book_slots()
		if n > slots:
			footer.append("今天通过 %d 人，明天只能约%s来面。" % [n, "一个" if slots == 1 else " %d 个" % slots])
		else:
			footer.append("今天通过 %d 人，约明天面试。" % n)
	if s.exception != "" and GameState.day < GameState.LAST_DAY:
		footer.append("破格：%s，%s 14:00 你单独面。" % [s.exception, "下个月第一天" if GameState.is_month_end() else "明天"])
	if s.unprocessed > 0:
		footer.append("未处理简历 %d 份。" % s.unprocessed)
	if not s.intake_left.is_empty():
		footer.append("入职手续没办完：%s。王总记了一笔。" % "、".join(PackedStringArray(s.intake_left)))
	for t: Dictionary in s.talks:
		footer.append("离职谈话 %s：%s。" % [t.name, {"signed": "签了", "refused": "没签"}.get(t.outcome, "谈完了")])
	if GameState.config.hc_today > 0:
		var placed := GameState.passed_today.size() + GameState.vouched_today.size()
		footer.append("今日 HC %d 个：放了 %d 个。%s" % [GameState.config.hc_today, placed, "" if placed >= GameState.config.hc_today else "王总：HC 没用完。（记一笔）"])
	if (GameState.config.ats or GameState.config.hirebot > 0) and s.ats_agree + s.ats_override > 0:
		var ats := "%s：跟系统一致 %d 份，推翻 %d 份" % ["HireBot" if GameState.config.hirebot > 0 else "HireBot 0.1", s.ats_agree, s.ats_override]
		if s.ats_override > 0:
			ats += "（其中判对 %d 份）" % s.ats_override_ok
		footer.append(ats + "。")
	if s.called_out > 0:
		footer.append("面试里，你红笔圈的疑点被说中 %d 处。" % s.called_out)
	if GameState.config.team_folders and not s.left_early:
		if GameState.day > 1 and RuleEngine.load_day(GameState.day - 1).team_folders and int(s.held) < 2:
			footer.append("王总：今天就面了 %d 场？HC 不用就收回了。（记一笔）" % int(s.held))
		var home := GameState.home_minutes()
		var late := "，饭已经凉了" if home >= GameState.LATE_HOME[0] else ""
		if home >= GameState.LATE_HOME[1]:
			late = "，孩子已经睡了"
		footer.append("到家大约 %s%s。" % [GameState.clock_text(home), late])
	footer.append("正确 %d / 已处理 %d" % [s.correct, s.processed])
	var labels: Array[Label] = []
	var footer_h := 0.0
	for text: String in footer:
		var l := UI.label(self, text, Vector2(336, 0), UI.INK_SOFT, 266)
		labels.append(l)
		footer_h += l.size.y + 1.0
	var fy := 342.0 - footer_h
	for l: Label in labels:
		l.position.y = fy
		fy += l.size.y + 1.0
	# 理由不准不算违规，排在违规后面、颜色淡一点；只在有理由奖金的月份提
	var notes: Array = s.errors.map(func(e: Dictionary) -> Array: return [e, UI.INK])
	if GameState.pay.get("per_reason", 0) > 0:
		notes.append_array(s.reason_off.map(func(e: Dictionary) -> Array: return [e, UI.INK_SOFT]))
	var limit := 342.0 - footer_h - 6.0
	var shown := 0
	for note: Array in notes:
		var l := UI.label(self, note[0].name + " —— " + note[0].why, Vector2(336, y), note[1], 266)
		var h := l.size.y + 5.0
		# 给“另有 N 条”留一行
		var need := h + (16.0 if shown < notes.size() - 1 else 0.0)
		if y + need > limit:
			l.free()
			break
		y += h
		shown += 1
	if shown < notes.size():
		UI.label(self, "……另有 %d 条" % (notes.size() - shown), Vector2(336, y), UI.INK_SOFT)


## 补窟窿：逾期、停补习、分期、她的补偿金、你爸的信封……勾了的钱今天进来。
func _open_rescue(rescues: Array) -> void:
	var cover := Control.new()
	add_child(cover)
	UI.panel(cover, Rect2(0, 0, 640, 360), Color(0, 0, 0, 0.45)).mouse_filter = Control.MOUSE_FILTER_STOP
	var box := UI.panel(cover, Rect2(120, 40, 400, 0), UI.PAPER, UI.BLACK)
	UI.label(cover, "这个月的窟窿，拿什么补？（可以多选，后果下个月算）", Vector2(132, 48), UI.INK)
	var y := 72.0
	for r: Dictionary in rescues:
		var check := CheckBox.new()
		check.text = "%s  +¥%d" % [r.label, r.amount]
		check.position = Vector2(130, y)
		check.focus_mode = Control.FOCUS_NONE
		check.button_pressed = rescue.get(r.id, false)
		for key in ["font_color", "font_pressed_color", "font_hover_color", "font_hover_pressed_color"]:
			check.add_theme_color_override(key, UI.INK)
		check.toggled.connect(func(on: bool) -> void:
			rescue[r.id] = on
			_refresh())
		cover.add_child(check)
		y += 22.0
		if r.get("note", "") != "":
			var n := UI.label(cover, r.note, Vector2(152, y - 4), UI.INK_SOFT, 356)
			y += n.get_line_count() * (n.get_line_height() + 1) + 2.0
	UI.button(cover, "就这样", Rect2(400, y + 6, 108, 20), cover.queue_free)
	box.size.y = y + 34.0 - 40.0


func _toggle_bill(pressed: bool, id: String) -> void:
	paid[id] = pressed
	_refresh()


func paid_ids() -> Array:
	return paid.keys().filter(func(id: String) -> bool: return paid[id])


func _refresh() -> void:
	var net := GameState.income() - GameState.mortgage_today()
	for r: Dictionary in GameState.config.rescue_options:
		if rescue.get(r.id, false):
			net += int(r.amount)
	for bill: Dictionary in GameState.bills_today():
		if paid[bill.id]:
			net -= int(bill.amount)
	var after := GameState.savings + net
	_total.text = "今日结余 %+d　→　存款 ¥%d" % [net, after]
	# 进度条：手里的钱够不够这个月的月供
	var funds := after + GameState.mortgage_today()
	var short := GameState.MORTGAGE - funds
	if GameState.is_month_end():
		_mortgage_label.text = "今天还月供 ¥%d" % GameState.MORTGAGE + ("　还差 ¥%d" % short if short > 0 else "")
	else:
		_mortgage_label.text = "距月底还房贷 %d 天　" % GameState.days_to_mortgage() + ("还差 ¥%d" % short if short > 0 else "已够月供")
	_mortgage_label.add_theme_color_override("font_color", UI.RED if short > 0 else UI.INK)
	_mortgage_bar.size.x = 258.0 * clampf(float(funds) / GameState.MORTGAGE, 0.0, 1.0)
	_mortgage_bar.get_theme_stylebox("panel").bg_color = UI.RED if short > 0 else UI.GREEN_DIM


func confirm() -> void:
	settled_net = GameState.settle(paid_ids(), rescue.keys().filter(func(id: String) -> bool: return rescue[id]))
	finished.emit()
