class_name Candidate extends Resource

enum Degree { HIGH_SCHOOL, COLLEGE, BACHELOR, MASTER, DOCTOR }

const DEGREE_NAMES := ["高中", "大专", "本科", "硕士", "博士"]
const FIELDS: Array[String] = [
	"id", "display_name", "applied_position", "birth_date", "degree", "school", "undergrad_school", "degree_note",
	"skills", "salary_k", "salary_low_k", "jobs", "gap_note", "self_eval", "attachment", "portrait_seed",
	"ability", "honesty", "loyalty", "pressure", "performance", "event_override", "is_story",
	"docs", "doc_overrides",
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
@export var skills: PackedStringArray
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


func salary_text() -> String:
	return "%dk" % salary_k if salary_low_k == 0 else "%d–%dk" % [salary_low_k, salary_k]


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
	return data


static func from_dict(data: Dictionary) -> Candidate:
	var c := Candidate.new()
	for field in FIELDS:
		if data.has(field):  # 旧存档缺新字段时保留默认值
			c.set(field, data[field])
	c.degree = int(data.degree) as Degree
	c.skills = PackedStringArray(data.skills)
	c.docs = PackedStringArray(data.get("docs", []))
	return c
