class_name PortraitFactory
## 64×64 头像：从美术图里切。每张图一行五帧（Frame 的顺序）。
## 剧情里有名字的人各一张（assets/portraits/<key>.png）；其余的人按种子从路人池里挑，男女各一池，画法同一套。
## 图是 素材/美术脚本/export_art.py 导出来的。

enum Frame { NEUTRAL, BLINK, EYES_LEFT, EYES_RIGHT, SWEAT }

const SIZE := 64
const BUST_SIZE := 128
const ART_DIR := "res://assets/portraits/"
const POOL_SIZE := 24
## 只用来算种子画出来是男是女（style_of 抽随机数的顺序），不再拿来画。
const SKINS := ["e0c0a4", "d3ad8d", "bd9474", "e6cbb5"]
const HAIRS := ["1c1d20", "33292a", "54463c", "6b6f70", "22262e"]
const CLOTHES := ["3b4a57", "4a4f55", "2f3a3a", "57606a", "39453f"]

## 剧情里有名字的人：种子 → 美术图。同一个人在不同地方用的种子不一样（离职谈话、组长位），都指到同一张。
const BY_SEED := {
	19960914: "chenmo", 19910512: "hejing", 19880703: "shaodong", 19991008: "liuziang",
	19930417: "shenwen", 19970821: "qiaoan", 20260327: "zhouyining", 20260331: "zhoulan",
	19990321: "chengye", 4401: "chengye", 20020603: "songzhiyao", 4402: "songzhiyao",
	19950211: "sunhao", 19970211: "weilai", 20260324: "lizhe", 19891120: "wangkai", 20260302: "guquan",
	1984: "wangzong", 4101: "zhao", 1979047: "laozhou", 6217: "xiaomeng",
	4529: "hanlei", 1992052: "hanlei", 1988017: "gemin", 1985020: "lixiuying",
	2803: "linchuan", 3317: "tangmin", 5106: "xuyan", 7741: "yeqing",
	3311: "interns",
}
## 撞了种子的两对（方晓 / 覃小满、许嘉禾 / 苏见青）按候选人 id 找。
const BY_ID := {
	"story_steady": "fangxiao", "story_zhuanshengben": "qinxiaoman", "story_zhuanshengben_2": "qinxiaoman",
	"story_no_project": "xujiahe", "story_philosophy": "sujianqing",
}
## 有 128 半身像的人：面试间的大框用它，不放大 64。
const BUSTS := ["hejing", "interns"]

static var _cache := {}


## 这个人用哪张美术图；空字符串表示路人。photo：简历上的照片（沈雯的照片是七年前的，单有一张）。
static func art_key(seed_value: int, id: StringName = &"", photo := false) -> String:
	var key: String = BY_ID.get(String(id), BY_SEED.get(seed_value, ""))
	if photo and key != "" and ResourceLoader.exists(ART_DIR + key + "_photo.png"):
		key += "_photo"
	return key


## key 空就按种子找；bust 只对有半身像的人生效，返回 128×128。
static func make(seed_value: int, frame: Frame = Frame.NEUTRAL, key := "", bust := false) -> Texture2D:
	if key == "":
		key = BY_SEED.get(seed_value, "")
	bust = bust and key in BUSTS
	var cache_key := [seed_value, frame, key, bust]
	if not _cache.has(cache_key):
		var atlas := AtlasTexture.new()
		if bust:
			atlas.atlas = load(ART_DIR + "bust_" + key + ".png")
			atlas.region = Rect2(frame * BUST_SIZE, 0, BUST_SIZE, BUST_SIZE)
		elif key != "":
			atlas.atlas = load(ART_DIR + key + ".png")
			atlas.region = Rect2(frame * SIZE, 0, SIZE, SIZE)
		else:
			var female := style_of(seed_value) >= 3
			atlas.atlas = load(ART_DIR + ("pool_f.png" if female else "pool_m.png"))
			atlas.region = Rect2(frame * SIZE, posmod(hash(seed_value), POOL_SIZE) * SIZE, SIZE, SIZE)
		_cache[cache_key] = atlas
	return _cache[cache_key]


static func has_bust(key: String) -> bool:
	return key in BUSTS


## 这个种子算男还是女（0–4，3、4 算女）：沿用原来程序拼头像时抽随机数的顺序，别的地方的种子才不用改。
static func style_of(seed_value: int) -> int:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	rng.randi_range(0, SKINS.size() - 1)
	rng.randi_range(0, HAIRS.size() - 1)
	rng.randi_range(0, CLOTHES.size() - 1)
	rng.randi_range(22, 28)
	rng.randi_range(26, 30)
	return rng.randi_range(0, 4)


## 从 base 往后找一个看得出男女的种子：路人池里女的进女池、男的进男池。有名字的人不动。
static func seed_for(base: int, female: bool) -> int:
	if BY_SEED.has(base):
		return base
	for k in 64:
		var style := style_of(base + k)
		if (style >= 3) == female:
			return base + k
	return base
