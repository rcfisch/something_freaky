extends Camera2D
class_name Camera2DShake

var shake_strength: float = 0.0
var shake_decay: float = 0.9
var shake_max_offset: float = 8.0
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()

func _process(_delta: float) -> void:
	# Only responsible for visual shake offset.
	if shake_strength > 0.01:
		var jitter: Vector2 = Vector2(
			rng.randf_range(-1.0, 1.0),
			rng.randf_range(-1.0, 1.0)
		)
		offset = jitter * shake_strength * shake_max_offset
		shake_strength *= shake_decay
	else:
		offset = Vector2.ZERO

func start_shake(strength: float = 1.0, decay: float = 0.85, max_offset: float = 8.0) -> void:
	shake_strength = strength
	shake_decay = decay
	shake_max_offset = max_offset
