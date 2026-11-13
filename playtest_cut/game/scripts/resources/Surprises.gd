class_name Surprises extends RefCounted
## 意外支出（动态难度）：每天早上看存款比“这个月该有的数”多出多少，多得越多，越可能来一件要花钱的事，事也越大。
## 钱紧的玩家（低于目标线 + 余量）不会碰到；同一件事一局只来一次；一个月最多 MAX_PER_MONTH 件，两件之间至少隔 GAP 天。
## 事情从手机上来（老婆 / 你爸），回话的几个选项都要花钱；不回就按第一项（全价）办。
## 钱走的是工资卡（GameState.reply_text 里 stats.sent 那一行），日结单上是“手机转给 X（备注）”一行。
##
## 运气：带 gamble 的那项是“省钱、赌一把”。选了当场掷一次（种子固定，读档不变），1–2 天后手机上揭晓：
##   好（没事，钱省下了）/ 中（补 MID_SHARE）/ 坏（补 BAD_SHARE，比当初付全价还贵，另扣家里）。
## 坏的概率看当时富不富（BAD_ODDS）；连着坏了 PITY 次，下一次一定不坏（坏的那份挪给“好”）。
## 揭晓那条不看富余、不占每月名额，到期必来。

const CUSHION := 250
const RESUME_SHARE := 0.8
const CORRECT_SHARE := 0.6
## 超出目标线多少才开始可能来事。
const THRESHOLD := 250
## 金额 = 超出部分 × SHARE，四舍五入到 ¥10，夹在 [MIN_COST, MAX_COST]。
const SHARE := 0.7
const MIN_COST := 150
const MAX_COST := 1000
const MAX_PER_MONTH := 3
const GAP := 1
## 每月第几天起才可能来（第 1 月前两天还在教学）。
const FIRST_DAY_IN_MONTH := [3, 2, 2]

## 赌一把的结果。概率：中固定 MID_ODDS；坏看掷骰那天早上多出多少；剩下的是好。
const MID_ODDS := 0.3
## [多出不到 0（钱紧）, 正常, 多出 RICH_LINE 以上]
const BAD_ODDS := [0.1, 0.2, 0.3]
const RICH_LINE := 600
## 补多少（占原价）。钱紧的人坏了也只补一个原价，不往下砸。
const MID_SHARE := 0.3
const BAD_SHARE := 1.5
const BAD_SHARE_POOR := 1.0
## 连着坏几次以后，下一次保底不坏。
const PITY := 2
## 揭晓在几天后（含两端），不超过最后一天。
const REVEAL_DELAY := [1, 2]

## 事件池。tier：small（≤¥300）/ mid（≤¥600）/ big（更多），只在对应档位抽到。
## from_day：第几天起才有；when：GameState.family_matches 的条件（你爸那条病是一串）。
## options 里 share 是占这次金额的比例；第一项是全价，不回消息也按它算。gamble：这项要掷骰，结果看 outcomes。
## outcomes.{good,mid,bad}：text 里 {extra} 换成补的钱；from 不写就是原来发消息的人；flag 记进 GameState.family。
## text / label 里的 {cost} {part} 换成第一项 / 当前项的钱。
const POOL := [
	# —— 孩子 ——
	{"id": "fever", "from": "老婆", "tiers": ["small", "mid"], "note": "孩子看病",
		"text": "老婆：孩子烧到 38 度 9，一直喊头疼。儿童医院挂急诊加验血，大概 ¥{cost}。",
		"options": [
			{"key": "hospital", "label": "去医院，我转你。", "share": 1.0, "marriage": 1},
			{"key": "wait", "label": "先吃退烧药，物理降温看看。", "share": 0.3, "gamble": true, "reply": "老婆：……那我今晚守着他。"},
		],
		"outcomes": {
			"good": {"text": "老婆：烧退了。早上自己爬起来喝了两碗粥，背着书包上学去了。"},
			"mid": {"text": "老婆：早上又有点低烧，带他去社区医院开了药，¥{extra}。"},
			"bad": {"text": "老婆：半夜烧到 40 度，抽了一下。打车去的急诊，医生说是肺炎，要住院输液。押金 ¥{extra}。", "marriage": -2, "family": -1},
		}},
	{"id": "glasses", "from": "老婆", "tiers": ["small"], "note": "赔同学眼镜",
		"text": "老婆：老师打电话来，孩子课间打闹把同学眼镜摔了。对方家长要 ¥{cost}，说是进口镜片。",
		"options": [
			{"key": "pay", "label": "赔吧，别让孩子在学校难做。", "share": 1.0, "family": 1},
			{"key": "haggle", "label": "让他们出发票，按一般镜片赔一半。", "share": 0.55, "family": -1, "reply": "老婆：我去说。孩子说他同学不跟他玩了。"},
		]},
	{"id": "trip", "from": "老婆", "tiers": ["small", "mid"], "note": "研学费",
		"text": "老婆：学校的研学营下周出发，班里就咱家没交。¥{cost}。",
		"options": [
			{"key": "pay", "label": "交，别让他一个人留在学校。", "share": 1.0, "family": 1},
			{"key": "skip", "label": "不去了，周末我带他出去玩。", "share": 0.35, "family": -2, "reply": "老婆：我跟他说了。他把房门关上了。"},
		]},
	# —— 你爸（胸口那条是一串：坏了才有下一件） ——
	{"id": "dad_chest", "from": "你爸", "tiers": ["mid", "big"], "note": "你爸做检查", "from_day": 5,
		"text": "你爸：胸口有点闷，老毛病。医生让做个冠脉 CT，¥{cost}。我说开点药就行，你妈非让我问你。",
		"options": [
			{"key": "scan", "label": "爸，做 CT。钱我转你。", "share": 1.0, "family": 1},
			{"key": "pills", "label": "那先开药吃着，过两周再看。", "share": 0.35, "gamble": true, "reply": "你爸：对嘛，我就说没事。"},
		],
		"outcomes": {
			"good": {"text": "你爸：药吃着挺好，昨晚睡了个整觉。你妈非让我跟你说一声。"},
			"mid": {"text": "你爸：昨天又闷了一下，你妈拉我去复查，换了个药。¥{extra}，你妈先垫的。"},
			"bad": {"from": "老婆", "text": "老婆：你爸夜里胸口疼得坐不起来，120 拉走的。医生说再晚点就麻烦了，要住院观察。先交 ¥{extra}。", "family": -2, "flag": {"dad_ill": "1"}},
		}},
	{"id": "dad_worse", "from": "老婆", "tiers": ["small", "mid", "big"], "note": "你爸的药", "when": "dad_ill:1",
		"text": "老婆：你爸出院以后一直喘。医生说心功能又差了一级，建议换进口的药，一个疗程 ¥{cost}，医保报不了。",
		"options": [
			{"key": "import", "label": "换进口的。", "share": 1.0, "family": 1},
			{"key": "local", "label": "先用医保能报的，看看效果。", "share": 0.4, "gamble": true, "reply": "老婆：我跟医生说。"},
		],
		"outcomes": {
			"good": {"text": "老婆：医保的药也管用。你爸今天自己下楼买菜了，还跟楼下吵了两句价钱。"},
			"mid": {"text": "老婆：国产那个吃了脚有点肿，医生加了个利尿的。¥{extra}。"},
			"bad": {"text": "老婆：你爸又住进去了。医生说是心衰，下回再这样就要装起搏器。这次住院 ¥{extra}。", "family": -2, "marriage": -1, "flag": {"dad_ill": "2"}},
		}},
	{"id": "fall", "from": "你爸", "tiers": ["mid", "big"], "note": "拍片",
		"text": "你爸：没事，早上下楼滑了一下。你妈非让我去拍片，说要 ¥{cost}，我说不拍了。",
		"options": [
			{"key": "scan", "label": "爸，拍。钱我转你。", "share": 1.0, "family": 1},
			{"key": "plaster", "label": "先贴膏药看看，不行再去。", "share": 0.3, "gamble": true, "reply": "你爸：好。不疼了。"},
		],
		"outcomes": {
			"good": {"text": "你爸：膏药贴了两天，不疼了。你妈白操心。"},
			"mid": {"text": "你爸：还是有点肿，去社区医院拍了个片子，说没伤着骨头。¥{extra}。"},
			"bad": {"from": "老婆", "text": "老婆：你爸那是骨裂，拖了两天肿得鞋都穿不上。要打石膏，¥{extra}。", "family": -2},
		}},
	{"id": "wedding", "from": "你爸", "tiers": ["mid", "big"], "note": "表弟结婚随礼",
		"text": "你爸：你表弟下个月结婚，你大姑打电话来了。咱家这边随 ¥{cost}，我跟你妈出一半也行。",
		"options": [
			{"key": "full", "label": "我来出，别让你们掏。", "share": 1.0, "family": 1},
			{"key": "half", "label": "那我出一半。", "share": 0.5},
			{"key": "less", "label": "随少点，现在手头紧。", "share": 0.3, "family": -2, "reply": "你爸：……我跟你大姑说吧。"},
		]},
	# —— 家里的东西 ——
	{"id": "heater", "from": "老婆", "tiers": ["small", "mid"], "note": "热水器",
		"text": "老婆：热水器坏了，孩子洗澡洗到一半全是凉水。师傅说换新的 ¥{cost}，修一修能凑合几个月。",
		"options": [
			{"key": "replace", "label": "换新的吧。", "share": 1.0},
			{"key": "fix", "label": "先修，能用就行。", "share": 0.4, "gamble": true},
		],
		"outcomes": {
			"good": {"text": "老婆：师傅修得挺好，说还能再用两三年。"},
			"mid": {"text": "老婆：热水器又滴水了，师傅上门换了个阀，¥{extra}。"},
			"bad": {"text": "老婆：修过的地方又裂了，水漫到客厅。师傅说只能换新的，加上门费 ¥{extra}。", "marriage": -1},
		}},
	{"id": "ebike", "from": "老婆", "tiers": ["small", "mid"], "note": "电动车",
		"text": "老婆：电动车在小区门口被偷了。明天孩子上学怎么送？新的一辆 ¥{cost}。",
		"options": [
			{"key": "new", "label": "买辆新的，我转你。", "share": 1.0, "marriage": 1},
			{"key": "used", "label": "先买辆二手的凑合。", "share": 0.45, "gamble": true, "reply": "老婆：……行吧，二手的。"},
		],
		"outcomes": {
			"good": {"text": "老婆：二手那辆骑着挺顺，孩子说比原来那辆还快。"},
			"mid": {"text": "老婆：二手车电池不行，骑一半没电了。换了块电池 ¥{extra}。"},
			"bad": {"text": "老婆：二手那辆是偷来的，派出所给收走了，钱也要不回来。只能再买辆新的，¥{extra}。", "marriage": -1},
		}},
	{"id": "leak", "from": "老婆", "tiers": ["mid", "big"], "note": "楼下漏水",
		"text": "老婆：楼下来敲门，说咱家卫生间漏水泡了他家天花板。物业说先赔他家 ¥{cost}，防水再另算。",
		"options": [
			{"key": "pay", "label": "赔，找正规的来做防水。", "share": 1.0},
			{"key": "cheap", "label": "找路边的师傅先堵上。", "share": 0.5, "gamble": true, "reply": "老婆：楼下那家脸色很难看。"},
		],
		"outcomes": {
			"good": {"text": "老婆：堵上了。楼下说这两天没再滴。"},
			"mid": {"text": "老婆：又渗了一点，路边那个师傅又来补了一回胶，¥{extra}。"},
			"bad": {"text": "老婆：路边那个没堵住，楼下天花板掉了一整块。物业说这回全额赔，防水还得重做，¥{extra}。", "marriage": -2},
		}},
	{"id": "fridge", "from": "老婆", "tiers": ["big"], "note": "冰箱",
		"text": "老婆：冰箱不制冷了，一冰箱的菜和你爸的药全化了。修不了，新的 ¥{cost}。",
		"options": [
			{"key": "new", "label": "买，药不能放坏。", "share": 1.0},
			{"key": "small", "label": "买个小的先放药。", "share": 0.5, "gamble": true},
		],
		"outcomes": {
			"good": {"text": "老婆：小冰箱放药刚好，菜就每天现买吧。"},
			"mid": {"text": "老婆：小冰箱塞不下，菜又坏了一回。补买的 ¥{extra}。"},
			"bad": {"text": "老婆：小冰箱压缩机响了一夜，第二天就不制冷了。你爸的药又坏了一批，重新开药加换个正经冰箱，¥{extra}。", "family": -1, "marriage": -1},
		}},
	# —— 大人自己 ——
	{"id": "tooth", "from": "老婆", "tiers": ["mid", "big"], "note": "看牙",
		"text": "老婆：牙疼了三天，今天实在扛不住去看了。医生说要做根管加牙冠，¥{cost}。",
		"options": [
			{"key": "treat", "label": "做吧，别拖。", "share": 1.0, "marriage": 1},
			{"key": "later", "label": "先做根管，牙冠下个月再说。", "share": 0.4, "gamble": true, "reply": "老婆：嗯。你先忙。"},
		],
		"outcomes": {
			"good": {"text": "老婆：根管做完就不疼了。牙冠真不急，医生也说先这样。"},
			"mid": {"text": "老婆：临时的那个掉了，又去粘了一回，¥{extra}。"},
			"bad": {"text": "老婆：那颗牙咬饭咬裂了，拔了。医生说现在只能种牙，¥{extra}。", "marriage": -2},
		}},
	{"id": "ticket", "from": "老婆", "tiers": ["small"], "note": "违停罚款加拖车",
		"text": "老婆：车停医院门口被拖了。罚款加拖车费 ¥{cost}，交了才放车。",
		"options": [
			{"key": "pay", "label": "交吧，我转你。", "share": 1.0},
		]},
]


## 第 d 天早上存款至少该有多少，到月底才付得起（没算今天的工资）。
static func target(d: int) -> int:
	var last := GameState.month_last_day(GameState.month_of(d))
	var need := GameState.MORTGAGE + CUSHION
	for i in range(d, last + 1):
		var cfg: DayConfig = RuleEngine.load_day(i)
		var pay: Dictionary = RuleEngine.pay(i)
		var n := cfg.resume_count
		need -= int(pay.get("base", 0)) + int(float(int(pay.get("per_resume", 0)) * n) * RESUME_SHARE) + int(float(int(pay.get("per_correct", 0)) * n) * CORRECT_SHARE)
		for b: Dictionary in cfg.bills:
			need += int(b.get("amount", 0))
	return need


## 今天早上比目标线多出多少（负数是不够）。
static func surplus(d: int, savings: int) -> int:
	return savings - target(d)


static func tier_of(cost: int) -> String:
	if cost <= 300:
		return "small"
	if cost <= 600:
		return "mid"
	return "big"


static func event(id: String) -> Dictionary:
	for e: Dictionary in POOL:
		if e.id == id:
			return e
	return {}


## 这件事今天能不能来（第几天起、家里的条件）。
static func available(e: Dictionary, d: int) -> bool:
	return d >= int(e.get("from_day", 0)) and GameState.family_matches(e.get("when", ""))


## 早上决定今天来不来事。history：之前来过的 [{day, id, cost}]。force：修改器用，不看门槛和次数。
## 返回要发到手机上的那条消息（desk_texts 的格式，带 surprise 字段），不来事返回 {}。
static func pick(d: int, savings: int, history: Array, seed: int, force := false) -> Dictionary:
	var m := GameState.month_of(d)
	var extra := surplus(d, savings)
	if not force:
		if d - GameState.month_first_day(m) + 1 < FIRST_DAY_IN_MONTH[clampi(m - 1, 0, FIRST_DAY_IN_MONTH.size() - 1)]:
			return {}
		if extra < THRESHOLD:
			return {}
		var this_month := history.filter(func(h: Dictionary) -> bool: return GameState.month_of(int(h.day)) == m)
		if this_month.size() >= MAX_PER_MONTH:
			return {}
		if history.any(func(h: Dictionary) -> bool: return d - int(h.day) <= GAP):
			return {}
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed, d, "surprise"])
	# 多出来越多越容易来：刚过门槛一半，多出 ¥600 以上必来
	if not force and rng.randf() > clampf(float(extra) / 600.0, 0.5, 1.0):
		return {}
	var cost := clampi(int(round(maxf(extra, 0) * SHARE / 10.0)) * 10, MIN_COST, MAX_COST)
	var tier := tier_of(cost)
	var used := history.map(func(h: Dictionary) -> String: return String(h.id))
	var open := POOL.filter(func(e: Dictionary) -> bool: return e.id not in used and available(e, d))
	var candidates := open.filter(func(e: Dictionary) -> bool: return tier in e.tiers)
	# 你爸那条病接上了就先来（一串里的下一件不等抽签）
	var chain := candidates.filter(func(e: Dictionary) -> bool: return e.has("when"))
	if not chain.is_empty():
		candidates = chain
	if candidates.is_empty():
		candidates = open
	if candidates.is_empty():
		return {}
	var ev: Dictionary = candidates[rng.randi_range(0, candidates.size() - 1)]
	# 本档的事用完了借别档的：钱不超过那件事最高一档的上限（赔副眼镜不会要 ¥900）
	if "big" not in ev.tiers:
		cost = mini(cost, 600 if "mid" in ev.tiers else 300)
	return build(ev, cost, rng.randi_range(600, 870))


## 把事件池里的一项变成一条手机消息。
static func build(ev: Dictionary, cost: int, at: int) -> Dictionary:
	var replies := []
	for o: Dictionary in ev.options:
		var part := maxi(int(round(cost * float(o.share) / 10.0)) * 10, 10)
		var r := {"key": o.key, "label": String(o.label).replace("{cost}", str(cost)).replace("{part}", str(part)),
			"transfer": part, "note": ev.note, "marriage": int(o.get("marriage", 0)), "family": int(o.get("family", 0)),
			"gamble": bool(o.get("gamble", false))}
		if o.has("reply"):
			r["after"] = o.reply
		replies.append(r)
	return {"id": "surprise_" + String(ev.id), "from": ev.from, "at": at, "surprise": ev.id, "cost": cost,
		"text": String(ev.text).replace("{cost}", str(cost)), "replies": replies}


## 这次掷骰的概率 {good, mid, bad}。extra：掷骰那天早上多出多少；streak：之前连着坏了几次。
static func odds(extra: int, streak: int) -> Dictionary:
	var bad: float = BAD_ODDS[1]
	if extra < 0:
		bad = BAD_ODDS[0]
	elif extra >= RICH_LINE:
		bad = BAD_ODDS[2]
	if streak >= PITY:
		bad = 0.0
	return {"good": 1.0 - MID_ODDS - bad, "mid": MID_ODDS, "bad": bad}


## 掷一次：返回 good / mid / bad。seed 固定，同一局同一天同一件事永远一样。force：修改器指定结果。
static func roll(extra: int, streak: int, seed: int, force := "") -> String:
	if force in ["good", "mid", "bad"]:
		return force
	var o := odds(extra, streak)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var x := rng.randf()
	if x < o.bad:
		return "bad"
	if x < o.bad + o.mid:
		return "mid"
	return "good"


## 结果要补多少钱（好是 0）。poor：掷骰那天钱紧。
static func extra_cost(outcome: String, cost: int, poor: bool) -> int:
	var share := 0.0
	if outcome == "mid":
		share = MID_SHARE
	elif outcome == "bad":
		share = BAD_SHARE_POOR if poor else BAD_SHARE
	return int(round(cost * share / 10.0)) * 10


## 选了赌一把的那项：掷骰，排进后账。返回 {outcome, item}；item 是要放进 GameState.surprise_queue 的一项。
static func gamble(d: int, ev_id: String, cost: int, extra: int, streak: int, seed: int, force := "") -> Dictionary:
	var outcome := roll(extra, streak, hash([seed, d, ev_id, "outcome"]), force)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed, d, ev_id, "reveal"])
	var due := mini(d + rng.randi_range(REVEAL_DELAY[0], REVEAL_DELAY[1]), GameState.LAST_DAY)
	return {"outcome": outcome, "item": {"id": ev_id, "day": d, "due": due, "outcome": outcome,
		"amount": extra_cost(outcome, cost, extra < 0), "at": rng.randi_range(540, 700)}}


## 第 d 天要揭晓的后账，变成手机消息（没有回话，钱自动转，GameState.close_surprise 里扣）。
static func reveals(d: int, queue: Array) -> Array:
	var out := []
	for q: Dictionary in queue:
		if int(q.due) != d:
			continue
		var ev := event(String(q.id))
		if ev.is_empty():
			continue
		var o: Dictionary = ev.outcomes[q.outcome]
		var amount := int(q.amount)
		out.append({"id": "reveal_%s" % q.id, "from": o.get("from", ev.from), "at": int(q.at), "reveal": q.outcome, "surprise": q.id,
			"text": String(o.text).replace("{extra}", str(amount)), "transfer": amount, "note": ev.note + ("（又）" if amount > 0 else ""),
			"marriage": int(o.get("marriage", 0)), "family": int(o.get("family", 0)), "flag": o.get("flag", {})})
	return out
