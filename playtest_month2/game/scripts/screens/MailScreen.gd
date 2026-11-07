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
	if ps != "":
		mail += "\n\n" + ps
	UI.label(self, mail, Vector2(72, 72), UI.TEXT, 340)
	# 便签高度跟着字数走：先放字，再按行数撑开底下的黄纸
	var sticky := UI.panel(self, Rect2(418, 150, 148, 118), UI.YELLOW)
	sticky.rotation = 0.03
	var note := UI.label(self, cfg.coworker_note, Vector2(426, 156), UI.INK, 132)
	note.rotation = 0.03
	# 太长的便签（第 12 天那种）往右加宽，贴出显示器边上：像素字不能再缩小
	if note.get_line_count() * (note.get_line_height() + 1) + 12.0 > 328.0 - 50.0:
		note.custom_minimum_size.x = 196
		note.size = Vector2(196, 0)
		sticky.size.x = 212
	sticky.size.y = maxf(118.0, note.get_line_count() * (note.get_line_height() + 1) + 12.0)
	# 便签太长、底边出了屏幕：整张往上挪，压住推送；推送几秒后自己收走
	var lift := minf(sticky.position.y + sticky.size.y - 328.0, sticky.position.y - 50.0)
	var covers_push := lift > 0.0
	if covers_push:
		sticky.position.y -= lift
		note.position.y -= lift
	if cfg.morning_push != "":
		_show_push(cfg.morning_push, covers_push)
	UI.button(self, "开始筛简历", Rect2(250, 298, 140, 24), finished.emit)


## 早间推送：手机从右边滑进来，标题预告今天的新规则。
func _show_push(text: String, fade := false) -> void:
	var phone := UI.panel(self, Rect2(418, 52, 148, 60), Color("161b1a"), UI.BLACK)
	UI.label(phone, "07:42　新闻推送", Vector2(8, 6), UI.GREEN_DIM)
	UI.label(phone, text, Vector2(8, 24), UI.TEXT, 132)
	var tween := create_tween()
	tween.tween_property(phone, "position:x", 418.0, 0.3).from(640.0).set_trans(Tween.TRANS_QUAD)
	if fade:
		# 底下压着便签：看几秒就滑走
		tween.tween_interval(3.0)
		tween.tween_property(phone, "position:x", 640.0, 0.3).set_trans(Tween.TRANS_QUAD)
