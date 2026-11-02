extends Control

signal finished


func _ready() -> void:
	UI.panel(self, Rect2(0, 0, 640, 360), UI.DESK_DARK)
	var logo := UI.label(self, "HR.exe", Vector2(0, 56), UI.GREEN)
	logo.add_theme_font_size_override("font_size", 36)
	logo.size.x = 640
	logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.label(self, "You screen people. The rules screen you.", Vector2(214, 116), UI.TEXT_DIM)
	UI.label(self, "US vertical slice · Days 1–3", Vector2(250, 134), UI.TEXT_DIM)
	UI.button(self, "Clock in", Rect2(260, 176, 120, 24), start_new)
	var resume := UI.button(self, "Continue", Rect2(260, 206, 120, 24), start_saved)
	resume.disabled = not SaveManager.has_save()
	UI.label(self, "Drag and click. A mouse is all you need.", Vector2(220, 330), UI.TEXT_DIM)


func start_new() -> void:
	GameState.new_game()
	finished.emit()


func start_saved() -> void:
	if SaveManager.load_game():
		finished.emit()
