class_name QuestionCard extends Resource
## 回答按属性抽取：高表演力背标准答案、诚实者说真话、其余露出破绽。

@export var id: StringName
@export var text_key: String
## 探测的隐藏属性名（Candidate 的字段）。
@export var probes: PackedStringArray
@export var honest: String      # 诚实且属性高
@export var honest_low: String  # 诚实且属性低
@export var standard: String    # 标准答案
@export var flaw: String        # 破绽
## 现场测试：表演不出来，只看属性。
@export var always_truthful := false
## 只对有空窗期的人可用。
@export var requires_gap := false
## 问了这张卡，诉讼风险累积多少。
@export var lawsuit_risk := 0
@export_group("主管反应")
## 主管当场改动的评分项；空表示只说话不打分。
@export var chief_item: String
@export var chief_standard: String
@export var chief_honest: String
@export var chief_flaw: String


func available_for(c: Candidate) -> bool:
	return not requires_gap or c.has_gap()


func answer(c: Candidate) -> Dictionary:
	var total := 0
	for attribute in probes:
		total += c.get(attribute)
	var strong := total >= 50 * probes.size()
	if always_truthful:
		return {"text": honest if strong else honest_low, "tic": "none", "kind": "honest"}
	if c.performance >= 70:
		return {"text": standard, "tic": "none", "kind": "standard"}
	if c.honesty >= 55:
		return {"text": honest if strong else honest_low, "tic": "none", "kind": "honest"}
	return {"text": flaw, "tic": "sweat" if c.honesty < 30 else "eyes", "kind": "flaw"}


## 主管只听像不像：背得好加分，说实话减分，露破绽的没抬头。
func chief_reaction(kind: String) -> Dictionary:
	match kind:
		"standard":
			return {"line": chief_standard, "delta": 1}
		"honest":
			return {"line": chief_honest, "delta": -1}
	return {"line": chief_flaw, "delta": 0}
