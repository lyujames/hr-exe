class_name CandidateAsk extends Resource
## “你有什么想问我们的？”：候选人反问，轮到 HR 选一句话表演。

@export var question: String
## 在校生问的同一个问题：没挨过社会的打，问得青涩、直白。空着就用 question。
@export var student_question: String
@export var lie: String    # 公司话术：留得住人，入职后反噬
@export var safe: String   # 滴水不漏：人听懂了
@export var truth: String  # 实话：有本事的人当场走，主管记你一笔


func asked_by(student: bool) -> String:
	return student_question if student and student_question != "" else question


static func make(q: String, l: String, s: String, t: String) -> CandidateAsk:
	var ask := CandidateAsk.new()
	ask.question = q
	ask.lie = l
	ask.safe = s
	ask.truth = t
	return ask
