extends Control

signal finished


## 便签底边最低到这里（显示器下框之上，留出便签斜贴多出来的几像素）
const NOTE_BOTTOM := 322.0


func _ready() -> void:
	var cfg := GameState.config
	UI.panel(self, Rect2(0, 0, 640, 360), UI.WALL)
	UI.panel(self, Rect2(60, 24, 520, 306), Color("1c2221"), UI.BLACK)
	UI.panel(self, Rect2(60, 24, 520, 18), UI.GREEN_DIM)
	UI.label(self, "内部邮件 · 第 %d 天 · %s %s" % [cfg.day, GameState.today, DateUtil.weekday(GameState.today)], Vector2(66, 26), UI.BLACK)
	UI.label(self, "发件人：王总　主题：今日招聘规范", Vector2(72, 50), UI.GREEN)
	# 人效看板：“{yesterday}”换成昨天处理了几份
	var mail := cfg.boss_mail.replace("{yesterday}", str(GameState.processed_on(GameState.day - 1)))
	var ps: String = GameState.story_echo().get("mail_ps", "")
	for extra: Dictionary in cfg.mail_ps_by:
		if GameState.family_matches(extra.when):
			ps = extra.ps if ps == "" else ps + "\n" + extra.ps
	# 今天的 HC 硬指标：主管的话写在附言里
	var push_note: String = cfg.hc_push.get("note", "")
	if push_note != "":
		ps = push_note if ps == "" else ps + "\n" + push_note
	# 被你按规则筛掉的人，在竞对干得好
	var echo_ps := GameState.blocked_echo_ps()
	if echo_ps != "":
		ps = echo_ps if ps == "" else ps + "\n" + echo_ps
	if GameState.late_ps != "":
		ps = GameState.late_ps if ps == "" else ps + "\n" + GameState.late_ps
	if ps != "":
		mail += "\n" + ps
	UI.label(self, mail, Vector2(72, 72), UI.TEXT, 340)
	# 早间推送在右上角，一直留着；便签贴在推送下面，不压它
	var push: Panel = _make_push(cfg.morning_push) if cfg.morning_push != "" else null
	var top := 150.0
	if push:
		top = maxf(top, push.position.y + push.size.y + 8.0)
	# 便签高度跟着字数走：先放字，再按行数撑开底下的黄纸
	var sticky := UI.panel(self, Rect2(418, top, 148, 118), Color("e9ebe6") if cfg.note_printed else UI.YELLOW)
	sticky.rotation = 0.03
	var note := UI.label(self, cfg.coworker_note, Vector2(426, top + 6), UI.INK, 132)
	note.rotation = 0.03
	# 刚建的 Label 还没排版，size.y 不准：按行数算高度
	var note_h := note.get_line_count() * (note.get_line_height() + 1) + 12.0
	# 太长的便签往右加宽，贴出显示器边上：像素字不能再缩小
	if top + note_h > NOTE_BOTTOM:
		note.custom_minimum_size.x = 196
		note.size = Vector2(196, 0)
		sticky.size.x = 212
		note_h = note.get_line_count() * (note.get_line_height() + 1) + 12.0
	sticky.size.y = maxf(118.0, note_h)
	# 没有推送时还嫌长：整张往上挪（最高到邮件标题那一行）
	var lift := minf(sticky.position.y + sticky.size.y - NOTE_BOTTOM, sticky.position.y - 50.0)
	if lift > 0.0 and push == null:
		sticky.position.y -= lift
		note.position.y -= lift
	UI.button(self, "开始筛简历", Rect2(250, 298, 140, 24), finished.emit)
	# 能打印的邮件：打一份出来，放进抽屉最里面（证据，第四个月交不交出去）
	if cfg.mail_print != "":
		var print_button := UI.button(self, "打印", Rect2(72, 298, 64, 24), func() -> void: pass)
		if cfg.mail_print in GameState.evidence:
			print_button.text = "已在抽屉"
			print_button.disabled = true
		print_button.pressed.connect(func() -> void:
			GameState.add_evidence(cfg.mail_print)
			Sfx.printer()
			print_button.text = "已在抽屉"
			print_button.disabled = true
			UI.label(self, "打印件折了两折，放进抽屉最里面。", Vector2(144, 302), UI.TEXT_DIM))
	# 砍减版：昨天的晚报挪到早上，先看报再看邮件（晚到的早上，家里那一幕盖在报纸上面）
	var covers: Array[Control] = []
	if not GameState.paper.is_empty() and GameState.paper.get("date", "") != GameState.today:
		covers.append(_show_paper(GameState.paper))
	if not GameState.late_today.is_empty():
		covers.append(_show_morning())
	if push:
		_slide_in(push, covers)


## 早上的报纸：昨天晚上那份。看完收起来，底下是今天的邮件。
func _show_paper(p: Dictionary) -> Control:
	var cover := UI.panel(self, Rect2(0, 0, 640, 360), UI.DESK_DARK)
	UI.panel(cover, Rect2(140, 20, 360, 296), UI.PAPER, UI.BLACK)
	UI.label(cover, "本市晚报", Vector2(152, 28), UI.INK_SOFT)
	UI.label(cover, str(p.get("date", "")), Vector2(410, 28), UI.INK_SOFT)
	UI.panel(cover, Rect2(152, 46, 336, 1), UI.INK)
	UI.label(cover, str(p.get("headline", "")), Vector2(152, 58), UI.INK, 336)
	UI.panel(cover, Rect2(152, 100, 336, 1), UI.INK_SOFT)
	UI.label(cover, str(p.get("body", "")), Vector2(152, 110), UI.INK, 336)
	UI.label(cover, "昨天的晚报，早饭桌上翻了翻。", Vector2(140, 324), UI.TEXT_DIM)
	UI.button(cover, "看邮件", Rect2(390, 328, 110, 24), cover.queue_free)
	return cover


## 晚到的早上：先是家里那一幕，进公司时邮件早就躺在收件箱里了。
func _show_morning() -> Control:
	var cover := UI.panel(self, Rect2(0, 0, 640, 360), UI.DESK_DARK)
	var d := DateUtil.parse(GameState.today)
	UI.label(cover, "%d 月 %d 日（%s），早上" % [d.y, d.z, DateUtil.weekday(GameState.today)], Vector2(40, 18), UI.GREEN)
	UI.label(cover, GameState.late_today.get("morning", ""), Vector2(40, 46), UI.TEXT_DIM, 560)
	# 早上那段不超过五六行，到公司那句压在下面固定的位置
	UI.label(cover, "你到公司，%s。早上那几个钟头的简历没看成，迟到按小时扣钱。" % GameState.arrival_time(), Vector2(40, 200), UI.YELLOW, 560)
	UI.button(cover, "进公司", Rect2(484, 328, 110, 24), cover.queue_free)
	return cover


## 早间推送：手机框，标题预告今天的新规则。先藏在屏幕右边外面。
func _make_push(text: String) -> Panel:
	var phone := UI.panel(self, Rect2(640, 52, 148, 60), Color("161b1a"), UI.BLACK)
	UI.label(phone, "07:42　新闻推送", Vector2(8, 6), UI.GREEN_DIM)
	var body := UI.label(phone, text, Vector2(8, 24), UI.TEXT, 132)
	# 标题长了折三四行：框跟着字撑高，底下留一点边
	phone.size.y = maxf(60.0, 24.0 + body.get_line_count() * (body.get_line_height() + 1) + 8.0)
	return phone


## 报纸、早上那一幕都收起来以后，推送才从右边滑进来，然后一直留着。
func _slide_in(phone: Panel, covers: Array[Control]) -> void:
	for c: Control in covers:
		if is_instance_valid(c):
			await c.tree_exited
	if not is_inside_tree():
		return
	await get_tree().create_timer(0.2).timeout
	if not is_instance_valid(phone):
		return
	create_tween().tween_property(phone, "position:x", 418.0, 0.3).set_trans(Tween.TRANS_QUAD)
