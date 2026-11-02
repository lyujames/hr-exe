class_name Candidate extends Resource

enum Degree { HIGH_SCHOOL, COLLEGE, BACHELOR, MASTER, DOCTOR }

const DEGREE_NAMES := ["高中", "大专", "本科", "硕士", "博士"]
const FIELDS: Array[String] = [
	"id", "display_name", "applied_position", "birth_date", "degree", "school", "degree_note",
	"skills", "salary_k", "salary_months", "jobs", "self_eval", "attachment", "portrait_seed",
	"ability", "honesty", "loyalty", "pressure", "performance", "event_override", "is_story",
]

@export var id: StringName
@export var display_name: String
@export var applied_position: String
@export var birth_date: String
@export var degree: Degree = Degree.BACHELOR
@export var school: String
@export var degree_note: String
@export var skills: PackedStringArray
@export var salary_k: int = 12
@export var salary_months: int = 12
## 每段 {company, title, start: "YYYY-MM", end: "YYYY-MM" 或 ""（至今）}，从新到旧。
@export var jobs: Array = []
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


func get_age(today: String) -> int:
	return DateUtil.age_on(birth_date, today)


func annual_salary() -> int:
	return salary_k * 1000 * salary_months


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
		c.set(field, data[field])
	c.degree = int(data.degree) as Degree
	c.skills = PackedStringArray(data.skills)
	return c
