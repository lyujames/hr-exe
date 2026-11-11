class_name QuestionCard extends Resource
## 回答按属性抽取：高表演力背标准答案、诚实者说真话、其余露出破绽。
## 追问顺着第一层的回答往下挖：背的接不上，说实话的越说越具体，露破绽的越问越慌。

@export var id: StringName
@export var text_key: String
## 探测的隐藏属性名（Candidate 的字段）。
@export var probes: PackedStringArray
@export var honest: String      # 诚实且属性高
@export var honest_low: String  # 诚实且属性低
@export var standard: String    # 标准答案
@export var flaw: String        # 破绽
## 现场测试：表演不出来，只看属性。
@export var always_truthful := false
## 尖锐题：问的是细节和数字，模板接不住。表演力要到 SHARP_BLUFF 才背得下来，
## 平时能背过去的人（70–84）在这里只能说实话或露破绽；背下来的人追问时直接冒汗。
@export var sharp := false
## 表演力到多少就背标准答案；0 表示按 sharp 取 BLUFF / SHARP_BLUFF。简历行的卡按有没有水分另算（见 ResumeQuestions）。
@export var bluff_at := 0
## 问谁："all"、"intern"（实习生）、"grad"（在读研究生实习生）、"regular"（社招）。
@export var audience := "all"
## 只对有空窗期的人可用。
@export var requires_gap := false
## 问了这张卡，诉讼风险累积多少。
@export var lawsuit_risk := 0
@export_group("追问")
## 追问的那句话；空表示这张卡不能追问（现场测试本来就问不出别的）。
@export var followup_text: String
@export var honest_followup: String      # 诚实且属性高：说得更具体
@export var honest_low_followup: String  # 诚实且属性低：具体，但短板也露出来
@export var standard_followup: String    # 背的：接不上
@export var flaw_followup: String        # 破绽：更慌
@export_group("主管反应")
## 主管当场改动的评分项；空表示只说话不打分。
@export var chief_item: String
@export var chief_standard: String
@export var chief_honest: String
@export var chief_flaw: String
@export_group("组长反应")
## 组长自己的卡打哪一项（技术 / 协作）；空的话按探的属性算，见 lead_item_for。
@export var lead_item: String
## 组长听到这几种回答时说的话；空就用 LEAD_LINES 里的。
@export var lead_strong: String
@export var lead_weak: String
@export var lead_standard: String
@export var lead_flaw: String
@export_group("男女说法")
## 同一道题，男的和女的心里想的不一样：男的往大里说、往自己身上揽，缺点也说成优点，压力在“养家”；
## 女的先替面试官把没问出口的那句（结婚、生孩子、能不能加班）堵上，功劳往团队身上推，说完还要道个歉。
## 键是上面的字段名（honest / standard_followup / chief_standard……），没写的就用上面那句。
## 女的已经生了孩子（婚育栏写了“已育”），先找“字段名_mom”那句。
@export var male: Dictionary
@export var female: Dictionary


## 平时表演力到这个数就背标准答案。
const BLUFF := 70
const SHARP_BLUFF := 85


func for_audience(c: Candidate) -> bool:
	match audience:
		"all":
			return true
		"grad":
			return c.is_grad()
	return (audience == "intern") == c.is_intern


func available_for(c: Candidate) -> bool:
	return for_audience(c) and (not requires_gap or c.has_gap())


## kind 是 standard / honest / flaw；strong 是被探的属性够不够（说实话的人，说的是好话还是短板）。
func answer(c: Candidate) -> Dictionary:
	var strong := is_strong(c)
	if c.answers.has(String(id)):
		return {"text": c.answers[String(id)], "tic": "none", "kind": c.answer_kind, "strong": strong}
	if always_truthful:
		return {"text": said(c, "honest" if strong else "honest_low"), "tic": "none", "kind": "honest", "strong": strong}
	if c.performance >= bluff_threshold():
		return {"text": said(c, "standard"), "tic": "none", "kind": "standard", "strong": strong}
	if c.honesty >= 55:
		return {"text": said(c, "honest" if strong else "honest_low"), "tic": "none", "kind": "honest", "strong": strong}
	return {"text": said(c, "flaw"), "tic": "sweat" if c.honesty < 30 else "eyes", "kind": "flaw", "strong": strong}


## 这句话 TA 怎么说：先看男女说法里有没有，没有用通用那句。
func said(c: Candidate, field: String) -> String:
	var own: Dictionary = female if c.is_female() else male
	if c.is_female() and c.marital.contains("已育") and own.has(field + "_mom"):
		return own[field + "_mom"]
	return own.get(field, get(field))


func bluff_threshold() -> int:
	if bluff_at > 0:
		return bluff_at
	return SHARP_BLUFF if sharp else BLUFF


func is_strong(c: Candidate) -> bool:
	var total := 0
	for attribute in probes:
		total += c.get(attribute)
	return total >= 50 * probes.size()


func can_follow_up() -> bool:
	return followup_text != "" and not always_truthful


## 追问顺着第一层走：first 是 answer() 的返回值。手写人物的追问写在 answers 里，键是“卡 id+”。
## 手写人物只写了第一层的，追问用旁白带过，不替 TA 编台词。
func follow_up(c: Candidate, first: Dictionary) -> Dictionary:
	var key := String(id) + "+"
	if c.answers.has(key):
		return {"text": c.answers[key], "tic": "none", "kind": c.answer_kind, "strong": first.strong}
	match first.kind:
		"standard":
			return {"text": said(c, "standard_followup"), "tic": "sweat" if sharp else "eyes", "kind": "standard", "strong": first.strong}
		"flaw":
			return {"text": said(c, "flaw_followup"), "tic": escalate(first.tic), "kind": "flaw", "strong": first.strong}
	if c.answers.has(String(id)) and first.kind == "honest":
		var told := "（TA 想了想，一条一条往下说：什么时候、几个人、多少数字，前后都对得上。）" if first.strong \
			else "（TA 说得很细，细到连自己没做好的地方也一起说了。）"
		return {"text": told, "tic": "none", "kind": "honest", "strong": first.strong}
	return {"text": said(c, "honest_followup" if first.strong else "honest_low_followup"), "tic": "none", "kind": "honest", "strong": first.strong}


## 越问越慌：眼神乱飘 → 冒汗 → 手抖。
static func escalate(tic: String) -> String:
	match tic:
		"none":
			return "eyes"
		"eyes":
			return "sweat"
	return "shake"


## 主管只听像不像：背得好加分，说实话减分，露破绽的没抬头。听的是女的，有几句他换个说法。
func chief_reaction(kind: String, c: Candidate = null) -> Dictionary:
	var line := func(field: String) -> String: return said(c, field) if c else get(field)
	match kind:
		"standard":
			return {"line": line.call("chief_standard"), "delta": 1}
		"honest":
			return {"line": line.call("chief_honest"), "delta": -1}
	return {"line": line.call("chief_flaw"), "delta": 0}


## 追问时主管的反应：背的被问穿，把刚才加的分扣回去；说实话又说得出数的，他才服气。
const CHIEF_FOLLOWUP_LINES := {
	"standard": ["刚才说得挺好，怎么一问就不会了？", "背的吧。", "……再想想？"],
	"strong": ["嗯，有数。", "这个说得实在。", "行，是干过的。"],
	"weak": ["问细了就露底。", "那就是没做过。", "……嗯。"],
}


## 组长和主管反着来：他自己写代码，听得出背的。说实话又说得出东西的加分；
## 老实说不会的不扣也不加（实话他认，可组里要会的）；背标准答案、露破绽的都扣。
const LEAD_ITEMS := ["技术", "协作"]
const LEAD_LINES := {
	"strong": ["嗯，干过。", "这个对。", "行，有东西。"],
	"weak": ["不会就说不会，挺好。可我们组要会的。", "……那这块得从头带。", "实话。记下了。"],
	"standard": ["这是网上的标准答案。", "背的吧。", "这些我们组实习生也会背。"],
	"flaw": ["你自己信吗？", "编的。", "……换个问题吧。"],
}


static func lead_item_for(card: QuestionCard) -> String:
	if card.lead_item != "":
		return card.lead_item
	return "技术" if "ability" in card.probes else "协作"


func lead_reaction(reply: Dictionary, pick: int) -> Dictionary:
	var key := _lead_key(reply)
	var own: String = {"strong": lead_strong, "weak": lead_weak, "standard": lead_standard, "flaw": lead_flaw}[key]
	var line: String = own if own != "" else LEAD_LINES[key][pick % 3]
	return {"line": line, "delta": {"strong": 1, "weak": 0, "standard": -1, "flaw": -1}[key]}


## 追问时组长更狠：问穿了的再扣，越说越具体的加两分。
func lead_followup_reaction(reply: Dictionary, pick: int) -> Dictionary:
	var key := _lead_key(reply)
	var lines := {"strong": ["对，就是这么回事。", "这个细节编不出来。", "行。"], "weak": LEAD_LINES.weak,
		"standard": ["一问细就没了。", "刚才那段是背的。", "……行了。"], "flaw": LEAD_LINES.flaw}
	return {"line": lines[key][pick % 3], "delta": {"strong": 2, "weak": 0, "standard": -1, "flaw": -1}[key]}


static func _lead_key(reply: Dictionary) -> String:
	match reply.kind:
		"honest":
			return "strong" if reply.strong else "weak"
		"standard":
			return "standard"
	return "flaw"


func chief_followup_reaction(reply: Dictionary, pick: int) -> Dictionary:
	match reply.kind:
		"standard":
			return {"line": CHIEF_FOLLOWUP_LINES.standard[pick % 3], "delta": -1}
		"honest":
			if reply.strong:
				return {"line": CHIEF_FOLLOWUP_LINES.strong[pick % 3], "delta": 2}
			return {"line": CHIEF_FOLLOWUP_LINES.weak[pick % 3], "delta": -1}
	return {"line": "", "delta": 0}
