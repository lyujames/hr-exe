extends Control
## 桌角的全家福：国庆的公园，午后斜光，树梢刚开始黄。你爸坐长椅中间，花白头发、灰开衫、笑眯了眼、手放膝盖；你站左后、深蓝 polo，手搭在他肩上；老婆站右后，齐肩黑发、灰绿上衣、金项链，也搭着他另一边肩；孩子在前面攥着跳绳、缺颗门牙在笑。
## 右下角橙色日期 25 10 03：去年国庆，你爸还没生病。图是 素材/美术脚本/desk_art.py 画的。

const W := 72
const H := 56


func _ready() -> void:
	custom_minimum_size = Vector2(W + 2, H + 2)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.sprite(self, "res://assets/desk/family_photo.png", Vector2.ZERO)
