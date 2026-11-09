class_name JobPostingDoc extends DraggableDoc
## 桌上的职位描述（JD）：每个月换一张，一张比一张长，工资栏一张比一张低。

const SIZE := Vector2(106, 232)


func setup(posting: JobPosting) -> void:
	size = SIZE
	UI.panel(self, Rect2(Vector2(2, 2), SIZE), UI.BLACK)
	UI.panel(self, Rect2(Vector2.ZERO, SIZE), UI.PAPER, UI.INK_SOFT)
	UI.panel(self, Rect2(0, 0, SIZE.x, 18), UI.YELLOW)
	UI.label(self, "职位描述", Vector2(4, 2), UI.INK)
	var width := SIZE.x - 8
	var title := UI.label(self, posting.title, Vector2(4, 24), UI.INK, width)
	var y := 26.0 + title.get_line_count() * 15.0
	var pay := UI.label(self, posting.pay_text, Vector2(4, y), UI.RED, width)
	y += 4.0 + pay.get_line_count() * 15.0
	UI.panel(self, Rect2(4, y, width, 1), UI.INK_SOFT)
	UI.label(self, "任职要求", Vector2(4, y + 4), UI.INK_SOFT)
	y += 22.0
	for requirement in posting.requirements:
		var line := UI.label(self, "·" + requirement, Vector2(4, y), UI.INK, width)
		y += 2.0 + line.get_line_count() * 15.0
