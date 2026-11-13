extends Node
## 意外支出的运气：概率、保底（连坏两次第三次不坏）、种子固定、后账揭晓扣钱、读档后后账还在、你爸那条病接得上。
## 用法：Godot --headless --path . res://tests/SurpriseLuck.tscn

var _errors: Array[String] = []


func _check(ok: bool, what: String) -> void:
	if not ok:
		_errors.append(what)


func _ready() -> void:
	await get_tree().process_frame
	var gs = get_node("/root/GameState")

	# 1. 概率：加起来是 1；连坏到 PITY 次坏是 0
	for extra in [-200, 300, 900]:
		for streak in [0, 1, 2, 3]:
			var o := Surprises.odds(extra, streak)
			_check(absf(o.good + o.mid + o.bad - 1.0) < 0.0001, "概率加起来不是 1：%d %d" % [extra, streak])
			_check((o.bad == 0.0) == (streak >= Surprises.PITY), "保底不对：%d %d → %s" % [extra, streak, o])

	# 2. 模拟：每局连着赌 8 次，看坏的比例、有没有连坏三次
	for extra in [-200, 300, 900]:
		var bad := 0
		var first := 0
		var three := 0
		var runs := 3000
		for run in runs:
			var streak := 0
			for i in 8:
				var r := Surprises.roll(extra, streak, hash([run, extra, i]))
				if i == 0 and r == "bad":
					first += 1
				if r == "bad":
					bad += 1
					streak += 1
					if streak >= 3:
						three += 1
				else:
					streak = 0
		var want: float = Surprises.odds(extra, 0).bad
		print("多出 %d：第一次坏 %.3f（应 %.2f），8 次里坏 %.3f，连坏三次 %d" % [extra, float(first) / runs, want, float(bad) / (runs * 8), three])
		_check(absf(float(first) / runs - want) < 0.03, "多出 %d 坏的比例不对" % extra)
		_check(three == 0, "多出 %d 出现了连坏三次" % extra)

	# 3. 种子固定
	var a := Surprises.gamble(7, "fever", 270, 300, 0, 4242)
	var b := Surprises.gamble(7, "fever", 270, 300, 0, 4242)
	_check(a == b, "同一个种子掷出来不一样")

	# 4. 整条走一遍：第 7 天来发烧，选退烧药，修改器定成坏
	gs.new_game(4242, 7)
	gs.surprise_today = Surprises.build(Surprises.event("fever"), 270, 0)
	gs.receive_text(gs.surprise_today)
	var gamble_opt: Dictionary = gs.surprise_today.replies.filter(func(o: Dictionary) -> bool: return o.gamble)[0]
	gs.reply_text(gs.surprise_today, gamble_opt)
	gs.luck_force = "bad"
	gs.close_surprise()
	gs.close_surprise()
	_check(gs.luck_streak == 1, "坏了一次连坏应是 1，是 %d" % gs.luck_streak)
	_check(gs.surprise_queue.size() == 1, "后账应有一条：%s" % [gs.surprise_queue])
	_check(gs.luck_force == "", "修改器定的结果用完没清")
	var q: Dictionary = gs.surprise_queue[0]
	var poor: bool = Surprises.surplus(7, int(gs.morning.savings)) < 0
	var want_amount := Surprises.extra_cost("bad", 270, poor)
	_check(want_amount == (270 if poor else 400), "补钱算法不对：%d" % want_amount)  # 270×1.5=405 四舍五入到 ¥10
	_check(int(q.amount) == want_amount, "坏的补钱应是 ¥%d，是 %d" % [want_amount, q.amount])
	_check(int(q.due) in [8, 9], "揭晓日不在 1–2 天后：%d" % q.due)
	# 到揭晓那天早上，存档、读档，后账还在
	gs.day = int(q.due)
	gs.begin_day()
	_check(gs.reveal_today.size() == 1, "揭晓那天没有后账消息")
	var saved: Dictionary = gs.morning.duplicate(true)
	gs.load_dict(saved)
	_check(gs.reveal_today.size() == 1, "读档以后后账没了")
	gs.close_surprise()
	gs.close_surprise()
	var sent: Array = gs.stats.sent.filter(func(t: Dictionary) -> bool: return t.note.begins_with("孩子看病"))
	_check(sent.size() == 1 and int(sent[0].amount) == want_amount, "后账没扣或扣了两次：%s" % [gs.stats.sent])
	_check(gs.surprise_queue.is_empty(), "后账扣完没删")
	_check(gs.surprises[0].get("revealed", -1) == want_amount, "来过的记录里没写揭晓了多少")

	# 5. 保底接在整条上：再坏一次，第三次 odds 里坏是 0
	gs.luck_streak = 2
	_check(Surprises.odds(900, gs.luck_streak).bad == 0.0, "连坏两次后还可能坏")

	# 6. 你爸那条：胸口闷坏了 → dad_ill:1 → 下一件只会是 dad_worse
	gs.new_game(4242, 6)
	_check(not Surprises.available(Surprises.event("dad_worse"), 6), "dad_worse 没接上就能来")
	gs.surprise_today = Surprises.build(Surprises.event("dad_chest"), 500, 0)
	gs.receive_text(gs.surprise_today)
	gs.reply_text(gs.surprise_today, gs.surprise_today.replies[1])
	gs.luck_force = "bad"
	gs.close_surprise()
	var due: int = gs.surprise_queue[0].due
	gs.day = due
	gs.begin_day()
	gs.close_surprise()
	_check(gs.family.get("dad_ill", "") == "1", "胸口那条坏了没记 dad_ill")
	_check(Surprises.available(Surprises.event("dad_worse"), due), "dad_ill:1 以后 dad_worse 还不能来")
	var hit := false
	for s in 60:
		var p := Surprises.pick(due + 2, 20000, gs.surprises, s, true)
		if not p.is_empty():
			_check(p.surprise == "dad_worse", "接上以后抽到的不是 dad_worse：%s" % p.surprise)
			hit = true
			break
	_check(hit, "接上以后一次都没抽到")

	# 7. 没回消息：按全价办，不掷骰
	gs.new_game(4242, 7)
	gs.surprise_today = Surprises.build(Surprises.event("heater"), 300, 0)
	gs.close_surprise()
	_check(gs.surprise_queue.is_empty() and gs.luck_streak == 0, "没回也掷骰了")

	# 8. 保底：存款 0 的人每个月也正好来一件，¥MIN_COST，在保底日或之后、月底之前
	for seed in 40:
		gs.new_game(seed, 1)
		var hist := []
		for d in range(1, gs.LAST_DAY + 1):
			var p := Surprises.pick(d, 0, hist, seed)
			if not p.is_empty():
				hist.append({"day": d, "id": p.surprise, "cost": p.cost})
				_check(p.floor and int(p.cost) == Surprises.MIN_COST, "钱紧的人来了不是保底的小事：第 %d 天 %s" % [d, p])
		for m in [1, 2, 3]:
			var got := hist.filter(func(h: Dictionary) -> bool: return gs.month_of(int(h.day)) == m)
			_check(got.size() == 1, "种子 %d 第 %d 月保底来了 %d 件" % [seed, m, got.size()])
			if got.size() == 1:
				_check(int(got[0].day) >= Surprises.floor_day(m, seed) and int(got[0].day) < gs.month_last_day(m), "保底日不对：%s" % [got])

	print("ERRORS: ", _errors.size())
	for e in _errors:
		print("  ", e)
	print("SURPRISE LUCK DONE")
	get_tree().quit()
