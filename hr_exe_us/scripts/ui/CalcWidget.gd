class_name CalcWidget extends DraggableDoc
## 桌面计算器：算年包、算年龄用。

const SIZE := Vector2(92, 124)

var _display: Label
var _value := 0.0
var _entry := ""
var _pending := ""


func setup() -> void:
	size = SIZE
	UI.panel(self, Rect2(Vector2.ZERO, SIZE), Color("3c4643"), UI.BLACK)
	UI.panel(self, Rect2(4, 4, 84, 16), Color("a8c8a8"), UI.BLACK)
	_display = UI.label(self, "0", Vector2(6, 3), UI.BLACK)
	_display.size.x = 80
	_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var keys := ["7", "8", "9", "÷", "4", "5", "6", "×", "1", "2", "3", "−", "C", "0", "=", "+"]
	for i in keys.size():
		var cell := Vector2(i % 4, i / 4) * Vector2(21, 24) + Vector2(4, 24)
		var key: String = keys[i]
		UI.button(self, key, Rect2(cell, Vector2(20, 23)), func() -> void: press(key))


func press(key: String) -> void:
	if key == "C":
		_value = 0.0
		_entry = ""
		_pending = ""
	elif key in ["+", "−", "×", "÷", "="]:
		_apply()
		_pending = "" if key == "=" else key
	elif _entry.length() < 9:
		_entry += key
	var shown := _entry if _entry != "" else String.num(_value, 2)
	_display.text = shown


func _apply() -> void:
	if _entry == "":
		return
	var number := _entry.to_float()
	match _pending:
		"+": _value += number
		"−": _value -= number
		"×": _value *= number
		"÷": _value = _value / number if number != 0.0 else 0.0
		_: _value = number
	_entry = ""
