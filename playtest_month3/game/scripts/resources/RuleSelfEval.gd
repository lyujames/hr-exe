class_name RuleSelfEval extends Rule
## “奋斗者文化”：自我评价里出现禁词（“平衡”“稳定”）的一律不要。只认这两个词，一字不差；意思一样、字不一样的不算。

const PASS_EVALS := [
	"结果导向，能扛事，愿与公司共同成长。",
	"热爱技术，能接受高强度工作。",
	"做事踏实，有责任心，抗压能力强。",
]
## 没写禁词，意思却差不多：规则只看字。
const EDGE_PASS_EVALS := [
	"希望找一家能长期做下去的公司。",
	"想要准点下班，按时陪孩子吃饭。",
	"擅长负载均衡与高可用架构。",
]
## 禁词藏在技术词里：规则不管上下文。
const EDGE_FAIL_EVALS := [
	"负责核心系统稳定性建设，全年零重大事故。",
	"擅长数据库读写分离与负载平衡。",
	"三年内主导支付链路改造，接口稳定在 50ms 以内。",
]
const FAIL_EVALS := [
	"希望工作和生活能保持平衡。",
	"性格稳定，追求一份稳定的工作。",
	"上有老下有小，想找个稳定的地方。",
]

@export var banned := PackedStringArray(["平衡", "稳定"])


func applies_to(c: Candidate) -> bool:
	return not c.is_intern


func check(c: Candidate) -> bool:
	for word in banned:
		if c.self_eval.contains(word):
			return false
	return true


func shape(c: Candidate, form: Shape, rng: RandomNumberGenerator) -> void:
	var pool: Array = PASS_EVALS
	match form:
		Shape.PASS:
			if check(c):
				return
		Shape.EDGE_PASS:
			pool = EDGE_PASS_EVALS
		Shape.EDGE_FAIL:
			pool = EDGE_FAIL_EVALS
		Shape.FAIL:
			pool = FAIL_EVALS
	c.self_eval = pool[rng.randi_range(0, pool.size() - 1)]
