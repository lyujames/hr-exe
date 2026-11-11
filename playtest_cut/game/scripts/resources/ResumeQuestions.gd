class_name ResumeQuestions
## 面试桌上摊着的简历：哪几行能问、每一行有没有水分、问这一行时 TA 怎么答。
## 第一个月招实习生：学历、专业、绩点、每周几天、技能、项目、自评都能问；社招那几行（年限、工作、空窗）第二个月才有。
## 第二个月招程序员（社招）：学历、技能、自评换成 SOCIAL 里的问法。
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
## 社招（第二个月起，程序员）：学历、技能、自评三行换成社招的问法；别的行两边一样，查不到就用 KINDS。
const SOCIAL := {
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
	},	"skill": {
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
	},	"self_eval": {
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
	},}

## 男女说法（同 QuestionCard.male / female）：同一行简历，男的往大里说、往自己身上揽、压力在“挣钱养家”；
## 女的先把没问出口的那句（结婚、生孩子、家里）堵上，功劳往别人身上推，说完还要道歉。
## 在校生（KINDS 里的学历、专业、绩点、技能、自评、项目）还没挨过社会的打：男的吹“队长”“部长”，女的被分去记纪要；
## 社招（年限、工作、空窗，SOCIAL 里的学历、技能、自评）已经挨过了：男的扛房贷、往管理说，女的婚育抢答、功劳被别人领。
## 键是 KINDS 里的字段名；admit / admit_followup 只在这一行有水分时用。加“_mom”是给已育的。没写的用 KINDS 那句。
const VOICES := {
	"exp": {
		"male": {
			"honest": "从第一份工作算起，一年没断过。中间换过一次组，后来组里的活基本是我在分。",
			"honest_low": "{exp}是算到这个月的。前两年主要打杂……不过那会儿谁不是。",
			"admit": "里面有一年多是实习，我算进去了。大家都这么写，不写吃亏。",
			"standard": "{exp}一线开发经验，独立负责过核心模块，也带过新人。",
			"flaw": "就是{exp}。从毕业算的，没问题。",
			"honest_followup": "{first_start}。（TA 报得很快。）第二年就转了正，比同一批早三个月。",
			"flaw_followup": "哪年……这个不重要吧？能力摆在这儿。",
		},
		"female": {
			"honest": "从第一份工作算起，一年没断过，长假也没休过。",
			"honest_mom": "从第一份工作算起，一年没断过。产假我休了四个月就回去了。",
			"honest_low": "{exp}是算到这个月的。前两年主要在做测试，后来才转的开发。",
			"honest_low_mom": "{exp}是算到这个月的。中间休了半年产假，我没扣掉……要扣吗？",
			"admit": "里面有一年多是实习，我算进去了。……对不起，我知道这样不对。",
			"standard": "{exp}的开发经验，覆盖需求、开发、上线全流程，团队协作能力强。",
			"flaw": "就、就是{exp}。……中间没断过。真的没断过。",
			"honest_followup": "{first_start}。（TA 报得很快。）转正那天我记得清楚，同一批的男生比我早转一个月。",
		},
	},
	"job": {
		"male": {
			"honest": "在{company}做{title}，手上一直有两三个需求在跑。走之前组里的新人都是我带的。",
			"honest_low": "在{company}做{title}，跟着改需求。核心的轮不到我——组长不放手。",
			"admit": "{company}那段……其实是外包，驻场。说出去不好听，我就没写。",
			"standard": "在{company}担任{title}，主导核心业务模块的设计与开发。",
			"flaw": "{company}……什么都做。那边基本是我在扛。",
			"honest_followup": "（TA 说了名字，还说了那人现在去了哪家。）我们现在还一起喝酒，你打过去他会夸我。",
		},
		"female": {
			"honest": "在{company}做{title}，手上一直有两三个需求在跑。走之前在带一个新人，他现在是组长了。",
			"honest_low": "在{company}做{title}。核心的轮不到我，组长说我细心，让我多做测试和文档。",
			"admit": "{company}那段……其实是外包，驻场。不好意思，我怕写外包过不了筛。",
			"standard": "在{company}担任{title}，参与核心业务模块开发，和团队配合得很顺。",
			"flaw": "{company}……就是做开发。各种都做，大家都挺照顾我的。",
			"honest_followup": "（TA 说了名字。）可以打电话问。他会说我能干，也可能说我“家里事多”。前半句是真的。",
		},
	},
	"gap": {
		"male": {
			"honest": "照顾家里，也在学东西。每周投十几份，面了七家。那几个月房贷是我爸妈帮着还的。",
			"honest_low": "主要在家。投简历，没什么回音。家里人到现在还以为我在上班。",
			"admit": "其实是被裁的。写“{gap}”，是听说写被裁过不了筛。男的被裁，听着像没本事。",
			"standard": "这段时间我系统地做了职业规划，也接了一些私活。",
			"flaw": "就是休息了一下。……也在看机会，好几家在谈。",
			"honest_followup": "（TA 打开手机，翻出一个代码仓库，最近一次提交是上周。）星最多的那个是我自己写的。",
		},
		"female": {
			"honest": "照顾家里，也在学东西。每周投十几份简历，面了七家，有三家问我是不是去生孩子了。",
			"honest_mom": "生孩子，带到一岁。这期间我把以前项目的文档都过了一遍，没落下。",
			"honest_low": "主要在家。投简历，没什么回音。……不是怀孕，您放心。",
			"honest_low_mom": "主要在家带孩子。投简历，一听有孩子就没下文了。",
			"admit": "其实是被裁的，名单上是我们组的三个女的。写“{gap}”，是听说写被裁过不了筛。",
			"admit_mom": "其实是休完产假回去，岗位没了，等于被裁。写“{gap}”，是怕你们问。",
			"standard": "这段时间我进行了系统的自我提升。家里的事都已经安排好了。",
			"flaw": "就、就是休息了一下。不是、不是因为家里。",
			"honest_followup": "（TA 打开手机，翻出一个代码仓库，最近一次提交是上周。）您可以随便点开看。",
			"honest_followup_mom": "（TA 打开手机，翻出一个代码仓库，提交时间全是夜里十一点以后。）孩子睡了以后写的。",
		},
	},
	"edu": {
		"male": {
			"honest": "{school}，{degree}。专业课一般，在学校主要待在学生会，外联部部长，拉了两年赞助。",
			"honest_low": "{school}。课没怎么上，大部分时间在宿舍打游戏。",
			"standard": "在{school}系统学习了专业知识，担任学生干部，组织能力突出。",
			"flaw": "{school}……正常上课。没挂。",
			"honest_low_followup": "姓……陈吧。没怎么见过，我们宿舍都翘课。",
		},
		"female": {
			"honest": "{school}，{degree}。专业课一般，在学校公众号干了两年，排版、选题、催稿都是我。主编挂的是学长的名字。",
			"honest_low": "{school}。课上得挺认真的，就是不知道学的有什么用。",
			"standard": "在{school}系统学习了专业知识，认真踏实，多次获得奖学金。",
			"flaw": "{school}……就、就正常上课。对不起，我说得不太好。",
			"honest_low_followup": "姓陈。他上课只点男生回答问题，我记得很清楚。",
		},
	},
	"major": {
		"male": {
			"honest": "{major}的课教会我看人想要什么。运营就是干这个的，以后我想往增长那边做。",
			"honest_low": "本专业的岗位少，钱也少。运营先进来，以后转产品。",
			"admit": "说实话，本专业找不到。投了四十多份，家里还等着我往回寄钱。",
			"standard": "我对互联网行业充满热情，运营是我的职业理想，希望将来能操盘大项目。",
			"flaw": "就是喜欢。……而且运营好晋升。",
			"honest_followup": "一半考公，一半考研。我们宿舍就我一个出来找工作的。",
		},
		"female": {
			"honest_low": "本专业的岗位少。招聘会上好几家写着“限男生”，运营没写。",
			"admit": "说实话，是本专业找不到。投了四十多份，只有运营回了我。我妈让我回去考公。",
			"standard": "我性格比较细心、有耐心，很适合做运营。",
			"flaw": "就、就是喜欢。我觉得女生做运营挺合适的……吧？",
			"honest_followup": "一半考公，一半考研。考公的基本是女生，家里都说稳定。",
		},
	},
	"gpa": {
		"male": {
			"honest": "专业前百分之二十。有一门统计学重修过——那学期我在外面创业。",
			"honest_low": "中间吧。不算好，没挂过。分数说明不了什么。",
			"admit": "这个绩点是去掉了两门选修算的，全算的话 {real}。选修课谁认真上啊。",
			"standard": "成绩中上。我更看重实践能力，在校期间一直在外面做事。",
			"flaw": "排……挺靠前的。具体没关注过。",
			"honest_followup": "（TA 从包里摸出一张对折的成绩单，抹平了递过来。重修那一门 TA 自己先指了出来。）",
		},
		"female": {
			"honest": "专业前百分之十。……就是绩点好看，别的我不太会。",
			"honest_low": "中间吧。不算好，没挂过。我已经很努力了。",
			"admit": "这个绩点是去掉了两门选修算的。全算的话只有 {real}。对不起，我不该这么写。",
			"standard": "我的成绩一直名列前茅，多次获得奖学金，学习态度认真。",
			"flaw": "排、排……挺靠前的。（TA 的声音越来越小。）",
			"honest_followup": "（TA 从文件袋里抽出一张盖了教务处章的成绩单，复印了三份，用回形针别好。）",
		},
	},
	"schedule": {
		"male": {
			"honest": "课都排在周一周二了，剩下几天全是空的。导师那边我去说的，他签了。",
			"honest_low": "课不多。有冲突的……翘了就行。",
			"admit": "其实下学期课多，{days} 天有点悬。怕写少了你们不要，先来了再说。",
			"standard": "课程基本修完了，可以全身心投入工作。",
			"flaw": "课、课不多。我能搞定。",
			"honest_followup": "期末两周只能来两天。其他时候一天不少，周末也能来。",
		},
		"female": {
			"honest": "课都排在周一周二了，剩下几天全是空的，导师签了字。就是下班太晚的话，宿舍有门禁。",
			"honest_low": "课不多。有冲突的我尽量调，调不开的……可能要请半天。真的很抱歉。",
			"admit": "其实下学期课多，{days} 天有点悬。我怕写少了你们不要。对不起。",
			"standard": "我会合理安排时间，保证学业与工作两不误，不会给团队添麻烦。",
			"flaw": "课、课不多的……应该没问题。我会想办法的。",
			"honest_followup": "期末两周我只能来两天，提前跟你们说。缺的活我晚上在宿舍补。",
		},
	},
	"skill": {
		"male": {
			"honest": "在学校天天用，社团的数据都是我一个人在弄。有一篇推文阅读量破了一万。",
			"honest_low": "“{skill}”会一点。真要用，现学也快。",
			"admit": "“{skill}”……上过一节选修课。写上去是因为招聘要求里有，进来我自学。",
			"standard": "“{skill}”我非常熟练，独立完成过多个项目。",
			"flaw": "“{skill}”……用过，挺简单的。",
		},
		"female": {
			"honest": "在学校公众号天天用。有一篇推文是我做的，阅读量破了一万，署名是部长。",
			"honest_low": "“{skill}”会一点，跟着教程能做出来。……我是不是不该写上去？",
			"admit": "“{skill}”……我就上过一节选修课。对不起，写上去是因为招聘要求里有。",
			"standard": "“{skill}”比较熟练。我学习能力强，不会的可以很快学会。",
			"flaw": "“{skill}”……用、用过的。不太熟，但我会努力学。",
		},
	},
	"self_eval": {
		"male": {
			"honest": "去年社团办活动，赞助商前一天跑了。我连夜打了十几个电话，第二天照常办。有三个电话是打给我爸朋友的。",
			"honest_low": "例子……老师交代的事我都做完了。大事还没轮到我。",
			"admit": "这句是网上模板抄的。我觉得写什么都差不多。",
			"standard": "在校期间担任学生干部，带领团队完成多项活动，抗压能力强。",
			"flaw": "例子……很多。挑一个？太多了。",
			"honest_followup": "社团指导老师。（TA 报了老师的名字和电话。）他会说那天我嗓子都喊哑了。",
			"honest_low_followup": "……室友吧。他知道我那段时间挺忙的。",
		},
		"female": {
			"honest": "去年社团办活动，赞助商前一天跑了。我连夜打了十几个电话，第二天照常办。总结会上部长说“大家辛苦了”。",
			"honest_low": "例子……我想想。其实就是老师和学长交代的事，我都做完了。我不太会说自己。",
			"admit": "这句是从网上的模板抄的。说实话，我不知道该写什么。不好意思。",
			"standard": "在校期间，我认真负责、细心踏实，多次获得老师认可。",
			"flaw": "例、例子……我想想。对不起，一下说不上来。",
		},
	},
	"project": {
		"male": {
			"honest": "从立项到结项我都在。中间有一次大返工，是我拍的板。",
			"honest_low": "我主要跟着做……名字写前面，是因为我是队长。",
			"admit": "我是挂名的。{role}是老师随手填的。不过答辩是我上去讲的。",
			"standard": "我作为{role}，从 0 到 1 主导了整个项目，带领团队拿到了优异成绩。",
			"flaw": "{project}……基本是我做的。",
			"honest_followup": "拿了省二。评委问的那个最难的问题，是我答的。决赛就差一点。",
		},
		"female": {
			"honest": "从立项到结项我都在。中间有一次大返工是我提的——第一次提没人理，第二次是队长替我说的。",
			"honest_low": "我主要跟着做，开会记记纪要。他们说女生细心。",
			"admit": "我是挂名的。{role}是老师随手填的。真的很抱歉。",
			"standard": "我在项目中担任{role}，主要负责统筹协调，团队配合得很好，取得了优异成绩。",
			"flaw": "{project}……我、我参加了。主要是配合大家。",
			"honest_followup": "拿了省二。评委问的那个最难的问题是我答的。上台领奖的是队长。",
		},
	},
}
## 社招那三行（SOCIAL）的男女说法：已经写了几年代码的人。
const SOCIAL_VOICES := {
	"edu": {
		"male": {
			"honest": "{school}，{degree}。课上学的用到的不多，写代码是那时候学会的，大二就在外面接活。",
			"honest_low": "{school}。说实话，大学没怎么好好学，一直在打游戏。",
			"standard": "在{school}系统学习了专业知识，竞赛拿过奖，基础扎实。",
			"flaw": "{school}……正常读完的。学校不重要。",
			"honest_followup": "一个排课系统。答辩的时候老师当场找出两个 bug，我修了一个，另一个我说是需求问题。",
		},
		"female": {
			"honest": "{school}，{degree}。写代码是那时候学会的。我们班四十个人五个女生，现在还在写代码的就我一个。",
			"honest_low": "{school}。说实话，大学没怎么好好学。……当时家里让我转去学会计。",
			"standard": "在{school}系统学习了专业知识，成绩优异，基础扎实。",
			"flaw": "{school}……就、就正常读完的。",
			"honest_followup": "一个排课系统。答辩时老师当场找出两个 bug，我当场修了一个。他说“女生能写成这样不错了”。",
		},
	},
	"skill": {
		"male": {
			"honest": "上一份工作天天用 {skill}。线上出过一次大问题，是我查出来的，全组就我会。",
			"honest_low": "{skill} 会用，深的说不上。用到了再看，问题不大。",
			"admit": "{skill}……跟着教程做过一个 demo。JD 里有就写了，大家都这么写。",
			"standard": "{skill} 我非常熟练，主导过多个大型项目落地。",
			"flaw": "{skill}？熟。没什么难的。",
		},
		"female": {
			"honest": "上一份工作天天用 {skill}。线上出过一次问题，是我查出来的。周报里写的是“团队快速定位”。",
			"honest_low": "{skill} 会用，深的说不上。跟着文档能做，慢一点，但不出错。",
			"admit": "{skill}……我就跟着教程做过一个 demo。写上去是因为 JD 里有。对不起。",
			"standard": "{skill} 比较熟练，有项目经验。我学习能力强，新东西上手快。",
			"flaw": "{skill}……用、用过的。不算很熟，但我学得很快。",
			"honest_followup": "上个月。查一个慢接口，最后改了三行。（TA 把那三行背了出来，连行号都对。）",
		},
	},
	"self_eval": {
		"male": {
			"honest": "去年项目延期，全组压在我这一块。我拆成三段，每天报进度，最后只晚了两天。那个月我在公司睡了一周。",
			"honest_low": "例子……领导交代的事我都做完了。主要是没碰上大项目。",
			"admit": "这句是模板上抄的。自评谁看啊。",
			"standard": "在过往工作中，我抗压能力强，多次在关键节点扛下核心任务。",
			"flaw": "例子……太多了。上家没我早就乱了。",
			"honest_followup": "组长打的，B+。他说要是早点报风险，能拿 A。……我觉得我该拿 A。",
		},
		"female": {
			"honest": "去年项目延期，全组压在我这一块。我拆成三段，每天报进度，最后只晚了两天。表扬邮件发给了组长。",
			"honest_low": "例子……我想想。领导交代的事都做完了。我不太会说自己做了什么。",
			"standard": "在过往工作中，我认真负责、沟通顺畅，和团队配合默契，多次获得领导认可。",
			"flaw": "例、例子……很多。对不起，一下说不上来。",
			"honest_followup": "组长打的，B+。他说我“稳”。稳就是 B+。",
			"admit_followup_mom": "绩效是 C。那年我休了产假。",
		},
	},
}

const CHIEF := {"standard": "说得挺好。", "honest": "讲这么细干嘛。", "flaw": "……"}
## 主管听男的、女的，夸法骂法不一样。
const CHIEF_MALE := {"chief_standard": "有冲劲。"}
const CHIEF_FEMALE := {"chief_standard": "女孩子，踏实就好。", "chief_honest": "这么较真，以后不好带。"}


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
	var t: Dictionary = SOCIAL[line.kind] if not c.is_intern and SOCIAL.has(line.kind) else KINDS[line.kind]
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
	var social := not c.is_intern and SOCIAL.has(line.kind)
	var voices: Dictionary = (SOCIAL_VOICES if social else VOICES).get(line.kind, {})
	card.male = _voice(voices.get("male", {}), pad, line.sub).merged(CHIEF_MALE)
	card.female = _voice(voices.get("female", {}), pad, line.sub).merged(CHIEF_FEMALE)
	return card


## 把 VOICES 里的一份说法换成卡上的字段：有水分时 admit 顶替 honest / honest_low，没水分时 admit 不用。
static func _voice(src: Dictionary, pad: bool, sub: Dictionary) -> Dictionary:
	var out := {}
	for k: String in src:
		var mom := "_mom" if k.ends_with("_mom") else ""
		var base := k.trim_suffix("_mom")
		var fields: Array = [base]
		match base:
			"admit":
				fields = ["honest", "honest_low"] if pad else []
			"admit_followup":
				fields = ["honest_followup", "honest_low_followup"] if pad else []
			"honest", "honest_low", "honest_followup", "honest_low_followup":
				if pad:
					fields = []
		for f: String in fields:
			out[f + mom] = _fill(src[k], sub)
	return out


static func _fill(text: String, sub: Dictionary) -> String:
	for k: String in sub:
		text = text.replace("{%s}" % k, str(sub[k]))
	return text
