class_name DayConfig extends Resource

@export var day := 1
## 日历日期 YYYY-MM-DD。日期按月跳着走，留空则从开局日期顺延。
@export var date: String
@export var resume_count := 10
## 09:00–18:00 对应的真实秒数。
@export var screening_seconds := 240.0
@export var new_rules: Array[Rule] = []
@export var story_candidates: Array[Candidate] = []
@export var story_slot := 2
## 简历堆的人群比例 {背景: 权重}，背景见 CandidateGenerator；经济越差，转行和被裁的人越多。
@export var candidate_mix: Dictionary = {}
## 本月的职位描述，只在月初设置，之后几天沿用。
@export var job_posting: JobPosting
## 晨会前的手机推送：一行标题，预告今天的新规则。
@export var morning_push: String
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
