class_name Candidate extends Resource

enum Degree { HIGH_SCHOOL, COLLEGE, BACHELOR, MASTER, DOCTOR }

const DEGREE_NAMES := ["高中", "大专", "本科", "硕士", "博士"]
const FIELDS: Array[String] = [
	"id", "display_name", "applied_position", "birth_date", "degree", "school", "undergrad_school", "degree_note",
	"is_intern", "exp_months", "exp_note", "major", "major_note", "gpa", "projects", "intern_days", "intern_months", "skills", "salary_k", "salary_low_k", "jobs", "gap_note", "self_eval", "attachment", "portrait_seed",
	"ability", "honesty", "loyalty", "pressure", "performance", "event_override", "is_story",
	"docs", "doc_overrides", "answers", "call_line", "envelope", "quirk", "entrance", "asides", "answer_kind", "padded_lines", "crack_lines",
]
## 公民身份号码的校验位。
const ID_WEIGHTS := [7, 9, 10, 5, 8, 4, 2, 1, 6, 3, 7, 9, 10, 5, 8, 4, 2]
const ID_CHECK := "10X98765432"

@export var id: StringName
@export var display_name: String
@export var applied_position: String
@export var birth_date: String
@export var degree: Degree = Degree.BACHELOR
@export var school: String
## 读了研、本科换过学校时才写；空串表示本科就是 school。
@export var undergrad_school: String
@export var degree_note: String
## 实习生（应届生）：没有工作经历和期望薪资，简历写专业和在校项目。
@export var is_intern := false
@export var major: String
## 专业后面的小字（辅修、转专业……）；规则只看主修。
@export var major_note: String
## 绩点（满分 4.0）。第 2 天起进规则（`RuleGpa`，3.0 以下不要），但跟能力只松松地挂钩。
@export var gpa := 0.0
## 每段 {name, role, start: "YYYY-MM", end: "YYYY-MM"}，从新到旧。
@export var projects: Array = []
## 实习生可到岗：每周几天、能连续实习几个月。
@export var intern_days := 0
@export var intern_months := 0
@export var skills: PackedStringArray
## 社招：简历上写的工作年限（月）和后面的小字（“含实习 1 年”“含外包”）；0 表示写的是“无”。
@export var exp_months := 0
@export var exp_note: String
## 期望月薪上限（k）；salary_low_k 非 0 时写成区间。
@export var salary_k: int = 12
@export var salary_low_k: int = 0
## 每段 {company, title, start: "YYYY-MM", end: "YYYY-MM" 或 ""（至今）}，从新到旧。
@export var jobs: Array = []
## 简历上写的空窗说明；空串表示没写。
@export var gap_note: String
@export var self_eval: String
@export var attachment: String
@export var portrait_seed: int
## 简历之外随身带的材料（"id_card" ……），由当天的 RuleEngine.active_docs 决定。
@export var docs: PackedStringArray
## 材料上和事实不一样的地方 {材料: {字段: 写的值}}：一处矛盾就是一条覆盖。上面的字段永远是事实。
@export var doc_overrides: Dictionary = {}

@export_group("手写人物")
## 手写的面试回答 {问题卡 id: 原话}，盖过按属性抽的回答。没写的卡照常按属性答。
@export var answers: Dictionary = {}
## 质询打电话时的原话；空串表示按矛盾的通用解释说。
@export var call_line: String
## 简历里夹着的信封 {from, text, amount}：收不收由玩家定，见 GameState.kickbacks。
@export var envelope: Dictionary = {}
## 这一条对上就不出现（写法同 story_echoes 的 when，比如“story_chenmo_1:hired”：上回已经录用了，不会再投）。
@export var skip_when: String
## 主角看到这份简历心里动了一下（第一次出现破格章的那天用）：桌上弹出的一句内心独白。空表示没有。
@export var liked_line: String
## 月底回顾里这个人的结局 {hired, pass, reject, exception: 一句话}；exception 是你破格放进来的（录用了用 hired），“{reason}”换成玩家拒绝 TA 时选的那句。
@export var epilogue: Dictionary = {}
## 套上了哪个奇葩面试者（Quirk），空表示没有；进门的旁白和没手写的回答前面那句小动作。
@export var quirk: StringName
@export var entrance: String
@export var asides: PackedStringArray
## 手写回答在主管耳朵里算什么：“honest”（默认）还是“standard”（黑话、表忠心，他爱听的那种）。
@export var answer_kind := "honest"
## 你追问到第几次就说第几句，不管追的是哪张卡；说完最后一句算问穿了（GameState.expose）。主管听不出来。
@export var crack_lines: PackedStringArray
## 简历上掺了水的行（ResumeQuestions 的 key，如“skill:Banyan（8 年）”“job:0”“self_eval”）。
## 手写人物只认这里；普通人按诚信另抽，这里写了的也算。
@export var padded_lines: PackedStringArray

@export_group("隐藏属性")
@export_range(0, 100) var ability := 50
@export_range(0, 100) var honesty := 50
@export_range(0, 100) var loyalty := 50
@export_range(0, 100) var pressure := 50
@export_range(0, 100) var performance := 50
## 非空时覆盖按属性推导的员工事件（例如剧情候选人）。
@export var event_override: StringName
@export var is_story := false

## 只供生成器排经历用：空窗月数、几个月前离职（-1 在职）。
var gap_months := 0
var left_months_ago := -1
## 只供生成器用：应届、转行、被裁……决定年龄段和自我评价。
var background := "regular"


## 某份材料上写的某一项，没被改过就是事实。这个人没带那份材料时退回简历。
func fact(key: String, doc := "resume") -> Variant:
	if doc not in docs:
		doc = "resume"
	return doc_overrides.get(doc, {}).get(key, get(key))


func override(doc: String, key: String, value: Variant) -> void:
	if not doc_overrides.has(doc):
		doc_overrides[doc] = {}
	doc_overrides[doc][key] = value


## 18 位号码：地区码随头像种子定，中间 8 位是身份证上的出生日期，最后一位真按校验算。
func id_number() -> String:
	var rng := RandomNumberGenerator.new()
	rng.seed = portrait_seed
	var birth: String = fact("birth_date", "id_card")
	var body := "%d%05d%s%03d" % [rng.randi_range(1, 6), rng.randi_range(10000, 99999), birth.replace("-", ""), rng.randi_range(1, 999)]
	var total := 0
	for i in body.length():
		total += int(body[i]) * ID_WEIGHTS[i]
	return body + ID_CHECK[total % 11]


func get_age(today: String) -> int:
	return DateUtil.age_on(birth_date, today)


func exp_text() -> String:
	if exp_months <= 0:
		return "无"
	var years := exp_months / 12
	var months := exp_months % 12
	if years == 0:
		return "%d 个月" % months
	return "%d 年" % years if months == 0 else "%d 年 %d 个月" % [years, months]


func salary_text() -> String:
	return "%dk" % salary_k if salary_low_k == 0 else "%d–%dk" % [salary_low_k, salary_k]


## 在读的研究生实习生：面试多问几问，还有专门的问题卡。
func is_grad() -> bool:
	return is_intern and degree >= Degree.MASTER


## 第一学历的学校：读了研的看本科。
func first_school() -> String:
	return undergrad_school if undergrad_school != "" else school


func degree_name() -> String:
	return DEGREE_NAMES[degree]


## 两段工作之间的空窗：返回较新那段的下标，没有则 -1。目前离职不算空窗，归在职规则管。
func gap_index() -> int:
	for i in range(1, jobs.size()):
		if jobs[i].end != "" and jobs[i].end < jobs[i - 1].start:
			return i - 1
	return -1


func has_gap() -> bool:
	return gap_index() >= 0


func to_dict() -> Dictionary:
	var data := {}
	for field in FIELDS:
		data[field] = get(field)
	data.id = String(id)
	data.event_override = String(event_override)
	data.skills = Array(skills)
	data.docs = Array(docs)
	data.quirk = String(quirk)
	data.asides = Array(asides)
	data.padded_lines = Array(padded_lines)
	data.crack_lines = Array(crack_lines)
	return data


static func from_dict(data: Dictionary) -> Candidate:
	var c := Candidate.new()
	for field in FIELDS:
		if data.has(field):  # 旧存档缺新字段时保留默认值
			c.set(field, data[field])
	c.degree = int(data.degree) as Degree
	c.skills = PackedStringArray(data.skills)
	c.projects = Array(data.get("projects", []))
	c.docs = PackedStringArray(data.get("docs", []))
	c.quirk = StringName(data.get("quirk", ""))
	c.asides = PackedStringArray(data.get("asides", []))
	c.padded_lines = PackedStringArray(data.get("padded_lines", []))
	c.crack_lines = PackedStringArray(data.get("crack_lines", []))
	return c
