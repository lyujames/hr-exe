class_name InspectLines extends Control
## 质询的标记：点中的那一行描黄框，标出的矛盾在两行之间画红线。
## 记的是“哪份材料的哪一项”，不是那个 Label：材料拖动、简历翻页重绘后照样跟着走。

## 先点的那一行 [材料, 字段]，等着点第二行。
var picked: Array = []
## [[材料, 字段, 材料, 字段]]：标出矛盾的两行。
var links: Array = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(640, 360)


func clear() -> void:
	picked = []
	links.clear()
	queue_redraw()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	for link: Array in links:
		var a := _rect(link[0], link[1])
		var b := _rect(link[2], link[3])
		if a.has_area() and b.has_area():
			draw_rect(a, UI.RED, false, 1.0)
			draw_rect(b, UI.RED, false, 1.0)
			draw_line(a.get_center(), b.get_center(), UI.RED, 2.0)
	if not picked.is_empty():
		var p := _rect(picked[0], picked[1])
		if p.has_area():
			draw_rect(p, UI.YELLOW, false, 2.0)


## 那一行现在不在桌上（材料收走了、简历翻到了第 2 页）时返回空矩形。
func _rect(doc: DraggableDoc, key: String) -> Rect2:
	if not is_instance_valid(doc):
		return Rect2()
	var label: Label = doc.fields.get(key)
	if not is_instance_valid(label) or label.is_queued_for_deletion():
		return Rect2()
	return Rect2(label.global_position - global_position, label.get_combined_minimum_size()).grow(2.0)
