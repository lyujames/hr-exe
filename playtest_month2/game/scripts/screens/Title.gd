extends Control

signal finished


func _ready() -> void:
	UI.panel(self, Rect2(0, 0, 640, 360), UI.DESK_DARK)
	var logo := UI.label(self, "HR.exe", Vector2(0, 56), UI.GREEN)
	logo.add_theme_font_size_override("font_size", 36)
	logo.size.x = 640
	logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.label(self, "你按规则筛人。规则也在筛你。", Vector2(236, 116), UI.TEXT_DIM)
	UI.label(self, "试玩版 · 第二个月（第 10–16 天）", Vector2(230, 134), UI.TEXT_DIM)
	UI.button(self, "从第二个月开始", Rect2(250, 170, 140, 24), start_month2)
	UI.button(self, "从第一个月开始", Rect2(250, 200, 140, 24), start_new)
	var resume := UI.button(self, "继续", Rect2(250, 230, 140, 24), start_saved)
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


## 直接从第二个月开始：先补两件上个月的事，再看一页这个月的处境。
const MONTH2_INTRO := "四月。\n\n你在蜂巢科技干满了一个月。实习生招满了，三月底那几条实习的规矩收进了抽屉。\n\n这个月招程序员。王总说要“即插即用”的。\n\n孩子报了编程班。你爸出院以后回了自己那边住，离你们家二十分钟。\n\n房贷还有十六年十一个月。"

var _kickback := false
var _xiaoliu := "try"


func start_month2() -> void:
	var page := Control.new()
	page.size = Vector2(640, 360)
	page.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(page)
	UI.panel(page, Rect2(0, 0, 640, 360), UI.DESK_DARK)
	UI.label(page, "上个月的两件事", Vector2(120, 40), UI.GREEN)
	UI.label(page, "3 月 24 日，李哲的简历里夹着他爸的信封，¥300。", Vector2(120, 70), UI.TEXT, 400)
	var take := UI.button(page, "收进了抽屉", Rect2(120, 92, 150, 24), func() -> void: _kickback = true)
	var back := UI.button(page, "退了回去", Rect2(280, 92, 150, 24), func() -> void: _kickback = false)
	UI.label(page, "3 月 16 日晚上，你爸替老单位小刘的儿子开口，问你们公司还招不招人。", Vector2(120, 136), UI.TEXT, 400)
	var try := UI.button(page, "让他投个简历试试", Rect2(120, 174, 150, 24), func() -> void: _xiaoliu = "try")
	var hard := UI.button(page, "我也说不上话", Rect2(280, 174, 150, 24), func() -> void: _xiaoliu = "hard")
	for pair in [[take, back], [try, hard]]:
		var group := ButtonGroup.new()
		for b: Button in pair:
			b.toggle_mode = true
			b.button_group = group
	back.button_pressed = true
	try.button_pressed = true
	UI.button(page, "继续", Rect2(260, 300, 120, 24), _show_month2_intro.bind(page))


func _show_month2_intro(previous: Control) -> void:
	previous.queue_free()
	var page := Control.new()
	page.size = Vector2(640, 360)
	page.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(page)
	UI.panel(page, Rect2(0, 0, 640, 360), UI.DESK_DARK)
	UI.label(page, MONTH2_INTRO, Vector2(120, 40), UI.TEXT, 400)
	UI.button(page, "去上班", Rect2(260, 300, 120, 24), func() -> void:
		GameState.new_game_month2(_kickback, _xiaoliu)
		finished.emit())
