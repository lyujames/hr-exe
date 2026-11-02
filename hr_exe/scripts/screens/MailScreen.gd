extends Control

signal finished


func _ready() -> void:
	var cfg := GameState.config
	UI.panel(self, Rect2(0, 0, 640, 360), UI.WALL)
	UI.panel(self, Rect2(60, 24, 520, 306), Color("1c2221"), UI.BLACK)
	UI.panel(self, Rect2(60, 24, 520, 18), UI.GREEN_DIM)
	UI.label(self, "内部邮件 · 第 %d 天 · %s %s" % [cfg.day, GameState.today, DateUtil.weekday(GameState.today)], Vector2(66, 26), UI.BLACK)
	UI.label(self, "发件人：王总　主题：今日招聘规范", Vector2(72, 50), UI.GREEN)
	UI.label(self, cfg.boss_mail, Vector2(72, 72), UI.TEXT, 340)
	var sticky := UI.panel(self, Rect2(418, 150, 148, 118), UI.YELLOW)
	sticky.rotation = 0.03
	UI.label(self, cfg.coworker_note, Vector2(426, 156), UI.INK, 132).rotation = 0.03
	UI.button(self, "开始筛简历", Rect2(250, 298, 140, 24), finished.emit)
