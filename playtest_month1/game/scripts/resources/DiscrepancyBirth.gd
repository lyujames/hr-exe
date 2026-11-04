class_name DiscrepancyBirth extends Discrepancy
## 简历上的出生年份和身份证对不上，身份证是事实。简历上的年份围着“90 后”那条线改：
## 89 年及以前的写成 90–92 年（看着过，其实不过，这是故意改小，诚实度压低）；
## 正好 90 年的一半写成 89 年（看着不过，其实过）；其余只差一年，不影响判定。
## 80 后在简历堆里本来就少，所以另有一部分本来能过的人被改成“其实是 80 后、简历写小了”，
## 这一种会改事实，判定从过变成不过。应届生不改：一个 80 后应届生太假。

const LIAR_HONESTY := 35

@export var pivot_year := 1990
## 真不是 90 后的人改小年龄的概率。
@export_range(0.0, 1.0) var liar_density := 0.7
## 本来能过的非应届生里，有多少其实是改小了年龄的 80 后。
@export_range(0.0, 1.0) var trap_density := 0.12
## 打电话时的解释。改小年龄的人编，其余的人说真话；两边都有“户口报错”，光听解释分不出来。%d 是简历上写的年份。
@export var lie_lines: PackedStringArray = [
	"身份证是当年上户口报错的，我真是 %d 年的，正在走更正。",
	"简历上那个才对，办身份证的时候派出所录错了。",
	"差一两年而已嘛，我心态很年轻的，干活绝对不输 90 后。",
]
@export var true_lines: PackedStringArray = [
	"不好意思，简历模板是同学的，年份忘了改。以身份证为准。",
	"我手误打错了，身份证上那个才对。",
	"上户口那年家里报错了，后来一直按身份证来。简历是我按实际生日写的。",
]


func chance(c: Candidate) -> float:
	if DateUtil.parse(c.birth_date).x < pivot_year:
		return liar_density
	return density + (trap_density if c.background != "fresh" else 0.0)


func shape(c: Candidate, rng: RandomNumberGenerator) -> void:
	var birth := DateUtil.parse(c.birth_date)
	var claimed := birth.x
	if birth.x >= pivot_year and c.background != "fresh" and rng.randf() * chance(c) < trap_density:
		# 简历照旧（年份压在线上一点），事实挪到线下
		claimed = mini(birth.x, pivot_year + 2)
		birth.x = pivot_year - rng.randi_range(1, 3)
		c.birth_date = DateUtil.format(birth)
	elif birth.x < pivot_year:
		claimed = pivot_year + rng.randi_range(0, 2)
	elif birth.x == pivot_year and rng.randf() < 0.5:
		claimed = pivot_year - 1
	else:
		claimed += 1 if birth.x == pivot_year or rng.randf() < 0.5 else -1
	if birth.x < pivot_year:
		c.honesty = mini(c.honesty, LIAR_HONESTY)
	var month := birth.y if rng.randf() < 0.6 else rng.randi_range(1, 12)
	c.override("resume", "birth_date", DateUtil.format(Vector3i(claimed, month, birth.z)))


func explain(c: Candidate, rng: RandomNumberGenerator) -> Dictionary:
	var claimed := DateUtil.parse(c.fact("birth_date")).x
	var lied := DateUtil.parse(c.birth_date).x < pivot_year and claimed >= pivot_year
	var lines := lie_lines if lied else true_lines
	var text := lines[rng.randi() % lines.size()]
	return {"text": text % claimed if "%d" in text else text, "truthful": not lied}
