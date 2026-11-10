class_name HomeScreen extends Control
## 下班回家：18:00 下班，到家快七点。跟老婆、孩子说几句话，一句一句往下点。
## 台词在 DayConfig.home_scene；有的地方要你选一句，选的话记进 GameState.family，夫妻感情跟着变。

signal finished

## 一页写满就翻页，不往按钮上压。
const PAGE_BOTTOM := 292.0
const TOP := 46.0

var _queue: Array = []
var _page: Control
var _y := TOP
var _next: Button
var _options: Array[Button] = []


func _ready() -> void:
	var cfg := GameState.config
	UI.panel(self, Rect2(0, 0, 640, 360), UI.DESK_DARK)
	var d := DateUtil.parse(GameState.today)
	UI.label(self, "%d 月 %d 日（%s），晚上" % [d.y, d.z, DateUtil.weekday(GameState.today)], Vector2(40, 18), UI.GREEN)
	_page = Control.new()
	add_child(_page)
	_next = UI.button(self, "……", Rect2(484, 328, 110, 24), _advance)
	_queue = cfg.home_scene.duplicate(true)
	if GameState.clocked_day() and not GameState.stats.left_early:
		_fit_to_clock()
	_advance()


## 按组招的日子下班不固定：台词里写死的“到家 18:50”换成实际到家的钟点；回得晚，开头多一两句。
func _fit_to_clock() -> void:
	var home := GameState.home_minutes()
	var at := GameState.clock_text(home)
	var re := RegEx.create_from_string("到家 \\d{1,2}:\\d{2}")
	for beat: Dictionary in _queue:
		if beat.has("text"):
			beat.text = re.sub(beat.text, "到家 " + at)
	var extra: Array = []
	if home >= GameState.LATE_HOME[1]:
		extra = [{"text": "孩子已经睡了。门缝底下的灯是关的。"}, {"text": "老婆：饭在锅里。我先睡了。"}]
	elif home >= GameState.LATE_HOME[0]:
		extra = [{"text": "饭在锅里，老婆热过一遍了。"}, {"text": "老婆：又这么晚。"}]
	# 接在“到家”那句后面；没有那句就放最前面
	var after := 0
	for i in _queue.size():
		if str(_queue[i].get("text", "")).contains("到家"):
			after = i + 1
			break
	for i in range(extra.size() - 1, -1, -1):
		_queue.insert(after, extra[i])


## 往下走一拍：台词就印出来，问话就摆出选项，没有了就去睡觉。
func _advance() -> void:
	while not _queue.is_empty():
		var beat: Dictionary = _queue.pop_front()
		if not GameState.family_matches(beat.get("when", "")):
			continue
		if beat.has("ask"):
			_ask(beat)
		else:
			# 一拍旁白也能带后果（破格面老婆那场、你爸塞的信封）：印出来就算
			GameState.apply_effects(beat.get("effects", {}))
			_say(beat.text)
		return
	_next.text = "睡觉" if not GameState.is_month_end() else "继续"
	_next.pressed.disconnect(_advance)
	_next.pressed.connect(finished.emit, CONNECT_ONE_SHOT)


func _say(text: String) -> void:
	text = text.replace("{processed}", str(GameState.stats.processed)).replace("{passed}", str(GameState.passed_today.size()))
	# 你说的绿、孩子说的黄、老婆和你爸白，旁白灰
	var color := UI.TEXT_DIM
	if text.begins_with("你："):
		color = UI.GREEN
	elif text.begins_with("孩子："):
		color = UI.YELLOW
	elif text.begins_with("老婆：") or text.begins_with("你爸：") or text.begins_with("李哲他爸："):
		color = UI.TEXT
	var probe := UI.label(_page, text, Vector2(40, _y), color, 560)
	var h := maxf(16.0, probe.get_line_count() * 15.0)
	if _y > TOP and _y + h > PAGE_BOTTOM:
		UI.clear(_page)
		_y = TOP
		probe = UI.label(_page, text, Vector2(40, _y), color, 560)
	_y += h + 6.0


## 选项排在台词下面；放不下就先翻页。
func _ask(beat: Dictionary) -> void:
	_next.visible = false
	var options: Array = beat.options.filter(func(o: Dictionary) -> bool: return GameState.family_matches(o.get("when", "")))
	for option: Dictionary in options:
		var label: String = option.label
		# 晚到的选项先说清楚代价；今天破格了的，明天下午还有你单独面的那场
		if option.has("late"):
			var at := 8 * 60 + int(option.late)
			label += "（明天 %02d:%02d 才到公司" % [at / 60, at % 60]
			label += "，14:00 还有你担保的面试）" if not GameState.vouched_today.is_empty() else "）"
		_options.append(UI.text_button(self, label, Rect2(56, 0, 520, 22), _choose.bind(beat, option)))
	var total := 0.0
	for b in _options:
		total += b.size.y + 4.0
	if _y + total > 324.0:
		UI.clear(_page)
		_y = TOP
	var y := _y
	for b in _options:
		b.position.y = y
		y += b.size.y + 4.0


func _choose(beat: Dictionary, option: Dictionary) -> void:
	GameState.answer_home(beat.ask, option)
	for b in _options:
		b.queue_free()
	_options = []
	_next.visible = true
	_say(option.get("say", "你：" + option.label))
	# 选完接着说的话插到队头
	var then: Array = option.get("then", [])
	for i in range(then.size() - 1, -1, -1):
		_queue.push_front(then[i])
