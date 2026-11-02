extends Control

signal finished


func _ready() -> void:
	UI.panel(self, Rect2(0, 0, 640, 360), UI.DESK_DARK)
	var logo := UI.label(self, "HR.exe", Vector2(0, 56), UI.GREEN)
	logo.add_theme_font_size_override("font_size", 36)
	logo.size.x = 640
	logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.label(self, "你按规则筛人。规则也在筛你。", Vector2(236, 116), UI.TEXT_DIM)
	UI.label(self, "垂直切片 · 第 1–3 天", Vector2(262, 134), UI.TEXT_DIM)
	UI.button(self, "开始上班", Rect2(260, 176, 120, 24), start_new)
	var resume := UI.button(self, "继续", Rect2(260, 206, 120, 24), start_saved)
	resume.disabled = not SaveManager.has_save()
	UI.label(self, "全部拖拽与点击操作，鼠标即可。", Vector2(236, 330), UI.TEXT_DIM)


func start_new() -> void:
	GameState.new_game()
	finished.emit()


func start_saved() -> void:
	if SaveManager.load_game():
		finished.emit()
