class_name BlockedTalent
## 被规则卡住的人：只差一条（学历差一档、年龄超一岁、空窗、专业不对口、绩点压线……），但自评里写着一件硬东西。
## 一半是真的（能力强、留得住，满试用期“项目大捷”），一半是吹的（东西是别人的，进来把活拖垮）。
## 纸面上的区别很小：吹的那份，附件一半写着“未附 / 打不开 / 私有”，另一半跟真的一模一样。
## 真假要在破格之后的单独面试里分：问自评那一行，真的说得出细节；吹的追问两次就说漏嘴（Candidate.crack_lines）。
## 规则拒掉的，过两天有回响（GameState.blocked_echoes）：真的在别家干得好，吹的在别家露了馅。

## 从第几天起每天塞几份：平时一份，简历多（≥ 8 份）或有 HC 硬指标（DayConfig.hc_push）的日子两份。
const MANY_RESUMES := 8
## 一份的日子是真的的概率；两份的日子第一份一定是真的，第二份是吹的的概率。
const REAL_CHANCE := 0.6
const SECOND_FAKE_CHANCE := 0.65
## 吹的那份附件上露馅的概率；其余跟真的一模一样，只能面试里问。
const FAKE_TELL_CHANCE := 0.5
const TRIES := 10

## 只卡这些“门槛”规则：学历、学校、年龄、空窗、在职、专业、年限、绩点、到岗时间、项目。荒谬的、违法的不算（那些是另一种破格）。
static func credential(r: Rule) -> bool:
	if r.is_illegal or r.hidden:
		return false
	return r is RuleDegree or r is RuleSchool or r is RuleAgeLimit or r is RuleGap or r is RuleMajor or r is RuleEmployed \
		or r is RuleExperience or r is RuleGpa or r is RuleInternship or r is RuleProjects


## 挑卡哪一条：学历、在职那两条权重低一点，免得破格章成了“学历章”。
static func weight(r: Rule) -> int:
	return 1 if r is RuleDegree or r is RuleEmployed else 3


## 自评里写的那件事。real_q / real_f：问自评那一行、追问时真的怎么答；fake_q：吹的第一层（背得很顺，主管爱听）；
## cracks：吹的被追问第一次、第二次说的（第二次算问穿）；echo_real / echo_fake：规则拒掉以后，两天后的回响（%s 是名字）。
const CLAIMS := {
	"intern": [
		{
			"eval": "大二起一个人做家里的网店，近半年月销九万。",
			"attach": "网店后台截图（近六个月）", "attach_fake": "网店后台截图（未附，面试时看手机）",
			"real_q": "店是我妈的，货是我选的，详情页是我写的，客服也是我。去年双十一一晚上回了六百条消息。",
			"real_f": "（TA 掏出手机，后台一页一页翻给你看：退货率、复购率，数字说得比你问的还细。）",
			"fake_q": "主要负责店铺整体运营，从选品到推广全链路都有参与，数据增长很明显。",
			"cracks": ["后台……今天没带那个手机。数据我大概记得，九万左右吧。", "（TA 沉默了一会儿。）其实店是我表哥的，我就帮他回过一个暑假的客服。"],
			"echo_real": "%s 去了竞对做电商运营，第一个月把他们的店做到了五十万。",
			"echo_fake": "%s 去了别家，第二周被发现网店是表哥的。",
		},
		{
			"eval": "一个人运营的公众号三万粉，写过十篇十万加。",
			"attach": "公众号后台截图、十篇文章链接", "attach_fake": "公众号截图（号已迁移，链接打不开）",
			"real_q": "号叫“后门食堂”，写我们学校后门那条街的店。最火那篇写一家要拆的面馆，老板后来打电话来哭了。",
			"real_f": "（TA 直接报出上周的打开率和掉粉数，掉粉那篇为什么掉也说得出来。）",
			"fake_q": "公众号主要做内容矩阵，通过精细化运营实现了粉丝的快速增长。",
			"cracks": ["十万加……具体哪篇？有好几篇，名字我一下想不起来。", "（TA 低下头。）号是我们社团的，文章是学姐写的，我负责排版。"],
			"echo_real": "%s 去了竞对做内容，写的第一篇就上了热榜，他们的运营总监转了朋友圈。",
			"echo_fake": "%s 去了别家，公众号的原作者在网上挂了 TA。",
		},
		{
			"eval": "全国大学生数学建模竞赛一等奖，队里的模型是我建的。",
			"attach": "获奖证书复印件（编号可查）", "attach_fake": "获奖证书（原件丢了，可以口述题目）",
			"real_q": "题目是共享单车调度。我建模，队友写代码。答辩时评委问为什么不用遗传算法，我说算不完。",
			"real_f": "（TA 在你的面试记录背面画了一张调度图，三分钟画完，比你看过的任何 PPT 都清楚。）",
			"fake_q": "比赛中我主要负责模型构建和论文撰写，团队协作非常顺利。",
			"cracks": ["题目……是关于交通的。具体模型叫什么，有点记不清了。", "（TA 把手缩回去。）一等奖是队长的，我那年是挂名。"],
			"echo_real": "%s 去了竞对做数据运营，他们拿 TA 做的模型去融了一轮。",
			"echo_fake": "%s 去了别家，背调一查，获奖名单上没有 TA。",
		},
	],
	"dev": [
		{
			"eval": "业余维护一个开源组件，GitHub 一千二百星。",
			"attach": "GitHub 链接（提交记录三年没断）", "attach_fake": "GitHub 链接（仓库私有，面试时演示）",
			"real_q": "一个日志采集的小库。开始是自己用，后来有人提 issue 我就一直修，现在两家公司在生产环境用。",
			"real_f": "（TA 当场打开手机，翻到凌晨两点合的一个 PR：别人报的 bug，TA 修了，还补了测试。）",
			"fake_q": "项目采用微服务架构，具备高可用、高并发、可扩展等特性，在社区获得了广泛认可。",
			"cracks": ["仓库……现在是私有的，在重构。星数是之前的。", "（TA 盯着桌子。）是我 fork 的别人的项目，星是原作者的。"],
			"echo_real": "%s 去了竞对，第二周就把他们线上那个三年没人敢动的服务重写了。",
			"echo_fake": "%s 去了别家，有人把 TA fork 来的仓库在网上挂了出来。",
		},
		{
			"eval": "独立做的记账 App 上架三年，日活四千。",
			"attach": "应用商店链接、后台日活截图", "attach_fake": "应用商店链接（已下架，正在改版）",
			"real_q": "前端后端都是我一个人写的。服务器一个月两百，我自己出。有个用户记了三年账，给我写过一封邮件。",
			"real_f": "（TA 报了一串崩溃率、留存率，又讲了一次数据库被删的事故：怎么恢复的、丢了几条。）",
			"fake_q": "从需求分析、架构设计到开发上线全部独立完成，用户反馈非常好。",
			"cracks": ["下架是……因为在改版。日活是之前的数据。", "（TA 叹了口气。）是我在外包公司做的项目，源码我拷了一份。"],
			"echo_real": "%s 去了竞对，三个月后他们上了个新 App，产品负责人一栏写的是 TA。",
			"echo_fake": "%s 去了别家，原来那家外包公司发了律师函。",
		},
		{
			"eval": "ACM 区域赛银牌，现在每周还在刷题。",
			"attach": "获奖证书、刷题网站主页", "attach_fake": "获奖证书（照片，原件在老家）",
			"real_q": "那年我们队三个人，两个是专科的。最后十分钟过了一道图论，银牌就是那道题。",
			"real_f": "（你随口出了道题，TA 在纸上写了五行，复杂度说得清清楚楚。）",
			"fake_q": "参赛期间系统提升了算法能力，也培养了团队协作精神。",
			"cracks": ["那道题……是动态规划吧。时间太久了。", "（TA 把证书照片收了起来。）是我室友的，名字是 P 上去的。"],
			"echo_real": "%s 去了竞对，他们直接把 TA 放进了核心交易组。",
			"echo_fake": "%s 去了别家，背调时证书编号对不上。",
		},
	],
	"general": [
		{
			"eval": "注册会计师六门过了四门，都是下班以后考的。",
			"attach": "成绩单（中注协官网可查）", "attach_fake": "成绩单（官网登不上，回头补）",
			"real_q": "一年两门，晚上十点开始学，学到一点。税法考了两次，第二次过的。",
			"real_f": "（TA 背出了今年增值税改的那两条，连生效日期都对。）",
			"fake_q": "我具备扎实的财务专业知识，持续学习，不断提升自我。",
			"cracks": ["哪四门……会计、审计，还有……经济法？", "（TA 不说话了。）一门都没过，是报了名。"],
			"echo_real": "%s 去了竞对做财务，第一个月就查出一笔四十万的重复付款。",
			"echo_fake": "%s 去了别家，审计来的那天，账做不平。",
		},
		{
			"eval": "自己做的报销对账表，前公司全部门用了三年。",
			"attach": "表格模板截图（公式没锁）", "attach_fake": "表格模板（公司资料，不方便带出）",
			"real_q": "原来对账要三天，用表格半天。公式我没锁，谁都能看、能改。",
			"real_f": "（TA 讲 VLOOKUP 讲到一半，改口说其实该用 INDEX，又讲了为什么。）",
			"fake_q": "通过优化流程大幅提升了部门效率，获得了领导的高度认可。",
			"cracks": ["表格……用了宏。具体怎么写的，我得回去看看。", "（TA 搓了搓手。）是前同事做的。他走了以后，大家以为是我。"],
			"echo_real": "%s 去了竞对，那张表他们财务部现在人手一份。",
			"echo_fake": "%s 去了别家，第一次月结就对不上账。",
		},
	],
}

## 简历底下那张附言：真的假的一样，只说“我知道差在哪”。
## 附言纸条一行放不下 11 个字以上。
const COVER_NOTES := ["差一条，东西在附件里。", "知道卡在哪，还想试试。", "条件差点，活儿干过。", "请看看我做过的东西。"]


## 今天塞几份。
static func count_for(cfg: DayConfig) -> int:
	if cfg.day < GameState.EXCEPTION_DAY:
		return 0
	return 2 if cfg.resume_count >= MANY_RESUMES or not cfg.hc_push.is_empty() else 1


## 第几份是真的：一份的日子按概率；两份的日子第一份真、第二份多半是吹的。
static func kinds(n: int, rng: RandomNumberGenerator) -> Array:
	if n <= 0:
		return []
	if n == 1:
		return ["real" if rng.randf() < REAL_CHANCE else "fake"]
	var out := ["real", "fake" if rng.randf() < SECOND_FAKE_CHANCE else "real"]
	for i in range(2, n):
		out.append("real" if rng.randf() < 0.5 else "fake")
	return out


static func _pool(c: Candidate) -> Array:
	if c.is_intern:
		return CLAIMS.intern
	if "工程师" in c.applied_position:
		return CLAIMS.dev
	return CLAIMS.general


## 卡好规则以后穿上：自评、附件、附言、面试里那一行怎么答、隐藏属性、满期结局、拒掉以后的回响。
## used：今天已经用过的自评（同一天两份不撞同一件事）。
static func dress(c: Candidate, kind: String, rng: RandomNumberGenerator, used: Array = []) -> void:
	var pool := _pool(c).filter(func(cl: Dictionary) -> bool: return String(cl.eval).left(10) not in used)
	if pool.is_empty():
		pool = _pool(c)
	var claim: Dictionary = pool[rng.randi_range(0, pool.size() - 1)]
	var real := kind == "real"
	c.blocked = kind
	# 原来那句留在后面：有的规则看自评里的字（AI 协同、禁词），塑好的形别被冲掉
	c.self_eval = claim.eval if c.self_eval == "" else claim.eval + c.self_eval
	var proof: String = claim.attach if real or rng.randf() >= FAKE_TELL_CHANCE else claim.attach_fake
	# “已离职”“在职，可一个月内到岗”这类附言是在职规则看的，留着，证明接在后面
	c.attachment = c.attachment + "；" + proof if c.attachment.contains("离职") or c.attachment.contains("到岗") else proof
	c.elsewhere = (claim.echo_real if real else claim.echo_fake) % c.display_name
	c.answers = {}
	c.crack_lines = PackedStringArray()
	c.padded_lines = PackedStringArray()
	if real:
		c.answers["r_self_eval"] = claim.real_q
		c.answers["r_self_eval+"] = claim.real_f
		c.answer_kind = "honest"
		c.ability = rng.randi_range(75, 92)
		c.honesty = rng.randi_range(70, 90)
		c.loyalty = rng.randi_range(65, 88)
		c.pressure = rng.randi_range(66, 86)
		c.performance = rng.randi_range(35, 60)
		c.event_override = &"praise"
	else:
		c.answers["r_self_eval"] = claim.fake_q
		c.answer_kind = "standard"
		c.crack_lines = PackedStringArray(claim.cracks)
		c.padded_lines = PackedStringArray(["self_eval"])
		c.ability = rng.randi_range(18, 35)
		c.honesty = rng.randi_range(15, 30)
		c.loyalty = rng.randi_range(30, 60)
		c.pressure = rng.randi_range(40, 70)
		c.performance = rng.randi_range(72, 90)
		c.event_override = &"delay"


static func cover_note(c: Candidate) -> String:
	return COVER_NOTES[absi(hash(String(c.id))) % COVER_NOTES.size()]
