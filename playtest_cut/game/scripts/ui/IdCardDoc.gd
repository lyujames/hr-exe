class_name IdCardDoc extends DraggableDoc
## 身份证复印件：出生年月日以它为准。和简历一起滑进来，一起收走；不收印章。

const SIZE := Vector2(170, 72)
const TINT := Color("bcc6c4")
const PHOTO := 32

var candidate: Candidate


func setup(c: Candidate) -> void:
	candidate = c
	size = SIZE
	UI.panel(self, Rect2(Vector2(2, 2), SIZE), UI.BLACK)
	# 复印件：灰底、碳粉麻点、左边一道复印机的黑边
	UI.sprite(self, "res://assets/desk/id_copy.png", Vector2.ZERO)
	UI.panel(self, Rect2(Vector2.ZERO, SIZE), Color.TRANSPARENT, UI.INK_SOFT)
	UI.label(self, "居民身份证（复印件）", Vector2(8, 1), UI.INK_SOFT)
	var birth := DateUtil.parse(c.fact("birth_date", "id_card"))
	fields.display_name = UI.label(self, "姓名　" + c.fact("display_name", "id_card"), Vector2(8, 17), UI.INK)
	fields.birth_date = UI.label(self, "出生　%d年%d月%d日" % [birth.x, birth.y, birth.z], Vector2(8, 33), UI.INK)
	UI.label(self, "号码　" + c.id_number(), Vector2(8, 52), UI.INK)
	var photo := PortraitView.new()
	photo.setup(c.portrait_seed, 1, PortraitFactory.art_key(c.portrait_seed, c.id))
	photo.set_process(false)
	add_child(photo)
	# 入树后再缩：之前设的尺寸会被 setup() 里 64 像素的最小尺寸顶回去
	photo.custom_minimum_size = Vector2.ONE * PHOTO
	photo.size = photo.custom_minimum_size
	photo.position = Vector2(SIZE.x - PHOTO - 6, 17)
