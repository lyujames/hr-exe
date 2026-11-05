class_name JobPosting extends Resource
## 一个招聘岗位的 JD。第一个月全是实习岗，每个岗位要的专业不一样：
## “指定专业”那条规则（RuleMajor）拿简历上的“应聘”去找对应的岗位，看主修在不在它的 majors 里。

@export var title: String
@export_multiline var pay_text: String
## 这个岗位要的专业，一字不差才算。
@export var majors: PackedStringArray
## 听着沾边、其实不在名单上的专业：生成器拿来出陷阱。
@export var lookalikes: PackedStringArray
## 专业之外的要求，只给人看，不参与判定。
@export var requirements: PackedStringArray
