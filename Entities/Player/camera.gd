extends Camera2D

var shake_strength: float = 0.0
var shake_decay: float = 0.9
var shake_max_offset: float = 8.0
var rng := RandomNumberGenerator.new()

func _ready():
	rng.randomize()

func _process(delta):
	if shake_strength > 0.01:
		offset = Vector2(
			rng.randf_range(-1, 1),
			rng.randf_range(-1, 1)
		) * shake_strength * shake_max_offset
		shake_strength *= shake_decay
	else:
		offset = Vector2.ZERO

func start_shake(strength := 1.0, decay := 0.85, max_offset := 8.0):
	shake_strength = strength
	shake_decay = decay
	shake_max_offset = max_offset

func freeze_frames(timescale, duration) -> void:
	Engine.time_scale = timescale
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0
