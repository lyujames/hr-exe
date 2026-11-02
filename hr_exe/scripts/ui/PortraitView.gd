class_name PortraitView extends TextureRect
## 播放候选人的小动作：出汗、眼神游移与诚实度挂钩，高表演力的人没有破绽。

var seed_value := 0
var tic := "none"
var _time := 0.0
var _frame := -1


func setup(portrait_seed: int, scale_factor := 1) -> void:
	seed_value = portrait_seed
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	custom_minimum_size = Vector2.ONE * PortraitFactory.SIZE * scale_factor
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_show(PortraitFactory.Frame.NEUTRAL)


func _process(delta: float) -> void:
	_time += delta
	var beat := int(_time * 3.0)
	var frame := PortraitFactory.Frame.NEUTRAL
	if beat % 11 == 0:
		frame = PortraitFactory.Frame.BLINK
	match tic:
		"sweat":
			if beat % 2 == 0:
				frame = PortraitFactory.Frame.SWEAT
		"eyes":
			frame = PortraitFactory.Frame.EYES_LEFT if beat % 4 < 2 else PortraitFactory.Frame.EYES_RIGHT
	_show(frame)


func _show(frame: int) -> void:
	if frame != _frame:
		_frame = frame
		texture = PortraitFactory.make(seed_value, frame)
