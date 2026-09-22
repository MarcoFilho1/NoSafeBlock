extends Node
## Original synthesized cues. No external audio assets or attribution dependency.

var muted: bool = false
var cues: Dictionary = {}
var voices: Array[AudioStreamPlayer] = []
var voice_index: int = 0
var ambience: AudioStreamPlayer

func _ready() -> void:
	for kind in ["shot", "hurt", "death", "attack", "reload", "wave", "over"]:
		cues[kind] = synthesize(kind)
	for i in range(8):
		var voice := AudioStreamPlayer.new()
		voice.volume_db = -15
		add_child(voice)
		voices.append(voice)
	ambience = AudioStreamPlayer.new()
	ambience.stream = synthesize("ambient")
	ambience.volume_db = -29
	add_child(ambience)
	ambience.play()

func synthesize(kind: String) -> AudioStreamWAV:
	var rate: int = 22050
	var duration: float = 4.0 if kind == "ambient" else (0.6 if kind in ["over", "wave"] else 0.16)
	var count := int(rate * duration)
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in range(count):
		var t := float(i) / rate
		var envelope := pow(1.0 - float(i) / count, 2.0)
		var sample: float = 0.0
		match kind:
			"shot": sample = (randf_range(-1, 1) * 0.65 + sin(t * 500) * 0.35) * envelope
			"hurt", "attack": sample = sin(TAU * (95 * t - 40 * t * t)) * envelope * 0.7
			"death": sample = (sin(TAU * (160 * t - 350 * t * t)) * 0.7 + randf_range(-0.1, 0.1)) * envelope
			"reload": sample = sin(TAU * 1200 * t) * envelope * (1.0 if fmod(t, 0.08) < 0.015 else 0.0)
			"wave": sample = sin(TAU * (330 if t < 0.3 else 440) * t) * envelope * 0.5
			"over": sample = sin(TAU * (180 * t - 70 * t * t)) * envelope * 0.5
			"ambient": sample = (sin(TAU * 55 * t) * 0.4 + sin(TAU * 82.5 * t) * 0.15) * (0.7 + sin(TAU * 0.25 * t) * 0.25)
		data.encode_s16(i * 2, int(clampf(sample, -1.0, 1.0) * 24000))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = data
	if kind == "ambient":
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = count
	return stream

func play_cue(kind: String) -> void:
	if muted or not cues.has(kind):
		return
	var voice := voices[voice_index]
	voice_index = (voice_index + 1) % voices.size()
	voice.stream = cues[kind]
	voice.play()

func set_muted(value: bool) -> void:
	muted = value
	ambience.volume_db = -80 if muted else -29
	if muted:
		for voice in voices:
			voice.stop()

func _exit_tree() -> void:
	# Explicitly release looping playback before the scene/audio server shuts down.
	for voice in voices:
		voice.stop()
		voice.stream = null
	ambience.stop()
	ambience.stream = null
	cues.clear()
