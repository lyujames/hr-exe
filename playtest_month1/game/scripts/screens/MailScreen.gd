extends Control

signal finished


func _ready() -> void:
	var cfg := GameState.config
	UI.panel(self, Rect2(0, 0, 640, 360), UI.WALL)
	UI.panel(self, Rect2(60, 24, 520, 306), Color("1c2221"), UI.BLACK)
	UI.panel(self, Rect2(60, 24, 520, 18), UI.GREEN_DIM)
	UI.label(self, "内部邮件 · 第 %d 天 · %s %s" % [cfg.day, GameState.today, DateUtil.weekday(GameState.today)], Vector2(66, 26), UI.BLACK)
	UI.label(self, "发件人：王总　主题：今日招聘规范", Vector2(72, 50), UI.GREEN)
	var mail := cfg.boss_mail
	var ps: String = GameState.story_echo().get("mail_ps", "")
	if GameState.late_ps != "":
		ps = GameState.late_ps if ps == "" else ps + "\n" + GameState.late_ps
	if ps != "":
		mail += "\n" + ps
	UI.label(self, mail, Vector2(72, 72), UI.TEXT, 340)
	# 便签高度跟着字数走：先放字，再按行数撑开底下的黄纸
	var sticky := UI.panel(self, Rect2(418, 150, 148, 118), UI.YELLOW)
	sticky.rotation = 0.03
	var note := UI.label(self, cfg.coworker_note, Vector2(426, 156), UI.INK, 132)
	note.rotation = 0.03
	sticky.size.y = maxf(118.0, note.size.y + 12.0)
	if cfg.morning_push != "":
		_show_push(cfg.morning_push)
	UI.button(self, "开始筛简历", Rect2(250, 298, 140, 24), finished.emit)
	if not GameState.late_today.is_empty():
		_show_morning()


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
func _show_push(text: String) -> void:
	var phone := UI.panel(self, Rect2(418, 52, 148, 60), Color("161b1a"), UI.BLACK)
	UI.label(phone, "07:42　新闻推送", Vector2(8, 6), UI.GREEN_DIM)
	UI.label(phone, text, Vector2(8, 24), UI.TEXT, 132)
	create_tween().tween_property(phone, "position:x", 418.0, 0.3).from(640.0).set_trans(Tween.TRANS_QUAD)
