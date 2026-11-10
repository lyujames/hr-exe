shader_type canvas_item;
// 章印的墨：按像素随机缺一点，再按 3×2 的小块缺几块（橡胶面没沾匀）。strength 越小缺得越多。
// 用节点自己的坐标抽随机数，简历拖着走的时候墨迹不跟着闪。

uniform float strength = 0.95;
uniform float seed = 0.0;
varying vec2 local;

float h(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233)) + seed * 7.13) * 43758.5453);
}

void vertex() {
	local = VERTEX;
}

void fragment() {
	vec2 p = floor(local);
	float keep = 0.86 + 0.14 * strength;
	if (h(floor(p / vec2(3.0, 2.0)) + 17.0) > 0.62 + 0.38 * strength) {
		keep = 0.0;
	}
	if (h(p) > keep) {
		COLOR.a = 0.0;
	} else {
		COLOR.a *= 0.86 + 0.14 * h(p + 3.0);
	}
}
