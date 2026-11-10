extends Node
## 没有音频素材时用程序合成音效：盖章要“重”。
## 几个播放器轮着用，盖章、打印机、手机震能叠在一起响；每次播放音高随机抖一点，连盖十份也不像复读机。

const RATE := 22050
const VOICES := 6

var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _stamps := {}
var _paper: AudioStreamWAV
var _slide: AudioStreamWAV
var _key: AudioStreamWAV
var _printer: AudioStreamWAV
var _buzz: AudioStreamWAV
var _drawer_open: AudioStreamWAV
var _drawer_close: AudioStreamWAV


func _ready() -> void:
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	# 盖章三层：橡胶面拍上纸的“啪”（很短的噪声）+ 章身砸到桌上的“咚”（音高往下掉）+ 纸被压的一点沙声。
	# 拒绝最沉，通过轻一点，破格多一声短促的金属余音（铜箍），像盖公章。
	for kind: String in ["pass", "reject", "exception"]:
		var low: float = {"pass": 78.0, "reject": 58.0, "exception": 66.0}[kind]
		var ring: float = 0.12 if kind == "exception" else 0.0
		_stamps[kind] = _synth(0.3, func(t: float, n: float) -> float:
			var clack := n * 0.9 * exp(-t * 420.0)
			var f := low * (1.0 + 1.4 * exp(-t * 40.0))
			var thump := sin(TAU * f * t) * 0.95 * exp(-t * 18.0)
			var press := n * 0.12 * exp(-t * 30.0)
			var bell := sin(TAU * 1240.0 * t) * ring * exp(-t * 22.0)
			return clack + thump + press + bell)
	# 翻页：一声“唰”，噪声先过一道低通（平滑），中间鼓起来；再夹两下纸边的脆响
	_paper = _smooth(_synth(0.16, func(t: float, n: float) -> float:
		var crinkle := n * 0.5 if absf(t - 0.04) < 0.002 or absf(t - 0.09) < 0.002 else 0.0
		return n * 0.32 * sin(PI * t / 0.16) + crinkle), 3)
	# 纸在桌上拖开：更轻更闷
	_slide = _smooth(_synth(0.12, func(t: float, n: float) -> float:
		return n * 0.18 * sin(PI * t / 0.12)), 6)
	_key = _synth(0.03, func(t: float, n: float) -> float:
		return n * 0.3 * exp(-t * 200.0))
	# 针式打印机：一顿一顿的“滋——”
	_printer = _synth(0.55, func(t: float, n: float) -> float:
		var gate := 1.0 if fmod(t * 14.0, 1.0) < 0.6 else 0.15
		return (n * 0.25 + signf(sin(TAU * 190.0 * t)) * 0.08) * gate * minf(1.0, (0.55 - t) * 20.0))
	# 手机扣在桌上震：“嗡、嗡”两下，桌面跟着有点咯噔的杂音
	_buzz = _synth(0.7, func(t: float, n: float) -> float:
		var on := fmod(t, 0.35) < 0.22
		if not on:
			return 0.0
		var rattle := n * 0.1 if fmod(t * 150.0, 1.0) < 0.15 else 0.0
		return sin(TAU * 140.0 * t) * 0.45 + signf(sin(TAU * 140.0 * t)) * 0.08 + rattle)
	# 抽屉：木头滑轨“嚓——”，最后一下“咚”到头
	_drawer_open = _smooth(_synth(0.32, func(t: float, n: float) -> float:
		var slide := n * 0.28 * minf(1.0, t * 12.0) * (1.0 if t < 0.24 else 0.0)
		var stop := sin(TAU * 70.0 * (t - 0.24)) * 0.8 * exp(-(t - 0.24) * 30.0) if t >= 0.24 else 0.0
		return slide + stop), 2)
	_drawer_close = _smooth(_synth(0.24, func(t: float, n: float) -> float:
		var slide := n * 0.25 * (1.0 if t < 0.14 else 0.0)
		var stop := sin(TAU * 60.0 * (t - 0.14)) * 0.9 * exp(-(t - 0.14) * 26.0) if t >= 0.14 else 0.0
		return slide + stop), 2)


## kind：pass / reject / exception；别的（组名、面试那张表）按通过的声音。
func stamp(kind := "pass") -> void:
	_play(_stamps.get(kind, _stamps.pass), randf_range(0.92, 1.06))


func paper() -> void:
	_play(_paper, randf_range(0.9, 1.12))


func slide() -> void:
	_play(_slide, randf_range(0.85, 1.1), -6.0)


func printer() -> void:
	_play(_printer)


func buzz() -> void:
	_play(_buzz)


func key() -> void:
	_play(_key, randf_range(0.9, 1.1))


func drawer(open: bool) -> void:
	_play(_drawer_open if open else _drawer_close, randf_range(0.95, 1.05))


func _play(stream: AudioStream, pitch := 1.0, db := 0.0) -> void:
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = stream
	p.pitch_scale = pitch
	p.volume_db = db
	p.play()


func _synth(seconds: float, wave: Callable) -> AudioStreamWAV:
	var count := int(seconds * RATE)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in count:
		var sample: float = wave.call(float(i) / RATE, rng.randf_range(-1.0, 1.0))
		bytes.encode_s16(i * 2, int(clampf(sample, -1.0, 1.0) * 32000.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.data = bytes
	return stream


## 简单低通：前后 k 个采样取平均，噪声就从“沙沙”变成“唰唰”。
func _smooth(stream: AudioStreamWAV, k: int) -> AudioStreamWAV:
	var src := stream.data
	var n := src.size() / 2
	var out := PackedByteArray()
	out.resize(src.size())
	for i in n:
		var sum := 0
		var cnt := 0
		for j in range(maxi(0, i - k), mini(n, i + k + 1)):
			sum += src.decode_s16(j * 2)
			cnt += 1
		out.encode_s16(i * 2, clampi(int(sum / cnt * 1.6), -32000, 32000))
	stream.data = out
	return stream
