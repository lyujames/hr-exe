class_name ResumeQuestions
## 面试桌上摊着的简历：哪几行能问、每一行有没有水分、问这一行时 TA 怎么答。
## 每一行现做一张 QuestionCard（id 是“r_”加行的 key），追问、主管反应、手写回答都照问题卡的老规矩走。
##
## 水分：普通人按诚信抽，种子跟着头像种子和行走，读档重来还是那几行；手写人物写在 Candidate.padded_lines。
## 有水分的行：背得住的照背（门槛比平时高 10），老实的自己认，其余的露破绽。
## 尖锐卡拖到某一行上，就是把这一行问穿：问法换成 sharp_q，背的门槛跟尖锐题走（85，有水分 95）。

## 每一行的水分概率：诚信 60 以上基本没有，越往下越多。
const PAD_BASE := 0.12
const PAD_MAX := 0.6
## 有水分时背答案的门槛往上加多少。
const PAD_BLUFF := 10
## 学历这一行不掺水：学历归筛简历的规则管。
const NEVER_PADDED := ["edu"]

## 每种行的问法和回答。{x} 换成这一行的内容，见 _subst。
const KINDS := {
	"exp": {
		"probe": "ability", "chief_item": "稳定性",
		"q": "工作年限写的 {exp}，怎么算的？",
		"sharp_q": "{exp}里，真正写代码的是几年？一年一年说。",
		"honest": "从第一份工作算起，一年没断过。中间换过一次组，活没停。",
		"honest_low": "{exp}是算到这个月的。前面一两年主要打杂，写代码不多。",
		"admit": "里面有一年多是实习，我算进去了。招聘软件上都这么写。",
		"standard": "{exp}的一线开发经验，覆盖需求、开发、上线全流程。",
		"flaw": "就、就是{exp}。……从毕业算的。大概。",
		"followup": "第一份工作是哪年哪月入职的？",
		"honest_followup": "{first_start}。（TA 报得很快，和简历上最早那段对得上，连转正那天都记得。）",
		"honest_low_followup": "{first_start}。前两年真没什么好讲的。",
		"admit_followup": "简历上写的 {first_start}，那会儿是实习。正式入职还要晚一年。",
		"standard_followup": "具体时间……简历上都有，我一下记不太准。",
		"flaw_followup": "哪、哪年……（TA 伸手想拿你桌上那份简历。）",
	},
	"job": {
		"probe": "ability", "chief_item": "稳定性",
		"q": "{company}这段，你具体做什么？",
		"sharp_q": "{company}那段，哪个系统、几个人、你写的哪一块？说名字。",
		"honest": "在{company}做{title}，手上一直有两三个需求在跑。走之前在带一个新人。",
		"honest_low": "在{company}做{title}，主要跟着别人改需求。核心的轮不到我。",
		"admit": "{company}那段……其实是外包，驻场在{company}。合同签的是另一家。",
		"standard": "在{company}担任{title}，负责核心业务模块的设计与开发。",
		"flaw": "{company}……就是做开发。各种都做。",
		"followup": "你在{company}的直属领导叫什么？",
		"honest_followup": "（TA 说了名字，还说了那人现在去了哪家。）可以打电话问，他会说实话。",
		"honest_low_followup": "（TA 说了名字。）他可能不太记得我了。",
		"admit_followup": "领导是外包公司的。{company}那边的组长，我只在群里见过。",
		"standard_followup": "这个……涉及前公司的信息，不太方便说吧。",
		"flaw_followup": "叫、叫王……王总。大家都叫他王总。",
	},
	"skill": {
		"probe": "ability", "chief_item": "格局",
		"q": "技能写了 {skill}，用它做过什么？",
		"sharp_q": "{skill}，你踩过最深的坑是什么？当时怎么查的？",
		"honest": "上一份工作天天用 {skill}。线上出过一次问题，是我查出来的。",
		"honest_low": "{skill} 会用，深的说不上。跟着文档能做。",
		"admit": "{skill}……我就跟着教程做过一个 demo。写上去是因为 JD 里有。",
		"standard": "{skill} 我非常熟练，有丰富的项目实战经验。",
		"flaw": "{skill}……用、用过的。挺好用的。",
		"followup": "上次用 {skill} 是什么时候？做的什么？",
		"honest_followup": "上个月。查一个慢接口，最后改了三行。（TA 把那三行在空中比划了一下。）",
		"honest_low_followup": "半年前吧。改了一个小功能，大部分是照着别人的抄的。",
		"admit_followup": "教程是去年看的。……之后就没打开过。",
		"standard_followup": "最近项目比较多，具体是哪一次……一下想不起来。",
		"flaw_followup": "上、上次……挺久了。",
	},
	"self_eval": {
		"probe": "ability", "chief_item": "格局",
		"q": "自我评价写“{eval}”，举个例子。",
		"sharp_q": "“{eval}”——哪件事能证明？谁能作证？",
		"honest": "去年项目延期，全组压在我这一块。我拆成三段，每天下班前报进度，最后晚了两天，没再往后拖。",
		"honest_low": "例子……我想想。其实也就是领导交代的事，我都做完了。",
		"admit": "这句是模板上抄的。说实话，我不知道该写什么。",
		"standard": "在过往工作中，我始终以高标准要求自己，多次获得领导认可。",
		"flaw": "例、例子……很多。一下说不上来。",
		"followup": "那年谁给你打的绩效？打了几？",
		"honest_followup": "组长打的，B+。他说要是早点报风险，能拿 A。",
		"honest_low_followup": "B。我们组大部分人都是 B。",
		"admit_followup": "绩效是 C。所以我才出来找。",
		"standard_followup": "绩效……我们公司不太公开这个。",
		"flaw_followup": "几、几分……挺高的。",
	},
	"gap": {
		"probe": "pressure", "chief_item": "稳定性",
		"q": "空窗这段写的“{gap}”，那几个月在做什么？",
		"sharp_q": "空窗那几个月，一个月一个月说，都干了什么？",
		"honest": "照顾家里，也在学东西。每周投十几份简历，面了七家。",
		"honest_low": "主要在家。投简历，没什么回音。",
		"admit": "其实是被裁的。写“{gap}”，是听说写被裁过不了筛。",
		"standard": "这段时间我进行了系统的自我提升和职业规划。",
		"flaw": "就、就是休息了一下。调整状态。",
		"followup": "那几个月学了什么？给我看看。",
		"honest_followup": "（TA 打开手机，翻出一个代码仓库，最近一次提交是上周。）",
		"honest_low_followup": "……没学成什么。说实话，那段时间状态不好。",
		"admit_followup": "裁员通知我还留着。要的话，我可以拿给你们看。",
		"standard_followup": "主要是……拓宽了视野。",
		"flaw_followup": "学、学了……挺多的。",
	},
	"edu": {
		"probe": "ability", "chief_item": "格局",
		"q": "{school}，在学校主要学了什么？",
		"sharp_q": "{school}那几年，学到的哪样东西现在还在用？",
		"honest": "{school}，{degree}。课上学的用到的不多，但写代码是那时候学会的。",
		"honest_low": "{school}。说实话，大学没怎么好好学。",
		"standard": "在{school}系统学习了专业知识，打下了扎实的基础。",
		"flaw": "{school}……就、就正常读完的。",
		"followup": "毕业设计做的什么？",
		"honest_followup": "一个排课系统。答辩的时候老师当场找出两个 bug，我当场修了一个。",
		"honest_low_followup": "抄了一个学长的，改了改。",
		"standard_followup": "毕业设计……时间有点久了。",
		"flaw_followup": "做、做的……一个系统。",
	},
	"project": {
		"probe": "ability", "chief_item": "格局",
		"q": "“{project}”里你是{role}，具体做了什么？",
		"sharp_q": "“{project}”，你做的那部分现在还在吗？拿出来给我看。",
		"honest": "从立项到结项我都在。中间有一次大返工，是我提的。",
		"honest_low": "我主要跟着做，开会记记纪要。",
		"admit": "我是挂名的。{role}是老师随手填的。",
		"standard": "我在项目中担任{role}，全面统筹，取得了优异成绩。",
		"flaw": "{project}……我、我参加了。",
		"followup": "那个项目最后结果怎么样？",
		"honest_followup": "拿了省二。评委问的那个最难的问题，是我答的。",
		"honest_low_followup": "结项了，没拿奖。",
		"admit_followup": "……我不太清楚。结项的时候我在外面实习。",
		"standard_followup": "结果还不错，具体奖项……我回去确认一下。",
		"flaw_followup": "结、结果挺好的。",
	},
}
const CHIEF := {"standard": "说得挺好。", "honest": "讲这么细干嘛。", "flaw": "……"}


## 简历上能问的行，从上到下：{key, kind, text（纸上印的那行字）, sub（替换用的字段）}。
static func lines(c: Candidate) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var first_start := ""
	if not c.jobs.is_empty():
		first_start = String(c.jobs[-1].start).replace("-", " 年 ") + " 月"
	var base := {"exp": c.exp_text(), "first_start": first_start, "school": c.school, "degree": c.degree_name()}
	var edu := "%s%s · %s" % [c.degree_name(), "在读" if c.is_intern else "", c.school]
	out.append(_line("edu", "edu", edu, base))
	if c.is_intern:
		out.append(_line("major", "", c.major, base))
		out.append(_line("intern_info", "", "绩点 %.2f · 每周 %d 天 × %d 个月" % [c.gpa, c.intern_days, c.intern_months], base))
	else:
		var exp := "年限 " + c.exp_text() + ("（%s）" % c.exp_note if c.exp_note != "" else "")
		out.append(_line("exp", "exp", exp, base))
	for i in c.skills.size():
		out.append(_line("skill:" + c.skills[i], "skill", c.skills[i], base.merged({"skill": c.skills[i]})))
	if c.is_intern:
		for i in c.projects.size():
			var p: Dictionary = c.projects[i]
			out.append(_line("project:%d" % i, "project", "%s · %s" % [p.name, p.role], base.merged({"project": p.name, "role": p.role})))
	else:
		var gap_at := c.gap_index()
		for i in c.jobs.size():
			var job: Dictionary = c.jobs[i]
			var end: String = String(job.end).right(5).replace("-", ".") if job.end != "" else "至今"
			var text := "%s–%s  %s · %s" % [String(job.start).right(5).replace("-", "."), end, job.company, job.title]
			out.append(_line("job:%d" % i, "job", text, base.merged({"company": job.company, "title": job.title})))
			if i == gap_at:
				var note := c.gap_note if c.gap_note != "" else "没写原因"
				out.append(_line("gap", "gap", "┆ 空窗：" + note, base.merged({"gap": note})))
	out.append(_line("self_eval", "self_eval", "自评：" + c.self_eval, base.merged({"eval": _clip(c.self_eval, 14)})))
	return out


## kind 为空的行只是印着，不能问。
static func _line(key: String, kind: String, text: String, sub: Dictionary) -> Dictionary:
	return {"key": key, "kind": kind, "text": text, "sub": sub}


static func _clip(text: String, length: int) -> String:
	return text if text.length() <= length else text.left(length - 1) + "…"


static func padded(c: Candidate, line: Dictionary) -> bool:
	if line.kind == "" or line.kind in NEVER_PADDED:
		return false
	if c.is_story:
		return line.key in c.padded_lines
	if line.key in c.padded_lines:
		return true
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([c.portrait_seed, line.key])
	var chance := clampf(PAD_BASE + (60.0 - c.honesty) / 100.0, PAD_BASE / 2.0, PAD_MAX)
	return rng.randf() < chance


## 问这一行的那张卡。sharp 为真：玩家拖了一张尖锐卡到这行上。
static func card_for(c: Candidate, line: Dictionary, sharp := false) -> QuestionCard:
	var t: Dictionary = KINDS[line.kind]
	var pad := padded(c, line)
	var card := QuestionCard.new()
	card.id = StringName("r_" + line.key)
	card.text_key = _fill(t.sharp_q if sharp else t.q, line.sub)
	card.probes = PackedStringArray([t.probe])
	card.sharp = sharp
	card.bluff_at = (QuestionCard.SHARP_BLUFF if sharp else QuestionCard.BLUFF) + (PAD_BLUFF if pad else 0)
	card.honest = _fill(t.admit if pad else t.honest, line.sub)
	card.honest_low = _fill(t.admit if pad else t.honest_low, line.sub)
	card.standard = _fill(t.standard, line.sub)
	card.flaw = _fill(t.flaw, line.sub)
	card.followup_text = _fill(t.followup, line.sub)
	card.honest_followup = _fill(t.admit_followup if pad else t.honest_followup, line.sub)
	card.honest_low_followup = _fill(t.admit_followup if pad else t.honest_low_followup, line.sub)
	card.standard_followup = _fill(t.standard_followup, line.sub)
	card.flaw_followup = _fill(t.flaw_followup, line.sub)
	card.chief_item = t.chief_item
	card.chief_standard = CHIEF.standard
	card.chief_honest = CHIEF.honest
	card.chief_flaw = CHIEF.flaw
	return card


static func _fill(text: String, sub: Dictionary) -> String:
	for k: String in sub:
		text = text.replace("{%s}" % k, str(sub[k]))
	return text
