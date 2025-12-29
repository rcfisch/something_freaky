extends GPUParticles2D
class_name WindTrail2D

@export var speed_start: float = 650.0   # start showing wind above walk speed
@export var speed_full: float = 900.0    # full intensity by this speed (dash/wavedash range)

@export var max_particles: int = 12      # overall density cap
@export var min_ratio: float = 0.0
@export var max_ratio: float = 0.6       # keep < 1.0 to avoid floods

@export var fade_in_speed: float = 10.0
@export var fade_out_speed: float = 16.0

var _player: Node = null
var _blend: float = 0.0

func _ready() -> void:
	_player = _find_player_owner()
	emitting = false
	amount = max_particles
	amount_ratio = 0.0

func _process(delta: float) -> void:
	if _player == null:
		_player = _find_player_owner()
		return

	var vel: Vector2 = _get_player_velocity()
	var speed: float = vel.length()

	# intensity curve: 0 at speed_start, 1 at speed_full
	var t: float = inverse_lerp(speed_start, speed_full, speed)
	t = clamp(t, 0.0, 1.0)

	# fade on/off based on whether we're above start
	var target_blend: float = 1.0 if speed > speed_start else 0.0
	var rate: float = fade_in_speed if target_blend > _blend else fade_out_speed
	_blend = move_toward(_blend, target_blend, rate * delta)

	var intensity: float = t * _blend

	emitting = intensity > 0.01
	amount_ratio = lerp(min_ratio, max_ratio, intensity)

func _get_player_velocity() -> Vector2:
	if _player.has_method("get_velocity"):
		return _player.call("get_velocity")
	if "velocity" in _player:
		return _player.velocity
	return Vector2.ZERO

func _find_player_owner() -> Node:
	var n: Node = self
	for i in range(8):
		if n == null:
			return null
		if "velocity" in n:
			return n
		n = n.get_parent()
	return null
