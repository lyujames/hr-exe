extends Control

signal finished


func _ready() -> void:
	UI.panel(self, Rect2(0, 0, 640, 360), UI.DESK_DARK)
	var logo := UI.label(self, "HR.exe", Vector2(0, 56), UI.GREEN)
	logo.add_theme_font_size_override("font_size", 36)
	logo.size.x = 640
	logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.label(self, "你按规则筛人。规则也在筛你。", Vector2(236, 116), UI.TEXT_DIM)
	UI.label(self, "垂直切片 · 第一个月（第 1–7 天）", Vector2(230, 134), UI.TEXT_DIM)
	UI.button(self, "开始上班", Rect2(260, 176, 120, 24), start_new)
	var resume := UI.button(self, "继续", Rect2(260, 206, 120, 24), start_saved)
	resume.disabled = not SaveManager.has_save()
	UI.label(self, "全部拖拽与点击操作，鼠标即可。", Vector2(236, 330), UI.TEXT_DIM)


## 你是谁：开新局先看一页背景。
const INTRO := "你，三十四岁。\n\n在星桥网络做了十年 HR。你进去的时候它正当红，现在它是“老牌互联网公司”。去年降本增效，裁员名单是你拟的。名单定稿那天，你开始投简历。\n\n两周前，你跳槽到了蜂巢科技。早上八点上班，晚上六点下班，地铁四十分钟。除了赵主管，部门里年纪最大的同事二十九岁。赵主管是创始员工，公司还在居民楼里办公的时候他就在了。\n\n老婆在一家贸易公司做会计。孩子上小学四年级。你爸一个人住在老房子里。\n\n房贷还有十七年。"


func start_new() -> void:
	var page := Control.new()
	page.size = Vector2(640, 360)
	page.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(page)
	UI.panel(page, Rect2(0, 0, 640, 360), UI.DESK_DARK)
	UI.label(page, INTRO, Vector2(120, 50), UI.TEXT, 400)
	UI.button(page, "去上班", Rect2(260, 300, 120, 24), func() -> void:
		GameState.new_game()
		finished.emit())


func start_saved() -> void:
	if SaveManager.load_game():
		finished.emit()
