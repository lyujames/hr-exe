class_name JobPosting extends Resource
## 一个招聘岗位的 JD。第一个月全是实习岗，每个岗位要的专业不一样：
## “指定专业”那条规则（RuleMajor）拿简历上的“应聘”去找对应的岗位，看主修在不在它的 majors 里。
## 第二个月是社招程序员：不看专业，看技能栏（RuleKeywords 拿 keywords 去对）。
## 新开一个同名岗位就是 JD 改版：盖过旧的那页。

@export var title: String
@export_multiline var pay_text: String
## 这个岗位要的专业，一字不差才算。
@export var majors: PackedStringArray
## 听着沾边、其实不在名单上的专业：生成器拿来出陷阱。
@export var lookalikes: PackedStringArray
## 专业之外的要求，只给人看，不参与判定。
@export var requirements: PackedStringArray
## 必备技能：技能栏要一字不差地写全（RuleKeywords）。空表示这个岗位不看。
@export var keywords: PackedStringArray
## 听着像必备技能、其实不是的（JavaScript 不是 Java）：生成器拿来出陷阱。
@export var keyword_lookalikes: PackedStringArray
## 社招简历技能栏从这里抽；空就用生成器的通用技能。
@export var skill_pool: PackedStringArray
## 社招简历工作经历里的职位名；空就用生成器的通用职位。
@export var job_titles: PackedStringArray
## 技术方向：后端 / 前端 / 运维。三个方向要的必备技能互不相同；只管某个方向的规则（Banyan 只管后端）看这个。空表示不分方向。
@export var role: String
## 这个岗位的人期望多少（k）：生成的简历按这个范围抽；(0, 0) 表示用程序员的默认。
@export var salary_range := Vector2i.ZERO

@export_group("按组招（第 13 天起）")
## 组名，写在文件夹上（“数据组”）；空表示这个岗位不是一个文件夹。
@export var team: String
## 本组期望薪资上限（k），写在文件夹上；超了不能放进这个组。
@export var salary_cap_k := 18
## 名额：同名岗位从开到现在一共能放进几个人（GameState.folder_filled），满了组长退回。
@export var hc := 2
## 加班强度 1–5，文件夹上画几颗星；影响留任期里累垮的概率（EmployeeEvents）。
@export var workload := 3
## 组长贴在文件夹上的一句话。
@export var folder_note: String
## 来面这个组的人的组长：{name, seed, cut_in, cut_in_again, next_line, bonus, opener, need: {item, note}, delay: {at: "start" | "mid", minutes, line}}。
## 空表示还是赵主管。
@export var lead: Dictionary = {}
## 组长自己带来的问题，第一张是尖锐题。
@export var lead_cards: Array[QuestionCard] = []
