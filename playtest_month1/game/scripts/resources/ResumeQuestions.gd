class_name ResumeQuestions
## 面试桌上摊着的简历：哪几行能问、每一行有没有水分、问这一行时 TA 怎么答。
## 第一个月招实习生：学历、专业、绩点、每周几天、技能、项目、自评都能问；社招那几行（年限、工作、空窗）这个月不出现，月 2 有。
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
		"sharp_q": "{school}这几年，哪门课你现在还能讲给我听？现在就讲。",
		"honest": "{school}，{degree}。专业课一般，但我在学校公众号干了两年，排版、选题、催稿都是那时候学的。",
		"honest_low": "{school}。说实话，课没怎么好好上，大部分时间在宿舍。",
		"standard": "在{school}系统学习了专业知识，打下了扎实的理论基础。",
		"flaw": "{school}……就、就正常上课。",
		"followup": "你们系主任叫什么？",
		"honest_followup": "（TA 报了名字，还顺口说了那人上课爱拖堂。）",
		"honest_low_followup": "姓……姓陈吧。我只在开学典礼上见过。",
		"standard_followup": "这个……老师比较多，我一下说不全。",
		"flaw_followup": "叫、叫……（TA 低头看了一眼自己的简历，上面没写。）",
	},
	"major": {
		"probe": "loyalty", "chief_item": "稳定性",
		"q": "你学{major}，怎么想到来做运营？",
		"sharp_q": "{major}和运营八竿子打不着。说实话，是不是本专业找不到工作？",
		"honest": "{major}的课教会我看人想要什么。运营不就是干这个的吗。",
		"honest_low": "本专业的岗位少。运营门槛低一点，我先进来再说。",
		"admit": "说实话，是本专业找不到。投了四十多份，只有运营回了我。",
		"standard": "我对互联网行业充满热情，运营是我一直以来的职业理想。",
		"flaw": "就、就是喜欢。挺喜欢运营的。",
		"followup": "你同学现在都去哪了？",
		"honest_followup": "一半考公，一半考研，剩下几个跟我一样在投互联网。",
		"honest_low_followup": "大部分还在找。我算找得早的。",
		"admit_followup": "专业对口的那几个，都是家里帮忙找的。",
		"standard_followup": "同学们都有很好的发展，我们经常交流。",
		"flaw_followup": "去、去……各个地方。",
	},
	"gpa": {
		"probe": "honesty", "chief_item": "颜值",
		"q": "绩点 {gpa}，在你们专业排第几？",
		"sharp_q": "绩点 {gpa}，挂过科吗？挂过几门？哪几门？",
		"honest": "专业前百分之二十。有一门统计学重修过，写在成绩单上了。",
		"honest_low": "中间吧。不算好，没挂过。",
		"admit": "这个绩点是去掉了两门选修算的。全算的话只有 {real}。",
		"standard": "我的成绩一直名列前茅，多次获得奖学金。",
		"flaw": "排、排……挺靠前的。",
		"followup": "成绩单带了吗？",
		"honest_followup": "（TA 从文件袋里抽出一张盖了教务处章的成绩单，重修那一门用铅笔圈着。）",
		"honest_low_followup": "带了。（TA 递过来。都是 B，一个 A 也没有。）",
		"admit_followup": "带了，教务处打的。（上面印着 {real}。）",
		"standard_followup": "成绩单……今天走得急，忘带了。",
		"flaw_followup": "带、带了吧……（TA 翻了半天包。）",
	},
	"schedule": {
		"probe": "loyalty", "chief_item": "狼性",
		"q": "简历写每周 {days} 天、能来 {months} 个月，课怎么办？",
		"sharp_q": "每周 {days} 天、{months} 个月——你导师知道吗？签字了吗？",
		"honest": "课都排在周一周二了，剩下几天全是空的。导师那边我说过，他签了字。",
		"honest_low": "课不多。有冲突的我尽量调，调不开的……可能要请半天。",
		"admit": "其实下学期课多，{days} 天有点悬。我怕写少了你们不要。",
		"standard": "我会合理安排时间，保证学业与工作两不误。",
		"flaw": "课、课不多的……应该没问题。",
		"followup": "期末那几周呢？",
		"honest_followup": "期末两周我只能来两天，提前跟你们说。其他时候一天不少。",
		"honest_low_followup": "期末……可能得少来几天。",
		"admit_followup": "期末那个月基本来不了。说实话，我还没想好怎么跟你们说。",
		"standard_followup": "期末我会提前复习，不影响工作。",
		"flaw_followup": "期、期末……再说吧。",
	},
	"skill": {
		"probe": "ability", "chief_item": "格局",
		"q": "技能写了“{skill}”，用它做过什么？",
		"sharp_q": "“{skill}”，现在就做给我看。最拿得出手的一次是什么？",
		"honest": "在学校公众号天天用。有一篇推文是我做的，阅读量破了一万。",
		"honest_low": "“{skill}”会一点，跟着教程能做出来。深的说不上。",
		"admit": "“{skill}”……我就上过一节选修课。写上去是因为招聘要求里有。",
		"standard": "“{skill}”我非常熟练，有丰富的实践经验。",
		"flaw": "“{skill}”……用、用过的。挺好用的。",
		"followup": "上次用“{skill}”是什么时候？做的什么？",
		"honest_followup": "上周。给社团做招新海报的数据，（TA 掏出手机给你看了截图。）",
		"honest_low_followup": "一两个月前吧。做课程作业，大部分是照着同学的改的。",
		"admit_followup": "选修课是大二上的。……之后就没碰过。",
		"standard_followup": "最近用得比较多，具体是哪一次……一下想不起来。",
		"flaw_followup": "上、上次……挺久了。",
	},
	"self_eval": {
		"probe": "ability", "chief_item": "格局",
		"q": "自我评价写“{eval}”，举个例子。",
		"sharp_q": "“{eval}”——哪件事能证明？谁能作证？",
		"honest": "去年社团办活动，赞助商前一天跑了。我连夜打了十几个电话，第二天活动照常办。",
		"honest_low": "例子……我想想。其实就是老师和学长交代的事，我都做完了。",
		"admit": "这句是从网上的模板抄的。说实话，我不知道该写什么。",
		"standard": "在校期间，我始终以高标准要求自己，多次获得老师认可。",
		"flaw": "例、例子……很多。一下说不上来。",
		"followup": "那件事，谁能给你作证？",
		"honest_followup": "社团指导老师。（TA 报了老师的名字和电话。）他会说我那天差点哭了。",
		"honest_low_followup": "……室友吧。她知道我那段时间挺忙的。",
		"admit_followup": "没有。我编不出来。",
		"standard_followup": "老师们都很认可我，具体……我回去问问。",
		"flaw_followup": "作、作证……很多人都知道。",
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
		out.append(_line("major", "major", "专业：" + c.major, base.merged({"major": c.major})))
		out.append(_line("gpa", "gpa", "绩点 %.2f" % c.gpa, base.merged({"gpa": "%.2f" % c.gpa})))
		out.append(_line("schedule", "schedule", "每周 %d 天 × %d 个月" % [c.intern_days, c.intern_months], base.merged({"days": c.intern_days, "months": c.intern_months})))
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
	var real := SelfIntro.truth(c, line)
	if not real.is_empty():
		line = line.merged({"sub": line.sub.merged({"real": real.show})}, true)
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
