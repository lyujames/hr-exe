class_name DayConfig extends Resource

@export var day := 1
@export var resume_count := 10
## 09:00–18:00 对应的真实秒数。
@export var screening_seconds := 240.0
@export var new_rules: Array[Rule] = []
@export var story_candidates: Array[Candidate] = []
@export var story_slot := 2
@export_multiline var boss_mail: String
@export_multiline var coworker_note: String
## 今天早上结算第一位录用者的员工事件。
@export var fires_employee_event := false
## 可选开销 [{id, label, amount, unpaid_note}]：可以不付，家庭状态会恶化。
@export var bills: Array = []
@export var headline: String
@export_multiline var news_body: String
## 按当天员工事件 id 替换报纸头条：{event_id: [标题, 正文]}。
@export var news_by_event: Dictionary = {}
@export_multiline var family_sms: String
## 面试：赵主管入座时说的话、抢走的那个问题、候选人的反问。
@export var chief_opener: String
@export var chief_question: QuestionCard
@export var candidate_ask: CandidateAsk
