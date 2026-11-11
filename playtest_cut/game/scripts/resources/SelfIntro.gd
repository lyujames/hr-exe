class_name SelfIntro
## 面试开场的自我介绍：TA 嘴上说的一份材料，一句一句绑着简历上的一行（key）。
## 没水分的行照实说。有水分的行（ResumeQuestions.padded）可能露出来：
##   说漏（mismatch）：嘴上的数和纸上的对不上——嘴上说的是真的，纸上那个是灌过水的；
##   绕开（skip）：开场你点名要 TA 说的那几样，偏偏这一样没提；
##   表演到家的照着纸念，一点看不出来（这种只能靠问）。
## 没水分的行偶尔嘴瓢、马上自己改口（misspeak）：听着像破绽，其实不是——划它就是抓字眼。
## 种子跟着头像种子和行走，读档重来说的还是那几句。
##
## 听的时候可以划句子；划过的句子连着简历那一行。问那一行就成了对质（confront）：
## 拿 TA 自己的话顶 TA，背答案的门槛往下降。简历上红笔圈过、自我介绍里又绕开没说的行，问的时候也是对质。

const ASK_INTERN := "先做个自我介绍吧：学校专业、绩点、每周能来几天、做过什么、会什么，都说说。"
const ASK_SOCIAL := "先做个自我介绍吧：工作几年、上一份做什么、中间有没有断过，都说说。"
## 表演到这个数，纸上写什么嘴上说什么。
const SMOOTH_AT := 75
## 没水分的数字行，嘴瓢一下再改口的概率。
const MISSPEAK := 0.08
## 有水分、又不够诚实的：绕开不说的概率（其余说漏）。
const SKIP := 0.4
## 对质时背答案的门槛往下降多少：自己刚说的话，圆不回来。
const CONFRONT_EASE := 15
## 对质时背得住的人怎么圆。男的说是口误，女的先道歉。
const CONFRONT_STANDARD := "刚才是我说错了，以简历上的为准。"
const CONFRONT_STANDARD_MALE := "刚才口误。以简历上的为准。"
const CONFRONT_STANDARD_FEMALE := "对不起，刚才是我说错了，以简历上的为准。"
## 你划了一句没毛病的话去对质：TA 莫名其妙，主管嫌你抠字眼。
const PETTY_LINE := "你抓字眼干嘛。"
const PETTY_LOYALTY := 5
## 有水分的技能说漏时怎么说，轮着用。
const SKILL_ADMITS := ["只上过几节课", "学过一点", "跟着教程弄过一次"]
## 项目里算“领头”的角色：有水分时真相是打下手，否则是只去过几次。
const LEAD_ROLES := ["负责人", "核心成员", "队长"]
## 这几样是开场点了名要说的：没提就是绕开。
const ASKED_INTERN := ["gpa", "schedule", "project", "skill"]
const ASKED_SOCIAL := ["exp", "job", "gap"]


static func ask_text(c: Candidate) -> String:
	return ASK_INTERN if c.is_intern else ASK_SOCIAL


## 一句一条：{key, kind, text, slip, said}。slip 是 "" / mismatch / skip / misspeak；
## skip 的那条 text 为空，不说出来，只留着记账。said 是这句里和简历对着的那个说法（对质时引用）。
static func build(c: Candidate) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var lines := ResumeQuestions.lines(c)
	var by_key := {}
	for line in lines:
		by_key[line.key] = line
	var study := "%s%s" % [c.school, (c.major + "专业") if c.is_intern and c.major != "" else c.degree_name()]
	out.append(_say("edu", "edu", "老师好，我叫%s，%s。" % [c.display_name, study], "", study))
	if c.is_intern:
		if by_key.has("gpa"):
			out.append(_gpa(c, by_key.gpa))
		if by_key.has("schedule"):
			out.append(_schedule(c, by_key.schedule))
		out.append_array(_projects(c, lines))
	else:
		if by_key.has("exp"):
			out.append(_exp(c, by_key.exp))
		for line in lines:
			if line.kind == "job":
				out.append(_job(c, line))
				break
		if by_key.has("gap"):
			out.append(_gap(c, by_key.gap))
	out.append_array(_skills(c, lines))
	out.append(_say("", "", _close(c), "", ""))
	return out


## 收尾那句。背得熟的社招，男的往“扛事”上落，女的先把婚育那句替面试官说了；在校生还轮不到这句。
static func _close(c: Candidate) -> String:
	if c.performance < SMOOTH_AT:
		return "就这些。我挺想来的。" if not c.is_female() else "就这些。……说得不好，不好意思。我挺想来的。"
	if c.is_intern:
		return "我学习能力强、抗压能力强，非常期待加入贵公司。"
	if not c.is_female():
		return "我学习能力强、抗压能力强，能扛事，非常期待加入贵公司。"
	if c.marital.contains("已育"):
		return "我学习能力强、抗压能力强。孩子有老人带，能全身心投入工作，非常期待加入贵公司。"
	return "我学习能力强、抗压能力强，近两年没有婚育计划，能全身心投入工作，非常期待加入贵公司。"


static func _say(key: String, kind: String, text: String, slip: String, said: String) -> Dictionary:
	return {"key": key, "kind": kind, "text": text, "slip": slip, "said": said}


static func _rng(c: Candidate, key: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([c.portrait_seed, key, "intro"])
	return rng


## 有水分的行怎么说：表演好的照念（""），诚实的说漏，其余的绕开或说漏。没水分的照实说，数字行偶尔嘴瓢。
static func _slip(c: Candidate, line: Dictionary, numeric: bool) -> String:
	var rng := _rng(c, line.key)
	if not ResumeQuestions.padded(c, line):
		return "misspeak" if numeric and rng.randf() < MISSPEAK else ""
	if c.performance >= SMOOTH_AT:
		return ""
	if c.honesty >= 55:
		return "mismatch"
	return "skip" if rng.randf() < SKIP else "mismatch"


static func _gpa(c: Candidate, line: Dictionary) -> Dictionary:
	var slip := _slip(c, line, true)
	var paper := "%.2f" % c.gpa
	match slip:
		"skip":
			return _say(line.key, line.kind, "", slip, "")
		"mismatch":
			var t := truth(c, line)
			return _say(line.key, line.kind, "绩点……%s一点吧。" % t.loose, slip, t.said)
		"misspeak":
			var wrong := "%.2f" % (c.gpa + 0.1)
			return _say(line.key, line.kind, "绩点 %s——不对，%s，我记岔了。" % [wrong, paper], slip, "绩点 %s" % paper)
	return _say(line.key, line.kind, "绩点 %s。" % paper, slip, "绩点 %s" % paper)


static func _schedule(c: Candidate, line: Dictionary) -> Dictionary:
	var slip := _slip(c, line, true)
	var days := c.intern_days
	var months := c.intern_months
	match slip:
		"skip":
			return _say(line.key, line.kind, "", slip, "")
		"mismatch":
			var t := truth(c, line)
			if t.patch.has("intern_days"):
				return _say(line.key, line.kind, "每周……能来 %d 天吧，课排开了能多来。" % t.patch.intern_days, slip, t.said)
			return _say(line.key, line.kind, "每周 %d 天，先做 %d 个月看看，下学期还不好说。" % [days, t.patch.intern_months], slip, t.said)
		"misspeak":
			return _say(line.key, line.kind, "每周能来 %d 天——%d 天，%d 天，课都调好了。能做 %d 个月。" % [days - 1, days, days, months], slip, "每周 %d 天" % days)
	return _say(line.key, line.kind, "每周能来 %d 天，能做 %d 个月。" % [days, months], slip, "每周 %d 天、%d 个月" % [days, months])


## 项目：头一个照实说（没水分时）；有水分又说漏的，不管排第几都会带一句。
## 头一个有水分、又绕开的：问的“做过什么”一个都没说，这才算绕开。后面的没提不算。
static func _projects(c: Candidate, lines: Array[Dictionary]) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var first := true
	for line in lines:
		if line.kind != "project":
			continue
		var slip := _slip(c, line, false)
		var name := _quote(line.sub.project)
		var role: String = line.sub.role
		if slip == "mismatch":
			var t := truth(c, line)
			if role in LEAD_ROLES:
				out.append(_say(line.key, line.kind, "还参加过%s，我主要是……帮着打打下手。" % name, slip, t.said))
			else:
				out.append(_say(line.key, line.kind, "%s我也去了，就是……去过几次。" % name, slip, t.said))
		elif first:
			if slip == "skip":
				out.append(_say(line.key, line.kind, "", slip, ""))
			else:
				out.append(_say(line.key, line.kind, "在学校做过%s，我是%s%s" % [name, role, _project_tail(c, role)], slip, "%s%s" % [name, role]))
		first = false
	return out


## 说完自己是什么角色，男的往上抬一句，女的往下压一句。表演到家的不加，照纸念。
static func _project_tail(c: Candidate, role: String) -> String:
	if c.performance >= SMOOTH_AT:
		return "。"
	if c.is_female():
		return "，主要是配合大家。" if role in LEAD_ROLES else "，帮着做些整理的活。"
	return "，从头带到尾。" if role in LEAD_ROLES else "，核心的那块是我做的。"


## 项目名本身带引号的（电子商务“三创赛”）不再套一层。
static func _quote(name: String) -> String:
	return name if "“" in name else "“%s”" % name


## 技能一句话带过：有水分又没背住的那几样，直接不提。
static func _skills(c: Candidate, lines: Array[Dictionary]) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var said: PackedStringArray = []
	for line in lines:
		if line.kind != "skill":
			continue
		var slip := _slip(c, line, false)
		if slip == "mismatch":
			var t := truth(c, line)
			out.append(_say(line.key, line.kind, "%s……%s。" % [line.sub.skill, t.show], slip, t.said))
		elif slip == "skip":
			out.append(_say(line.key, line.kind, "", slip, ""))
		else:
			said.append(line.sub.skill)
	if not said.is_empty():
		var tail := "。"
		if c.performance < SMOOTH_AT:
			tail = "，不算精，但我学得快。" if c.is_female() else "，都挺熟。"
		var head := _say("skill:" + said[0], "skill", "会%s%s" % ["、".join(said), tail], "", "会" + "、".join(said))
		out.push_front(head)
	return out


static func _exp(c: Candidate, line: Dictionary) -> Dictionary:
	var slip := _slip(c, line, true)
	var paper := c.exp_text()
	match slip:
		"skip":
			return _say(line.key, line.kind, "", slip, "")
		"mismatch":
			var t := truth(c, line)
			var real: int = t.patch.exp_months / 12
			var text := "正式工作是 %d 年，前面那段算实习。" % real if real > 0 else "正式工作不到一年，前面是实习。"
			return _say(line.key, line.kind, text, slip, t.said)
	return _say(line.key, line.kind, "工作 %s 了。" % paper, slip, "工作 " + paper)


static func _job(c: Candidate, line: Dictionary) -> Dictionary:
	var slip := _slip(c, line, false)
	var company: String = line.sub.company
	var title: String = line.sub.title
	match slip:
		"skip":
			return _say(line.key, line.kind, "", slip, "")
		"mismatch":
			return _say(line.key, line.kind, "上一份在%s那边……驻场，合同签的是另一家。" % company, slip, "在%s驻场" % company)
	var tail := "。"
	if c.performance < SMOOTH_AT:
		tail = "，走之前在带新人。" if c.is_female() else "，组里的活基本是我在扛。"
	return _say(line.key, line.kind, "上一份在%s做%s%s" % [company, title, tail], slip, "在%s做%s" % [company, title])


static func _gap(c: Candidate, line: Dictionary) -> Dictionary:
	var slip := _slip(c, line, false)
	match slip:
		"skip":
			return _say(line.key, line.kind, "", slip, "")
		"mismatch":
			return _say(line.key, line.kind, "中间那几个月……其实是被裁了，一直在找。", slip, "被裁了")
	var tail := "歇了几个月。"
	var note: String = line.sub.gap
	if c.is_female():
		if note in ["备孕", "产后休整"]:
			tail = "歇了几个月。现在都过去了，不影响工作。"
		elif note in ["照顾家人", "家中有事", "陪父亲住院"]:
			tail = "歇了几个月。家里现在都安排好了。"
		elif c.marital.contains("已育"):
			tail = "歇了几个月。孩子有老人带。"
		else:
			tail = "歇了几个月。……不是因为结婚生孩子。"
	elif c.performance < SMOOTH_AT:
		tail = "歇了几个月，也一直在看机会。"
	return _say(line.key, line.kind, "中间%s，%s" % [line.sub.gap, tail], slip, line.sub.gap)


## 有水分的那一行，真的是什么。自我介绍说漏、对质认了、追问破防，说出来的都是这一个：
## {show：简历上划掉原文以后红笔写的，said：嘴上的说法，loose：说得含糊时的数，
##  confess：破防时 TA 自己说的那句，patch：真实的字段（拿去重新过一遍规则）}。
## 没水分的行，或者这种行说不出个“真的”（学历、专业、自评），返回空。种子跟着头像种子走。
static func truth(c: Candidate, line: Dictionary) -> Dictionary:
	if not ResumeQuestions.padded(c, line):
		return {}
	match line.kind:
		"gpa":
			var real := snappedf(c.gpa - _rng(c, "gpa_real").randf_range(0.25, 0.5), 0.01)
			var loose := "%.1f 多" % (floorf(real * 10.0) / 10.0)
			return {"show": "%.2f" % real, "said": "绩点 " + loose, "loose": loose,
				"confess": "……全算上挂的那两门，是 %.2f。" % real, "patch": {"gpa": real}}
		"schedule":
			var rng := _rng(c, "schedule_real")
			if rng.randf() < 0.5 and c.intern_days > 2:
				var d := maxi(2, c.intern_days - rng.randi_range(1, 2))
				return {"show": "每周 %d 天" % d, "said": "每周 %d 天" % d, "loose": "",
					"confess": "……其实下学期课多，每周只能来 %d 天。" % d, "patch": {"intern_days": d}}
			var m := maxi(2, c.intern_months - rng.randi_range(2, 4))
			return {"show": "%d 个月" % m, "said": "先做 %d 个月" % m, "loose": "",
				"confess": "……其实只能做 %d 个月，后面要准备考研。" % m, "patch": {"intern_months": m}}
		"skill":
			var how: String = SKILL_ADMITS[absi(hash(line.key)) % SKILL_ADMITS.size()]
			var skill: String = line.sub.skill
			var rest := Array(c.skills).filter(func(k: String) -> bool: return k != skill)
			return {"show": how, "said": skill + how, "loose": "",
				"confess": "……%s我其实%s。写上去是因为招聘要求里有。" % [skill, how], "patch": {"skills": PackedStringArray(rest)}}
		"project":
			var name := _quote(line.sub.project)
			var did := "打下手" if line.sub.role in LEAD_ROLES else "去过几次"
			return {"show": did, "said": name + did, "loose": "",
				"confess": "……%s我就是%s的。%s是挂的名。" % [name, did, line.sub.role], "patch": {}}
		"exp":
			var months := maxi(0, c.exp_months - 12)
			return {"show": "正式 %d 年" % (months / 12), "said": "正式工作 %d 年" % (months / 12), "loose": "",
				"confess": "……有一年是实习，正式的只有 %d 年。" % (months / 12), "patch": {"exp_months": months}}
		"job":
			return {"show": "外包驻场", "said": "在%s驻场" % line.sub.company, "loose": "",
				"confess": "……是外包，驻场在%s。合同签的另一家。" % line.sub.company, "patch": {}}
		"gap":
			return {"show": "被裁", "said": "被裁了", "loose": "",
				"confess": "……其实是被裁的。", "patch": {}}
	return {}


## 问简历这一行时，自我介绍里有没有能拿来顶 TA 的：划过的句子，或者红笔圈了、TA 又绕开没提的。
static func hook(intro: Array[Dictionary], key: String, underlined: Dictionary, circled: PackedStringArray) -> Dictionary:
	if underlined.has(key):
		return underlined[key]
	if key in circled:
		for s in intro:
			if s.key == key and s.slip == "skip":
				return s
	return {}


## 把问这一行的卡改成对质：问法换成“你刚才说……”，背的门槛降下来。
## 这一行没水分（你划的是一句没毛病的话）：TA 照实解释，卡记 petty，主管嫌你抠字眼。
static func confront(c: Candidate, line: Dictionary, card: QuestionCard, s: Dictionary) -> QuestionCard:
	var out := card.duplicate() as QuestionCard
	var paper: String = line.text
	if s.slip == "skip":
		out.text_key = "刚才自我介绍让你说的，你没提简历上这条：“%s”。怎么回事？" % paper
	else:
		out.text_key = "你刚才说“%s”，简历上写的是“%s”？" % [s.said, paper]
	out.bluff_at = maxi(50, card.bluff_threshold() - CONFRONT_EASE)
	# 男女说法是一份份字典，改之前先复制一份，别改到原卡上。
	out.male = card.male.duplicate()
	out.female = card.female.duplicate()
	if s.slip in ["mismatch", "skip"]:
		out.standard = CONFRONT_STANDARD
		_drop(out, "standard")
		out.male["standard"] = CONFRONT_STANDARD_MALE
		out.female["standard"] = CONFRONT_STANDARD_FEMALE
	if not ResumeQuestions.padded(c, line):
		out.always_truthful = true
		var why := "刚才嘴瓢了，我后面不是改过来了吗？" if s.slip == "misspeak" else "啊？……我说的就是这个啊。简历上写的没错。"
		out.honest = why
		out.honest_low = why
		_drop(out, "honest")
		_drop(out, "honest_low")
		if s.slip != "misspeak":
			out.male["honest"] = "啊？我说的就是这个。简历上写的没错，你可以去查。"
			out.male["honest_low"] = out.male.honest
			out.female["honest"] = "啊？……我、我说的就是这个呀。是我哪里没说清楚吗？"
			out.female["honest_low"] = out.female.honest
		out.set_meta("petty", true)
	return out


## 对质改了卡上的某句话，男女说法里的同一句（连已育那句）也得拿掉，不然还是说老词。
static func _drop(card: QuestionCard, field: String) -> void:
	for own: Dictionary in [card.male, card.female]:
		own.erase(field)
		own.erase(field + "_mom")
