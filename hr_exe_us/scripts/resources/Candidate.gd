class_name Candidate extends Resource

enum Degree { HIGH_SCHOOL, COLLEGE, BACHELOR, MASTER, DOCTOR }

const DEGREE_NAMES := ["High School", "Associate", "Bachelor's", "Master's", "PhD"]
const STATUS_CITIZEN := "US Citizen"
const STATUS_GREEN_CARD := "Permanent Resident"
const STATUS_H1B := "H-1B"
const STATUS_OPT := "F-1 OPT"
const STATUS_TN := "TN"
## TN 是条约身份，只给这两国公民。
const TN_COUNTRIES := ["Canada", "Mexico"]
const FIELDS: Array[String] = [
	"id", "display_name", "applied_position", "birth_date", "degree", "school", "degree_note",
	"skills", "salary_k", "bonus_pct", "jobs", "self_eval", "attachment", "portrait_seed",
	"nationality", "work_status", "status_expiry",
	"ability", "honesty", "loyalty", "pressure", "performance", "event_override", "is_story",
]

@export var id: StringName
@export var display_name: String
@export var applied_position: String
## 不上简历（法务删了），只能从毕业年份反推。
@export var birth_date: String
@export var degree: Degree = Degree.BACHELOR
@export var school: String
@export var degree_note: String
@export var skills: PackedStringArray
## 年薪（千美元）与目标奖金百分比；总包要自己算。
@export var salary_k: int = 80
@export var bonus_pct: int = 0
## 每段 {company, title, start: "YYYY-MM", end: "YYYY-MM" 或 ""（至今）}，从新到旧。
@export var jobs: Array = []
@export var self_eval: String
@export var attachment: String
@export var portrait_seed: int

@export_group("工作资格")
@export var nationality := "United States"
@export var work_status := STATUS_CITIZEN
## "YYYY-MM-DD"；公民和绿卡为空。
@export var status_expiry := ""

@export_group("隐藏属性")
@export_range(0, 100) var ability := 50
@export_range(0, 100) var honesty := 50
@export_range(0, 100) var loyalty := 50
@export_range(0, 100) var pressure := 50
@export_range(0, 100) var performance := 50
## 非空时覆盖按属性推导的员工事件（例如剧情候选人）。
@export var event_override: StringName
@export var is_story := false


func get_age(today: String) -> int:
	return DateUtil.age_on(birth_date, today)


func annual_salary() -> int:
	return salary_k * 10 * (100 + bonus_pct)


## 有效期当天仍算有效。
func authorized_on(today: String) -> bool:
	if work_status == STATUS_TN and not nationality in TN_COUNTRIES:
		return false
	return status_expiry == "" or status_expiry >= today


## 简历上唯一泄露年龄的字段。
func graduation_year() -> int:
	return int(birth_date.left(4)) + 22


func degree_name() -> String:
	return DEGREE_NAMES[degree]


## 最长空窗（月）：下段起始月 − 上段结束月；最新一段已结束则算到今天。
func max_gap_months(today: String) -> int:
	var longest := 0
	var later_start := DateUtil.month_index(today)
	for job: Dictionary in jobs:
		if job.end != "":
			longest = maxi(longest, later_start - DateUtil.month_index(job.end))
		later_start = DateUtil.month_index(job.start)
	return longest


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
		if data.has(field):  # 旧存档没有工作资格字段
			c.set(field, data[field])
	c.degree = int(data.degree) as Degree
	c.skills = PackedStringArray(data.skills)
	return c
