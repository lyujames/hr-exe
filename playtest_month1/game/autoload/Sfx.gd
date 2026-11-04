extends Node
## 没有音频素材时用程序合成音效：盖章要“重”。

const RATE := 22050

var _player: AudioStreamPlayer
var _stamp: AudioStreamWAV
var _paper: AudioStreamWAV
var _key: AudioStreamWAV
var _printer: AudioStreamWAV


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.max_polyphony = 4
	add_child(_player)
	_stamp = _synth(0.22, func(t: float, n: float) -> float:
		return (sin(TAU * 62.0 * t) * 0.9 + n * 0.5 * exp(-t * 90.0)) * exp(-t * 16.0))
	_paper = _synth(0.13, func(t: float, n: float) -> float:
		return n * 0.22 * sin(PI * t / 0.13))
	_key = _synth(0.03, func(t: float, n: float) -> float:
		return n * 0.3 * exp(-t * 200.0))
	# 针式打印机：一顿一顿的“滋——”
	_printer = _synth(0.55, func(t: float, n: float) -> float:
		var gate := 1.0 if fmod(t * 14.0, 1.0) < 0.6 else 0.15
		return (n * 0.25 + signf(sin(TAU * 190.0 * t)) * 0.08) * gate * minf(1.0, (0.55 - t) * 20.0))


func stamp() -> void:
	_play(_stamp)


func paper() -> void:
	_play(_paper)


func printer() -> void:
	_play(_printer)


func key() -> void:
	_play(_key)


func _play(stream: AudioStream) -> void:
	_player.stream = stream
	_player.play()


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
