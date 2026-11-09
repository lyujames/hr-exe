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
