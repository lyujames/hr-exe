extends Control
## 报纸头条与家人短信：世界与家人的反应。

signal finished

var _next: Button
var _replies: Array[Button] = []


func _ready() -> void:
	var cfg := GameState.config
	var headline := cfg.headline
	var body := cfg.news_body
	var event_id: String = GameState.event_today.get("id", "")
	var echo := GameState.story_echo()
	var sms := GameState.family_sms()
	if echo.get("sms", "") != "":
		sms = echo.sms + "\n" + sms
	if echo.get("headline", "") != "":
		headline = echo.headline
		body = echo.get("body", "")
	if cfg.news_by_event.has(event_id):
		headline = cfg.news_by_event[event_id][0]
		body = cfg.news_by_event[event_id][1]
	UI.panel(self, Rect2(0, 0, 640, 360), UI.DESK_DARK)
	UI.panel(self, Rect2(40, 20, 360, 300), UI.PAPER, UI.BLACK)
	UI.label(self, "本市晚报", Vector2(52, 28), UI.INK_SOFT)
	UI.label(self, GameState.today, Vector2(310, 28), UI.INK_SOFT)
	UI.panel(self, Rect2(52, 46, 336, 1), UI.INK)
	UI.label(self, headline, Vector2(52, 58), UI.INK, 336)
	UI.panel(self, Rect2(52, 100, 336, 1), UI.INK_SOFT)
	UI.label(self, body, Vector2(52, 110), UI.INK, 336)

	UI.panel(self, Rect2(420, 60, 186, 154), Color("161b1a"), UI.BLACK)
	UI.label(self, "短信", Vector2(430, 66), UI.GREEN)
	UI.label(self, sms, Vector2(430, 86), UI.TEXT, 166)
	_next = UI.button(self, "回家", Rect2(420, 296, 186, 24), finished.emit)
	var options := GameState.sms_options()
	if options.is_empty():
		if GameState.family_state < 0:
			UI.label(self, "（你没有回复。）", Vector2(430, 192), UI.TEXT_DIM)
		return
	# 今晚可以回：选一句才能去第二天
	_next.visible = false
	# 宽度固定，字长就折行变高；从下往上排，最后一个贴着原来“第二天”按钮的底
	for option: Dictionary in options:
		_replies.append(UI.text_button(self, option.label, Rect2(420, 0, 186, 22), _reply.bind(option)))
	var y := 320.0
	for i in range(_replies.size() - 1, -1, -1):
		y -= _replies[i].size.y
		_replies[i].position.y = y
		y -= 2.0


func _reply(option: Dictionary) -> void:
	GameState.answer_sms(option)
	Sfx.key()
	for b in _replies:
		b.queue_free()
	_replies = []
	var silent: bool = option.key == "silent"
	UI.label(self, "（你没有回复。）" if silent else "你：" + option.label, Vector2(430, 192), UI.TEXT_DIM if silent else UI.GREEN, 166)
	_next.visible = true
