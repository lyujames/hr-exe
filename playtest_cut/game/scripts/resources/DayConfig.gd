class_name DayConfig extends Resource

@export var day := 1
## 日历日期 YYYY-MM-DD。日期按月跳着走，留空则从开局日期顺延。
@export var date: String
@export var resume_count := 10
## 08:00–15:00 筛简历对应的真实秒数；15:00 去面试，18:00 下班。
@export var screening_seconds := 240.0
@export var new_rules: Array[Rule] = []
## 今天收起来的东西：规则 id、材料矛盾 id、岗位名（比如月初实习岗招满，实习那几条规矩不再生效）。先收后加。
@export var retire: PackedStringArray
## 今天起简历之外多带的材料，和规则一样只增不减。
@export var new_docs: PackedStringArray
## 今天起出现的材料矛盾，桌上有对应材料才生效。
@export var discrepancies: Array[Discrepancy] = []
@export var story_candidates: Array[Candidate] = []
@export var story_slot := 2
## 简历堆的人群比例 {背景: 权重}，背景见 CandidateGenerator；经济越差，转行和被裁的人越多。
@export var candidate_mix: Dictionary = {}
## 今天新开的招聘岗位，和规则一样只增不减：桌上的岗位 JD 一页一个。
@export var new_postings: Array[JobPosting] = []
## 晨会前的手机推送：一行标题，预告今天的新规则。
@export var morning_push: String
@export_multiline var boss_mail: String
@export_multiline var coworker_note: String
## 本月工资标准 {base, per_resume, per_correct, per_reason, chief_bonus, edit_bonus, retention, retention_days, retention_deferred, fines}
## chief_bonus：主管推荐奖，录用的人是赵主管要的（见 chief_need），当天发；没写算 0。，只在月初设置，之后沿用。
## fines 为 false 时不扣钱：违规只是拿不到判断奖金，老板对质也不罚款；没写算 true。
## edit_bonus：识人奖，评分表上你改的那一处，留任期满对账时比主管填的准，每人发一次；没写算 0。
## per_reason：拒对且理由选中违反的那条，再加的钱；只有经济好的第 1 月有，没写算 0。
## 员工事件不再按天配置：每个录用的人在留任期满那天早上结算。
@export var pay: Dictionary = {}
## 可选开销 [{id, label, amount, unpaid_note, when}]：可以不付，家庭状态会恶化。
## when 见 GameState.family_matches：之前选过的事才带出来的账单（报了进阶课、选了进口支架），对不上就不出这张。
@export var bills: Array = []
## 今天几份生成的简历是猎头推来的（Candidate.broker）：只从不是今天新加的规则里挑一条，卡在边上不合格。0 表示没有。
@export var broker_count := 0
## 人效指标（第 14 天起）：今天要处理完几份，底薪才拿全额；少几份按比例扣（GameState.base_pay）。0 表示没有指标。
@export var quota := 0
## 关键词初筛系统（第 15 天起）：社招简历右上角盖一个系统标签（Ats.label），日结单记跟系统一致 / 推翻了几份。
@export var ats := false
## 入职手续（第 13 天起，老周被抽走以后）：昨天录用的人，今天桌上各一张入职登记表，签一张扣 Desk.INTAKE_MINUTES；下班没签完，王总记一笔。
@export var intake := false
## 按组分文件夹（第 13 天起）：桌上“通过”章换成今天开着的组（JobPosting.team 不空的岗位），简历拖进文件夹 = 放进那个组。
## 面试按组排：每场是那个组的组长，一天最多 GameState.MAX_SESSIONS 场；钟按实际问的走，可以过 18:00，下班跟着最后一场走。
@export var team_folders := false
## 按之前的事给邮件加附言 [{when, ps}]，when 见 GameState.family_matches；对上的都接在后面。
@export var mail_ps_by: Array = []
@export var headline: String
@export_multiline var news_body: String
## 按当天员工事件 id 替换报纸头条：{event_id: [标题, 正文]}。
@export var news_by_event: Dictionary = {}
## 之前那些手写人物的回响 [{when, headline, body, mail_ps, sms}]，when 是“候选人 id:pass/reject/hired”。
## 第一条对上的生效；headline 让位给 news_by_event。bonus {label, amount}：对上了，今天日结单多一行老板发的钱。文字里的“{reason}”换成玩家拒绝 TA 时选的那句。
@export var story_echoes: Array = []
@export_multiline var family_sms: String
## 按之前的家里事换掉 family_sms [{when, sms}]，when 是“标记:选项”（见 GameState.family），第一条对上的生效。
@export var family_sms_by: Array = []
## 晚上可以回的短信 [{key, label, family, marriage, paid|unpaid}]：label 是你回的那句，family 是对家庭状态的影响、marriage 是对夫妻感情的（默认 0）；
## key 为 silent 的是“不回”。
## paid / unpaid 写账单 id，只在付了 / 没付那张账单时出现。选了哪句记进 GameState.family[sms_flag]。
@export var sms_replies: Array = []
@export var sms_flag: String
## 上班时老婆发来的消息 [{id, at: 几点（分钟，08:00 = 480，13:00 = 780）, text, when, replies, ignored}]：手机震一下、弹一行预览；
## 点手机能翻今天的消息、选一句回（扣 GameState.REPLY_MINUTES 分钟）。
## from：谁发的（手机里一个人一个对话），默认老婆。
## replies [{key, label, marriage, family, when, transfer, note}]：没有就是不用回；when 对不上的选项不出；transfer 是从零钱转过去多少（note 写在转账卡上）。
## ignored：下班还没回，夫妻感情变多少（老婆的默认 −1，别人的默认 0）。
## 王总的消息：选项带 trust 是老板信任变多少，ignored_trust 是没回扣多少；text 里的“{done}”换成到这会儿处理了几份。
## when 见 GameState.family_matches；同一个 id 写几条变体，按顺序取第一条对上的。
@export var desk_texts: Array = []
## 上班时家里来电 {at, text, flag, left, stayed}：之后桌上多一个“提前下班”的按钮。flag 记进 GameState.family，值是“yes”，没走就没有这一项。
## left / stayed：走了、没走，夫妻感情各变多少（默认 +2 / −1）。
## trust：走了老板信任变多少（第 15 天手术那天走，人效垫底，−1）。
@export var midday_call: Dictionary = {}
## 下班回家（18:00 下班，到家快七点）的一幕，一拍一拍往下点：
## {text, when}：一句台词或旁白，“老婆：”“孩子：”“你爸：”“你：”开头是有人说话，别的是旁白；{processed}{passed} 换成今天看了几份、过了几份。
## {ask: 标记, when, options: [{key, label, say, marriage, when, then: [拍]}]}：你选一句说（say 是做了件事、不是说话时印出来的旁白），选了哪句记进 GameState.family[标记]，then 是接着的话。
## when 见 GameState.family_matches；晚上的短信先回，所以这里能看 sms_flag 回了什么。最后一天回家写在 SliceEnd。
@export var home_scene: Array = []
## 你爸来家里吃饭：回家那张图换成桌子后面坐着你爸的（home_1930_dad / home_2030_dad）；22:30 才到家他已经走了，用平常那张。
@export var dad_at_dinner := false
## 面试：赵主管入座时说的话、抢走的那个问题、候选人的反问。
@export var chief_opener: String
## 赵主管的便签 {note: 便签上的话, short: 桌角那张小便签上的要点, item: 评分表上打★的那项, project / role / months: 他要的经历, seed_projects: 往简历里多撒的项目名}：
## 早上贴在你桌上，写的是今天筛的人里他明天想见什么样的；第二天面试拍在桌上，录用的人简历第二页对得上
## （Candidate.fits，只看纸面），发主管推荐奖（pay.chief_bonus）。最后一天没有明天，不写。
## 组长（interviewer 不空）的便签还是当天面试用、只写 item，看他自己心里那一项。空表示今天没有。
@export var chief_need: Dictionary = {}
@export var chief_question: QuestionCard
## 招程序员起主管每场先问一道尖锐题，从今天及之前每天的这一张里抽（见 InterviewRoom._plan_chief）。
@export var chief_sharp: QuestionCard
## 今天的奇葩面试者：没有剧情候选人进面试时，套在抽中的普通人身上。
## 第 13 天起程序员按组招：面试的人换成用人那个组的组长，空表示还是赵主管。
## {name: 头像旁的名字, seed: 头像种子, cut_in / cut_in_again: 插话前那句旁白, next_line: 第二场开场, bonus: 日结单上推荐奖的叫法}
## 组长和赵主管反着来：说实话、说得出细节的加分，背标准答案、露破绽的扣分（QuestionCard.lead_reaction）。
## 他不碰老板评分表，只记自己心里的“技术 / 协作”，填表时直接告诉你要不要（这时 chief_need 的 item 写这两项之一；赵主管面试时写评分表上的一项，如“稳定性”“狼性”）。
@export var interviewer: Dictionary = {}
## 组长自己带来的问题，第一张是尖锐题，每场抢两问；只在 interviewer 不空时用。
@export var lead_cards: Array[QuestionCard] = []
@export var quirk: Quirk
@export var candidate_ask: CandidateAsk

@export_group("第三个月起")
## HireBot（第 17 天起）：1 助手（每份简历角上一张建议小条）；2 预筛（简历分“推荐”“不推荐”两叠，推翻要写理由、扣 Desk.OVERRIDE_MINUTES）；
## 3 写规则（同 2，另外桌上的便签换成打印的）。0 表示没有。日结单记跟它一致 / 推翻了几份（和关键词初筛系统同一套账）。
@export var hirebot := 0
## 标准耗时（第 18 天起）：今天的量按你最快的那一段排（GameState.quota_today / resume_count_today）。
@export var standard_time := false
## 便签是打印的（第 22 天老周最后一张手写的之后）：邮件旁边那张纸是白的。
@export var note_printed := false
## 邮件能打印：点“打印”，打印件进抽屉，记一件证据（这里写证据 id）。空表示不能。
@export var mail_print := ""
## 傍晚的离职谈话 [{id, name, seed, when, info, opener, questions: [...], after}]，面试之后一场接一场（ExitTalk）。
## questions 每项 {q, template: "why" | "comp" | "sign"（用默认三句）, options: [{style, label, reply, minutes, effects}]}。
## effects：{lawsuit, trust, conscience, fine, marriage, flag: {标记: 值}, evidence}。
@export var exit_talks: Array = []
## 上班时桌上弹出来的事 [{id, at, when, title, text, options: [{key, label, reply, effects}]}]：钟停着，选完接着走。
## at 是几点（分钟）；effects 同上，另有 money（今天日结多一笔）、void（作废这个人的录用）。选了哪项记进 GameState.family[id]。
@export var desk_memos: Array = []
## 月底补窟窿的路（日结单上勾选）[{id, label, amount, when, family, marriage}]：勾了就进今天的钱，记 family["rescue_" + id]。
@export var rescue_options: Array = []
## 按之前的事换报纸头条 [{when, headline, body}]，when 见 GameState.family_matches；第一条对上的生效，盖过 story_echoes 的头条。
@export var news_by: Array = []
## 今天的 HC：一定要放满几个（第 23 天月底）。放不满王总记一笔。0 表示没有。
@export var hc_today := 0
## HC 硬指标 {posting: 岗位名, note: 邮件附言（主管的话）}：今天这个岗位至少放进一个人（通过或破格）。
## 生成的简历里投这个岗位的都卡在规则上（BlockedTalent 那两份除外），规则内的基本没有。放不满扣 GameState.HC_PUSH_FINE、王总记一笔。
@export var hc_push: Dictionary = {}
