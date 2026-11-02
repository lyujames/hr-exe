class_name Rule extends Resource
## 每条规则是一个 Resource 子类。shape() 让生成器无需了解具体规则，新增规则只需实现这两个方法。

enum Shape { PASS, EDGE_PASS, EDGE_FAIL, FAIL }

@export var id: StringName
@export var day_added: int
@export var title_key: String         # 规则手册标题
@export_multiline var text_key: String # 规则手册正文
@export var reject_reason_key: String # 拒绝理由，终章原样复用
@export var is_illegal := false
## 荒谬规则：故意放行违反它的人会累积良心值。
@export var is_absurd := false


func check(_c: Candidate) -> bool:
	return true  # 子类覆写


## 把候选人改造成指定形态，由生成器在 GameState.today 下调用。
func shape(_c: Candidate, _form: Shape, _rng: RandomNumberGenerator) -> void:
	pass  # 子类覆写
