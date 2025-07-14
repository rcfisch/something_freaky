extends Camera2D

var shake_strength: float = 0.0
var shake_decay: float = 0.9
var shake_max_offset: float = 8.0
var rng := RandomNumberGenerator.new()

var vertical_offset : float = -300
var look_down_offset : float = 600
var looking_down : bool = true
var frames_to_look_down : int = 40
var down_frames_held : int = 0

func _ready():
	rng.randomize()
	position.y = vertical_offset
	

func _process(delta):
	if shake_strength > 0.01:
		offset = Vector2(
			rng.randf_range(-1, 1),
			rng.randf_range(-1, 1)
		) * shake_strength * shake_max_offset
		shake_strength *= shake_decay
	else:
		offset = Vector2.ZERO
func _physics_process(delta: float) -> void:
	if Input.is_action_pressed("down"):
		down_frames_held += 1
		if down_frames_held > frames_to_look_down:
			look_down()
	else:
		down_frames_held = 0
		reset_camera()

func start_shake(strength := 1.0, decay := 0.85, max_offset := 8.0):
	shake_strength = strength
	shake_decay = decay
	shake_max_offset = max_offset

func freeze_frames(timescale, duration) -> void:
	Engine.time_scale = timescale
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0

func look_down():
	looking_down = true
	position.y = lerp(position.y, look_down_offset, 0.1)
	
func reset_camera():
	looking_down = false
	position.y = lerp(position.y, vertical_offset, 0.2)
	
