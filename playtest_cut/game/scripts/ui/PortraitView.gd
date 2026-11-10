class_name PortraitView extends TextureRect
## 播放候选人的小动作：出汗、眼神游移与诚实度挂钩，高表演力的人没有破绽。
## shake 是追问追到最慌：一边冒汗一边抖。

var seed_value := 0
## 美术图的 key（空 = 路人池）；bust：面试间的大框，有半身像就用半身像。
var art_key := ""
var bust := false
var tic := "none"
var _time := 0.0
var _frame := -1
var _base_position := Vector2.ZERO
var _shaking := false


func setup(portrait_seed: int, scale_factor := 1, key := "") -> void:
	seed_value = portrait_seed
	art_key = key if key != "" else PortraitFactory.art_key(portrait_seed)
	bust = scale_factor == 2 and PortraitFactory.has_bust(art_key)
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
		"shake":
			frame = PortraitFactory.Frame.SWEAT if beat % 2 == 0 else PortraitFactory.Frame.EYES_LEFT
	_shake(tic == "shake")
	_show(frame)


func _shake(on: bool) -> void:
	if on and not _shaking:
		_base_position = position
	_shaking = on
	if on:
		position = _base_position + Vector2(1 if int(_time * 20.0) % 2 == 0 else -1, 0)
	elif position != _base_position and _base_position != Vector2.ZERO:
		position = _base_position
		_base_position = Vector2.ZERO


func _show(frame: int) -> void:
	if frame != _frame:
		_frame = frame
		texture = PortraitFactory.make(seed_value, frame, art_key, bust)
