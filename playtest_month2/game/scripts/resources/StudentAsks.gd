class_name StudentAsks
## 在校生的反问：还没被社会拷打过，想到什么问什么。学生问一到两个：
## 有时先从这里抽一个傻问题，最后总会问当天那一题（用学生的口气）。

const POOL := [
	["公司有零食和下午茶吗？我看网上说大厂都有。",
		"零食柜每天补，周五还有下午茶。", "行政那边有一些福利安排。", "零食柜是空的，上次补货是去年年会。"],
	["实习可以每周来三天吗？我周三下午还有课。",
		"可以，我们很支持同学兼顾学业。", "可以跟带你的人商量。", "JD 上写了一周五天。说三天的，都没过。"],
	["组里的同事都多大呀？好相处吗？",
		"都是年轻人，氛围像大学社团。", "团队整体比较年轻。", "上一个实习生走的时候，组里没人知道他叫什么。"],
	["要是我做错了事，会有人教我吗？",
		"我们鼓励试错，犯错就是成长。", "会有相应的复盘机制。", "做错了会在大群里被@，全组都看得到。"],
	["公司离学校有点远，有住宿补贴吗？",
		"有的，实习生也有住房补贴。", "具体以 offer 上写的为准。", "没有。去年有个实习生在公司沙发上睡了一个月。"],
	["我想问一下……我刚才表现得怎么样？",
		"非常好，基本没问题了。", "我们会综合评估，一周内通知。", "评分表在主管手里，我说了不算。"],
	["实习能学到真东西吗？我以后想做这一行。",
		"能，实习生直接上手真实业务。", "学到多少主要看个人。", "主要是贴表格、录数据。学不学得到，看你下班以后。"],
	["年会可以带爸妈来吗？想让他们看看我上班的地方。",
		"当然，我们很欢迎家属。", "年会安排行政会另行通知。", "年会去年取消了，今年还没说。"],
]
## 先问一个傻问题的概率。
const EXTRA_CHANCE := 0.5


## 这个学生要问的：0~1 个池子里的问题，加上当天那一题。整月尽量不重样。
static func for_candidate(c: Candidate, day: int, day_ask: CandidateAsk, asked_before: Array) -> Array[CandidateAsk]:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(c.display_name + str(day))
	var asks: Array[CandidateAsk] = []
	if day_ask == null or rng.randf() < EXTRA_CHANCE:
		var fresh := POOL.filter(func(row: Array) -> bool: return not (row[0] in asked_before))
		if fresh.is_empty():
			fresh = POOL
		var row: Array = fresh[rng.randi_range(0, fresh.size() - 1)]
		asks.append(CandidateAsk.make(row[0], row[1], row[2], row[3]))
	if day_ask:
		asks.append(day_ask)
	return asks
