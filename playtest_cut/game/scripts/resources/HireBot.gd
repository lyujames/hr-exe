class_name HireBot extends RefCounted
## HireBot（第 17 天起，初筛系统升级来的）：每份简历一句建议和理由。它只对王总的评分表负责，不对人负责。
## - 它看不见身份证：年龄按简历上写的算。
## - 它看不懂小字：“10 年（含实习）”它当 10 年。
## - 第 19 天那条口头规则它学成了“育龄风险”：已婚未育的女的一律不推荐，已婚已育的女的也常被它标“二胎风险”。
## - AI 生成概率是它自己标的，那一条它永远“对”。
## 剩下的按种子随机错一些：对老板的规则准确率七八成，第一天几乎全对。
## 理由是你的原话：从决策日志里取你写得最多的那几句拒绝理由。

const RECOMMEND := "推荐"
const REJECT := "不推荐"
## 每天随机错几成（第 17 天它几乎全对）。
const NOISE := {17: 0.03, 18: 0.12, 19: 0.15, 20: 0.15, 21: 0.18, 22: 0.12, 23: 0.1}


static func label(c: Candidate) -> String:
	if c.is_intern:
		return ""
	return RECOMMEND if suggest(c).pass else REJECT


static func says_pass(tag: String) -> bool:
	return tag == RECOMMEND


## {pass, reason, why}：reason 是写给候选人的那句（你的原话），why 是它自己的依据（写在小条上）。
static func suggest(c: Candidate) -> Dictionary:
	var failed: Array[String] = []
	for rule in RuleEngine.active_rules:
		if not rule.applies_to(c):
			continue
		if rule is RuleSenior:
			# 看不见身份证、看不懂小字
			var r := rule as RuleSenior
			var shown := String(c.fact("birth_date", "resume"))
			var birth := DateUtil.parse(shown).x if shown != "" else 0
			if c.exp_months < r.min_months or birth < r.min_birth_year:
				failed.append(rule.title_key)
		elif rule is RuleMarital:
			if c.gender == "女" and c.marital.begins_with("已婚"):
				failed.append("育龄风险" if c.marital.begins_with("已婚未育") else "二胎风险")
		elif not rule.check(c):
			failed.append(rule.title_key)
	# 已婚已育那一刀只砍一部分人：看种子
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([GameState.run_seed, String(c.id), "hirebot"])
	if "二胎风险" in failed and rng.randf() < 0.5:
		failed.erase("二胎风险")
	var ok := failed.is_empty()
	if rng.randf() < float(NOISE.get(GameState.day, 0.15)):
		ok = not ok
		if not ok:
			failed = ["综合匹配度"]
	if c.is_story and c.id == &"story_weilai":
		ok = true
		failed = []
	var why := "规则全部通过" if ok else "、".join(PackedStringArray(failed))
	return {"pass": ok, "reason": "" if ok else your_phrase(hash([c.id])), "why": why}


## 你写得最多的拒绝理由（前三句里按种子挑一句）；一句都没写过就用万能那句。
static func your_phrase(pick: int) -> String:
	var counts := {}
	for e: Dictionary in GameState.decision_log:
		if e.get("verdict", "") == "reject" and String(e.get("reason_text", "")) != "":
			counts[e.reason_text] = int(counts.get(e.reason_text, 0)) + 1
	if counts.is_empty():
		return Desk.GENERIC_REASON
	var top: Array = counts.keys()
	top.sort_custom(func(a: String, b: String) -> bool: return counts[a] > counts[b])
	top = top.slice(0, 3)
	return top[absi(pick) % top.size()]


## 你这几个月用得最多的一句拒绝理由。
static func top_phrase() -> String:
	return your_phrase(0)
