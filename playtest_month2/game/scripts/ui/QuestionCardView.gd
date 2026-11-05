class_name QuestionCardView extends Control
## 桌上的一张问题卡：拖到候选人身上就是问这一句。
## 左上角的小标签按这张卡探的属性上色，玩家一眼看出是问能力、诚信、忠诚还是抗压。

const SIZE := Vector2(100, 92)
const TAGS := {
	"ability": ["能力", Color("7a5a2a")],
	"honesty": ["诚信", Color("3a5a7a")],
	"loyalty": ["忠诚", Color("3a6a5a")],
	"pressure": ["抗压", Color("8a3a3a")],
	"performance": ["表现", Color("5a4a6a")],
}

var card: QuestionCard
## 追问或主管插话时手牌压着不让动。
var enabled := true:
	set(value):
		enabled = value
		modulate = Color.WHITE if value else Color(1, 1, 1, 0.45)
		mouse_default_cursor_shape = Control.CURSOR_DRAG if value else Control.CURSOR_ARROW
var _box: StyleBoxFlat


func setup(question: QuestionCard) -> void:
	card = question
	size = SIZE
	custom_minimum_size = SIZE
	mouse_default_cursor_shape = Control.CURSOR_DRAG
	_draw_face(self)
	mouse_entered.connect(_hover.bind(true))
	mouse_exited.connect(_hover.bind(false))


## 卡面画在 parent 上：拖动时的影子也用这一套。
func _draw_face(parent: Control) -> StyleBoxFlat:
	var bg := UI.panel(parent, Rect2(Vector2.ZERO, SIZE), UI.PAPER, UI.BLACK)
	var box: StyleBoxFlat = bg.get_theme_stylebox("panel")
	box.set_border_width_all(2)
	if parent == self:
		_box = box
	var tag: Array = TAGS.get(card.probes[0] if card.probes.size() > 0 else "", ["其他", UI.INK_SOFT])
	var tag_width := 30.0
	UI.panel(parent, Rect2(5, 5, tag_width, 14), tag[1])
	UI.label(parent, tag[0], Vector2(8, 4), UI.PAPER)
	if card.lawsuit_risk > 0:
		UI.label(parent, "!", Vector2(SIZE.x - 12, 4), UI.RED)
	UI.label(parent, card.text_key, Vector2(5, 22), UI.INK, SIZE.x - 10)
	return box


func _hover(on: bool) -> void:
	if _box and enabled:
		_box.border_color = UI.GREEN if on else UI.BLACK


func _get_drag_data(_at: Vector2) -> Variant:
	if not enabled:
		return null
	var preview := Control.new()
	var face := Control.new()
	face.position = -SIZE / 2.0
	face.rotation = -0.06
	preview.add_child(face)
	_draw_face(face).border_color = UI.GREEN
	set_drag_preview(preview)
	modulate = Color(1, 1, 1, 0.25)
	Sfx.key()
	return {"question_card": card}


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END and is_inside_tree():
		enabled = enabled  # 没扔准就回到手里
		_hover(false)
