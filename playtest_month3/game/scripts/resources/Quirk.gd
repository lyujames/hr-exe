class_name Quirk extends Resource
## 奇葩面试者：简历是当天随机生成、照规则筛过的那份，看着很正常；人一进门才知道是什么样。
## 当天没有剧情候选人进面试时，抽中的那个普通人套上这一层（见 InterviewRoom.pick_candidate）。
## 隐藏属性一并盖掉，所以录不录、留不留得住，跟着这个人走，不跟着简历走。

@export var id: StringName
## 进门那一句旁白，盖掉“坐下，等你提问”。
@export_multiline var entrance: String
## 手写回答，写法同 Candidate.answers（“卡 id+”是追问）。没写的卡照常按属性答，
## 前面贴一句 asides 里的小动作，让人记得对面坐的是谁。
@export var answers: Dictionary = {}
@export var asides: PackedStringArray
## 手写回答算哪一种，见 Candidate.answer_kind。
@export var answer_kind := "honest"
@export_range(0, 100) var ability := 50
@export_range(0, 100) var honesty := 50
@export_range(0, 100) var loyalty := 50
@export_range(0, 100) var pressure := 50
@export_range(0, 100) var performance := 50
@export var event_override: StringName


func apply(c: Candidate) -> void:
	c.quirk = id
	c.entrance = entrance
	c.asides = asides
	c.answer_kind = answer_kind
	var merged := answers.duplicate()
	merged.merge(c.answers)
	c.answers = merged
	for attribute in ["ability", "honesty", "loyalty", "pressure", "performance"]:
		c.set(attribute, get(attribute))
	c.event_override = event_override
