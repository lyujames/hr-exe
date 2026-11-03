class_name Discrepancy extends Resource
## 材料之间的一种矛盾。shape() 只改某份材料上写的（Candidate.override），不改事实；
## 规则读权威材料（Candidate.fact），所以矛盾不改对错，只把“读漏”从一页里挪到两份材料之间。

@export var id: StringName
## 桌上要有这份材料（简历之外）才会出现。
@export var doc: String
## 带着这份材料的人里，有多少带这种矛盾。
@export_range(0.0, 1.0) var density := 0.3


## 这个人带这种矛盾的概率；子类可以按人改，比如更愿意挑卡在规则边上的人。
func chance(_c: Candidate) -> float:
	return density


func shape(_c: Candidate, _rng: RandomNumberGenerator) -> void:
	pass  # 子类覆写
