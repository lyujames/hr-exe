extends Control
## 报纸头条与家人短信：世界与家人的反应。

signal finished


func _ready() -> void:
	var cfg := GameState.config
	var headline := cfg.headline
	var body := cfg.news_body
	var event_id: String = GameState.event_today.get("id", "")
	if cfg.news_by_event.has(event_id):
		headline = cfg.news_by_event[event_id][0]
		body = cfg.news_by_event[event_id][1]
	UI.panel(self, Rect2(0, 0, 640, 360), UI.DESK_DARK)
	UI.panel(self, Rect2(40, 20, 360, 300), UI.PAPER, UI.BLACK)
	UI.label(self, "The Daily Ledger", Vector2(52, 28), UI.INK_SOFT)
	UI.label(self, GameState.today, Vector2(310, 28), UI.INK_SOFT)
	UI.panel(self, Rect2(52, 46, 336, 1), UI.INK)
	UI.label(self, headline, Vector2(52, 58), UI.INK, 336)
	UI.panel(self, Rect2(52, 100, 336, 1), UI.INK_SOFT)
	UI.label(self, body, Vector2(52, 110), UI.INK, 336)

	UI.panel(self, Rect2(420, 60, 186, 180), Color("161b1a"), UI.BLACK)
	UI.label(self, "Messages", Vector2(430, 66), UI.GREEN)
	UI.label(self, cfg.family_sms, Vector2(430, 86), UI.TEXT, 166)
	if GameState.family_state < 0:
		UI.label(self, "(You didn't reply.)", Vector2(430, 216), UI.TEXT_DIM)
	var next := "Head home" if GameState.day >= GameState.LAST_DAY else "Next day"
	UI.button(self, next, Rect2(420, 296, 186, 24), finished.emit)
