class_name Discrepancy extends Resource
## 材料之间的一种矛盾。shape() 只改某份材料上写的（Candidate.override），不改事实；
## 规则读权威材料（Candidate.fact），所以矛盾不改对错，只把“读漏”从一页里挪到两份材料之间。

@export var id: StringName
## 桌上要有这份材料（简历之外）才会出现。
@export var doc: String
## 对不上的是哪一项（Candidate 的字段），质询时两份材料点的就是这一行。
@export var field: String
## 这处矛盾牵扯的规则 id：标出它、以“材料不一致”拒绝，违反的正是这几条之一才算理由准确。
@export var rule_ids: PackedStringArray
## 带着这份材料的人里，有多少带这种矛盾。
@export_range(0.0, 1.0) var density := 0.3


## 这个人带这种矛盾的概率；子类可以按人改，比如更愿意挑卡在规则边上的人。
func chance(_c: Candidate) -> float:
	return density


func shape(_c: Candidate, _rng: RandomNumberGenerator) -> void:
	pass  # 子类覆写


## 质询打电话时候选人的解释 {text, truthful}。解释不改判定，只透露这个人诚不诚实。
func explain(_c: Candidate, _rng: RandomNumberGenerator) -> Dictionary:
	return {"text": "啊？我也不清楚，可能是填错了吧。", "truthful": true}
