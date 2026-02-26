extends Node
var sfx_library : Dictionary = {
	"footstep": preload("res://Audio/Assets/SFX/Player/Cat/cat_footstep.wav")
}
var loop_timers: Dictionary = {} # id -> Timer

func play_sfx(sfx_name: String, pitch_variation: float = 0.5, volume_variation: float = 2.0, looping: bool = false, custom_loop_offset: float = 0.0):
	if looping:
		start_loop(StringName(sfx_name), sfx_name, custom_loop_offset, pitch_variation, volume_variation)
		return
		
	if not sfx_library.has(sfx_name):
		push_warning("SFX not found: %s" % sfx_name)
		return

	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.stream = sfx_library[sfx_name]
	player.bus = &"SFX"
	player.pitch_scale = RandomNumberGenerator.new().randf_range(1 - pitch_variation, 1 + pitch_variation)
	player.volume_db = RandomNumberGenerator.new().randf_range(-volume_variation, volume_variation)
	$SFXPlayers.add_child(player)
	player.play()
	await player.finished
	player.queue_free()

var active_loops: Dictionary = {} # sfx_name -> AudioStreamPlayer

func start_loop(id: StringName, sfx_name: String,  interval: float, pitch_variation: float = 0.0, volume_variation: float = 0.0) -> void:
	if not sfx_library.has(sfx_name):
		push_warning("SFX not found: %s" % sfx_name)
		return

	if loop_timers.has(id):
		return

	var t: Timer = Timer.new()
	t.wait_time = max(0.01, interval)
	t.one_shot = false
	$SFXPlayers.add_child(t)

	t.timeout.connect(func() -> void:
		play_sfx(sfx_name, pitch_variation, volume_variation)
	)

	loop_timers[id] = t
	t.start()


func stop_loop(id: StringName) -> void:
	if not loop_timers.has(id):
		return

	var t: Timer = loop_timers[id]
	loop_timers.erase(id)

	if is_instance_valid(t):
		t.stop()
		t.queue_free()


func set_loop_interval(id: StringName, interval: float) -> void:
	if not loop_timers.has(id):
		return
	var t: Timer = loop_timers[id]
	if is_instance_valid(t):
		t.wait_time = max(0.01, interval)
