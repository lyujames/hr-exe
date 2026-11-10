extends Control

signal finished


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
	if GameState.late_ps != "":
		ps = GameState.late_ps if ps == "" else ps + "\n" + GameState.late_ps
	if ps != "":
		mail += "\n" + ps
	UI.label(self, mail, Vector2(72, 72), UI.TEXT, 340)
	# 便签高度跟着字数走：先放字，再按行数撑开底下的黄纸
	var sticky := UI.panel(self, Rect2(418, 150, 148, 118), Color("e9ebe6") if cfg.note_printed else UI.YELLOW)
	sticky.rotation = 0.03
	var note := UI.label(self, cfg.coworker_note, Vector2(426, 156), UI.INK, 132)
	note.rotation = 0.03
	# 刚建的 Label 还没排版，size.y 不准：按行数算高度
	var note_h := note.get_line_count() * (note.get_line_height() + 1) + 12.0
	# 太长的便签往右加宽，贴出显示器边上：像素字不能再缩小
	if note_h > 328.0 - 50.0:
		note.custom_minimum_size.x = 196
		note.size = Vector2(196, 0)
		sticky.size.x = 212
		note_h = note.get_line_count() * (note.get_line_height() + 1) + 12.0
	sticky.size.y = maxf(118.0, note_h)
	# 便签太长、底边出了屏幕：整张往上挪，压住推送；推送几秒后自己收走
	var lift := minf(sticky.position.y + sticky.size.y - 328.0, sticky.position.y - 50.0)
	var covers_push := lift > 0.0
	if covers_push:
		sticky.position.y -= lift
		note.position.y -= lift
	if cfg.morning_push != "":
		_show_push(cfg.morning_push, covers_push)
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
	if not GameState.paper.is_empty() and GameState.paper.get("date", "") != GameState.today:
		_show_paper(GameState.paper)
	if not GameState.late_today.is_empty():
		_show_morning()


## 早上的报纸：昨天晚上那份。看完收起来，底下是今天的邮件。
func _show_paper(p: Dictionary) -> void:
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


## 晚到的早上：先是家里那一幕，进公司时邮件早就躺在收件箱里了。
func _show_morning() -> void:
	var cover := UI.panel(self, Rect2(0, 0, 640, 360), UI.DESK_DARK)
	var d := DateUtil.parse(GameState.today)
	UI.label(cover, "%d 月 %d 日（%s），早上" % [d.y, d.z, DateUtil.weekday(GameState.today)], Vector2(40, 18), UI.GREEN)
	UI.label(cover, GameState.late_today.get("morning", ""), Vector2(40, 46), UI.TEXT_DIM, 560)
	# 早上那段不超过五六行，到公司那句压在下面固定的位置
	UI.label(cover, "你到公司，%s。早上那几个钟头的简历没看成，迟到按小时扣钱。" % GameState.arrival_time(), Vector2(40, 200), UI.YELLOW, 560)
	UI.button(cover, "进公司", Rect2(484, 328, 110, 24), cover.queue_free)


## 早间推送：手机从右边滑进来，标题预告今天的新规则。
func _show_push(text: String, fade := false) -> void:
	var phone := UI.panel(self, Rect2(418, 52, 148, 60), Color("161b1a"), UI.BLACK)
	UI.label(phone, "07:42　新闻推送", Vector2(8, 6), UI.GREEN_DIM)
	var body := UI.label(phone, text, Vector2(8, 24), UI.TEXT, 132)
	# 标题长了折三四行：框跟着字撑高，底下留一点边
	phone.size.y = maxf(60.0, 24.0 + body.get_line_count() * (body.get_line_height() + 1) + 8.0)
	var tween := create_tween()
	tween.tween_property(phone, "position:x", 418.0, 0.3).from(640.0).set_trans(Tween.TRANS_QUAD)
	if fade:
		# 底下压着便签：看几秒就滑走
		tween.tween_interval(3.0)
		tween.tween_property(phone, "position:x", 640.0, 0.3).set_trans(Tween.TRANS_QUAD)
