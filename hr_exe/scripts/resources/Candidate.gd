class_name Candidate extends Resource

enum Degree { HIGH_SCHOOL, COLLEGE, BACHELOR, MASTER, DOCTOR }

const DEGREE_NAMES := ["高中", "大专", "本科", "硕士", "博士"]
const FIELDS: Array[String] = [
	"id", "display_name", "applied_position", "birth_date", "degree", "school", "undergrad_school", "degree_note",
	"skills", "salary_k", "salary_low_k", "jobs", "gap_note", "self_eval", "attachment", "portrait_seed",
	"ability", "honesty", "loyalty", "pressure", "performance", "event_override", "is_story",
]

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
	return data


static func from_dict(data: Dictionary) -> Candidate:
	var c := Candidate.new()
	for field in FIELDS:
		if data.has(field):  # 旧存档缺新字段时保留默认值
			c.set(field, data[field])
	c.degree = int(data.degree) as Degree
	c.skills = PackedStringArray(data.skills)
	return c
